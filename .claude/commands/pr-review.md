---
description: Comprehensive PR code review with parallel analysis agents
---

# PR Code Review

Perform a thorough code review of the current branch's changes.

## Steps

### 1. Gather Changes

```bash
# Get the base branch
git log --oneline -1 origin/master

# Get all changed files
git diff origin/master...HEAD --name-only

# Get the full diff
git diff origin/master...HEAD

# Get commit history
git log origin/master...HEAD --oneline
```

### 2. Context Gathering

For each changed file, read surrounding context:
- Other methods in the same class
- Related test files
- Pigeon API definitions if platform channel code changed
- Public exports if API surface changed

### 3. Review Categories

Analyze changes across these dimensions in parallel:

**a. Logical Errors**
- Off-by-one errors, null handling, missing edge cases
- Incorrect platform channel data mapping
- Missing await on Futures

**b. Flutter/Dart Standards**
- Follows effective Dart guidelines
- Proper use of null safety
- Widget lifecycle correctness
- Proper use of async/await patterns

**c. Platform Channel Safety**
- Pigeon API contracts are consistent
- PlatformException handling
- Data serialization correctness between Dart and native

**d. Test Coverage**
- New code has tests
- Tests cover error paths
- Mocks are properly set up

**e. Performance**
- No unnecessary rebuilds
- No blocking operations on main isolate
- Efficient data structures

**f. SDK Best Practices**
- No host app crashes
- Backward compatible
- Follows existing module patterns

### 4. Report

For each issue found:
- **File:line** - exact location
- **Severity** - critical / warning / suggestion
- **Issue** - what's wrong
- **Before/After** - code showing the fix
- **Explanation** - why it matters
