#!/bin/bash
set -euo pipefail

# =============================================================================
# BDR-Thermea Release Branch Generator
#
# Creates a `release/bdr-thermea-<VERSION>` branch after a normal SDK release.
#
# Strategy (why this is safe):
#   A bdr-thermea release is cut AFTER the matching master release, so master
#   already carries the correct plugin version AND the correct native SDK
#   dependency versions (which are set per-release and are NOT derived from the
#   plugin version). We therefore branch off origin/master and bump NOTHING —
#   we only layer on the three bdr-thermea customizations:
#
#     1. Android native dep group: ai.luciq.library:luciq
#                               -> ai.luciq.library-bdrthermea:luciq
#        (done version-agnostically, so it works for any release version)
#     2. Remove the internal Nexus maven repository block from build.gradle
#     3. Inject the extra LCQLocale entries into the Dart enum + the Android
#        (Java) and iOS (Obj-C) ArgsRegistry locale maps.
#
#   The locale entries are derived verbatim from the latest existing
#   release/bdr-thermea-* branch (overridable via --ref). The three files are
#   intentionally treated independently: they are not identical on the bdr
#   branch, and each references native enum constants that must exist in its own
#   platform SDK, so we reproduce the proven shipping state per file rather than
#   unifying the locale sets.
#
# Packaging mirrors scripts/snapshot.sh: non-essential packages are removed and
# generated files are committed so the branch is consumable via a git ref.
# =============================================================================

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

PUBSPEC="packages/luciq_flutter/pubspec.yaml"
GITIGNORE=".gitignore"
REPO_URL="https://github.com/luciqai/luciq-flutter-sdk.git"

BUILD_GRADLE="packages/luciq_flutter/android/build.gradle"
DART_LOCALES="packages/luciq_flutter/lib/src/modules/luciq.dart"
JAVA_LOCALES="packages/luciq_flutter/android/src/main/java/ai/luciq/flutter/util/ArgsRegistry.java"
OBJC_LOCALES="packages/luciq_flutter/ios/Classes/Util/ArgsRegistry.m"

NATIVE_GROUP_FROM="ai.luciq.library:luciq"
NATIVE_GROUP_TO="ai.luciq.library-bdrthermea:luciq"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# -----------------------------------------------------------------------------
# Parse arguments
# -----------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Creates release/bdr-thermea-<VERSION> off origin/master and layers on the
bdr-thermea customizations (native dep group, nexus removal, extra locales).

Options:
  -r, --ref BRANCH     bdr-thermea branch to derive locale entries from
                       (default: latest origin/release/bdr-thermea-*)
  -b, --base BRANCH    base branch to build from (default: current branch)
  -s, --skip-pigeon    Skip running pigeon / build_runner generation
  -n, --no-push        Don't push the branch after committing
  -h, --help           Show this help message

Examples:
  $(basename "$0")
  $(basename "$0") -r origin/release/bdr-thermea-19.8.0 -n
EOF
  exit 0
}

REF_BRANCH=""
BASE_BRANCH=""
SKIP_PIGEON=false
NO_PUSH=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--ref)          REF_BRANCH="$2"; shift 2 ;;
    -b|--base)         BASE_BRANCH="$2"; shift 2 ;;
    -s|--skip-pigeon)  SKIP_PIGEON=true; shift ;;
    -n|--no-push)      NO_PUSH=true; shift ;;
    -h|--help)         usage ;;
    *)                 error "Unknown option: $1. Use --help for usage." ;;
  esac
done

# -----------------------------------------------------------------------------
# Write the Python helper used for structural file edits (brace-aware nexus
# removal + locale-map merge). Python is used instead of sed/awk because macOS
# awk lacks asorti and the edits must stay indentation-tolerant.
# -----------------------------------------------------------------------------
HELPER="$(mktemp)"
cleanup() { rm -f "$HELPER"; }
trap cleanup EXIT

cat > "$HELPER" <<'PY'
import re
import sys

def strip_nexus(path):
    with open(path) as f:
        lines = f.readlines()
    out, i, removed = [], 0, False
    while i < len(lines):
        line = lines[i]
        if re.match(r'^\s*maven\s*\{', line):
            block, depth, j = [], 0, i
            while j < len(lines):
                block.append(lines[j])
                depth += lines[j].count('{') - lines[j].count('}')
                j += 1
                if depth <= 0:
                    break
            if any('luciq-internal' in b for b in block):
                removed = True
                i = j
                continue
            out.extend(block)
            i = j
            continue
        out.append(line)
        i += 1
    with open(path, 'w') as f:
        f.writelines(out)
    print('removed' if removed else 'absent')


