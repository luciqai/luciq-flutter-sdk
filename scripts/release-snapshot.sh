#!/bin/bash
set -euo pipefail

# =============================================================================
# Luciq Flutter - Release Snapshot Generator (CI)
# -----------------------------------------------------------------------------
# Creates a customer release branch (e.g. release/bdr-thermea-<version>),
# bumps the SDK version strings, carries over the customer customizations that
# live in ArgsRegistry / luciq CLI (by branching from a base branch that
# already contains them), regenerates and commits the generated files
# (pigeon + mockito), then pushes the branch so it can be consumed as a git
# dependency (snapshot) from a host app's pubspec.yaml.
#
# ASSUMPTIONS (adjust flags if these are wrong):
#   * Customer-specific edits to:
#       - packages/luciq_flutter/ios/Classes/Util/ArgsRegistry.m
#       - packages/luciq_flutter/android/.../util/ArgsRegistry.java
#       - packages/luciq_cli/bin/luciq.dart
#     are already committed on the --base branch and are carried over simply by
#     branching from it. This script does NOT invent those edits.
#   * The new version is supplied explicitly with -v/--version.
#   * The native SDK versions default to the package version but can be
#     overridden per-platform with --android-sdk / --ios-sdk.
# =============================================================================

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

FLUTTER_PKG="packages/luciq_flutter"
PUBSPEC="$FLUTTER_PKG/pubspec.yaml"
BUILD_GRADLE="$FLUTTER_PKG/android/build.gradle"
PODSPEC="$FLUTTER_PKG/ios/luciq_flutter.podspec"
GEN_GITIGNORE="$FLUTTER_PKG/.gitignore"
REPO_URL="https://github.com/luciqai/luciq-flutter-sdk.git"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Portable in-place sed (BSD/macOS vs GNU/Linux CI).
sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

# -----------------------------------------------------------------------------
# Args
# -----------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $(basename "$0") -v VERSION [OPTIONS]

Required:
  -v, --version VERSION      Flutter package version for this release (e.g. 19.9.0)

Options:
  -p, --prefix PREFIX        Branch prefix / customer (default: bdr-thermea)
                             Branch becomes release/<PREFIX>-<VERSION>
  -b, --base BRANCH          Base branch to branch from (default: current branch).
                             Should already contain the customer customizations.
      --android-sdk VERSION  Native Android SDK version for build.gradle 'api'
                             (default: same as --version)
      --ios-sdk VERSION      Native iOS SDK version for podspec dependency
                             (default: same as --version)
  -s, --skip-gen             Skip pigeon + build_runner generation
  -n, --no-push              Commit locally but do not push
  -h, --help                 Show this help

Examples:
  $(basename "$0") -v 19.9.0
  $(basename "$0") -v 19.9.0 --android-sdk 19.9.0 --ios-sdk 19.9.1
  $(basename "$0") -v 19.9.0 -b master -p bdr-thermea
EOF
  exit 0
}

VERSION=""
PREFIX="bdr-thermea"
BASE_BRANCH=""
ANDROID_SDK=""
IOS_SDK=""
SKIP_GEN=false
NO_PUSH=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--version)     VERSION="$2"; shift 2 ;;
    -p|--prefix)      PREFIX="$2"; shift 2 ;;
    -b|--base)        BASE_BRANCH="$2"; shift 2 ;;
    --android-sdk)    ANDROID_SDK="$2"; shift 2 ;;
    --ios-sdk)        IOS_SDK="$2"; shift 2 ;;
    -s|--skip-gen)    SKIP_GEN=true; shift ;;
    -n|--no-push)     NO_PUSH=true; shift ;;
    -h|--help)        usage ;;
    *)                error "Unknown option: $1. Use --help for usage." ;;
  esac
done

[[ -z "$VERSION" ]] && error "Version is required. Use -v/--version VERSION"
[[ -z "$ANDROID_SDK" ]] && ANDROID_SDK="$VERSION"
[[ -z "$IOS_SDK" ]] && IOS_SDK="$VERSION"
[[ -z "$BASE_BRANCH" ]] && BASE_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

BRANCH_NAME="release/${PREFIX}-${VERSION}"

info "New version    : $VERSION"
info "Android SDK    : $ANDROID_SDK"
info "iOS SDK        : $IOS_SDK"
info "Base branch    : $BASE_BRANCH"
info "Release branch : $BRANCH_NAME"

# -----------------------------------------------------------------------------
# Step 1: Create release branch from the base branch
# -----------------------------------------------------------------------------
info "Fetching origin/$BASE_BRANCH..."
git fetch origin "$BASE_BRANCH"

if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" || \
   git ls-remote --exit-code --heads origin "$BRANCH_NAME" >/dev/null 2>&1; then
  error "Branch '$BRANCH_NAME' already exists (locally or on origin). Pick a new version."
fi

