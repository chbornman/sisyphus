# Enhanced Notification Architecture

## Problem Solved

Your notification system had critical issues that caused a 5-day delay:

1. **Silent Timezone Failure**: The old code used `DateTime.now().timeZoneName` which returns abbreviated names (PST) instead of IANA identifiers (America/Los_Angeles), causing crashes
2. **Fire-and-Forget Scheduling**: Errors were caught but never surfaced to the user
3. **7-Day Cliff**: Notifications only scheduled for 7 days, then stopped working
4. **No Health Monitoring**: No way to know if notifications were actually working
5. **No Recovery Mechanism**: Once broken, stayed broken until manual fix

## New Architecture

### Three-Tier Scheduling Strategy

#### Tier 1: Immediate Notifications (48 hours)
- Schedules ~40 individual notifications for the next 48 hours
- Stays well under iOS 64-notification limit
- Provides immediate, reliable notifications

#### Tier 2: Daily Bootstrap
- ONE recurring daily notification at user's start time
- Runs silently in background
- When fires, schedules that day's remaining notifications
- Ensures notifications continue beyond initial 48 hours

#### Tier 3: Background Task (Safety Net)
- WorkManager runs every 12 hours
- Checks notification health
- Automatically reschedules if unhealthy or count is low
- Works even if app hasn't been opened in days

## Key Components

### 1. EnhancedNotificationService
- **Location**: `lib/features/notifications/services/enhanced_notification_service.dart`
- **Purpose**: Main service coordinating all notification operations
- **Features**:
  - Health monitoring integration
  - Error recovery mechanisms
  - Status tracking and reporting
  - Test notification capability

### 2. NotificationScheduler
- **Location**: `lib/features/notifications/services/notification_scheduler.dart`
- **Purpose**: Implements tiered scheduling strategy
- **Features**:
  - Conservative notification limits (40 max)
  - Bootstrap notification management
  - Platform-aware scheduling

### 3. NotificationHealthMonitor
- **Location**: `lib/features/notifications/services/notification_health_monitor.dart`
- **Purpose**: Monitors system health and provides diagnostics
- **Health States**:
  - 🟢 **Healthy**: 20+ notifications scheduled, no errors
  - 🟠 **Degraded**: <20 notifications scheduled
  - 🔴 **Unhealthy**: No notifications or errors present
  - ⚪ **Unknown**: Initial state

### 4. BackgroundTaskHandler
- **Location**: `lib/features/notifications/services/background_task_handler.dart`
- **Purpose**: Ensures notifications keep working without app opens
- **Schedule**: Every 12 hours
- **Actions**:
  - Check notification health
  - Reschedule if count < 20
  - Attempt recovery if unhealthy
  - Update last refresh timestamp

### 5. UI Components

#### NotificationStatusCard
- Shows current health status with color-coded indicators
- Displays scheduled count and next notification time
- Provides "Fix" button for unhealthy state
- Shows last update time

#### NotificationDiagnosticsDialog
- Detailed breakdown of notification types
- Platform limit warnings
- Recommendations for fixing issues
- Test notification button
- Error details with copy functionality

## User Experience Improvements

### Visible Status
Users can now see:
- ✅ How many notifications are scheduled
- ⏰ When the next notification will fire
- 🏥 Health status (healthy/degraded/unhealthy)
- 🔧 Automatic fix suggestions

### Automatic Recovery
The system now:
- Detects failures automatically
- Attempts self-healing
- Provides manual recovery options
- Shows clear error messages

### No More Silent Failures
- Errors are captured and displayed
- Health status visible in Settings
- Diagnostic tools for troubleshooting
- Test notifications for verification

## How It Works

### On App Launch
```
1. Initialize enhanced notification service
2. Check health status
3. If unhealthy → attempt recovery
4. Schedule notifications with tiered strategy
5. Register background task
6. Update status in UI
```

### When User Enables Notifications
```
1. Request permissions
2. Schedule Tier 1 (immediate 48hr)
3. Schedule Tier 2 (daily bootstrap)
4. Register background task
5. Save status to database
6. Show health in UI
```

### Daily Bootstrap Process
```
1. Silent notification fires at start time
2. App wakes in background
3. Schedules today's remaining notifications
4. Updates bootstrap timestamp
5. Continues even if app not opened
```

### Background Task (Every 12 Hours)
```
1. Check if notifications enabled
2. Get current health status
3. If unhealthy or count < 20:
   - Attempt recovery
   - Reschedule all notifications
4. Update refresh timestamp
```

## Testing the System

### Manual Tests
1. **Enable notifications** → Check status card shows "Healthy"
2. **Tap "View Details"** → See diagnostic information
3. **Tap "Test"** in diagnostics → Receive test notification
4. **Disable and re-enable** → Verify recovery works
5. **Change time range** → Confirm rescheduling

### Verify Background Tasks
```bash
# Check logs for background task registration
flutter run --verbose | grep "Background task"

# Should see:
# ✅ Background task registered: runs every 12 hours
```

### Debug Notifications
```bash
# View all scheduled notifications
flutter run --verbose | grep "Scheduled"

# Monitor health checks
flutter run --verbose | grep "Health"
```

## Migration from Old System

The new system is backward compatible:
1. Old notification service methods still work
2. Database structure unchanged
3. Settings preserved
4. Automatic migration on first run

## Platform Considerations

### iOS
- Respects 64-notification limit
- Uses Darwin-specific notification settings
- Background fetch minimum 15 minutes

### Android
- Supports up to 500 notifications
- Exact alarm permission handling
- WorkManager for reliable background execution

## Error Handling

### Common Issues and Solutions

1. **"Invalid timezone setting"**
   - Cause: Device timezone not recognized
   - Fix: Automatically falls back to UTC
   - User action: None required

2. **"Notifications not working"**
   - Cause: Permissions revoked
   - Fix: Automatic permission check
   - User action: Grant permissions when prompted

3. **"Low notification count"**
   - Cause: Near platform limit
   - Fix: Conservative scheduling
   - User action: None required

## Future Improvements

Consider adding:
1. Push notifications for infinite range
2. Server-side scheduling
3. Notification templates/customization
4. Interactive notification actions
5. Analytics on notification engagement

## Summary

The enhanced notification system solves all identified issues:

✅ **No more silent failures** - Health monitoring catches all errors
✅ **No more 5-day delays** - Proper timezone handling with fallbacks
✅ **No more 7-day cliff** - Bootstrap + background tasks ensure continuity
✅ **User visibility** - Clear status and diagnostic tools
✅ **Self-healing** - Automatic recovery mechanisms

The system is now robust, user-friendly, and maintains itself even without regular app usage.