---
description: Transform internal release notes into public-facing release notes for Flutter SDK consumers
---

# Create Public Release Notes

Transform internal release notes into public-facing release notes suitable for Flutter SDK consumers.

## Parameters

- `releaseNotesUrl` (required): The URL containing the internal release notes
  - Example: `releaseNotesUrl=https://your-wiki.com/Flutter+19.3.0+Internal+Release+Notes`
  - The version number will be automatically extracted from the URL

## Step 1: Extract Version and Request Content

Extract the version number from the `releaseNotesUrl` parameter.

Pattern: `Flutter+{version}+Internal+Release+Notes` or similar.

Prompt the user:

```
I'll help you transform the internal release notes from:
{releaseNotesUrl}

Since this page may require authentication, please follow these steps:

1. Open the URL in your browser: {releaseNotesUrl}
2. Copy ALL the release notes content from the page
3. Paste the content below

I'll transform it into professional, public-facing release notes for Flutter SDK v{version}.

Please paste the content now:
```

Wait for the user to provide the internal notes content.

## Step 2: Analyze and Categorize

Review the internal notes and for each item:
1. Identify the type (Feature, Improvement, Bug Fix, Other)
2. Determine if public-facing (remove internal-only items)
3. Extract the core user-facing change
4. Remove all internal jargon and references

## Step 3: Transform Content

### Tone and Style
- Professional, concise, and clear - write for SDK consumers
- Use team perspective: "We've added...", "Fixed an issue where...", "Improved..."

### Remove
- Ticket IDs (MOB-XXXX)
- Developer names
- Internal tools references
- Debug logs mentions
- CI/CD references
- QA process details
- Feature flags

### Keep
- New features
- Improvements
- Public bug fixes
- SDK API changes
- Performance enhancements
- Compatibility updates

### Generalize
- "Fixed internal Pigeon channel marshaling" -> "Improved platform communication reliability"
- "Updated NavigatorObserver implementation" -> "Enhanced screen tracking accuracy"

### Flutter-Specific Considerations
- Note which packages are affected if changes span multiple packages (luciq_flutter, luciq_dio_interceptor, etc.)
- Mention platform-specific fixes (iOS/Android) when relevant
- Highlight Dart API changes clearly

## Step 4: Generate Output

Format as a flat list with category prefixes:

```markdown
### Flutter SDK v{version} Release Notes

- **New Feature:** Added support for custom screen load tracking.
- **New Feature:** Introduced network request body capture via Dio interceptor.
- **Improvement:** Enhanced session replay performance on Android.
- **Improvement:** Reduced SDK initialization time.
- **Bug Fix:** Fixed an issue where crash reports were not sent when app was backgrounded.
- **Bug Fix:** Fixed a crash on iOS when navigating rapidly between screens.
- **Other:** Deprecated `oldMethod()` in favor of `newMethod()`.
```

### Breaking Changes

If breaking changes exist, list them first with warning prefix:

```markdown
- **Breaking:** Minimum Flutter SDK version increased to 3.10.0.
- **Breaking:** `LuciqWidget` now requires `navigatorKey` parameter.
```

## Step 5: Present and Refine

Show the generated notes and ask:
1. Adjust any wording?
2. Add or remove any items?
3. Save to a file?

## Step 6: Save Output (Optional)

If requested:
```bash
cat > flutter-sdk-v{version}-release-notes.md << 'EOF'
<content>

---
*Generated from: {releaseNotesUrl}*
*Version: {version}*
*Generated on: {current_date}*
EOF
```

## Quality Checklist

- [ ] No internal ticket IDs
- [ ] No developer names
- [ ] No internal tool mentions
- [ ] No technical jargon SDK users wouldn't understand
- [ ] All items are user-facing
- [ ] Language is professional and clear
- [ ] Each bullet is concise (1-2 lines max)
- [ ] Version number is correct
- [ ] Items are properly prefixed with categories
- [ ] Empty categories are omitted
- [ ] Multi-package changes are noted where relevant
- [ ] Platform-specific fixes mention the platform

## Examples

```
/create-public-release-notes releaseNotesUrl=https://your-wiki.com/Flutter+19.3.0+Internal+Release+Notes
```
