"""
Scans files to implement project_datas
Check into directories & get a list of films/animes/series
"""

import datetime
import json
import os
import re
import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional

import pandas as pd

script_path = Path(__file__).parent.absolute()
root_path = script_path.parent.parent

ssd_path = Path("/media") / os.environ.get("USER", "unknown") / "SSD4OWL"

video_extensions = {
    ".mp4",
    ".mkv",
    ".avi",
    ".mov",
    ".wmv",
    ".flv",
    ".webm",
    ".m4v",
    ".mpg",
    ".mpeg",
    ".3gp",
    ".ts",
}

def is_wsl():
    try:
        with open("/proc/version", "r") as f:
            return "microsoft" in f.read().lower()
    except FileNotFoundError:
        return False

if is_wsl():
    ssd_path = Path("/mnt/e")
else:
    ssd_path = Path("/media/psowl/SSD4OWL")

# sub-dirs
films_path = ssd_path / "1_Films"
animes_path = ssd_path / "2.2_Animes"
series_path = ssd_path / "2_Series"

def clean_title(raw_name: str) -> str:
    """
    Nettoie un nom de fichier pour ne garder que le titre du film.
    Supprime les tags de qualité, langues, codecs, etc.
    """
    name = raw_name

    patterns_to_remove = [
        r"\b(1080p|720p|2160p|4k|10bit|x265|x264|hdr|dv|bluray|bdrip|web[-_ ]?dl|web[-_ ]?rip|hdtv|dvdrip|repack|multi|vostfr|vf|vff|atmos|ddp|hevc|ac3)\b",
        r"\b(fr|eng|french|english)\b",
        r"(?i)\b(sub|subs)\b",
    ]
    for pat in patterns_to_remove:
        name = re.sub(pat, "", name, flags=re.IGNORECASE)

    name = re.sub(r"[\._]", " ", name)
    name = re.sub(r"\s{2,}", " ", name)

    name = re.sub(r"\[(.*?)\]", "", name)
    name = re.sub(
        r"\((?:(?:19|20)\d{2}|.*?rip|.*?x26[45].*?)\)", "", name, flags=re.IGNORECASE
    )

    name = name.strip(" -_.").strip()

    return name


def get_video_duration_ffprobe(film_path: str) -> Optional[str]:
    """
    Obtient la durée d'une vidéo avec ffprobe (plus rapide et fiable qu'OpenCV).

    Args:
        film_path: Chemin vers le fichier vidéo

    Returns:
        Durée au format HH:MM:SS ou None en cas d'erreur
    """
    try:
        result = subprocess.run(
            [
                "ffprobe",
                "-v",
                "quiet",
                "-print_format",
                "json",
                "-show_format",
                str(film_path),
            ],
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        )

        if result.returncode != 0:
            return None

        data = json.loads(result.stdout)

        if "format" not in data or "duration" not in data["format"]:
            return None

        duration_seconds = int(float(data["format"]["duration"]))
        duration_str = str(datetime.timedelta(seconds=duration_seconds))

        # Enlever "0 days " si présent (pour vidéos < 24h)
        return duration_str.replace("0 days ", "")

    except (subprocess.TimeoutExpired, json.JSONDecodeError, ValueError, KeyError) as e:
        print(f"    ⚠️  Error reading duration: {e}")
        return None
    except FileNotFoundError:
        print("    ⚠️  ffprobe not found. Install ffmpeg: sudo apt install ffmpeg")
        return None


def get_video_duration_opencv(film_path: str) -> Optional[str]:
    """
    Fallback: Obtient la durée avec OpenCV (plus lent mais ne nécessite pas ffprobe).

    Args:
        film_path: Chemin vers le fichier vidéo

    Returns:
        Durée au format HH:MM:SS ou None en cas d'erreur
    """
    try:
        import cv2

        video = cv2.VideoCapture(str(film_path))
        frames = video.get(cv2.CAP_PROP_FRAME_COUNT)
        fps = video.get(cv2.CAP_PROP_FPS)
        video.release()

        if fps == 0 or frames == 0:
            return None

        seconds = round(frames / fps)
        duration_str = str(datetime.timedelta(seconds=seconds))
        return duration_str.replace("0 days ", "")

    except Exception as e:
        print(f"    ⚠️  OpenCV error: {e}")
        return None


def get_video_duration(film_path: str, use_ffprobe: bool = True) -> str:
    """
    Obtient la durée d'une vidéo en essayant ffprobe puis OpenCV en fallback.

    Args:
        film_path: Chemin vers le fichier vidéo
        use_ffprobe: Si True, essaie ffprobe en premier

    Returns:
        Durée au format HH:MM:SS ou "00:00:00" si échec
    """
    duration = None

    if use_ffprobe:
        duration = get_video_duration_ffprobe(film_path)

    # Fallback to OpenCV if ffprobe failed or not used
    if duration is None:
        duration = get_video_duration_opencv(film_path)

    return duration if duration is not None else "00:00:00"


