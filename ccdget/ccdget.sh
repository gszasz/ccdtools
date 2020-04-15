#!/bin/bash
#########################################################################
#									#
# 	ccdget			                Version: 0.1		#
#									#
# 	Author: Gabriel Szasz			20.12.2004		#
#									#
#	Copyright (C) 2004 Hlohovec Observatory                         #
#									#
#  Utility for extraction of variable star and/or comparison star data  #
#  from C-Munipack data files. Heliocentric correction will be          #
#  automatically applied if the object (object name is extracted from   #
#  file name) has a record in central catalog file:                     #
#                                                                       #
#      /usr/local/share/ccdtools/catalog                                #
#                                                                       #
#  Used backend 'helcor' (part of C-Munipack package)                   #
#  was created by David Motl (2004).                                    #
#									#
#########################################################################

# Catalog path
ccd_root=/usr/local/share/ccdtools
catalog_file=$ccd_root/catalog

# Temporary file
temp=/tmp/ccdhelcor.tmp

# Default settings
no_delete=false
files=`echo *.dat`

# Argument processing
while [ -n "$1" ]; do
  if [ "$1" = "-h" -o "$1" = "--help" ]; then
    echo -e "Usage: ccdget [OPTIONS]... [FILE]..."
    echo -e "Utility for extraction of variable star and/or comparison star data"
    echo -e "from FILE (or *.dat if no files are named) in C-Munipack fomat.\n"
    echo -e "  -g, --debug\t\t\tdebug mode (echo commands only)"
    echo -e "  -v, --variable\t\textract data of variable star vs. comparison"
    echo -e "  -c, --comparison\t\textract data of comparison star vs. check 1"
    echo -e "  -n, --no-delete\t\tsuppress deletion of intermediate files"
    echo -e "  -h, --help \t\t\tdisplay this help and exit"
    echo -e "      --version\t\t\toutput version information and exit\n"
    echo -e "Default behavior: extract data of variable star vs. comparison\n"
    echo -e "To prevent extraction from output file of any 'ccdtools' package utility,"
    echo -e "files matching masks '*-var.dat', '*-cmp.dat', '*-hc.dat' and '*-phase.dat'"
    echo -e "will be skipped.\n"
    echo -e "Heliocentric correction is automatically applied if the object (object name"
    echo -e "is extracted from the file name) has a record in central catalog file:\n"
    echo -e "    /usr/local/share/ccdtools/catalog\n"
    echo -e "Intermediate (uncorrected) file will be deleted automatically unless"
    echo -e "argument -n (--no-delete) specified."
    exit 0
  elif [ "$1" = "-g" -o "$1" = "--debug" ]; then
    debug=true
  elif [ "$1" = "-v" -o "$1" = "--variable" ]; then
    get_variable=true
  elif [ "$1" = "-c" -o "$1" = "--comparison" ]; then
    get_comparison=true
  elif [ "$1" = "-n" -o "$1" = "--no-delete" ]; then
    no_delete=true
  elif [ "$1" = "--version" ]; then
    echo -e "ccdget (ccdtools) 0.1"
    echo -e "Written by Gabriel Szasz.\n"
    echo -e "Copyright (C) 2004 Hlohovec Observatory"
    exit 0
  else
    files=$*
    break
  fi
  shift
done

# Default behavior
if [ -z "$get_variable" -a -z "$get_comparison" ]; then
  get_variable=true
fi

# Check catalog file
if [ ! -f "$catalog_file" ]; then
  echo "ccdget: Cannot read catalog file ${catalog_file}"
fi

# Process input files
for file in $files ; do
  if [ -n "`echo $file | grep '^.*-\(var\|cmp\|hc\|phase\).dat$'`" ]; then
    continue
  fi

  object=`echo $file | cut -d '-' -f 1`
  if [ ! "$object" = "$prev_object" ]; then
    record=`grep $object $catalog_file`
    if [ -n "$record" ]; then
      ra=`echo $record | cut -d ' ' -f 2 | gawk -F ':' '{ printf "%02d%02d", $1, $2 }'`
      dec=`echo $record | cut -d ' ' -f 3 | gawk -F ':' '{ printf "%+02d%02d", $1, $2 }'`
      prev_object=$object
    fi
  fi

  # Get variable
  if [ "$get_variable" = "true" ]; then
    if [ "$debug" = "true" ]; then
      echo "dos2unix -q $file"
      echo "cat $file | tail -n +3 | grep -v '^$' | grep -v '99.999' | cut -d ' ' -f 1-3 > ${file%.dat}-var.dat"
    else
      echo "$file -> ${file%.dat}-var.dat"
      dos2unix -q $file
      cat $file | tail -n +3 | grep -v '^$' | grep -v '99.999' | cut -d ' ' -f 1-3 > ${file%.dat}-var.dat
    fi

    if [ -n "$record" ]; then
      if [ "$debug" = "true" ]; then
        echo "helcor ra=$ra de=$dec mask=${file%.dat}-var-hc.dat ${file%.dat}-var.dat"
      else
        helcor ra=$ra de=$dec mask=${file%.dat}-var-hc.dat ${file%.dat}-var.dat
      fi	
    fi

    if [ "$no_delete" = "false" ]; then
      if [ "$debug" = "true" ]; then
        echo "rm -f ${file%.dat}-var.dat"
      else
        rm -f ${file%.dat}-var.dat
      fi
    fi

  fi

  # Get comparison
  if [ "$get_comparison" = "true" ]; then
    if [ "$debug" = "true" ]; then
      echo "dos2unix -q $file"
      echo "cat $file | tail -n +3 | grep -v '^$' | grep -v '99.999' | cut -d ' ' -f 1,8,9 > ${file%.dat}-cmp.dat"
    else
      echo "$file -> ${file%.dat}-cmp.dat"
      dos2unix -q $file
      cat $file | tail -n +3 | grep -v '^$' | grep -v '99.999' | cut -d ' ' -f 1,8,9 > ${file%.dat}-cmp.dat
    fi

    if [ -n "$record" ]; then
      if [ "$debug" = "true" ]; then
        echo "helcor ra=$ra de=$dec mask=${file%.dat}-cmp-hc.dat ${file%.dat}-cmp.dat"
      else
        helcor ra=$ra de=$dec mask=${file%.dat}-cmp-hc.dat ${file%.dat}-cmp.dat
      fi	
    fi

    if [ "$no_delete" = "false" ]; then
      if [ "$debug" = "true" ]; then
        echo "rm -f ${file%.dat}-cmp.dat"
      else
        rm -f ${file%.dat}-cmp.dat
      fi
    fi
  fi

done
