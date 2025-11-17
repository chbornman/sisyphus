# Screenshot Setup Guide for Sisyphus

This guide will help you set up automated screenshot generation using fastlane snapshot.

## What's Been Configured

✅ UI test file created: `ios/RunnerUITests/RunnerUITests.swift`
✅ Snapfile configured with App Store required devices
✅ SnapshotHelper.swift already present in `ios/fastlane/`
✅ Screenshots lane already exists in Fastfile

## Steps to Complete Setup

### 1. Add UI Test Target to Xcode

You need to add the RunnerUITests target to your Xcode project:

1. Open `ios/Runner.xcworkspace` in Xcode
2. In the Project Navigator, select the **Runner** project (the blue icon at the top)
3. In the main editor area, click the **+** button at the bottom of the targets list
4. Select **iOS** → **UI Testing Bundle**
5. Click **Next**
6. Configure the target:
   - **Product Name**: `RunnerUITests`
   - **Team**: Select your development team
   - **Organization Identifier**: Use your existing identifier
   - **Project**: Runner
   - **Target to be Tested**: Runner
7. Click **Finish**

### 2. Replace Generated Files

Xcode will create a default test file. Replace it with our configured files:

1. In the Project Navigator, expand **RunnerUITests** folder
2. Delete the auto-generated `RunnerUITests.swift` file (Move to Trash)
3. Right-click on **RunnerUITests** folder → **Add Files to "Runner"...**
4. Navigate to `ios/RunnerUITests/` and select:
   - `RunnerUITests.swift`
   - `Info.plist`
5. Make sure **"Copy items if needed"** is UNCHECKED (we want references)
6. Click **Add**

### 3. Add SnapshotHelper to UI Test Target

1. In the Project Navigator, find `ios/fastlane/SnapshotHelper.swift`
2. Click on the file to select it
3. In the File Inspector (right sidebar), under **Target Membership**:
   - ✅ Check **RunnerUITests**
   - ⬜ Uncheck **Runner** (if checked)

### 4. Configure UI Test Target Settings

1. Select the **RunnerUITests** target in the project settings
2. Go to **Build Settings** tab
3. Search for "Swift Language Version" and set it to **Swift 5** or later

### 5. Update the Test Selectors (Important!)

The UI test file uses generic selectors. You need to update them based on your app's actual UI:

Open `ios/RunnerUITests/RunnerUITests.swift` and update:
- Button identifiers (e.g., "Settings", "Analysis")
- Navigation elements
- Any specific UI elements you want to interact with

To find the correct accessibility identifiers:
1. Run your app in the simulator
2. Open **Xcode** → **Debug** → **View Debugging** → **Capture View Hierarchy**
3. Inspect elements to find their accessibility identifiers

### 6. Add Accessibility Identifiers to Your Flutter Widgets

In your Flutter code, add `Key` or `Semantics` widgets to make elements testable:

```dart
// Example: Add a key to the settings button
IconButton(
  key: const Key('settings_button'),
  icon: Icon(Icons.settings),
  onPressed: () => // ...
)
```

In XCUITest, this becomes: `app.buttons["settings_button"]`

### 7. Build and Test

1. In Xcode, select the **RunnerUITests** scheme
2. Select a simulator (e.g., iPhone 15 Pro)
3. Press **Cmd+U** to run the UI tests
4. Verify the tests run and the app launches

## Taking Screenshots

Once everything is set up, you can generate screenshots:

### Option 1: Using fastlane (Recommended)

```bash
cd ios
fastlane screenshots
```

This will:
- Run UI tests on all configured devices
- Capture screenshots automatically
- Save them to `ios/fastlane/screenshots/`
- Upload them to App Store Connect

### Option 2: Just capture (no upload)

Update the `screenshots` lane in `ios/fastlane/Fastfile`:

```ruby
desc "Generate new localized screenshots"
lane :screenshots do
  capture_screenshots(scheme: "Runner")
  # Remove the upload_to_app_store call if you don't want to upload
end
```

Then run:
```bash
cd ios
fastlane screenshots
```

## Configured Devices

Screenshots will be generated for:
- iPhone 15 Pro Max (6.7")
- iPhone 15 Pro (6.1")
- iPhone SE 3rd gen (4.7")
- iPad Pro 12.9" (6th gen)
- iPad Pro 11" (4th gen)

These match App Store Connect requirements.

## Customizing Screenshots

Edit `ios/RunnerUITests/RunnerUITests.swift` to:
- Add more screenshots with `snapshot("name")`
- Navigate to different screens
- Set up test data
- Interact with UI elements

## Troubleshooting

### "No such module 'XCTest'"
- Make sure you added the UI Testing Bundle target (not Unit Testing Bundle)

### "SnapshotHelper.swift not found"
- Verify SnapshotHelper.swift is added to RunnerUITests target membership

### Tests fail to find UI elements
- Add accessibility identifiers to your Flutter widgets
- Use Xcode's View Hierarchy debugger to inspect element identifiers
- Add delays (`sleep(1)`) between actions to wait for animations

### Simulator doesn't launch
- Clean build folder: **Cmd+Shift+K**
- Quit and restart Xcode
- Reset simulator: Device → Erase All Content and Settings

## Resources

- [fastlane snapshot docs](https://docs.fastlane.tools/actions/snapshot/)
- [XCUITest documentation](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [Flutter testing guide](https://docs.flutter.dev/testing)

---

**Next Steps**: Follow steps 1-7 above, then run `cd ios && fastlane screenshots` to generate your first set of automated screenshots!
