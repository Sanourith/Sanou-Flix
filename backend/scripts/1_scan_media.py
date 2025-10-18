"""
Scans files to implement project_datas
Check into directories & get a list of films/animes/series/p#
"""

import datetime
import os
import re
from pathlib import Path
from typing import Any, Dict, List

import cv2
import pandas as pd

script_path = Path(__file__).parent.absolute()
root_path = script_path.parent.parent

output_csv_films = root_path / "data" / "raw" / "films_list.csv"

ssd_path = Path("/media") / os.environ.get("USER", "unknown") / "SSD4OWL"

# sub-dirs
films_path = ssd_path / "1_Films"  # _test"
anime_path = ssd_path / "2.2_Animes"
series_path = ssd_path / "2_Series"

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

list_films = []
nb_films = 0
list_animes = []
nb_animes = 0
list_series = []
nb_series = 0


def clean_title(raw_name: str) -> str:
    """
    Nettoie un nom de fichier pour ne garder que le titre du film.
    Supprime les tags de qualité, langues, codecs, etc.
    """
    name = raw_name

    # 1. Retire les extensions techniques
    patterns_to_remove = [
        r"\b(1080p|720p|2160p|4k|10bit|x265|x264|hdr|dv|bluray|bdrip|web[-_ ]?dl|web[-_ ]?rip|hdtv|dvdrip|repack|multi|vostfr|vf|vff|atmos|ddp|hevc|ac3)\b",
        r"\b(fr|eng|french|english)\b",
        r"(?i)\b(sub|subs)\b",
    ]
    for pat in patterns_to_remove:
        name = re.sub(pat, "", name, flags=re.IGNORECASE)

    # 2. Nettoie les délimiteurs inutiles
    name = re.sub(r"[\._]", " ", name)
    name = re.sub(r"\s{2,}", " ", name)

    # 3. Supprime les crochets ou parenthèses contenant uniquement des tags
    name = re.sub(r"\[(.*?)\]", "", name)
    name = re.sub(
        r"\((?:(?:19|20)\d{2}|.*?rip|.*?x26[45].*?)\)", "", name, flags=re.IGNORECASE
    )

    # 4. Trim final
    name = name.strip(" -_.").strip()

    return name


def get_video_duration(film: str) -> str:
    """Returns duration of a movie

    Args:
        film (path): Film to describe

    Returns:
        str: film furation, format HH:MM:SS
    """
    video = cv2.VideoCapture(f"{film}")
    frames = video.get(cv2.CAP_PROP_FRAME_COUNT)
    fps = video.get(cv2.CAP_PROP_FPS)
    seconds = round(frames / fps)
    video_time = datetime.timedelta(seconds=seconds)
    video_time_str = str(video_time)
    video_time_str = video_time_str.replace("0 days ", "")
    return video_time_str


def main():
    print("SSD path:", ssd_path)
    print("Films path exists:", films_path.exists())
    print("Video extensions:", ", ".join(sorted(video_extensions)))

    if not films_path.exists():
        print("ERROR: Films directory not found")
        return

    films_data: List[Dict[str, Any]] = []

    for film in sorted(films_path.iterdir()):
        if film.is_dir():
            continue  # Ignore directories

        file_extension = film.suffix.lower()
        if file_extension not in video_extensions:
            continue  # Ignore file if it's not a video
        file_extension_str = str(file_extension)
        file_extension_str = file_extension_str.replace(".", "")

        film_basename = film.stem
        film_name_clean = clean_title(film_basename)

        film_duration = get_video_duration(film)

        # INSERT DATA INTO CSV
        films_data.append(
            {
                "NAME": film_name_clean,
                "EXTENTION": file_extension_str,
                "DURATION(s)": film_duration,
            }
        )

        print(f"Treated: {film_basename} - format {file_extension}")

    df = pd.DataFrame(films_data)
    df.to_csv(output_csv_films, encoding="utf-8", index=False)

    print(f"\nFilms found : {len(df)}")
    print(f"CSV saved to: {output_csv_films}")

    print(df.head())


if __name__ == "__main__":
    main()
