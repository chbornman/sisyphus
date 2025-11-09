# TODO

## Future Enhancements

### High Priority
- [ ] **Tutorial/Onboarding Flow**
  - First-time user experience
  - Explain drag gesture for happiness scoring
  - Show how to add descriptions
  - Explain notification system
  - Show analysis/insights features

### Investigations
- [ ] **Push Notification Interactivity**
  - Investigate if we can add description AND score directly from notification
  - Research notification action buttons with text input (iOS/Android limitations)
  - Look into notification extensions or rich notifications
  - Goal: Allow tracking without opening the app at all
  - Fallback: Current approach (open app to timeslot)

### Medium Priority
- [ ] **Data Export/Import**
  - Export all timeslot data to JSON/CSV
  - Import data from backup file
  - Cloud sync option (Firebase/Supabase?)

- [ ] **Advanced Analytics**
  - Weekly/monthly happiness trends graph
  - Day-of-week patterns (e.g., "Mondays are tough")
  - Time-of-day patterns (e.g., "always happy at 6pm")
  - Correlation with descriptions (word cloud of happy moments)

- [ ] **Tags/Categories**
  - Allow tagging timeslots (e.g., "work", "family", "exercise")
  - Filter heatmap by tags
  - See which activities correlate with happiness

- [ ] **Goals/Streaks**
  - Set daily happiness goals
  - Track completion streaks
  - Celebrate milestones

- [ ] **Widgets**
  - iOS/Android home screen widgets
  - Quick score entry without opening app
  - Mini heatmap on home screen

### Low Priority
- [ ] **Customization**
  - Custom timeslot intervals (e.g., hourly instead of half-hourly)
  - Multiple accent color themes/presets
  - Custom notification messages

- [ ] **Social/Sharing**
  - Share weekly heatmap as image
  - Privacy-first: no cloud by default

- [ ] **Accessibility**
  - VoiceOver/TalkBack support
  - High contrast mode
  - Larger text options
  - Haptic feedback on score changes

## Technical Debt
- [ ] Write unit tests for utility functions
- [ ] Write widget tests for core components
- [ ] Set up integration tests for full user flows
- [ ] Performance profiling for large datasets (1+ years)
- [ ] Database query optimization with indexes
- [ ] Error handling and retry logic for failed operations

## Documentation
- [ ] API documentation for services
- [ ] Widget documentation with screenshots
- [ ] User manual/help section in-app
- [ ] Privacy policy
- [ ] Open source licenses attribution

## Known Issues
_None yet - add here as they're discovered during development_

---

**Note:** This is a living document. Update as features are implemented or priorities change.
