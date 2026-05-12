---
description: Research and document how specific parts of the codebase work
---

# Research Codebase

Research a specific topic in the Luciq Flutter SDK codebase and document findings.

## Parameters

- `topic` (required): What to research (e.g., "how screen loading tracking works", "crash reporting flow")

## Steps

1. **Decompose the question** into searchable sub-topics

2. **Search the codebase** using multiple strategies:
   - Grep for relevant class names, method names, and keywords
   - Glob for relevant file patterns
   - Read key files to understand implementation

3. **Trace the flow** from public API to platform channel:
   - Start from the public module class in `lib/src/modules/`
   - Follow through to Pigeon API definitions in `pigeons/`
   - Check generated code in `lib/src/generated/`
   - Note any utilities involved from `lib/src/utils/`

4. **Document findings** with:
   - Overview of the feature/system
   - Entry points (file:line references)
   - Core implementation details
   - Data flow (Dart -> Pigeon -> Native)
   - Key patterns used
   - Test coverage locations

## Rules

- Document and explain the codebase as it exists - no improvements or suggestions
- All file paths must be relative to the repo root
- Include file:line references for key code locations
- Focus on accuracy over completeness
