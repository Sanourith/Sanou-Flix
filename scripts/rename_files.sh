#!/bin/bash
set -x
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

##### CHANGE DIRECTORY FOR SERIES' ONE IF NEEDED (eg "2.3_Series")
ssd_dir="/media/psowl/SSD4OWL/2.2_Animes"

# ASK DIR NAME
echo "This script will only treat one directory."
read -p "Enter the name of the directory you'll rename (eg: Dan_Da_Dan): " series_name

if [[ -z "$series_name" ]]; then
    echo "Error: cannot be empty"
    exit 1
fi

cd "$ssd_dir/$series_name" || exit 1

mapfile -t season_dirs < <(find . -maxdepth 1 -type d ! -name "." ! -name "Additional" -printf "%P\n" | sort)
mapfile -t loose_videos < <(find . -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -iname "*.flv" \) | sort)

# echo "${season_dirs[@]}"    # Tous les éléments
# echo "${loose_videos[@]}"   # Tous les éléments

###
# IF THERE IS SEASONS DIR BUT LOOSES EPISODES
# >> MODE EPISODES TO 'Additional' DIRECTORY
###
if [[ ${#loose_videos[@]} -gt 0 ]] && [[ ${#season_dirs[@]} -gt 0 ]]; then
  echo "Video found without dir, creating 'Additional' content..."
  mkdir -p "Additional"

  for video in "${loose_videos[@]}"; do
    echo "  >>> Moving: $(basename "$video") -> Additional/"
    mv "$video" "Additional/"
  done

  echo ""
fi

############      PART 1 - IF NO DIRECTORIES
# IF THERE IS NO SEASON DIR
# >> MODE EVERY FILES INTO S01 DIR
###
if [[ ${#season_dirs[@]} -eq 0 ]]; then
  echo "No season_dir found, creating S01..."

  mapfile -t video_files < <(find . -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.flv" \) | sort)

  if [[ ${#video_files} -eq 0 ]]; then
    echo "No video file found"
    exit 1
  fi

  mkdir -p "TO_BE_MODIFIED"

  episode_num=1
  for video in "${video_files[@]}"; do
    # ext="${video##*.}"
    # new_name="${series_name}_S01E$(printf '%02d' $episode_num).${ext}"
    # echo "  Moving $(basename "$video") >> S01/$new_name"
    mv "$video" "TO_BE_MODIFIED/$video"
  done

  echo "TO_BE_MODIFIED directory into $series_name saga"
  exit 0
fi


############      PART 2 - IF SEASON DIRECTORIES DETECTED

season_num=1

for dir in "${season_dirs[@]}"; do
  old_name="$dir"
  new_season_dir="S$(printf '%02d' $season_num)"

  echo "=== Modifying $old_name"

  need_rename=true
  if [[ "$old_name" == "$new_season_dir" ]]; then
    need_rename=false
  fi

  episode_num=1
  while IFS= read -r -d '' episode; do
    ext="${episode##*.}"
    new_episode_name="${series_name}_S$(printf '%02d' $season_num)E$(printf '%02d' $episode_num).${ext}"

    echo "   >> Rename $(basename "$episode") -> $new_episode_name"

    if $need_rename; then
      mkdir -p "$new_season_dir"
      mv "$episode" "$new_season_dir/$new_episode_name"
    else
      mv "$episode" "$old_name/$new_episode_name"
    fi

    ((episode_num++))
  done < <(find "$old_name" -maxdepth 1 -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.flv" \) -print0 | sort -z)

  if $need_rename && [[ -d "$old_name" ]] && [[ -z "$(ls -A "$old_name")" ]]; then
    rmdir "$old_name"
    echo "    Directory renamed : $old_name -> $new_season_dir"
  fi

  echo ""
  ((season_num++))
done

echo "Rename_step completed !"
## Demon_Slayer
