---
description: Create a PR with commit suggestion, template filling, and GitHub CLI
---

# Create Pull Request

Automates the complete PR workflow: suggest commit, fill PR template, create draft PR.

## Parameters

- `baseBranch` (optional): Target branch. Defaults to `master`.
- `taskUrl` (required): Jira task URL (e.g., `https://instabug.atlassian.net/browse/MOB-20541`).

## Step 0: Prerequisites Check

```bash
gh --version 2>/dev/null || echo "GH_CLI_NOT_INSTALLED"
```

If GitHub CLI is not installed, **STOP** and show:

```
GitHub CLI Required
========================
1. Install: brew install gh
2. Authenticate: gh auth login
3. Re-run: /create-pr
```

If installed, verify authentication:

```bash
gh auth status
```

**Only proceed if `gh` is installed and authenticated.**

---

## Step 1: Suggest Commit Message

Analyze staged/unstaged changes and suggest a commit message:

```
<type>(<scope>): <subject>

<body>
```

Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`

Scope should reference the affected package (e.g., `luciq_flutter`, `dio_interceptor`, `http_client`, `flutter_modular`, `flutter_ndk`).

Example:
```
feat(luciq_flutter): add screen loading time tracking

- Implement ScreenLoadingManager for measuring screen load durations
- Add route matching for automatic screen detection
- Include unit tests for edge cases
```

**Present the suggested commit message and wait for user approval.**

Once approved, show the user what will be staged and confirm before committing:

```bash
# Show current status so the user can review untracked/modified files
git status

# Stage explicit files only (never `git add -A` - it can sweep in .env, build artifacts, etc.)
git add <file1> <file2> ...

# Commit with the approved message
git commit -m "<approved-message>"
```

**Do not proceed until the user approves the file list, the message, and the commit succeeds.**

---

## Step 2: Generate PR Description

Read the PR template:

```bash
cat .github/pull_request_template.md
```

Fill the template based on the actual changes:

1. **Description of the change** - Summarize what changed and why
2. **Type of change** - Check the appropriate box based on the changes:
   - Bug fix, New feature, or Breaking change
3. **Related issues** - Use the `taskUrl` parameter to link the Jira ticket
4. **Checklists** - Fill based on analysis of the changes

**Present the filled template to the user and ask for modifications.**

---

## Step 3: Create Pull Request

Extract the task ID from `taskUrl` (the part after `/browse/`).

Generate PR title in format: `<type>: [TASK-ID] brief description`

Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`

Examples:
- `feat: [MOB-20541] add network request duration tracking to APM`
- `fix: [MOB-18732] fix crash when initializing SDK on iOS 14`
- `chore: [MOB-19000] update CI Flutter version to 3.24.3`

**Present the title to the user for approval.**

Once approved:

```bash
# Push the branch
git push -u origin HEAD

# Save PR description to a safe, unique temp file
tmpfile=$(mktemp)
cat > "$tmpfile" << 'EOF'
<filled PR template from Step 2>
EOF

# Create draft PR
gh pr create --base {baseBranch} --title "<approved-title>" --body-file "$tmpfile" --draft --assignee @me

# Clean up
rm "$tmpfile"
```

Display the PR URL when done.
