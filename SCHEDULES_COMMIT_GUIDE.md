# View Schedules Feature - Commit Guide

## Files to Commit

### New Files
1. `lib/screens/teacher/teacher_schedules_screen.dart` - Main schedules screen
2. `lib/providers/app_provider.dart` - Theme provider (recreated)

### Modified Files
1. `lib/config/routes/app_routes.dart` - Added route
2. `lib/widgets/main_scaffold.dart` - Added navigation

---

## Commit Steps

### Step 1: Check Status
```bash
git status
```

Expected output:
```
Changes not staged for commit:
  modified:   lib/config/routes/app_routes.dart
  modified:   lib/widgets/main_scaffold.dart

Untracked files:
  lib/screens/teacher/teacher_schedules_screen.dart
  lib/providers/app_provider.dart
```

### Step 2: Stage All Files
```bash
git add lib/screens/teacher/teacher_schedules_screen.dart
git add lib/providers/app_provider.dart
git add lib/config/routes/app_routes.dart
git add lib/widgets/main_scaffold.dart
```

Or stage all at once:
```bash
git add lib/screens/teacher/teacher_schedules_screen.dart \
        lib/providers/app_provider.dart \
        lib/config/routes/app_routes.dart \
        lib/widgets/main_scaffold.dart
```

### Step 3: Verify Staging
```bash
git status
```

Expected output:
```
Changes to be committed:
  new file:   lib/providers/app_provider.dart
  new file:   lib/screens/teacher/teacher_schedules_screen.dart
  modified:   lib/config/routes/app_routes.dart
  modified:   lib/widgets/main_scaffold.dart
```

### Step 4: Commit
```bash
git commit -m "feat: implement view schedules feature for teacher"
```

Or with detailed message:
```bash
git commit -m "feat: implement view schedules feature for teacher

- Add TeacherSchedulesScreen to view assigned schedules
- Organize schedules by day of week
- Sort schedules by time within each day
- Display schedule details (subject, time, location, section)
- Add summary statistics (total schedules, days)
- Integrate with teacher navigation menu
- Support light and dark themes
- Include pull-to-refresh functionality
- Add error handling and empty state
- Recreate app_provider.dart for theme management"
```

### Step 5: Verify Commit
```bash
git log --oneline -1
```

Expected output:
```
[commit-hash] feat: implement view schedules feature for teacher
```

### Step 6: Push to Remote
```bash
git push origin ams-1-lightmode
```

---

## Commit Message Format

**Type**: `feat` (new feature)

**Scope**: `teacher` (teacher feature)

**Subject**: `implement view schedules feature for teacher`

**Body** (optional):
```
- Add TeacherSchedulesScreen
- Organize by day of week
- Sort by time
- Display schedule details
- Add summary statistics
- Integrate navigation
- Theme support
- Pull-to-refresh
- Error handling
```

---

## Verification Before Commit

### 1. Check for Errors
```bash
dart analyze lib/screens/teacher/teacher_schedules_screen.dart
dart analyze lib/config/routes/app_routes.dart
dart analyze lib/widgets/main_scaffold.dart
dart analyze lib/providers/app_provider.dart
```

Expected: No errors

### 2. Check Imports
```bash
grep -n "import.*teacher_schedules_screen" lib/config/routes/app_routes.dart
```

Expected: Import found

### 3. Check Routes
```bash
grep -n "teacherSchedules" lib/config/routes/app_routes.dart
```

Expected: Route constant and route mapping found

### 4. Check Navigation
```bash
grep -n "Schedules" lib/widgets/main_scaffold.dart
```

Expected: Navigation item found

---

## After Commit

### View the Commit
```bash
git show HEAD
```

### Create Pull Request
```bash
gh pr create --title "feat: implement view schedules for teacher" \
  --body "Adds schedule viewing feature for teachers with theme support and navigation integration"
```

### Merge to Main (when ready)
```bash
git checkout main
git pull origin main
git merge ams-1-lightmode
git push origin main
```

---

## Rollback (if needed)

### Undo Last Commit (keep changes)
```bash
git reset --soft HEAD~1
```

### Undo Last Commit (discard changes)
```bash
git reset --hard HEAD~1
```

### Undo Staging
```bash
git reset HEAD <file>
```

---

## Quick Commands

### All in One
```bash
git add lib/screens/teacher/teacher_schedules_screen.dart \
        lib/providers/app_provider.dart \
        lib/config/routes/app_routes.dart \
        lib/widgets/main_scaffold.dart && \
git commit -m "feat: implement view schedules feature for teacher" && \
git push origin ams-1-lightmode
```

### View Changes Before Commit
```bash
git diff --cached
```

### View Specific File Changes
```bash
git diff --cached lib/screens/teacher/teacher_schedules_screen.dart
```

---

## Commit Checklist

- [ ] All files staged
- [ ] No compilation errors
- [ ] No syntax errors
- [ ] Imports correct
- [ ] Routes added
- [ ] Navigation updated
- [ ] Commit message clear
- [ ] Ready to push

---

## Summary

**Files**: 4 (2 new, 2 modified)
**Lines Added**: ~400+
**Feature**: View Schedules for Teachers
**Status**: Ready to commit

---

**Ready to Commit** ✅
