#!/usr/bin/env python3
"""
fetch_campus_hero_images.py
─────────────────────────────
Downloads campus hero JPEGs from Wikipedia / Wikimedia Commons (verify
licenses on each file page — see cinfo/CampusHero/SOURCES.txt).

Reads every `name` from cinfo/universities.csv.

Resolution order per university:
  1. COMMONS_FILE_OVERRIDES (exact Commons file)
  2. SEARCHES — curated Commons file search (high quality)
  3. English Wikipedia `pageimages` for the university name (plus dash variants)
  4. Commons search: «{name} campus»

Usage:
  cd /path/to/cinfo/repo
  python3 scripts/fetch_campus_hero_images.py
  python3 scripts/fetch_campus_hero_images.py --skip-existing

Requires: curl (subprocess — avoids Python SSL issues on some Macs).
PNG/WebP thumbnails are converted to JPEG (macOS `sips`, else `pip install Pillow`).
"""

from __future__ import annotations

import argparse
import csv
import json
import platform
import re
import subprocess
import time
import urllib.parse
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CSV_PATH = ROOT / "cinfo" / "universities.csv"
OUT = ROOT / "cinfo" / "CampusHero"
COMMONS_API = "https://commons.wikimedia.org/w/api.php"
WP_API = "https://en.wikipedia.org/w/api.php"
CURL_UA = (
    "cinfo-campus-hero/1.2 (batch download for educational offline app; "
    "local build; respects Wikimedia User-Agent / hotlink policy)"
)

# Curated Commons keyword searches (exact CSV `name` → search string, file namespace).
SEARCHES: dict[str, str] = {
    "Massachusetts Institute of Technology": "MIT Great Dome Building 10",
    "Harvard University": "Harvard Widener Library exterior",
    "Princeton University": "Nassau Hall Princeton",
    "California Institute of Technology": "Beckman Auditorium Caltech",
    "Stanford University": "Stanford Main Quad Hoover Tower",
    "Yale University": "Yale Sterling Memorial Library exterior",
    "University of Chicago": "Hutchinson Commons University of Chicago",
    "University of Cambridge": "King's College Chapel Cambridge",
    "University of Oxford": "Radcliffe Camera Oxford",
    "University of Pennsylvania": "College Hall University of Pennsylvania",
    "Columbia University": "Low Library Columbia University",
    "Johns Hopkins University": "Gilman Hall Johns Hopkins",
    "University of California, Berkeley": "Sather Tower Berkeley Campanile",
    "Cornell University": "McGraw Tower Cornell University",
    "ETH Zurich": "ETH Zurich main building Polybahn",
    "Duke University": "Duke Chapel exterior",
    "Imperial College London": "Imperial College London Queen's Tower",
    "Northwestern University": "University Hall Northwestern Evanston",
    "Karolinska Institute": "Karolinska Institute Solna campus",
    "University of California, Los Angeles": "Royce Hall UCLA",
    "Nagoya University": "Nagoya University Higashiyama campus",
    "Technion – Israel Institute of Technology": "Technion Institute of Technology Haifa building",
    "Queen's University": "Queen's University Kingston Ontario campus",
    "POSTECH": "POSTECH university Pohang campus",
    "Rice University": "Rice University Lovett Hall Sallyport",
    "University of Minnesota–Twin Cities": "Northrop Mall University of Minnesota Minneapolis",
    "North Carolina State University": "NC State University campus Belltower",
    "University of Wollongong": "University of Wollongong campus",
    "Xi'an Jiaotong University": "Xi'an Jiaotong University main building",
    "Shandong University": "Shandong University campus",
    "University College Dublin": "UCD Belfield campus",
    "Politecnico di Milano": "Politecnico di Milano Leonardo campus",
    "University of Padova": "University of Padua Palazzo Bo",
    "Hong Kong Baptist University": "Hong Kong Baptist University campus"
}

