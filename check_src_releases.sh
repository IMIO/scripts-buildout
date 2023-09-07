#!/bin/bash

# Script to be used in a plone buildout to check if development eggs must be released.
# Must be run in buildout src directory
# if argument "1" is passed, only changed folders are echoed

if [[ "$PWD" != */src ]];
then
    echo "Error: must be run in src directory"
    exit 1;
fi

for j in $(ls -1)
do
    if [ -d $j ] && [ "$j" != appy ]
    then
      cd $j
      for cf in CHANGES.rst CHANGES.txt docs/HISTORY.rst docs/HISTORY.txt docs/CHANGES.rst nothing;
      do
        if [[ -f $cf ]]
        then
          break
        fi
      done
      if [ "$cf" = "nothing" ]
      then
        echo "!! $j: NO CHANGE FILE"
        # continue => break ???
      else
        found=$(head -n 10 $cf |grep -i "Nothing changed yet")
        # echo $found
        if [ "$found" ]
        then
          if [ "$1" != "1" ]; then echo "$j/$cf UNCHANGED"; fi
        else
          echo "$j/$cf"
        fi
      fi
      cd ..
    fi
done
