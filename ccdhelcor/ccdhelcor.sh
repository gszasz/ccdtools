#!/bin/bash
#
# ccdhelcor.sh -- Perform heliocentric correction of JD in the LC data files
#
# Copyright (C) 2004, 2020  Gabriel Szasz <gabriel.szasz1@gmail.com>
#
# This file is part of the 'ccdtools' package.
#
# The 'ccdtools' package is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# The 'ccdtools' package is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# the 'ccdtools' package.  If not, see <http://www.gnu.org/licenses/>.
#
# The 'ccdhelcor.sh' is a utility for heliocentric correction of Julian Date in
# light curve data files.
#
# Used backend 'helcor' (part of C-Munipack package) was created by David Motl
# (2004).
#
# Coordinates of observed object are read from the central catalog file:
#
#   /usr/local/share/ccdtools/catalog
#

# Version information
script="ccdhelcor.sh"
package="ccdtools"
version="0.2"
author="Gabriel Szasz"
copyright_year="2004, 2020"
copyright="Gabriel Szasz <gabriel.szasz1@gmail.com>"

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
    echo -e "$script ${package:+($package) }$version"
    echo -e "Written by $author.\n"
    echo -e "Copyright (C) $copyright_year  $copyright"
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
