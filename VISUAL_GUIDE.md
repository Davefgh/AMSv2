# Light Mode - Visual Implementation Guide

## Dashboard Header

### Dark Mode (Default)
```
┌─────────────────────────────────────────────────────────────┐
│ 🔷 Dashboard                                    🌙 (Toggle)  │
│ ─────────────────────────────────────────────────────────── │
│ 👤 Hi, Jovelyn Comaingking                    6:16 PM       │
│    INSTRUCTOR                                 Thursday, Apr 23│
└─────────────────────────────────────────────────────────────┘
```

### Light Mode
```
┌─────────────────────────────────────────────────────────────┐
│ 🔷 Dashboard                                    ☀️ (Toggle)  │
│ ─────────────────────────────────────────────────────────── │
│ 👤 Hi, Jovelyn Comaingking                    6:16 PM       │
│    INSTRUCTOR                                 Thursday, Apr 23│
└─────────────────────────────────────────────────────────────┘
```

---

## Stats Cards

### Dark Mode
```
┌──────────────────┐  ┌──────────────────┐
│ 📅               │  │ ✓                │
│ 10               │  │ 100%             │
│ Total Sessions   │  │ Attendance Rate  │
└──────────────────┘  └──────────────────┘

┌──────────────────┐  ┌──────────────────┐
│ ⏱️               │  │ 📚               │
│ 1                │  │ 1                │
│ Active Classes   │  │ Subjects Taught  │
└──────────────────┘  └──────────────────┘

Background: Dark blue with semi-transparent white cards
Text: White
```

### Light Mode
```
┌──────────────────┐  ┌──────────────────┐
│ 📅               │  │ ✓                │
│ 10               │  │ 100%             │
│ Total Sessions   │  │ Attendance Rate  │
└──────────────────┘  └──────────────────┘

┌──────────────────┐  ┌──────────────────┐
│ ⏱️               │  │ 📚               │
│ 1                │  │ 1                │
│ Active Classes   │  │ Subjects Taught  │
└──────────────────┘  └──────────────────┘

Background: White
Cards: White with subtle shadow
Text: Black
```

---

## Active Sessions Card

### Dark Mode
```
┌─────────────────────────────────────────┐
│ IT1000                          ACTIVE  │
│ CS31B                                   │
│                                         │
│ Computing Fundamentals                 │
│                                         │
│ 📍 Room 101  ⏰ Started: 6:00 AM       │
└─────────────────────────────────────────┘

Background: Semi-transparent white
Text: White
Secondary: Light gray
```

### Light Mode
```
┌─────────────────────────────────────────┐
│ IT1000                          ACTIVE  │
│ CS31B                                   │
│                                         │
│ Computing Fundamentals                 │
│                                         │
│ 📍 Room 101  ⏰ Started: 6:00 AM       │
└─────────────────────────────────────────┘

Background: White with shadow
Text: Black
Secondary: Dark gray
```

---

## Weekly Schedule

### Dark Mode
```
Monday
─────────────────────────────────────────
│ 8:00 AM - 9:00 AM
│ IT1000 - Computing Fundamentals
│ Room 101 • CS31B

Tuesday
─────────────────────────────────────────
│ 10:00 AM - 11:00 AM
│ IT2000 - Advanced Programming
│ Room 102 • CS32A

Text: White
Secondary: Light gray
Dividers: Light gray
```

### Light Mode
```
Monday
─────────────────────────────────────────
│ 8:00 AM - 9:00 AM
│ IT1000 - Computing Fundamentals
│ Room 101 • CS31B

Tuesday
─────────────────────────────────────────
│ 10:00 AM - 11:00 AM
│ IT2000 - Advanced Programming
│ Room 102 • CS32A

Text: Black
Secondary: Dark gray
Dividers: Light gray
```

---

## Color Palette

