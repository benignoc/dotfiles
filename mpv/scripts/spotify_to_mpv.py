#!/usr/bin/env python3
# /// script
# dependencies = ["yt-dlp", "tqdm"]
# ///
import json
import os
import sys
import argparse
import concurrent.futures
import re
from pathlib import Path
from typing import Dict, List, Any
from tqdm import tqdm

try:
    from yt_dlp import YoutubeDL
except ImportError:
    print("Missing dependency: yt-dlp\nInstall with: pip install yt-dlp", file=sys.stderr)
    sys.exit(1)

# Configuration
SCRIPT_DIR = Path(__file__).parent.resolve()
BASE_DIR = SCRIPT_DIR.parent
DEFAULT_INPUT = BASE_DIR / "playlists" / "saved_tracks.json"
DEFAULT_OUTPUT_DIR = BASE_DIR / "playlists"
CACHE_FILE = DEFAULT_OUTPUT_DIR / "yt_cache.json"
MAX_WORKERS = 10  # Number of concurrent searches

# Major genre mapping (Optional: if we want to collapse many subgenres)
GENRE_GROUPS = {
    "Rock": ["rock", "classic rock", "art rock", "hard rock", "progressive rock", "psychedelic rock", "folk rock", "soft rock", "modern rock", "garage rock", "grunge"],
    "Jazz": ["jazz", "bebop", "cool jazz", "jazz piano", "vocal jazz", "jazz fusion", "jazz funk", "ecm-style jazz", "contemporary post-bop"],
    "Soul": ["soul", "motown", "neo soul", "r&b", "indie soul", "pop soul"],
    "Pop": ["pop", "dance pop", "synthpop", "art pop", "indie pop", "new wave"],
    "Folk": ["folk", "singer-songwriter", "americana", "acoustic pop", "indie folk"],
    "Blues": ["blues", "blues rock", "electric blues", "delta blues"],
    "Latin": ["latin", "salsa", "bolero", "cumbia", "tango", "flamenco", "rumba"],
    "Electronic": ["electronica", "downtempo", "trip hop", "house", "techno", "disco"],
}

