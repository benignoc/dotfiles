# YouTube API Setup Instructions

To use the `m3u_to_youtube.py` script, you need to create a project in the Google Cloud Console and obtain a `client_secret.json` file.

## 1. Create a Google Cloud Project
1.  Go to the [Google Cloud Console](https://console.cloud.google.com/).
2.  Click the project dropdown in the top left and select **New Project**.
3.  Name it (e.g., `mpv-youtube-manager`) and click **Create**.

## 2. Enable the YouTube Data API
1.  In the sidebar, go to **APIs & Services > Library**.
2.  Search for **YouTube Data API v3**.
3.  Select it and click **Enable**.

## 3. Configure the OAuth Consent Screen
1.  Go to **APIs & Services > OAuth consent screen**.
2.  Select **External** (unless you have a Workspace organization).
3.  Fill in the **App name** (e.g., `mpv-script`) and **User support email**.
4.  Add your email to **Developer contact information**.
5.  Click **Save and Continue** (you don't need to add scopes here yet).
6.  **⚠️ CRUCIAL STEP (Fixes Error 403: access_denied):**
    *   Under the **Test users** section, click **ADD USERS**.
    *   Enter your own Google email address (the one you will use to log in).
    *   Click **Save**. 
    *   *If you skip this, Google will block the login because the app is not "Verified" yet.*

## 4. Create Credentials
1.  Go to **APIs & Services > Credentials**.
2.  Click **Create Credentials** at the top and select **OAuth client ID**.
3.  Select **Application type: Desktop app**.
4.  Name it and click **Create**.
5.  A dialog will appear. Click **Download JSON**.

## 5. Place the File
1.  Rename the downloaded file to `client_secret.json`.
2.  Move it into the `scripts/` directory of this project.

The script will automatically handle the creation of `token.json` the first time you run it.
