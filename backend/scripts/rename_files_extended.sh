#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

echo "This script will automatically rename every directory into your SSD."
read -p "Which directory do you want to rename ? (anime/serie) " answer

case ${answer,,} in  # ${answer,,} = lowercase automatique
  anime|animes)
    media="2.2_Animes"
    ;;
  serie|series)
    media="2_Series"
    ;;
  *)
    echo "Unknown option: $answer"
    echo "Please choose: anime or serie"
    exit 1
    ;;
esac

read -p "You selected $answer << Are you sure you want to proceed ? (y/n)" confirmation

if [[ ! "$confirmation" =~ ^[yY]$ ]]; then
  echo "Ok, aborting operation"
  exit 1
fi

ssd_dir="/media/psowl/SSD4OWL/$media"

cd "$ssd_dir" || exit 1

# Find every directory
mapfile -t series_dirs < <(find . -maxdepth 1 -type d ! -name "." -printf "%P\n" | sort)

if [[ ${#series_dirs[@]} -eq 0 ]]; then
    echo "No directory found in $ssd_dir"
    exit 1
fi

echo "=== Treating ${#series_dirs[@]} serie(s) ==="
echo ""

# Each serie
for series_name in "${series_dirs[@]}"; do
    echo "========================================"
    echo "SERIE: $series_name"
    echo "========================================"

    cd "$ssd_dir/$series_name" || continue

    # Find directories & loose_videos
    mapfile -t season_dirs < <(find . -maxdepth 1 -type d ! -name "." ! -name "Additional" ! -name "TO_BE_MODIFIED" -printf "%P\n" | sort)
    mapfile -t loose_videos < <(find . -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "$.flv" \) | sort)

    # If directories & loose_videos exist
    if [[ ${#loose_videos[@]} -gt 0 ]] && [[ ${#season_dirs[@]} -gt 0 ]]; then
        echo "Creating 'Additional' to stock files with no dir..."
        mkdir -p "Additional"

        for video in "${loose_videos[@]}"; do
            echo "  >>> Moving: $(basename "$video") -> Additional/"
            mv "$video" "Additional/"
        done

        echo ""
    fi

    # Si aucun dossier de saison n'existe, créer TO_BE_MODIFIED
    if [[ ${#season_dirs[@]} -eq 0 ]]; then
        echo "No directory found, creating 'TO_BE_MODIFIED'..."

        mapfile -t video_files < <(find . -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "$.flv" \) | sort)

        if [[ ${#video_files[@]} -eq 0 ]]; then
            echo "  No video found, nexting..."
            echo ""
            continue
        fi

        mkdir -p "TO_BE_MODIFIED"

        episode_num=1
        for video in "${video_files[@]}"; do
            ext="${video##*.}"
            new_name="${series_name}_E$(printf '%02d' $episode_num).${ext}"
            echo "  >>> Moving: $(basename "$video") -> TO_BE_MODIFIED/$new_name"
            mv "$video" "TO_BE_MODIFIED/$new_name"
            ((episode_num++))
        done

        echo "TO_BE_MODIFIED created ${#video_files[@]} episodes"
        echo ""
        continue
    fi

    # Each season
    echo "Found season directories: ${#season_dirs[@]}"
    season_num=1

    for dir in "${season_dirs[@]}"; do
        old_name="$dir"
        new_season_dir="S$(printf '%02d' $season_num)"

        echo "  === Treating: $old_name ==="

        need_rename=true
        if [[ "$old_name" == "$new_season_dir" ]]; then
            need_rename=false
        fi

        episode_num=1

        while IFS= read -r -d '' episode; do
            ext="${episode##*.}"
            new_episode_name="${series_name}_S$(printf '%02d' $season_num)E$(printf '%02d' $episode_num).${ext}"

            echo "    >> Naming: $(basename "$episode") -> $new_episode_name"

            if $need_rename; then
                mkdir -p "$new_season_dir"
                mv "$episode" "$new_season_dir/$new_episode_name"
            else
                mv "$episode" "$old_name/$new_episode_name"
            fi

            ((episode_num++))
        done < <(find "$old_name" -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "$.flv" \) -print0 | sort -z)

        if $need_rename && [[ -d "$old_name" ]] && [[ -z "$(ls -A "$old_name")" ]]; then
            rmdir "$old_name"
            echo "    Directory renamed: $old_name -> $new_season_dir"
        fi

        ((season_num++))
    done

    echo ""
done

echo "========================================"
echo "Everything is done"
echo "========================================"