def load_cache() -> Dict[str, Dict[str, Any]]:
    if CACHE_FILE.exists():
        try:
            with open(CACHE_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception as e:
            print(f"Warning: Could not load cache: {e}")
    return {}

def save_cache(cache: Dict[str, Dict[str, Any]]):
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        json.dump(cache, f, indent=4)

def get_yt_url(track: Dict[str, Any], ydl: YoutubeDL) -> Dict[str, Any]:
    track_id = track["track_id"]
    name = track["name"]
    artists = ", ".join(track["artist"])
    spotify_duration = track.get("duration_ms", 0) / 1000
    query = f"{artists} - {name}"
    
    try:
        # Search for the top 3 results to find the best match
        search_results = ydl.extract_info(f"ytsearch3:{query}", download=False)
        if "entries" in search_results and search_results["entries"]:
            best_match = None
            min_diff = float("inf")
            
            for entry in search_results["entries"]:
                if not entry: continue
                yt_duration = entry.get("duration", 0)
                
                # Validation: YouTube result should be within 15 seconds of Spotify duration
                # This helps avoid picking up 10-minute "extended mixes" or 1-hour "best of" videos
                diff = abs(yt_duration - spotify_duration)
                if diff < 15 and diff < min_diff:
                    min_diff = diff
                    best_match = {
                        "track_id": track_id,
                        "url": entry.get("webpage_url") or f"https://www.youtube.com/watch?v={entry['id']}",
                        "title": entry.get("title", query),
                        "duration": int(yt_duration)
                    }
            
            if best_match:
                return best_match
                
    except Exception:
        pass
    
    return {"track_id": track_id, "url": None, "query": query}

def main():
    parser = argparse.ArgumentParser(description="Generate M3U playlists from Spotify saved tracks.")
    parser.add_argument("-i", "--input", default=DEFAULT_INPUT, help="Path to saved_tracks.json")
    parser.add_argument("-o", "--output-dir", default=DEFAULT_OUTPUT_DIR, help="Directory to save .m3u files")
    parser.add_argument("-f", "--force", action="store_true", help="Force re-search for all tracks")
    parser.add_argument("-l", "--limit", type=int, help="Limit total number of tracks to process (for testing)")
    args = parser.parse_args()

    input_path = Path(args.input)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    if not input_path.exists():
        print(f"Error: Input file {input_path} not found.")
        sys.exit(1)

    with open(input_path, "r", encoding="utf-8") as f:
        tracks = json.load(f)

    if args.limit:
        tracks = tracks[:args.limit]

    cache = load_cache()
    if args.force:
        cache = {}

    to_search = [t for t in tracks if t["track_id"] not in cache or cache[t["track_id"]].get("url") is None]
    cached_count = len(tracks) - len(to_search)

    skipped_tracks = []

    if cached_count > 0:
        print(f"Found {cached_count} tracks in cache.")

    if to_search:
        print(f"Searching YouTube for {len(to_search)} new tracks...")
        ydl_opts = {
            "quiet": True,
            "no_warnings": True,
            "extract_flat": True,
            "skip_download": True,
        }
        
        with YoutubeDL(ydl_opts) as ydl:
            with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
                futures = {executor.submit(get_yt_url, track, ydl): track for track in to_search}
                
                with tqdm(total=len(to_search), desc="Search Progress", unit="track") as pbar:
                    for i, future in enumerate(concurrent.futures.as_completed(futures)):
                        result = future.result()
                        if result["url"]:
                            cache[result["track_id"]] = result
                        else:
                            skipped_tracks.append(result.get("query", "Unknown"))
                        
                        pbar.update(1)
                        if (i + 1) % 20 == 0:
                            save_cache(cache)
        save_cache(cache)

    # Organize tracks by genre
    playlists = { "All Favorites": [] }
    for group in GENRE_GROUPS:
        playlists[group] = []

    final_count = 0
    for track in tracks:
        yt_info = cache.get(track["track_id"])
        if not yt_info or not yt_info.get("url"):
            continue

        final_count += 1
        track_data = {
            "title": f"{', '.join(track['artist'])} - {track['name']}",
            "url": yt_info["url"],
            "duration": int(track["duration_ms"] / 1000)
        }
        
        playlists["All Favorites"].append(track_data)
        
        # Add to matching genre groups
        track_genres = [g.lower() for g in track.get("genres", [])]
        matched = False
        for group, keywords in GENRE_GROUPS.items():
            if any(k in track_genres for k in keywords):
                playlists[group].append(track_data)
                matched = True
        
        # Optional: Add to "Others" if no group matched but has genres
        if not matched and track_genres:
            if "Others" not in playlists: playlists["Others"] = []
            playlists["Others"].append(track_data)

    # Write M3U files
    print("\nGenerating playlists...")
    index_lines = ["#EXTM3U"]
    
    sorted_playlists = sorted(playlists.items(), key=lambda x: len(x[1]), reverse=True)

    for name, items in sorted_playlists:
        if not items:
            continue
            
        safe_name = re.sub(r"[^\w\s-]", "", name).strip().replace(" ", "_").lower()
        filename = f"{safe_name}.m3u"
        file_path = output_dir / filename
        
        lines = ["#EXTM3U"]
        for item in items:
            lines.append(f"#EXTINF:{item['duration']},{item['title']}")
            lines.append(item['url'])
        
        with open(file_path, "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")
        
        print(f" - {name:<15} ({len(items):>3} tracks) -> {filename}")
        
        if name != "All Favorites":
            index_lines.append(f"#EXTINF:-1,{name}")
            index_lines.append(filename)

    # Create master playlist
    with open(output_dir / "index.m3u", "w", encoding="utf-8") as f:
        f.write("\n".join(index_lines) + "\n")
        
    print(f"\nDone! Processed {len(tracks)} tracks.")
    print(f"Successfully matched: {final_count}")
    if skipped_tracks:
        print(f"Skipped (no match): {len(skipped_tracks)}")
        # Optional: save skipped to a file if requested
    
    print(f"Master playlist created: {output_dir / 'index.m3u'}")

if __name__ == "__main__":
    main()
