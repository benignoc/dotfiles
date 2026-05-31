# Implementation Plan: M3U to YouTube Playlist Script

## Objective
Create a script that reads an M3U playlist file containing YouTube links and automatically creates a corresponding playlist on the user's YouTube account, ensuring sensitive authentication credentials are ignored by git.

## Key Files & Context
- `scripts/m3u_to_youtube.py`: The new script to be created.
- `.gitignore`: Will be created/updated to protect OAuth secrets.
- `playlists/*.m3u`: The input files to be parsed.

## Implementation Steps

### 1. Protect Secrets (.gitignore)
- Create or update a `.gitignore` file at the root of `dotfiles/mpv/`.
- Add `client_secret*.json` and `token*.json` to ensure these files are never committed to GitHub.

### 2. Create the Script (`scripts/m3u_to_youtube.py`)
- Implement an inline dependencies block (`/// script`) specifying `google-api-python-client`, `google-auth-httplib2`, and `google-auth-oauthlib`.
- **M3U Parsing:** Read the M3U file, ignore comments (lines starting with `#`), and extract YouTube video IDs from the URLs using regex or string manipulation.
- **YouTube API Authentication:** 
  - Define OAuth 2.0 scopes (`https://www.googleapis.com/auth/youtube`).
  - Read `client_secret.json` from the `scripts/` directory.
  - Perform the OAuth flow using `InstalledAppFlow`. It will prompt the user to log in via a browser if no valid `token.json` exists.
  - Save the resulting credentials to `token.json`.
- **Playlist Creation:** Create a new playlist using the `youtube.playlists().insert` endpoint. The name of the playlist will be derived from the M3U file name by default.
- **Adding Items:** Iterate over the extracted video IDs and use `youtube.playlistItems().insert` to add each video to the newly created playlist.

## Verification & Testing
- Ensure `.gitignore` successfully hides `client_secret.json` and `token.json`.
- Execute the script on a small test M3U file (e.g., `playlists/rock.m3u` or a custom test file with 2-3 links).
- Verify the playlist is created correctly on YouTube and contains the expected videos.

## Instructions for Setting Up YouTube API
Once the code is written, you will need to follow these steps to generate your `client_secret.json`:
1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new Project (e.g., "MPV Playlist Manager").
3. Navigate to **APIs & Services > Library** and search for "YouTube Data API v3". Click **Enable**.
4. Navigate to **APIs & Services > OAuth consent screen**. Choose "External", fill in the required app name and user support email. Add yourself as a Test User.
5. Navigate to **APIs & Services > Credentials**. Click **Create Credentials** > **OAuth client ID**.
6. Choose **Desktop app** as the application type.
7. Click **Download JSON** on the created credential and save it as `scripts/client_secret.json`.