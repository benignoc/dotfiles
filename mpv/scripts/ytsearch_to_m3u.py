#!/usr/bin/env python3
# /// script
# dependencies = ["yt-dlp"]
# ///
"""
Create an M3U playlist from a YouTube search query for use with mpv.

Example:
    python ytsearch_to_m3u.py "Electric Light Orchestra playlists" -n 20 -o elo_playlists.m3u
"""

from __future__ import annotations

import argparse
import pathlib
import re
import sys
from typing import Iterable

try:
    from yt_dlp import YoutubeDL
except ImportError:
    print("Missing dependency: yt-dlp\nInstall with: pip install yt-dlp", file=sys.stderr)
    sys.exit(1)


def safe_name(text: str) -> str:
    text = re.sub(r"[^\w\s.-]", "", text, flags=re.UNICODE).strip()
    text = re.sub(r"\s+", "_", text)
    return text or "playlist"


def iter_entries(result: dict) -> Iterable[dict]:
    entries = result.get("entries") or []
    for entry in entries:
        if not entry:
            continue
        yield entry


def build_playlist(query: str, limit: int, output_path: pathlib.Path) -> int:
    # yt-dlp supports ytsearchN:QUERY syntax for YouTube search. :contentReference[oaicite:1]{index=1}
    search_term = f"ytsearch{limit}:{query}"

    ydl_opts = {
        "quiet": True,
        "no_warnings": True,
        "extract_flat": False,
        "skip_download": True,
        "default_search": "ytsearch",
    }

    lines: list[str] = ["#EXTM3U"]
    count = 0

    with YoutubeDL(ydl_opts) as ydl:
        result = ydl.extract_info(search_term, download=False)

    for entry in iter_entries(result):
        # Keep only normal video/playlist-style web URLs that mpv can hand off to yt-dlp.
        webpage_url = entry.get("webpage_url") or entry.get("url")
        title = entry.get("title") or "Untitled"
        duration = entry.get("duration")

        if not webpage_url:
            continue
        if not isinstance(webpage_url, str):
            continue
        if not webpage_url.startswith(("http://", "https://")):
            continue

        extinf_duration = duration if isinstance(duration, int) else -1
        lines.append(f"#EXTINF:{extinf_duration},{title}")
        lines.append(webpage_url)
        count += 1

    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return count


def main() -> None:
    parser = argparse.ArgumentParser(description="Create an M3U playlist from a YouTube search query.")
    parser.add_argument("query", help='Search string, e.g. "Electric Light Orchestra playlists"')
    parser.add_argument("-n", "--limit", type=int, default=20, help="Number of search results to include")
    parser.add_argument("-o", "--output", help="Output .m3u filename")
    args = parser.parse_args()

    output = pathlib.Path(args.output) if args.output else pathlib.Path(f"{safe_name(args.query)}.m3u")
    count = build_playlist(args.query, args.limit, output)

    print(f"Wrote {count} entries to {output}")


if __name__ == "__main__":
    main()