info "Creating '$BRANCH_NAME' from 'origin/$BASE_BRANCH'..."
git checkout -b "$BRANCH_NAME" "origin/$BASE_BRANCH"
success "Branch '$BRANCH_NAME' created."

# -----------------------------------------------------------------------------
# Step 2: Bump version strings
#   - build.gradle : version '<pkg>'  +  api 'ai.luciq.library:luciq:<android sdk>'
#   - podspec      : s.version '<pkg>' +  s.dependency 'Luciq', '<ios sdk>'
#   - pubspec.yaml : version: <pkg>
# -----------------------------------------------------------------------------
info "Bumping version in $BUILD_GRADLE..."
sed_inplace -E "s/^version '.*'/version '${VERSION}'/" "$BUILD_GRADLE"
sed_inplace -E "s#(ai\.luciq\.library:luciq:)[^']*#\1${ANDROID_SDK}#" "$BUILD_GRADLE"

info "Bumping version in $PODSPEC..."
sed_inplace -E "s/(s\.version[[:space:]]*=[[:space:]]*)'[^']*'/\1'${VERSION}'/" "$PODSPEC"
sed_inplace -E "s/(s\.dependency[[:space:]]+'Luciq',[[:space:]]*)'[^']*'/\1'${IOS_SDK}'/" "$PODSPEC"

info "Bumping version in $PUBSPEC..."
sed_inplace -E "s/^version:[[:space:]]*.*/version: ${VERSION}/" "$PUBSPEC"

success "Version strings updated."
git --no-pager diff -- "$BUILD_GRADLE" "$PODSPEC" "$PUBSPEC" || true

# -----------------------------------------------------------------------------
# Step 3: Regenerate pigeon + build_runner code
# -----------------------------------------------------------------------------
if [[ "$SKIP_GEN" == false ]]; then
  info "Running pigeon generation..."
  (cd "$FLUTTER_PKG" && sh scripts/pigeon.sh)
  success "Pigeon generation complete."

  info "Running build_runner..."
  (cd "$FLUTTER_PKG" && dart run build_runner build --delete-conflicting-outputs) \
    || warn "build_runner reported issues, continuing..."
  success "Code generation complete."
else
  warn "Skipping generation (--skip-gen)."
fi

# -----------------------------------------------------------------------------
# Step 4: Un-ignore generated files so they ship with the snapshot
# -----------------------------------------------------------------------------
info "Un-ignoring generated files in $GEN_GITIGNORE..."
for pattern in '*.mocks.dart' '*.g.dart' 'android/**/generated/' 'ios/**/Generated/'; do
  esc=$(printf '%s' "$pattern" | sed 's/[.[\*^$]/\\&/g')
  if grep -qE "^${esc}$" "$GEN_GITIGNORE" 2>/dev/null; then
    sed_inplace -E "s|^${esc}\$|# &|" "$GEN_GITIGNORE"
    success "Commented out '$pattern'"
  fi
done

info "Force-adding generated files..."
git add -f "$FLUTTER_PKG"/android/src/main/java/ai/luciq/flutter/generated/*.java 2>/dev/null || true
git add -f "$FLUTTER_PKG"/ios/Classes/Generated/*.h 2>/dev/null || true
git add -f "$FLUTTER_PKG"/ios/Classes/Generated/*.m 2>/dev/null || true
git add -f "$FLUTTER_PKG"/lib/src/generated/*.g.dart 2>/dev/null || true
git add -f "$FLUTTER_PKG"/test/*.mocks.dart 2>/dev/null || true
git add -f "$FLUTTER_PKG"/test/**/*.mocks.dart 2>/dev/null || true
success "Generated files staged."

# -----------------------------------------------------------------------------
# Step 5: Commit
# -----------------------------------------------------------------------------
info "Staging remaining changes..."
git add -A
if git diff --cached --quiet; then
  warn "No changes to commit."
else
  git commit -m "Release:${PREFIX}-${VERSION}

Snapshot release for ${PREFIX} based on Luciq Flutter ${VERSION}
(Android SDK ${ANDROID_SDK}, iOS SDK ${IOS_SDK})."
  success "Committed."
fi

# -----------------------------------------------------------------------------
# Step 6: Push
# -----------------------------------------------------------------------------
if [[ "$NO_PUSH" == false ]]; then
  info "Pushing '$BRANCH_NAME' to origin..."
  git push -u origin "$BRANCH_NAME"
  success "Pushed."
else
  warn "Skipping push (--no-push). Run: git push -u origin $BRANCH_NAME"
fi

# -----------------------------------------------------------------------------
# Step 7: Consumer instructions
# -----------------------------------------------------------------------------
cat <<EOF

===========================================================================
Snapshot branch ready: ${BRANCH_NAME}
===========================================================================

Add to the host app pubspec.yaml:

dependencies:
  luciq_flutter:
    git:
      url: ${REPO_URL}
      path: ${FLUTTER_PKG}
      ref: ${BRANCH_NAME}

EOF
