#!/bin/bash
set -euo pipefail

# =============================================================================
# Flutter Snapshot Generator
# Automates the snapshot branch creation process for sharing custom SDK builds.
# =============================================================================

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

PUBSPEC="packages/luciq_flutter/pubspec.yaml"
GITIGNORE=".gitignore"
REPO_URL="https://github.com/luciqai/luciq-flutter-sdk.git"

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

Options:
  -t, --ticket TICKET_KEY   Jira ticket key (e.g. INSD-8796) [required]
  -s, --skip-pigeon         Skip running pigeon generation
  -n, --no-push             Don't push the branch after committing
  -h, --help                Show this help message

Examples:
  $(basename "$0") -t INSD-1234
  $(basename "$0") -t INSD-1234 -n
EOF
  exit 0
}

TICKET_KEY=""
SKIP_PIGEON=false
NO_PUSH=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -t|--ticket)        TICKET_KEY="$2"; shift 2 ;;
    -s|--skip-pigeon)   SKIP_PIGEON=true; shift ;;
    -n|--no-push)       NO_PUSH=true; shift ;;
    -h|--help)          usage ;;
    *)                  error "Unknown option: $1. Use --help for usage." ;;
  esac
done

[[ -z "$TICKET_KEY" ]] && error "Ticket key is required. Use -t/--ticket TICKET_KEY"

# -----------------------------------------------------------------------------
# Derive version & branch name
# -----------------------------------------------------------------------------
SDK_VERSION=$(grep -m1 '^version:' "$PUBSPEC" | awk '{print $2}')
[[ -z "$SDK_VERSION" ]] && error "Could not extract SDK version from $PUBSPEC"

BRANCH_NAME="snapshot/${SDK_VERSION}-${TICKET_KEY}"
info "SDK version: $SDK_VERSION"
info "Branch name: $BRANCH_NAME"

# -----------------------------------------------------------------------------
# Step 1: Create snapshot branch from latest master
# -----------------------------------------------------------------------------
info "Fetching latest master..."
git fetch origin master

info "Stashing local changes..."
git stash --include-untracked
STASHED=true

info "Creating branch '$BRANCH_NAME' from origin/master..."
git checkout -b "$BRANCH_NAME" origin/master
success "Branch '$BRANCH_NAME' created."

info "Restoring stashed changes..."
git stash pop || warn "Nothing to restore from stash."
STASHED=false

# -----------------------------------------------------------------------------
# Step 2: Remove all packages except luciq_flutter to reduce size
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
# Step 3: Run pigeon & build_runner to generate build files
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
# Step 4: Uncomment generated files in .gitignore and force-add them
# -----------------------------------------------------------------------------
info "Updating .gitignore to include generated files..."

# Comment out patterns that block generated files
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
# Pigeon generated files (Android Java, iOS ObjC, Dart)
git add -f packages/luciq_flutter/android/src/main/java/ai/luciq/flutter/generated/*.java 2>/dev/null || true
git add -f packages/luciq_flutter/ios/Classes/Generated/*.h 2>/dev/null || true
git add -f packages/luciq_flutter/ios/Classes/Generated/*.m 2>/dev/null || true
git add -f packages/luciq_flutter/lib/src/generated/*.g.dart 2>/dev/null || true
# Mockito generated files
git add -f packages/luciq_flutter/test/**/*.mocks.dart 2>/dev/null || true
success "Generated files added."

# -----------------------------------------------------------------------------
# Step 5: Stage and commit all changes
# -----------------------------------------------------------------------------
info "Staging all changes..."
git add -A
git commit -m "chore: create snapshot ${BRANCH_NAME}

Snapshot for ${TICKET_KEY} based on SDK version ${SDK_VERSION}."
success "Changes committed."

# -----------------------------------------------------------------------------
# Step 6: Push branch
# -----------------------------------------------------------------------------
if [[ "$NO_PUSH" == false ]]; then
  info "Pushing branch to origin..."
  git push -u origin "$BRANCH_NAME"
  success "Branch pushed to origin."
else
  warn "Skipping push (--no-push). Run 'git push -u origin $BRANCH_NAME' when ready."
fi

# -----------------------------------------------------------------------------
# Step 7: Print usage instructions for the user
# -----------------------------------------------------------------------------
echo ""
echo "==========================================================================="
echo -e "${GREEN}Snapshot branch ready: ${BRANCH_NAME}${NC}"
echo "==========================================================================="
echo ""
echo "Share the following with the user to install the snapshot:"
echo ""
echo -e "${CYAN}# pubspec.yaml${NC}"
cat <<YAML
dependencies:
  luciq_flutter:
    git:
      url: ${REPO_URL}
      path: packages/luciq_flutter
      ref: ${BRANCH_NAME}

# Add this only if the user has one of our network logging packages
# to avoid resolution conflict:
dependency_overrides:
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
