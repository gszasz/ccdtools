#!/bin/bash
#
# ccdphase.sh -- Create phased light curve data files
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
# The 'ccdphase.sh' is a utility for creating phased light curve data files.
#
# Ephemeris of observed object is read from central catalog file:
#
#     /usr/local/share/ccdtools/catalog
#

# Version information
script="ccdphase.sh"
package="ccdtools"
version="0.2"
author="Gabriel Szasz"
copyright_year="2004, 2020"
copyright="Gabriel Szasz <gabriel.szasz1@gmail.com>"

# Catalog path
ccd_root=/usr/local/share/ccdtools
catalog_file=$ccd_root/catalog

# Default settings
force_object=false
append_phase=false
files=`echo *-hc.dat`

# Argument processing
while [ -n "$1" ]; do
  if [ "$1" = "-h" -o "$1" = "--help" ]; then
    echo -e "Usage: ccdphase [OPTIONS]... [FILE]..."
    echo -e "Utility for creating phased light curve data file from"
    echo -e "each FILE (or *-hc.dat if no files are named)\n"
    echo -e "  -g, --debug\t\t\tdebug mode (echo commands only)"
    echo -e "  -a, --append\t\t\tappend phase as fourth column"
    echo -e "  -o, --object OBJECT\t\tuse ephemeris of OBJECT"
    echo -e "  -h, --help \t\t\tdisplay this help and exit"
    echo -e "      --version\t\t\toutput version information and exit\n"
    echo -e "Default behavior: analyze filename structure according to"
    echo -e "Hlohovec Observatory standards to obtain the object name\n"
    echo -e "Input files must be processed with 'ccdhelcor' first."
    echo -e "Every file not matching mask '*-hc.dat' will be skipped.\n"
    echo -e "Ephemeris of object is read from central catalog file:\n"
    echo -e "    /usr/local/share/ccdtools/catalog\n"
    exit 0
  elif [ "$1" = "-g" -o "$1" = "--debug" ]; then
    debug=true
  elif [ "$1" = "-a" -o "$1" = "--append" ]; then
    append_phase=true
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
  echo "ccdphase: Cannot read catalog file ${catalog_file}"
  exit 1
fi

# Read data
if [ "$force_object" = "true" ]; then
  record=`grep $object $catalog_file`
  if [ -z "$record" ]; then
    echo "ccdphase: Object '$object' not found in catalog"
    exit 1
  fi
  epoch=`echo $record | cut -d ' ' -f 4`
  period=`$(echo $record | cut -d ' ' -f 5)`
fi

for file in $files ; do
  if [ -z "`echo $file | grep '^.*-hc.dat$'`" ]; then
    continue
  fi

  if [ "$force_object" = "false" ]; then
    object=`echo $file | cut -d '-' -f 1`
    if [ ! "$object" = "$prev_object" ]; then
      record=`grep $object $catalog_file`
      if [ -z "$record" ]; then
	echo "ccdphase: $file: Object '$object' not found in catalog"
	continue
      fi
      epoch=`echo $record | cut -d ' ' -f 4`
      period=`echo $record | cut -d ' ' -f 5`
      prev_object=$object
    fi
  fi

  if [ "$append_phase" = "true" ]; then
    if [ "$debug" = "true" ]; then
      echo -n "gawk -v epoch=$epoch -v period=$period "
      echo -n '{ jd = $1 - epoch; phase = (jd % period) / period; print $1, $2, $3, phase; }'
      echo " $file > ${file%-hc.dat}-phase.dat"
    else
      echo "$file -> ${file%-hc.dat}-phase.dat"
      gawk -v epoch=$epoch -v period=$period \
        '{ \
          jd = $1 - epoch; \
          phase = (jd % period) / period; \
          print $1, $2, $3, phase; \
         }' $file > ${file%-hc.dat}-phase.dat
    fi
  else
    if [ "$debug" = "true" ]; then
      echo -n "gawk -v epoch=$epoch -v period=$period "
      echo -n '{ jd = $1 - epoch; phase = (jd % period) / period; print phase, $2, $3; }'
      echo " $file > ${file%-hc.dat}-phase.dat"
    else
      echo "$file -> ${file%-hc.dat}-phase.dat"
      gawk -v epoch=$epoch -v period=$period \
        '{ \
          jd = $1 - epoch; \
          phase = (jd % period) / period; \ls

          print phase, $2, $3; \
         }' $file > ${file%-hc.dat}-phase.dat
    fi
  fi
done