### Dark Mode
```
┌─────────────────────────────────────────┐
│ Background:     ████ #0F172A            │
│ Cards:          ████ rgba(255,255,255,5%)
│ Text:           ████ #FFFFFF            │
│ Secondary:      ████ rgba(255,255,255,50%)
│ Accent Cyan:    ████ #38BDF8            │
│ Accent Green:   ████ #34D399            │
│ Accent Yellow:  ████ #FBBF24            │
└─────────────────────────────────────────┘
```

### Light Mode
```
┌─────────────────────────────────────────┐
│ Background:     ████ #FFFFFF            │
│ Cards:          ████ #FFFFFF (shadow)   │
│ Text:           ████ #000000            │
│ Secondary:      ████ rgba(0,0,0,60%)    │
│ Accent Cyan:    ████ #38BDF8            │
│ Accent Green:   ████ #34D399            │
│ Accent Yellow:  ████ #FBBF24            │
└─────────────────────────────────────────┘
```

---

## Theme Toggle Button

### Location
```
┌─────────────────────────────────────────────────────────────┐
│ 🔷 Dashboard                                    [🌙] or [☀️] │
│                                                    ↑         │
│                                            Theme Toggle Here │
└─────────────────────────────────────────────────────────────┘
```

### Behavior
```
Click 🌙 (Dark Mode) → Switches to Light Mode (☀️)
Click ☀️ (Light Mode) → Switches to Dark Mode (🌙)

Theme changes instantly
Preference is saved automatically
```

---

## Card Shadow in Light Mode

```
Card with Shadow:
┌─────────────────────────────────┐
│                                 │
│  White Card Content             │
│                                 │
└─────────────────────────────────┘
  ╰─ Subtle shadow below card
     Blur: 12px
     Offset: (0, 4)
     Color: rgba(0, 0, 0, 8%)
```

---

## Navbar (Unchanged)

### Both Modes
```
┌─────────────────────────────────────────┐
│ 🏠 Home  │ 📚 Attendance  │ 📱 Sessions │
│ ─────────────────────────────────────── │
│ 👥 Sections                             │
└─────────────────────────────────────────┘

Navbar styling remains the same in both light and dark modes
Only the main content area changes
```

---

## Implementation Flow

```
User clicks theme toggle
        ↓
AppProvider.toggleDarkMode()
        ↓
Theme saved to storage
        ↓
notifyListeners() called
        ↓
All Consumer<AppProvider> widgets rebuild
        ↓
Dashboard instantly updates with new colors
        ↓
User sees light or dark mode
```

---

## Responsive Design

### Mobile
```
┌─────────────────────────────────┐
│ 🔷 Dashboard          [🌙] or [☀️]│
├─────────────────────────────────┤
│                                 │
│  Stats Cards (2 columns)        │
│                                 │
│  Active Sessions                │
│  Weekly Schedule                │
│                                 │
├─────────────────────────────────┤
│ 🏠 📚 📱 👥                      │
└─────────────────────────────────┘
```

### Tablet/Desktop
```
┌──────────────┬──────────────────────────────┐
│ 🏠 Home      │ 🔷 Dashboard      [🌙] or [☀️]│
│ 📚 Attendance├──────────────────────────────┤
│ 📱 Sessions │                              │
│ 👥 Sections │  Stats Cards (4 columns)     │
│              │                              │
│              │  Active Sessions | Schedule  │
│              │                              │
└──────────────┴──────────────────────────────┘
```

---

## Accessibility

### Text Contrast
- Dark Mode: White text on dark background ✓ High contrast
- Light Mode: Black text on white background ✓ High contrast
- Secondary text: Sufficient opacity for readability ✓

### Color Blindness
- Accent colors are distinct and not solely reliant on color
- Icons and text labels provide additional context
- No critical information conveyed by color alone

---

## Performance

- Theme switching is instant (no loading)
- Minimal memory overhead
- Efficient Provider pattern updates only affected widgets
- No animation lag or stuttering

---

**Visual Guide Complete** ✅
