#!/usr/bin/env python3
# /// script
# dependencies = [
#     "google-api-python-client",
#     "google-auth-oauthlib",
#     "google-auth-httplib2",
# ]
# ///

import os
import re
import sys
import argparse
import pickle
from pathlib import Path

from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

# If modifying these scopes, delete the file token.json.
SCOPES = ['https://www.googleapis.com/auth/youtube']

SCRIPT_DIR = Path(__file__).parent.resolve()
CLIENT_SECRET_FILE = SCRIPT_DIR / 'client_secret.json'
TOKEN_FILE = SCRIPT_DIR / 'token.json'

def get_authenticated_service():
    creds = None
    if TOKEN_FILE.exists():
        with open(TOKEN_FILE, 'rb') as token:
            creds = pickle.load(token)
    
    # If there are no (valid) credentials available, let the user log in.
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not CLIENT_SECRET_FILE.exists():
                print(f"Error: {CLIENT_SECRET_FILE} not found.")
                print("Follow the instructions in scripts/YOUTUBE_API_SETUP.md to create it.")
                sys.exit(1)
            
            flow = InstalledAppFlow.from_client_secrets_file(str(CLIENT_SECRET_FILE), SCOPES)
            creds = flow.run_local_server(port=0)
        
        # Save the credentials for the next run
        with open(TOKEN_FILE, 'wb') as token:
            pickle.dump(creds, token)

    return build('youtube', 'v3', credentials=creds)

def extract_video_id(url):
    """Extracts the YouTube video ID from a URL."""
    # Handle watch?v= format
    match = re.search(r"v=([a-zA-Z0-9_-]{11})", url)
    if match:
        return match.group(1)
    # Handle be/ format
    match = re.search(r"youtu\.be/([a-zA-Z0-9_-]{11})", url)
    if match:
        return match.group(1)
    return None

def parse_m3u(file_path):
    """Parses M3U file and returns a list of video IDs."""
    video_ids = []
    if not os.path.exists(file_path):
        print(f"Error: File {file_path} does not exist.")
        return video_ids

    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            vid_id = extract_video_id(line)
            if vid_id:
                video_ids.append(vid_id)
            else:
                print(f"Skipping non-YouTube URL: {line}")
    
    return video_ids

def get_playlist_id(youtube, title):
    """Checks if a playlist with the given title exists."""
    request = youtube.playlists().list(
        part="snippet",
        mine=True,
        maxResults=50
    )
    while request:
        response = request.execute()
        for item in response.get('items', []):
            if item['snippet']['title'] == title:
                return item['id']
        request = youtube.playlists().list_next(request, response)
    return None

def get_videos_in_playlist(youtube, playlist_id):
    """Returns a set of video IDs already in the playlist."""
    video_ids = set()
    request = youtube.playlistItems().list(
        part="snippet",
        playlistId=playlist_id,
        maxResults=50
    )
    print("Checking existing videos in playlist...")
    while request:
        response = request.execute()
        for item in response.get('items', []):
            video_ids.add(item['snippet']['resourceId']['videoId'])
        request = youtube.playlistItems().list_next(request, response)
    return video_ids

def create_playlist(youtube, title):
    """Creates a private YouTube playlist."""
    print(f"Creating NEW playlist: {title}...")
    request = youtube.playlists().insert(
        part="snippet,status",
        body={
          "snippet": {
            "title": title,
            "description": "Created from M3U via script",
          },
          "status": {
            "privacyStatus": "private"
          }
        }
    )
    response = request.execute()
    return response['id']

def add_video_to_playlist(youtube, playlist_id, video_id):
    """Adds a video to a YouTube playlist."""
    request = youtube.playlistItems().insert(
        part="snippet",
        body={
            "snippet": {
                "playlistId": playlist_id,
                "resourceId": {
                    "kind": "youtube#video",
                    "videoId": video_id
                }
            }
        }
    )
    try:
        request.execute()
        return "success"
    except Exception as e:
        if "quotaExceeded" in str(e):
            return "quota"
        print(f"Error adding video {video_id}: {e}")
        return "error"

def main():
    parser = argparse.ArgumentParser(description="Create/Sync a YouTube playlist from an M3U file.")
    parser.add_argument("m3u_file", help="Path to the M3U file")
    parser.add_argument("-n", "--name", help="Name of the playlist (defaults to filename)")
    args = parser.parse_args()

    m3u_path = Path(args.m3u_file)
    playlist_name = args.name if args.name else m3u_path.stem

    video_ids = parse_m3u(m3u_path)
    if not video_ids:
        print("No YouTube video IDs found in the file.")
        return

    print(f"File contains {len(video_ids)} unique-ish entries. Authenticating...")
    youtube = get_authenticated_service()

    try:
        playlist_id = get_playlist_id(youtube, playlist_name)
        existing_videos = set()

        if playlist_id:
            print(f"Found existing playlist '{playlist_name}' (ID: {playlist_id})")
            existing_videos = get_videos_in_playlist(youtube, playlist_id)
            print(f"Playlist already has {len(existing_videos)} videos.")
        else:
            playlist_id = create_playlist(youtube, playlist_name)
            print(f"Playlist created with ID: {playlist_id}")
    except Exception as e:
        if "quotaExceeded" in str(e):
            print("\n❌ API Quota is completely exhausted for today.")
            print("Even basic checks are being blocked. Please try again tomorrow!")
            return
        raise e

    # Filter out videos already in the playlist
    to_add = [v for v in video_ids if v not in existing_videos]
    
    if not to_add:
        print("All videos from the M3U are already in the YouTube playlist. Nothing to do!")
        return

    print(f"Need to add {len(to_add)} more videos.")
    
    added_count = 0
    for vid_id in to_add:
        status = add_video_to_playlist(youtube, playlist_id, vid_id)
        if status == "success":
            added_count += 1
            print(f"[{added_count}/{len(to_add)}] Added video: {vid_id}")
        elif status == "quota":
            print("\n❌ API Quota exceeded for today!")
            print(f"Added {added_count} videos today.")
            print(f"Remaining to add: {len(to_add) - added_count}")
            print("Please run the script again tomorrow to continue.")
            break
    
    if status != "quota":
        print(f"\nDone! Successfully added {added_count} videos to playlist '{playlist_name}'.")

if __name__ == "__main__":
    main()