# Exact `File:…` on Commons when search picks the wrong image.
COMMONS_FILE_OVERRIDES: dict[str, str] = {
    "Duke University": "File:Duke Chapel 4 16 05.jpg",
    "University of California, Berkeley": "File:Campanile Hi-Res - reduced file size.jpg",
    "ETH Zurich": "File:ETH Zürich - Hauptgebäude - Unispital 2012-07-30 07-57-03 ShiftN.jpg",
    "Northwestern University": "File:University Hall at Northwestern University.jpg",
    "University of California, Los Angeles": "File:Royce Hall edit.jpg",
    "Karolinska Institute": "File:Karolinska Institutet Campus Solna, entré, 2019.jpg",
    "University of Hong Kong": "File:Main Building of the University of Hong Kong, 1912.png",
    "Osaka University": "File:Osaka university toyonaka campus street.jpg",
    "Hokkaido University": "File:Hokkaido University Sapporo Campus Aerial photograph.2020.jpg",
    "Nagoya University": "File:Nagoya University Higashiyama Campus.jpg",
    "University of Auckland": "File:University of Auckland Clock Tower.jpg",
    "Technion – Israel Institute of Technology": "File:122748 haifa - technion PikiWiki Israel.png",
}


def slug(name: str) -> str:
    """Match CampusHeroImage.slug in Swift."""
    s = (
        name.replace("/", "_")
        .replace(",", "")
        .replace(" ", "_")
        .replace("'", "")
        .replace("–", "-")
        .replace("—", "-")
    )
    s = re.sub(r"_+", "_", s).strip("_")
    return s