def scan_video_directory(
    dir_path: Path,
    output_csv_name: str,
    category_name: str = "videos",
    recursive: bool = False,
    use_ffprobe: bool = True,
) -> pd.DataFrame:
    """
    Scanne un répertoire de vidéos et génère un CSV avec les métadonnées.

    Args:
        dir_path: Chemin du répertoire à scanner
        output_csv_name: Nom du fichier CSV de sortie (ex: "films_list.csv")
        category_name: Nom de la catégorie pour les logs (ex: "films", "animes")
        recursive: Si True, scanne les sous-dossiers (pour series/animes)
        use_ffprobe: Si True, utilise ffprobe (plus rapide), sinon OpenCV

    Returns:
        DataFrame contenant les données scannées
    """
    print(f"\n{'='*60}")
    print(f"Scanning {category_name.upper()}")
    print(f"Directory: {dir_path}")
    print(f"Recursive: {recursive}")
    print(f"Method: {'ffprobe' if use_ffprobe else 'OpenCV'}")
    print(f"{'='*60}")

    if not dir_path.exists():
        print(f"ERROR: {category_name} directory not found at {dir_path}")
        return pd.DataFrame()

    videos_data: List[Dict[str, Any]] = []
    error_count = 0

    # Si recursive, on cherche tous les fichiers vidéo en profondeur
    if recursive:
        # Collecter tous les fichiers vidéo, peu importe la profondeur
        for ext in video_extensions:
            for video_file in sorted(dir_path.rglob(f"*{ext}")):
                # Trouver le dossier série (premier niveau sous dir_path)
                try:
                    relative_path = video_file.relative_to(dir_path)
                    serie_folder = relative_path.parts[0]
                except (ValueError, IndexError):
                    serie_folder = "Unknown"

                file_extension_str = video_file.suffix.replace(".", "")
                file_basename = video_file.stem
                file_name_clean = clean_title(file_basename)
                file_duration = get_video_duration(str(video_file), use_ffprobe)

                if file_duration == "00:00:00":
                    error_count += 1

                videos_data.append(
                    {
                        "NAME": file_name_clean,
                        "EXTENTION": file_extension_str,
                        "DURATION": file_duration,
                        "PATH": str(video_file),
                        "FOLDER": serie_folder,
                    }
                )

                status = "✓" if file_duration != "00:00:00" else "✗"
                print(
                    f"  {status} [{serie_folder}] {file_basename[:40]:<40} | {file_extension_str:>4} | {file_duration}"
                )

    # Sinon, scan direct (pour films)
    else:
        for video_file in sorted(dir_path.iterdir()):
            if video_file.is_dir():
                continue

            file_extension = video_file.suffix.lower()
            if file_extension not in video_extensions:
                continue

            file_extension_str = file_extension.replace(".", "")
            file_basename = video_file.stem
            file_name_clean = clean_title(file_basename)
            file_duration = get_video_duration(str(video_file), use_ffprobe)

            if file_duration == "00:00:00":
                error_count += 1

            videos_data.append(
                {
                    "NAME": file_name_clean,
                    "EXTENTION": file_extension_str,
                    "DURATION": file_duration,
                    "PATH": str(video_file),
                }
            )

            status = "✓" if file_duration != "00:00:00" else "✗"
            print(
                f"{status} {file_basename[:50]:<50} | {file_extension_str:>4} | {file_duration}"
            )

    # Create DataFrame and save to CSV
    df = pd.DataFrame(videos_data)
    output_path = root_path / "data" / "raw" / output_csv_name
    output_path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(output_path, encoding="utf-8", index=False)

    print(f"\n{category_name.capitalize()} found: {len(df)}")
    if error_count > 0:
        print(f"⚠️  Errors reading duration: {error_count}")
    print(f"CSV saved to: {output_path}")
    if not df.empty:
        print(f"\nPreview:\n{df.head()}")

    return df


def main():
    print(f"SSD path: {ssd_path}")
    print(f"Video extensions: {', '.join(sorted(video_extensions))}")

    # Scan all categories
    df_films = scan_video_directory(
        films_path, "films_list.csv", "films", recursive=False
    )
    df_animes = scan_video_directory(
        animes_path, "animes_list.csv", "animes", recursive=True
    )
    df_series = scan_video_directory(
        series_path, "series_list.csv", "series", recursive=True
    )

    print(f"\n{'=' * 60}")
    print("SUMMARY")
    print(f"{'=' * 60}")
    print(f"Films:  {len(df_films)}")
    print(f"Animes: {len(df_animes)}")
    print(f"Series: {len(df_series)}")
    print(f"Total:  {len(df_films) + len(df_animes) + len(df_series)}")


if __name__ == "__main__":
    main()