KINDS = {
    'dart': {
        'start': re.compile(r'enum LCQLocale\s*\{'),
        'end':   re.compile(r'^\}'),
        'entry': re.compile(r'^\s*[A-Za-z]+,\s*$'),
    },
    'java': {
        'start': re.compile(r'locales\s*=\s*new ArgsMap<LuciqLocale>'),
        'end':   re.compile(r'^\s*\}\};'),
        'entry': re.compile(r'put\("LCQLocale\.'),
    },
    'objc': {
        'start': re.compile(r'\(ArgsDictionary \*\)locales'),
        'end':   re.compile(r'^\s*\};'),
        'entry': re.compile(r'@"LCQLocale\.'),
    },
}


def key_of(line):
    m = re.search(r'LCQLocale\.([A-Za-z]+)', line)
    if m:
        return m.group(1)
    m = re.match(r'\s*([A-Za-z]+)\s*,', line)
    return m.group(1) if m else None


def entries_of(lines, spec):
    """Return {key: stripped_line} for locale entries inside the block."""
    out = {}
    inside = False
    for line in lines:
        if not inside:
            if spec['start'].search(line):
                inside = True
            continue
        if spec['end'].match(line):
            break
        if spec['entry'].search(line):
            k = key_of(line)
            if k:
                out[k] = line.strip()
    return out


def merge_locales(target, ref, kind):
    spec = KINDS[kind]
    with open(target) as f:
        lines = f.readlines()
    with open(ref) as f:
        ref_lines = f.readlines()

    start = next((i for i, l in enumerate(lines) if spec['start'].search(l)), None)
    if start is None:
        sys.exit(f'locale block start not found in {target}')
    end = next((i for i in range(start + 1, len(lines))
                if spec['end'].match(lines[i])), None)
    if end is None:
        sys.exit(f'locale block end not found in {target}')

    block = lines[start + 1:end]
    entry_lines = [l for l in block if spec['entry'].search(l)]
    if not entry_lines:
        sys.exit(f'no locale entries found in {target}')
    indent = re.match(r'^(\s*)', entry_lines[0]).group(1)
    non_entry = [l for l in block if not spec['entry'].search(l)]

    target_map = entries_of(lines, spec)
    ref_map = entries_of(ref_lines, spec)
    added = sorted(k for k in ref_map if k not in target_map)

    merged = dict(target_map)
    for k in added:
        merged[k] = ref_map[k]

    rebuilt = non_entry + [f'{indent}{merged[k]}\n' for k in sorted(merged)]
    lines[start + 1:end] = rebuilt

    with open(target, 'w') as f:
        f.writelines(lines)
    print(' '.join(added))


cmd = sys.argv[1]
if cmd == 'strip-nexus':
    strip_nexus(sys.argv[2])
elif cmd == 'merge-locales':
    merge_locales(sys.argv[2], sys.argv[3], sys.argv[4])
else:
    sys.exit(f'unknown command: {cmd}')
PY

# -----------------------------------------------------------------------------
# Step 1: Resolve base + reference branches
# -----------------------------------------------------------------------------
if [[ -z "$BASE_BRANCH" ]]; then
  BASE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  [[ "$BASE_BRANCH" == "HEAD" ]] && error "Detached HEAD; pass an explicit --base BRANCH."
fi
info "Base branch: $BASE_BRANCH"

