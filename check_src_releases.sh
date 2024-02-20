#!/bin/bash

# Script to be used in a plone buildout to check if development eggs must be released.
# if argument "1" is passed, only changed folders are echoed

CHANGED=''
TOOL=''
TOOLS="iadocs"
escaped_iadocs="collective.contact.importexport collective.externaleditor collective.portlet.actions collective.relationhelpers
                collective.z3cform.select2 imio.dms.mail imio.transmogrifier.contact imio.transmogrifier.iadocs
                plone.app.robotframework plone.formwidget.datetime Products.LDAPUserFolder transmogrify.dexterity"

usage () {
    echo "DESCRIPTION: This script must be used on an src buildout directory, to check if development eggs are to be released."
    echo "USAGE: `basename $0` (-c) (-t iadocs)"
    echo "  -c = changed folders only are listed."
    echo "  -h = this help."
    echo "  -t tool = tool filtering (iadocs)"
}

while getopts ":cht:" opt; do
  case $opt in
    c)  CHANGED='1'; echo "=> CHANGED='$CHANGED'"
        ;;
    t)  TOOL="$OPTARG"; echo "=> TOOL='$TOOL'"
        ;;
    h)  usage; exit 1;
        ;;
    \?) echo "Invalid option -$OPTARG" >&2 ; usage; exit 1
        ;;
    :)  echo "Option -$OPTARG requires an argument." >&2; exit 1
        ;;
  esac
done

# check if in src directory
if [[ "$PWD" != */src ]]; then echo "Error: must be run in src directory"; exit 1; fi

# check if TOOL is valid
#if [ "$TOOL" != "" ] && ! echo "$TOOLS" | tr " " '\n' |grep -Fqx "$TOOL" ; then echo "Invalid tool option '$TOOL' : must be one of '$TOOLS'"; exit 1; fi
if [ "$TOOL" != "" ] && ! echo "$TOOLS" | grep -wq "$TOOL" ; then echo "Invalid tool option '$TOOL' : must be one of '$TOOLS'"; exit 1; fi
ESCAPING="escaped_${TOOL}"

for j in $(ls -1)
do
    if [ -d $j ] && [ "$j" != appy ]
    then
      if [ "$TOOL" != "" ] && echo "${!ESCAPING}" | grep -wq "$j"; then continue; fi
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
          if [ "$CHANGED" != "1" ]; then echo "$j/$cf UNCHANGED"; fi
        else
          echo "$j/$cf"
        fi
      fi
      cd ..
    fi
done
