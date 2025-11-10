# Sisyphus Implementation Plan

A Flutter application for tracking happiness throughout the day with half-hour timeslots.

## Overview

Sisyphus allows users to track their happiness score (0-100) every half hour throughout the day. Users can drag horizontally on timeslots to set scores, add descriptions of activities, and visualize patterns over time through a heatmap and calendar views.

## Core Features

### 1. Main Timeslot View
- List of 48 half-hour timeslots (00:00 - 23:30)
- Horizontal drag gesture to set happiness score (0-100)
- Visual feedback: numeric score + opacity change based on score
- Tap to add description text
- Auto-scroll to current time on load

### 2. Calendar View
- View all past tracked days
- Mini visualization of each day's tracking
- Tap to view/edit historical timeslots
- Uses same timeslot widget as main view
- **Data retention: Forever** (all historical data preserved)

### 3. Analysis/Insights View
- Heatmap grid: 48 rows (timeslots) × N columns (days)
- Visual patterns showing happiness throughout days
- Top 10 happiest moments carousel with descriptions
- Bottom 10 lowest moments carousel (toggle)
- Color opacity represents happiness score

### 4. Push Notifications
- Every half hour, on the half hour
- Notification opens app to current timeslot for tracking
- User can enable/disable in settings
- Configurable start/end hours

### 5. Settings
- Theme toggle: Light/Dark
- Accent color picker
- Notification enable/disable
- Notification time range (start/end hours)

## Technical Stack

- **Framework:** Flutter
- **State Management:** Riverpod
- **Database:** SQLite (local storage)
- **Icons:** Hero Icons (no emojis)
- **Design:** Modern, thin borders, tightly rounded corners (8px radius)

## Theme Design

### Light Theme
- Background: `#FAFAFA` (off-white)
- Surface: `#FFFFFF`
- Text: `#1A1A1A`
- Border: `#E5E5E5`

### Dark Theme
- Background: `#1A1A1A` (dark grey)
- Surface: `#2A2A2A`
- Text: `#FAFAFA`
- Border: `#3A3A3A`

### Accent Color (User-selectable)
Opacity based on happiness score:
- 0-20: 20% opacity
- 21-40: 40% opacity
- 41-60: 60% opacity
- 61-80: 80% opacity
- 81-100: 100% opacity

### Design System
- **Border Radius:** 8px (tightly rounded)
- **Spacing:** 8px base unit (8, 16, 24, 32)
- **Icons:** Heroicons

## Implementation Phases

### Phase 1: Foundation
- Initialize Flutter project structure
- Set up SQLite database and migrations
- Create data models
- Set up Riverpod providers
- Implement theme system

### Phase 2: Core Feature (Main View)
- Build TimeslotListItem widget
- Implement horizontal drag detection
- Add numeric feedback during drag
- Create description editor dialog
- Test data persistence

### Phase 3: Navigation (Calendar)
- Build Calendar Screen
- Implement date selection
- Create mini heatmap visualization for calendar cells
- Reuse timeslot widgets for historical editing

### Phase 4: Analysis (Heatmap + Insights)
- Build heatmap grid visualization
- Implement description carousel
- Add top/bottom 10 filtering logic
- Add date range selector

### Phase 5: Notifications
- Set up flutter_local_notifications
- Implement half-hourly scheduling
- Handle notification taps
- Respect time range settings

### Phase 6: Settings
- Build settings UI
- Wire up theme changes
- Connect notification preferences
- Implement color picker

## User Interaction Flows

### Tracking Happiness
1. User receives notification at half-hour mark
2. Taps notification
3. App opens to current timeslot
4. User drags horizontally to set score (sees numeric feedback + color change)
5. User taps to add description (optional)
6. Data auto-saves

### Reviewing History
1. User navigates to Calendar view
2. Sees month grid with mini visualizations
3. Taps a past day
4. Bottom sheet opens with that day's full timeslot list
5. Can edit any historical entry

### Analyzing Patterns
1. User navigates to Analysis view
2. Views heatmap showing patterns across days/times
3. Scrolls through top 10 happiest moments
4. Toggles to view bottom 10 lowest moments
5. Identifies patterns (e.g., "always happy at 6pm on Fridays")

## Next Steps

See [TODO.md](TODO.md) for future enhancements and investigation items.
See [DATABASE.md](DATABASE.md) for detailed database schema.
See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed project structure and widget breakdown.