if [[ "$BASE_BRANCH" == origin/* ]]; then
  info "Fetching base branch ($BASE_BRANCH)..."
  git fetch origin "${BASE_BRANCH#origin/}"
fi
git rev-parse --verify --quiet "$BASE_BRANCH" >/dev/null || error "Base branch '$BASE_BRANCH' cannot be resolved."

info "Fetching bdr-thermea branches..."
git fetch origin '+refs/heads/release/bdr-thermea-*:refs/remotes/origin/release/bdr-thermea-*' 2>/dev/null || true

if [[ -z "$REF_BRANCH" ]]; then
  REF_BRANCH=$(git for-each-ref --sort=-v:refname \
    --format='%(refname:short)' \
    'refs/remotes/origin/release/bdr-thermea-*' | head -n1)
fi
[[ -z "$REF_BRANCH" ]] && error "No release/bdr-thermea-* branch found to derive locales from. Pass one with --ref."
git rev-parse --verify --quiet "$REF_BRANCH" >/dev/null || error "Reference branch '$REF_BRANCH' cannot be resolved."
info "Deriving locale customizations from: $REF_BRANCH"

# -----------------------------------------------------------------------------
# Step 2: Derive version & branch name from the base branch
# -----------------------------------------------------------------------------
SDK_VERSION=$(git show "$BASE_BRANCH:$PUBSPEC" | grep -m1 '^version:' | awk '{print $2}')
[[ -z "$SDK_VERSION" ]] && error "Could not extract SDK version from $BASE_BRANCH:$PUBSPEC"

BRANCH_NAME="release/bdr-thermea-${SDK_VERSION}"
info "SDK version: $SDK_VERSION"
info "Branch name: $BRANCH_NAME"

git rev-parse --verify --quiet "refs/heads/$BRANCH_NAME" >/dev/null \
  && error "Local branch '$BRANCH_NAME' already exists. Delete it or bump the release first."

# -----------------------------------------------------------------------------
# Step 3: Create the release branch from the base branch
# -----------------------------------------------------------------------------
info "Stashing local changes..."
STASH_TAG="bdr-release-$$"
STASHED=false
git stash push --include-untracked -m "$STASH_TAG" >/dev/null 2>&1 || true
if git stash list | grep -q "$STASH_TAG"; then
  STASHED=true
  success "Local changes stashed."
else
  info "No local changes to stash."
fi

info "Creating branch '$BRANCH_NAME' from $BASE_BRANCH..."
git checkout -b "$BRANCH_NAME" "$BASE_BRANCH"
success "Branch '$BRANCH_NAME' created."

if [[ "$STASHED" == true ]]; then
  git stash pop || warn "Failed to restore stashed changes; resolve manually."
fi

# -----------------------------------------------------------------------------
# Step 4: Remove all packages except luciq_flutter to reduce size
# -----------------------------------------------------------------------------
info "Removing non-essential packages..."
for pkg in packages/*/; do
  pkg_name=$(basename "$pkg")
  if [[ "$pkg_name" != "luciq_flutter" ]]; then
    rm -rf "$pkg"
    success "Removed packages/$pkg_name"
  fi
done

# -----------------------------------------------------------------------------
# Step 5: Run pigeon & build_runner to generate build files
# -----------------------------------------------------------------------------
if [[ "$SKIP_PIGEON" == false ]]; then
  info "Running pigeon generation..."
  (cd packages/luciq_flutter && sh scripts/pigeon.sh)
  success "Pigeon generation complete."

  info "Running build_runner..."
  (cd packages/luciq_flutter && dart run build_runner build -d) || warn "build_runner failed or not needed, continuing..."
  success "Code generation complete."
else
  warn "Skipping pigeon generation (--skip-pigeon)."
fi

# -----------------------------------------------------------------------------
# Step 6: Apply bdr-thermea customizations
# -----------------------------------------------------------------------------
info "Applying bdr-thermea customizations..."

# 6a. Swap the Android native dependency group (version-agnostic).
if grep -qF "$NATIVE_GROUP_FROM" "$BUILD_GRADLE"; then
  sed -i '' "s|${NATIVE_GROUP_FROM}|${NATIVE_GROUP_TO}|g" "$BUILD_GRADLE"
  success "Android dep group -> ${NATIVE_GROUP_TO}"
else
  warn "Android dep group '${NATIVE_GROUP_FROM}' not found (already customized?)."
fi

# 6b. Remove the internal Nexus maven repository block.
NEXUS_RESULT=$(python3 "$HELPER" strip-nexus "$BUILD_GRADLE")
if [[ "$NEXUS_RESULT" == "removed" ]]; then
  success "Removed internal Nexus maven repository block."
else
  warn "Internal Nexus maven block not present (already customized?)."
fi

# 6c. Inject the extra LCQLocale entries into each file from the ref branch.
REF_DART=$(mktemp); REF_JAVA=$(mktemp); REF_OBJC=$(mktemp)
git show "$REF_BRANCH:$DART_LOCALES" > "$REF_DART"
git show "$REF_BRANCH:$JAVA_LOCALES" > "$REF_JAVA"
git show "$REF_BRANCH:$OBJC_LOCALES" > "$REF_OBJC"

ADDED_DART=$(python3 "$HELPER" merge-locales "$DART_LOCALES" "$REF_DART" dart)
ADDED_JAVA=$(python3 "$HELPER" merge-locales "$JAVA_LOCALES" "$REF_JAVA" java)
ADDED_OBJC=$(python3 "$HELPER" merge-locales "$OBJC_LOCALES" "$REF_OBJC" objc)
rm -f "$REF_DART" "$REF_JAVA" "$REF_OBJC"

success "Locales added (Dart):  ${ADDED_DART:-none}"
success "Locales added (Java):  ${ADDED_JAVA:-none}"
success "Locales added (Obj-C): ${ADDED_OBJC:-none}"

# -----------------------------------------------------------------------------
# Step 7: Uncomment generated files in .gitignore and force-add them
# -----------------------------------------------------------------------------
info "Updating .gitignore to include generated files..."

PATTERNS_TO_COMMENT=(
  "*.mocks.dart"
  "*.g.dart"
)

for pattern in "${PATTERNS_TO_COMMENT[@]}"; do
  if grep -qE "^${pattern}$" "$GITIGNORE" 2>/dev/null; then
    sed -i '' "s|^${pattern}$|# ${pattern}|" "$GITIGNORE"
    success "Commented out '$pattern' in .gitignore"
  elif grep -qE "^\*\*/${pattern}$" "$GITIGNORE" 2>/dev/null; then
    sed -i '' "s|^\*\*/${pattern}$|# **/${pattern}|" "$GITIGNORE"
    success "Commented out '**/$pattern' in .gitignore"
  fi
done

for dir_pattern in "android/**/generated/" "ios/**/Generated/"; do
  full_pattern="**/${dir_pattern}"
  if grep -qF "${full_pattern}" "$GITIGNORE" 2>/dev/null; then
    sed -i '' "s|^${full_pattern}$|# ${full_pattern}|" "$GITIGNORE"
    success "Commented out '${full_pattern}' in .gitignore"
  fi
done

info "Force-adding generated files..."
git add -f packages/luciq_flutter/android/src/main/java/ai/luciq/flutter/generated/*.java 2>/dev/null || true
git add -f packages/luciq_flutter/ios/Classes/Generated/*.h 2>/dev/null || true
git add -f packages/luciq_flutter/ios/Classes/Generated/*.m 2>/dev/null || true
git add -f packages/luciq_flutter/lib/src/generated/*.g.dart 2>/dev/null || true
git add -f packages/luciq_flutter/test/**/*.mocks.dart 2>/dev/null || true
success "Generated files added."

# -----------------------------------------------------------------------------
# Step 8: Stage and commit all changes
# -----------------------------------------------------------------------------
info "Staging all changes..."
git add -A
git commit -m "Release:bdr-thermea-${SDK_VERSION}

Based on ${BASE_BRANCH} (${SDK_VERSION}).
bdr-thermea customizations derived from ${REF_BRANCH}:
- Android native dep group -> ${NATIVE_GROUP_TO}
- Removed internal Nexus maven repository
- Extra LCQLocale entries injected"
success "Changes committed."

# -----------------------------------------------------------------------------
# Step 9: Push branch
# -----------------------------------------------------------------------------
if [[ "$NO_PUSH" == false ]]; then
  info "Pushing branch to origin..."
  git push -u origin "$BRANCH_NAME"
  success "Branch pushed to origin."
else
  warn "Skipping push (--no-push). Run 'git push -u origin $BRANCH_NAME' when ready."
fi

# -----------------------------------------------------------------------------
# Step 10: Print usage instructions
# -----------------------------------------------------------------------------
echo ""
echo "==========================================================================="
echo -e "${GREEN}bdr-thermea release branch ready: ${BRANCH_NAME}${NC}"
echo "==========================================================================="
echo ""
echo -e "${CYAN}# pubspec.yaml${NC}"
cat <<YAML
dependencies:
  luciq_flutter:
    git:
      url: ${REPO_URL}
      path: packages/luciq_flutter
      ref: ${BRANCH_NAME}
YAML
echo ""
echo -e "${YELLOW}Verification commands:${NC}"
echo "  Android: cd packages/luciq_flutter/example/android && ./gradlew clean && ./gradlew androidDependencies"
echo "  iOS:     cd packages/luciq_flutter/example/ios && pod install"
echo ""
