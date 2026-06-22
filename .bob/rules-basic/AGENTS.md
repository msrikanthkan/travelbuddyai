# Project Basic Rules

## Task Logging

For every task created or updated, create a log file in the `tasks_logs/` directory with the following format:

### Log File Naming Convention
- **Format**: `yyyy-mm-ddTHH-mm-ss_<concise-task-summary>.md`
- **Example**: `2026-06-16T15-28-00_multiplication-tables-implementation.md`

### Log File Location
- **Directory**: `tasks_logs/` (in project root)
- Create the directory if it doesn't exist

### Log File Content
Include:
1. **Task Title** - Brief description
2. **Date/Time** - ISO 8601 format
3. **Objective** - What was the goal
4. **Changes Made** - List of files created/modified
5. **Key Features** - What was implemented
6. **Status** - Completed/In Progress/Blocked
7. **Next Steps** - What remains to be done (if applicable)

### Example Log File Structure
```markdown
# Task: [Task Name]

**Date**: 2026-06-16T15:28:00+05:30
**Status**: Completed

## Objective
Brief description of what needed to be done.

## Changes Made
- Created: file1.dart
- Modified: file2.dart
- Updated: documentation.md

## Key Features Implemented
- Feature 1
- Feature 2

## Next Steps
- Remaining task 1
- Remaining task 2
```

## Usage
This logging system helps track:
- Project evolution over time
- What was done in each session
- Decision rationale
- Future reference for similar tasks