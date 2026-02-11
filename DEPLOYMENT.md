# Deployment Guide (iOS) 📱

Sharing your Flutter app with friends on iPhone requires navigating Apple's security model. You have two main options:

## Option 1: The "Hackathon Way" (Wired Install)
**Cost:** Free
**Requirements:** Mac, iPhone, USB Cable
**Pros:** Fast, no waiting for review.
**Cons:** Expires after 7 days (requires re-install), manual process.

### Steps:
1.  **Enable Developer Mode on iPhone:**
    *   Go to **Settings > Privacy & Security**.
    *   Scroll down to **Developer Mode** and turn it **ON**.
    *   Restart the phone if prompted.

2.  **Connect to Mac:**
    *   Plug the iPhone into your Mac.
    *   Unlock the phone and tap **"Trust This Computer"** if asked.

3.  **Open in Xcode:**
    *   Navigate to your project folder in Finder: calls `ios/Runner.xcworkspace`.
    *   Double-click to open it in Xcode.

4.  **Sign the App:**
    *   In Xcode, click on the root **Runner** project in the left sidebar.
    *   Select the **Signing & Capabilities** tab.
    *   Under **Team**, select your personal Apple ID (e.g., "Juan Jue (Personal Team)").
    *   *Note: If you don't see one, click "Add Account" and log in with your Apple ID.*

5.  **Run on Device:**
    *   In the top bar of Xcode, select your iPhone as the destination (instead of a simulator).
    *   Click the **Play** button (Run).
    *   *Alternatively, in terminal:* `flutter run --release -d <your_device_id>`

6.  **Trust the App (First Time Only):**
    *   On the iPhone, the app might not open immediately.
    *   Go to **Settings > General > VPN & Device Management**.
    *   Tap your Apple ID email under "Developer App".
    *   Tap **"Trust"**.

---

## Option 2: The "Pro Way" (TestFlight)
**Cost:** $99/year (Apple Developer Program)
**Requirements:** Apple Developer Account
**Pros:** Wireless install, lasts 90 days, professional.
**Cons:** Cost, requires App Store Connect setup.

### Steps:
1.  **Register App ID:**
    *   Log in to [Apple Developer Portal](https://developer.apple.com/).
    *   Create an App ID (matches `com.yourname.punca_ai` in your code).

2.  **Create App Record:**
    *   Log in to [App Store Connect](https://appstoreconnect.apple.com/).
    *   Create a New App using your App ID.

3.  **Archive & Upload:**
    *   In Xcode, select "Any iOS Device (arm64)" as destination.
    *   Go to **Product > Archive**.
    *   Once archived, click **"Distribute App"** -> **App Store Connect** -> **Upload**.

4.  **Invite Testers:**
    *   In App Store Connect, go to **TestFlight** tab.
    *   Under "Internal Testing", click **(+)** to add a group.
    *   Add your friends' emails. They will receive an invite to download the "TestFlight" app and install your app from there.
