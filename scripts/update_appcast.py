#!/usr/bin/env python3
import sys
import os
import re
from datetime import datetime, timezone

def update_appcast(appcast_path, version, build_number, zip_url, zip_size, ed_signature, release_notes=""):
    with open(appcast_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Format pubDate in RFC 822 format: e.g. "Mon, 31 Aug 2026 18:40:00 +0000"
    pub_date = datetime.now(timezone.utc).strftime("%a, %d %b %Y %H:%M:%S +0000")

    if not release_notes:
        release_notes = f"<h2>Version {version} Release Notes</h2><p>Maintenance and performance improvements.</p>"

    item_xml = f"""        <item>
            <title>Version {version}</title>
            <sparkle:releaseNotesLink>https://github.com/wenujacodes/GitStreak/releases/tag/v{version}</sparkle:releaseNotesLink>
            <description><![CDATA[
                {release_notes.strip()}
            ]]></description>
            <pubDate>{pub_date}</pubDate>
            <enclosure url="{zip_url}"
                       sparkle:version="{build_number}"
                       sparkle:shortVersionString="{version}"
                       sparkle:edSignature="{ed_signature}"
                       length="{zip_size}"
                       type="application/octet-stream" />
        </item>"""

    # Check if this version item is already in appcast.xml
    version_pattern = rf'<sparkle:shortVersionString>{re.escape(version)}</sparkle:shortVersionString>'
    if version_pattern in content:
        print(f"Version {version} already exists in {appcast_path}. Skipping duplication.")
        return

    # Insert right after <channel> metadata (after <language>en</language>)
    insert_marker = "<language>en</language>"
    if insert_marker in content:
        new_content = content.replace(insert_marker, f"{insert_marker}\n{item_xml}", 1)
    else:
        # Fallback to after <channel>
        new_content = content.replace("<channel>", f"<channel>\n{item_xml}", 1)

    with open(appcast_path, "w", encoding="utf-8") as f:
        f.write(new_content)
    print(f"Successfully updated {appcast_path} for Version {version} (Build {build_number}).")

if __name__ == "__main__":
    if len(sys.argv) < 7:
        print("Usage: update_appcast.py <appcast.xml> <version> <build_number> <zip_url> <zip_size> <ed_signature> [release_notes_html]")
        sys.exit(1)

    appcast_file = sys.argv[1]
    ver = sys.argv[2].lstrip("v")
    bld = sys.argv[3]
    url = sys.argv[4]
    sz = sys.argv[5]
    sig = sys.argv[6]
    notes = sys.argv[7] if len(sys.argv) > 7 else ""

    update_appcast(appcast_file, ver, bld, url, sz, sig, notes)