def curl_json(url: str, *, attempts: int = 5) -> dict:
    last: Exception | None = None
    delay = 2.0
    for i in range(attempts):
        r = subprocess.run(
            [
                "curl",
                "-sL",
                "--compressed",
                "-A",
                CURL_UA,
                url,
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        if r.returncode != 0:
            last = RuntimeError(r.stderr or "curl failed")
            time.sleep(delay)
            delay = min(delay * 1.5, 20.0)
            continue
        raw = r.stdout.strip()
        if not raw:
            last = RuntimeError("empty response from curl")
            time.sleep(delay)
            delay = min(delay * 1.5, 20.0)
            continue
        try:
            return json.loads(raw)
        except json.JSONDecodeError as e:
            last = e
            time.sleep(delay)
            delay = min(delay * 1.5, 20.0)
            continue
    assert last is not None
    raise last


def first_commons_thumb_from_search(search: str) -> tuple[str, str]:
    params = {
        "action": "query",
        "generator": "search",
        "gsrsearch": search,
        "gsrnamespace": "6",
        "gsrlimit": "1",
        "prop": "imageinfo",
        "iiprop": "url",
        "iiurlwidth": "1600",
        "format": "json",
    }
    url = COMMONS_API + "?" + urllib.parse.urlencode(params)
    data = curl_json(url)
    pages = data.get("query", {}).get("pages", {})
    for _pid, p in pages.items():
        title = p.get("title", "")
        infos = p.get("imageinfo") or []
        if not infos:
            continue
        info = infos[0]
        thumb = info.get("thumburl") or info.get("url")
        if thumb:
            return title, thumb
    raise LookupError(f"No Commons file for search: {search!r}")


def thumb_from_commons_file_title(file_title: str) -> tuple[str, str]:
    params = {
        "action": "query",
        "titles": file_title,
        "prop": "imageinfo",
        "iiprop": "url",
        "iiurlwidth": "1600",
        "format": "json",
    }
    url = COMMONS_API + "?" + urllib.parse.urlencode(params)
    data = curl_json(url)
    pages = data.get("query", {}).get("pages", {})
    for _pid, p in pages.items():
        title = p.get("title", "")
        infos = p.get("imageinfo") or []
        if not infos:
            continue
        info = infos[0]
        thumb = info.get("thumburl") or info.get("url")
        if thumb:
            return title, thumb
    raise LookupError(f"No imageinfo for: {file_title!r}")


def wiki_title_variants(name: str) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()

    def add(s: str) -> None:
        s = s.strip()
        if s and s not in seen:
            seen.add(s)
            out.append(s)

    add(name)
    add(name.replace("–", "-"))
    add(name.replace("–", " "))
    add(name.replace("—", "-"))
    return out


def wikipedia_pageimage(name: str) -> tuple[str, str] | None:
    for title in wiki_title_variants(name):
        params = {
            "action": "query",
            "titles": title,
            "prop": "pageimages",
            "format": "json",
            "piprop": "thumbnail",
            "pithumbsize": "1600",
        }
        url = WP_API + "?" + urllib.parse.urlencode(params)
        try:
            data = curl_json(url)
        except (RuntimeError, json.JSONDecodeError):
            time.sleep(1.0)
            continue
        pages = data.get("query", {}).get("pages", {})
        for pid, p in pages.items():
            if p.get("missing"):
                continue
            if "pageid" not in p and not pid.isdigit():
                continue
            th = (p.get("thumbnail") or {}) if isinstance(p.get("thumbnail"), dict) else {}
            src = th.get("source")
            if src:
                return f"Wikipedia:{p.get('title', title)}", src
        time.sleep(0.4)
    return None


def resolve_thumb(uni_name: str) -> tuple[str, str]:
    if uni_name in COMMONS_FILE_OVERRIDES:
        return thumb_from_commons_file_title(COMMONS_FILE_OVERRIDES[uni_name])
    if uni_name in SEARCHES:
        return first_commons_thumb_from_search(SEARCHES[uni_name])
    wp = wikipedia_pageimage(uni_name)
    if wp:
        return wp
    try:
        return first_commons_thumb_from_search(f"{uni_name} campus")
    except LookupError:
        return first_commons_thumb_from_search(uni_name)


def _convert_to_jpeg(src: Path, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if platform.system() == "Darwin":
        subprocess.run(
            ["sips", "-s", "format", "jpeg", str(src), "--out", str(dest)],
            check=True,
        )
        return
    try:
        from PIL import Image  # type: ignore[import-not-found]

        Image.open(src).convert("RGB").save(dest, "JPEG", quality=88)
    except ImportError as e:
        raise RuntimeError(
            "Campus image is PNG/WebP; on macOS run again (uses sips), "
            "else: pip install Pillow"
        ) from e


def _referer_for_media_url(url: str) -> str:
    u = url.lower()
    if "upload.wikimedia.org" in u:
        return "https://commons.wikimedia.org/"
    return "https://en.wikipedia.org/"


def download_hero_image(url: str, dest: Path) -> None:
    """Download upload.wikimedia image with Referer + UA; normalize to JPEG."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(dest.suffix + ".part")
    referer = _referer_for_media_url(url)
    last_err: Exception | None = None

    for attempt in range(10):
        if tmp.exists():
            tmp.unlink()
        r = subprocess.run(
            [
                "curl",
                "-sL",
                "--compressed",
                "-o",
                str(tmp),
                "-w",
                "%{http_code}",
                "-H",
                f"Referer: {referer}",
                "-A",
                CURL_UA,
                url,
            ],
            capture_output=True,
            text=True,
        )
        try:
            code = int((r.stdout or "").strip())
        except ValueError:
            code = 0

        if code in (429, 503):
            if tmp.exists():
                tmp.unlink(missing_ok=True)
            wait = min(20.0 + 12.0 * attempt, 150.0)
            last_err = RuntimeError(f"HTTP {code} (wikimedia throttle)")
            time.sleep(wait)
            continue

        if code != 200:
            if tmp.exists():
                tmp.unlink(missing_ok=True)
            last_err = RuntimeError(f"HTTP {code}" if code else "download failed")
            time.sleep(2.5 + 2.0 * attempt)
            continue

        if not tmp.is_file() or tmp.stat().st_size < 200:
            if tmp.exists():
                tmp.unlink(missing_ok=True)
            last_err = RuntimeError("empty download")
            time.sleep(3.0 + 2.0 * attempt)
            continue

        data = tmp.read_bytes()
        if len(data) < 500 or data.lstrip()[:9].lower() == b"<!doctype":
            tmp.unlink(missing_ok=True)
            last_err = RuntimeError("server returned HTML not an image")
            time.sleep(4.0 + 3.0 * attempt)
            continue

        head = data[:16]
        if head[:2] == b"\xff\xd8":
            tmp.replace(dest)
            return
        if head[:8] == b"\x89PNG\r\n\x1a\n" or (head[:4] == b"RIFF" and len(data) > 12 and data[8:12] == b"WEBP"):
            _convert_to_jpeg(tmp, dest)
            tmp.unlink(missing_ok=True)
            return

        tmp.unlink(missing_ok=True)
        last_err = RuntimeError(f"unsupported image magic {head!r}")
        time.sleep(2.0)

    raise last_err if last_err else RuntimeError("download failed")


def hero_file_usable(path: Path) -> bool:
    if not path.is_file() or path.stat().st_size < 3000:
        return False
    return path.read_bytes()[:2] == b"\xff\xd8"


def load_university_names(path: Path) -> list[str]:
    with path.open(encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        return [row["name"].strip() for row in reader if row.get("name", "").strip()]


def parse_sources_file(text: str) -> dict[str, str]:
    """CSV name → full tab-separated line (without newline)."""
    m: dict[str, str] = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or line.startswith("Wikimedia"):
            continue
        parts = line.split("\t", 2)
        if len(parts) >= 3:
            m[parts[0]] = line
    return m


def main() -> None:
    parser = argparse.ArgumentParser(description="Fetch campus hero JPGs for all universities in CSV.")
    parser.add_argument(
        "--skip-existing",
        action="store_true",
        help="Do not re-download if cinfo/CampusHero/{slug}.jpg already exists.",
    )
    args = parser.parse_args()

    if not CSV_PATH.is_file():
        raise SystemExit(f"Missing {CSV_PATH}")

    names = load_university_names(CSV_PATH)
    OUT.mkdir(parents=True, exist_ok=True)

    sources_path = OUT / "SOURCES.txt"
    prev: dict[str, str] = {}
    if sources_path.is_file():
        prev = parse_sources_file(sources_path.read_text(encoding="utf-8"))
    record: dict[str, str] = {u: prev[u] for u in names if u in prev}

    ok = fail = skipped = 0

    for uni_name in names:
        key = slug(uni_name)
        jpg = OUT / f"{key}.jpg"
        if args.skip_existing and hero_file_usable(jpg):
            skipped += 1
            continue
        attempted = False
        try:
            title, thumb = resolve_thumb(uni_name)
            print(f"… {uni_name[:52]:<52} ← {title[:60]}")
            download_hero_image(thumb, jpg)
            record[uni_name] = f"{uni_name}\t{title}\t{thumb}"
            ok += 1
            attempted = True
        except Exception as e:
            print(f"✗ {uni_name}: {e}")
            fail += 1
            attempted = True
        if attempted:
            time.sleep(3.2)

    record = {u: record[u] for u in names if u in record}
    header = (
        "Wikimedia Commons / Wikipedia thumbnails (verify license on each file page).\n"
        f"# generated; downloaded_ok={ok} failed={fail} skipped_existing={skipped}\n\n"
    )
    body = "".join(record[u] + "\n" for u in names if u in record)
    sources_path.write_text(header + body, encoding="utf-8")

    n_with = 0
    for u in names:
        p = OUT / f"{slug(u)}.jpg"
        if p.is_file() and p.stat().st_size > 1000:
            n_with += 1
    print(f"\nDone. downloaded_ok={ok} failed={fail} skipped={skipped}. With JPG: {n_with}/{len(names)}. Images in {OUT}")


if __name__ == "__main__":
    main()
