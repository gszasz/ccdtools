#!/bin/bash
#########################################################################
#									#
# 	ccdhelcor			        Version: 0.2		#
#									#
# 	Author: Gabriel Szasz			20.12.2004		#
#									#
#	Copyright (C) 2004 Hlohovec Observatory                         #
#									#
#  Utility for heliocentric correction of Julian Date in light curve    #
#  data files.                                                          #
#                                                                       #
#  Used backend 'helcor' (part of C-Munipack package)                   #
#  was created by David Motl (2004).                                    #
#                                                                       #
#  Coordinates of observed object are read from central catalog file:   #
#                                                                       #
#      /usr/local/share/ccdtools/catalog                                #
#									#
#########################################################################

# Catalog path
ccd_root=/usr/local/share/ccdtools
catalog_file=$ccd_root/catalog

# Temporary file
temp=/tmp/ccdhelcor.tmp

# Default settings
force_object=false
files=`echo *.dat`

# Argument processing
while [ -n "$1" ]; do
  if [ "$1" = "-h" -o "$1" = "--help" ]; then
    echo -e "Usage: ccdhelcor [OPTIONS]... [FILE]..."
    echo -e "Utility for heliocentric correction of Julian Date in the first column"
    echo -e "of each FILE (or *.dat if no files are named)\n"
    echo -e "  -g, --debug\t\t\tdebug mode (echo commands only)"
    echo -e "  -o, --object OBJECT\t\tuse coordinates of OBJECT"
    echo -e "  -h, --help \t\t\tdisplay this help and exit"
    echo -e "      --version\t\t\toutput version information and exit\n"
    echo -e "Default behavior: analyze filename structure according to"
    echo -e "Hlohovec Observatory standards to obtain the object name\n"
    echo -e "To prevent heliocentric correction of already corrected file,"
    echo -e "files matching mask '*-hc.dat' or '*-phase.dat' will be skipped.\n"
    echo -e "Coordinates of the object are read from central catalog file:\n"
    echo -e "    /usr/local/share/ccdtools/catalog\n"
    exit 0
  elif [ "$1" = "-g" -o "$1" = "--debug" ]; then
    debug=true
  elif [ "$1" = "-o" -o "$1" = "--object" ]; then
    shift
    object="$1"
    force_object=true
  elif [ "$1" = "--version" ]; then
    echo -e "ccdhelcor (ccdtools) 0.2"
    echo -e "Written by Gabriel Szasz.\n"
    echo -e "Copyright (C) 2004 Hlohovec Observatory"
    exit 0
  else
    files=$*
    break
  fi
  shift
done

# Check catalog file
if [ ! -f "$catalog_file" ]; then
  echo "ccdhelcor: Cannot read catalog file ${catalog_file}"
  exit 1
fi

# Read data
if [ "$force_object" = "true" ]; then
  record=`grep $object $catalog_file`
  if [ -z "$record" ]; then
    echo "ccdhelcor: Object '$object' not found in catalog"
    exit 1
  fi
  ra=`echo $record | cut -d ' ' -f 2 | gawk -F ':' '{ printf "%02d%02d", $1, $2 }'`
  dec=`echo $record | cut -d ' ' -f 3 | gawk -F ':' '{ printf "%+02d%02d", $1, $2 }'`
fi

for file in $files ; do
  if [ -n "`echo $file | grep '^.*-hc.dat$'`" ]; then
    continue
  elif [ -n "`echo $file | grep '^.*-phase.dat$'`" ]; then
    continue
  fi

  if [ "$force_object" = "false" ]; then
    object=`echo $file | cut -d '-' -f 1`
    if [ ! "$object" = "$prev_object" ]; then      
      record=`grep $object $catalog_file`
      if [ -z "$record" ]; then
	echo "ccdhelcor: $file: Object '$object' not found in catalog"
	continue
      fi
      ra=`echo $record | cut -d ' ' -f 2 | gawk -F ':' '{ printf "%02d%02d", $1, $2 }'`
      dec=`echo $record | cut -d ' ' -f 3 | gawk -F ':' '{ printf "%+02d%02d", $1, $2 }'`
      prev_object=$object
    fi
  fi

  if [ "$debug" = "true" ]; then
    echo helcor ra=$ra de=$dec mask=${file%.dat}-hc.dat $file
  else
    helcor ra=$ra de=$dec mask=${file%.dat}-hc.dat $file
  fi

done
