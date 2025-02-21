#!/bin/bash

# Script to be used in a Plone buildout to redo a tag after modifications.

DOIT=''
TAG=''
FILES="version.txt CHANGES.txt"

usage () {
    echo "DESCRIPTION: This script must be used to redo a specific tag."
    echo "USAGE: `basename $0` (-d) (-t tag)"
    echo "  -d = doit."
    echo "  -t tag = tag that will be deleted and redone."
    echo "  -h = this help."
}

while getopts ":dht:" opt; do
  case $opt in
    d)  DOIT='1'; echo "=> DOIT='$DOIT'"
        ;;
    t)  TAG="$OPTARG"; echo "=> TAG='$TAG'"
        ;;
    h)  usage; exit 1;
        ;;
    \?) echo "Invalid option -$OPTARG" >&2 ; usage; exit 1
        ;;
    :)  echo "Option -$OPTARG requires an argument." >&2; exit 1
        ;;
  esac
done

# works without quotes in parameters
execute_cmd () {
  if [ "$DOIT" == "1" ]; then
    echo "Running command: $@" >&2
    "$@"
    if [ $? -ne 0 ] ; then
      echo "Error in previous command"
      exit $?
    fi
  else
    echo "Will run command: $@" >&2
  fi
}

# check if tag exists
if [ "$TAG" == "" ]; then usage; exit 1; fi
if [ ! $(git tag -l "$TAG") ]; then
    echo "Error: tag '$TAG' doesn't exist."
    exit 1
fi

merge_changes_txt() {
  local current_file="CHANGES.txt.bck"
  local tag_file="CHANGES.txt"
  local temp_file="CHANGES.txt.temp"
  local patch_file="changes.diff"
  # check if current_file exists, otherwise get it from tag
  if [ ! -e "$current_file" ]; then
      cp "$tag_file" "$current_file"
      git restore -s $TAG -- $tag_file
  fi
  sed -n '1,/^$/p' "$current_file" > "$temp_file"
  sed -n "/^$TAG /,\$p" "$current_file" >> "$temp_file"
  diff "$tag_file" "$temp_file" > "$patch_file"
  if [ -s "$patch_file" ]; then
    echo "Patching CHANGES.txt"
    cat $patch_file
    if [ "$DOIT" == "1" ]; then
      patch "$tag_file" < "$patch_file"
    else
      rm $tag_file
      mv $current_file $tag_file
    fi
  fi
  rm $patch_file $temp_file
}

# Change versioned files
echo "Backing up versioned files"
for f in $FILES
do
  if [ -e $f ]; then
    if [ ! -e "$f.bck" ]; then
      cmd=(cp $f $f.bck)
      execute_cmd "${cmd[@]}"
    fi
    cmd=(git restore -s $TAG -- $f)
    execute_cmd "${cmd[@]}"
  fi
done

# Special handling for CHANGES.txt to merge additional lines
merge_changes_txt

echo "Deleting tag '$TAG'"
cmd=(git tag -d "$TAG")
execute_cmd "${cmd[@]}"
cmd=(git push --delete origin "$TAG")
execute_cmd "${cmd[@]}"

# Re-tag
echo "Redoing tag $TAG"
if [ "$DOIT" == "1" ]; then
  echo "Running command: git ci -am \"Redoing release $TAG\" && git tag $TAG -m \"Tagging $TAG\" && git push origin $TAG" >&2
  git ci -am "Redoing release $TAG" && git tag $TAG -m "Tagging $TAG" && git push origin $TAG
else
  echo "Will run command: git ci -am \"Redoing release $TAG\" && git tag $TAG -m \"Tagging $TAG\" && git push origin $TAG" >&2
fi

# Restoring versioned files
echo "Restoring versioned files"
for f in $FILES
do
  if [ -e "$f" ]; then
    cmd=(cp "$f.bck" "$f")
    execute_cmd "${cmd[@]}"
    cmd=(rm "$f.bck")
    execute_cmd "${cmd[@]}"
  fi
done

if [ "$DOIT" == "1" ]; then
  echo "Running command: git ci -am \"Restoring previous files\" && git push" >&2
  git ci -am "Restoring previous files" && git push
  echo ""
else
  echo "Will run command: git ci -am \"Restoring previous files\" && git push" >&2
fi
