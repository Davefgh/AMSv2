# View Schedules - UI Guide

## Screen Layout

### Header
```
┌─────────────────────────────────────────┐
│ 🔷 My Schedules                         │
└─────────────────────────────────────────┘
```

### Summary Section
```
┌─────────────────────────────────────────┐
│  📅 Total Schedules    📅 Days          │
│  5                     3                │
└─────────────────────────────────────────┘
```

### Weekly Schedule Section
```
Monday
─────────────────────────────────────────
┌─────────────────────────────────────────┐
│ IT1000                      8:00-9:00   │
│ Computing Fundamentals                  │
│ 📍 Room 101                             │
│ 👥 CS31B                                │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ IT2000                      10:00-11:00 │
│ Advanced Programming                    │
│ 📍 Room 102                             │
│ 👥 CS32A                                │
└─────────────────────────────────────────┘

Tuesday
─────────────────────────────────────────
┌─────────────────────────────────────────┐
│ IT3000                      2:00-3:00   │
│ Database Systems                        │
│ 📍 Room 103                             │
│ 👥 CS33B                                │
└─────────────────────────────────────────┘
```

---

## Light Mode

### Colors
```
Background:      White (#FFFFFF)
Cards:           White with shadow
Text:            Black (#000000)
Secondary:       Dark Gray (60% opacity)
Subject Code:    Cyan (#38BDF8)
Time Badge:      Green (#34D399)
Icons:           Dark Gray
```

### Example
```
┌─────────────────────────────────────────┐
│ IT1000                      8:00-9:00   │  ← Cyan code, Green time
│ Computing Fundamentals                  │  ← Black text
│ 📍 Room 101                             │  ← Dark gray secondary
│ 👥 CS31B                                │  ← Dark gray secondary
└─────────────────────────────────────────┘
  ↑ White card with shadow
```

---

## Dark Mode

### Colors
```
Background:      Dark Blue (#0F172A)
Cards:           Semi-transparent white
Text:            White (#FFFFFF)
Secondary:       Light Gray (50% opacity)
Subject Code:    Cyan (#38BDF8)
Time Badge:      Green (#34D399)
Icons:           Light Gray
```

### Example
```
┌─────────────────────────────────────────┐
│ IT1000                      8:00-9:00   │  ← Cyan code, Green time
│ Computing Fundamentals                  │  ← White text
│ 📍 Room 101                             │  ← Light gray secondary
│ 👥 CS31B                                │  ← Light gray secondary
└─────────────────────────────────────────┘
  ↑ Semi-transparent card
```

---

## Schedule Card Components

### Header Row
```
┌─────────────────────────────────────────┐
│ [Subject Code]              [Time Badge]│
│ IT1000                      8:00-9:00   │
└─────────────────────────────────────────┘
```

### Subject Name
```
┌─────────────────────────────────────────┐
│ Computing Fundamentals                  │
│ (Bold, larger text)                     │
└─────────────────────────────────────────┘
```

### Location Row
```
┌─────────────────────────────────────────┐
│ 📍 Room 101                             │
│ (Icon + Location)                       │
└─────────────────────────────────────────┘
```

### Section Row
```
┌─────────────────────────────────────────┐
│ 👥 CS31B                                │
│ (Icon + Section)                        │
└─────────────────────────────────────────┘
```

---

## Summary Cards

### Total Schedules Card
```
┌──────────────────┐
│      📅          │
│      5           │
│ Total Schedules  │
└──────────────────┘
```

### Days Card
```
┌──────────────────┐
│      📅          │
│      3           │
│      Days        │
└──────────────────┘
```

---

## Empty State

```
┌─────────────────────────────────────────┐
│                                         │
│            📅                           │
│                                         │
│      No schedules assigned              │
│                                         │
└─────────────────────────────────────────┘
```

---

## Error State

```
┌─────────────────────────────────────────┐
│                                         │
│            ⚠️                           │
│                                         │
│      Error loading schedules            │
│                                         │
│         [Retry Button]                  │
│                                         │
└─────────────────────────────────────────┘
```

---

## Loading State

```
┌─────────────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ (Skeleton)        │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                    │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                    │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                    │
└─────────────────────────────────────────┘
```

---

## Navigation

### Teacher Menu
```
┌─────────────────────────────────────────┐
│ 🏠 Home                                 │
│ 📚 Attendance                           │
│ 📱 Sessions                             │
│ 📅 Schedules ← NEW                      │
│ 👥 Sections                             │
└─────────────────────────────────────────┘
```

---

## Interactions

### Pull to Refresh
```
User pulls down on the schedule list
         ↓
Refresh indicator appears
         ↓
API fetches latest schedules
         ↓
List updates
```

### Theme Toggle
```
User clicks theme icon (top-right)
         ↓
Theme switches (light ↔ dark)
         ↓
All colors update instantly
         ↓
Schedule cards adapt to new theme
```

### Navigation
```
User clicks "Schedules" in menu
         ↓
Route: /teacher-schedules
         ↓
TeacherSchedulesScreen loads
         ↓
Schedules fetch from API
         ↓
Display schedules
```

---

## Responsive Design

### Mobile
```
Full width schedule cards
Single column layout
Bottom navigation bar
```

### Tablet
```
Wider schedule cards
Optimized spacing
Side navigation rail
```

### Desktop
```
Maximum width constraint
Centered layout
Side navigation rail
```

---

## Accessibility

### Icons
- 📅 Calendar: Schedules/Days
- 📍 Location: Classroom
- 👥 People: Section
- ⚠️ Warning: Error state

### Colors
- Cyan (#38BDF8): Subject code (distinct)
- Green (#34D399): Time (distinct)
- High contrast text in both modes

### Text
- Clear hierarchy
- Readable font sizes
- Proper spacing

---

## Animation

### Card Appearance
- Smooth fade-in
- Staggered animation
- 300ms duration

### Theme Switch
- Instant color change
- No animation lag
- Smooth transition

### Pull to Refresh
- Circular indicator
- Smooth rotation
- Completion animation

---

**UI Guide Complete** ✅
