#!/bin/bash
#########################################################################
#									#
# 	ccdrename				Version: 0.9.1		#
#				.					#
# 	Author: Gabriel Szasz			29.10.2004		#
#									#
#  Rename each FILE due to the standard filename pattern for CCD FITS 	#
#  files at Hlohovec Observatory. Very useful utility for changing	# 
#  fields in file prefix and/or for shifting the suffix numbering.	#
#									#
#########################################################################

# Version information
script="ccdrename"
package="ccdtools"
version="0.9.1"
author="Gabriel Szasz"
copyright_year="2005"
copyright="Gabriel Szasz"

# Default settings
offset=0
base=0
check_offset=false
clear_letter=false
change_letter=false
change_flip_flag=false
flipped=false

# Argument processing
while [ -n "$1" ]; do
  case $1 in
    -h | --help )
      echo -e "Usage: ccdrename [OPTIONS]... [FILE]..."
      echo -e "Rename each FILE due to the standard filename pattern for CCD FITS files"
      echo -e "at Hlohovec Observatory. Very useful utility for changing fields in file"
      echo -e "prefix and/or for shifting the suffix numbering.\n"
      echo -e "  -g, --debug\t\t\tdebug mode (echo commands only)"
      echo -e "  -o, --object OBJECT\t\tset object name in file prefix to OBJECT"
      echo -e "  -d, --date YYYY-MM-DD\t\tset date in file prefix to YYYY-MM-DD"
      echo -e "  -n, --num-offset OFFSET\tsubstract OFFSET from file suffix number"
      echo -e "  -a, --auto-num-offset\t\tsubstract automaticaly specified offset"
      echo -e "                       \t\t  from file suffix number"
      echo -e "  -b, --num-offset-base BASE\tsubstract offset relative to BASE suffix number"
      echo -e "  -f, --filter FILTER\t\tset filter letter in file suffix to FILTER"
      echo -e "  -F, --flipped\t\t\tset GEM flip state flag to 'flipped'"
      echo -e "  -N, --non-flipped\t\tset GEM flip state flag to 'non-flipped'"
      echo -e "  -c, --clear-filter\t\tdelete filter letter from file suffix\n"
      echo -e "Automaticaly specified offset is computed from the first processed filename"
      echo -e "as N-1 where N is suffix number of the file.\n"
      echo -e "Standard filename pattern of CCD FITS files at Hlohovec Observatory"
      echo -e "compounds from two parts: prefix and suffix.\n"
      echo -e "\t\tOBJECT-YYYY-MM-DD-NNN[F][f].fit[s]"
      echo -e "\t\t|-----prefix----| |--sfx--|\n"    
      echo -e "  OBJECT\tname of observed object (without spaces)"
      echo -e "  YYYY-MM-DD\tevening date of the observation"
      echo -e "  NNN\t\tsuffix number of the image (three digits)"
      echo -e "  F\t\tfilter letter (not used for clear filter and dark frames)"
      echo -e "  f\t\tGEM flip state flag (none for non-flipped and 'f' for flipped)\n"
      exit 0
      ;;
    --version )
      echo -e "$script ${package:+($package) }$version"
      echo -e "Written by $author.\n"
      echo -e "Copyright (C) $copyright_year $copyright"
      exit 0
      ;;
    -g | --debug )     debug=true                                ;; 
    -o | --object )    shift; object="$1"; change_object=true    ;;
    -d | --date )      shift; obs_date=`echo $1 | gawk -F '-' '{ printf "%4d-%02d-%02d", $1, $2, $3 }'` ;;
    -n | --num-offset) shift; offset="$1"                        ;;
    -a | --auto-num-offset )  check_offset=true                  ;;
    -b | --num-offset-base ) shift; base="$1"; check_offset=true ;;
    -f | --filter )    shift; letter="$1";  change_letter=true ;;
    -F | --flipped )      flipped=true;  change_flip_flag=true ;;
    -N | --non-flipped )  flipped=false; change_flip_flag=true ;;
    -c | --clear-filter)     clear_letter=true                   ;;
    *)                 files=$*; break                           ;;
  esac
  shift
done

if $change_letter ; then
   letter="$(echo $letter | cut -c 1 | tr [:lower:] [:upper:] | grep -o '[UBVRIC]')"
   if [ -z "$letter" ]; then
     echo "ccdrename: Unknown filter letter. Supported letters: U, B, V, R, I, C."
     exit 1
   fi
fi

if $check_offset ; then
  for file in $files ; do
    # Get raw filename and file extension
    raw_file=`echo $file | cut -d '.' -f 1`
    extension=`echo $file | cut -d '.' -f 2`

    if [ "$extension" = "fit" -o "$extension" = "fits" ]; then
      # Get filename prefix and suffix
      suffix=`echo $raw_file | gawk -F '-' '{ print $NF }'`
    
      # Analyze file suffix
      num="$(echo $suffix | sed 's/\([0-9]*\)[^0-9]*/\1/')"
      break
    fi
  done

  offset=`expr $num - 1 - $base`
fi

# Reverse the file order if offset is less than zero
if [ $offset -lt 0 ]; then
  for file in $files ; do
    rev_files="$file $rev_files"
  done
  files=$rev_files
fi

for file in $files ; do
  # Get raw filename and file extension
  raw_file=`echo $file | cut -d '.' -f 1`
  extension=`echo $file | cut -d '.' -f 2`

  if [ "$extension" = "fit" -o "$extension" = "fits" ]; then
   
    # Object variable initialization
    if [ -z "$change_object" ]; then 
      object=""
    fi
    
    # Letter variable initialization
    if [ -z "$change_letter" ]; then 
      letter=""
    fi
  
    # Get filename prefix and suffix
    prefix=`echo $raw_file | gawk -F '-' '{ for(i=1;i<NF-1;i++) { printf "%s-", $i } printf "%s", $i }'`
    suffix=`echo $raw_file | gawk -F '-' '{ print $NF }'`
    
    # Analyze file prefix
    nf="$(echo $prefix | gawk -F '-' '{ print NF }')"
    
    # Analyze file suffix
    num="$(echo $suffix | sed 's/\([0-9]*\)[^0-9]*/\1/')"
    flags="$(echo $suffix | sed 's/[0-9]*\([^0-9]*\)/\1/')"


    # Get filter letter from original suffix if not forced
    if ! $change_letter ; then
       [ -n "$flags" ] && letter="$(echo $flags | grep -o '[UBVRIC]')"
    fi

    # Get GEM flip state flag from original suffix if not forced
    if ! $change_flip_flag ; then
      [ -n "$(echo $flags | grep f)" ] && flipped=true || flipped=false
    fi   

    # Change object name due to deprecated suffix letter (compatibility stuff)
    if [ "$letter" = "F" ]; then
      object=flat
      letter=""
    elif [ "$letter" = "D" ]; then
      object=dark
      letter=""
    fi

    # Set object in file prefix
    if [ -z $object ]; then
      object=`echo $prefix | cut -d '-' -f 1`
    fi  
    
    # Set date in file prefix    
    if [ $nf -eq 4 -a -z "$obs_date" ]; then
      obs_date=`echo $prefix | gawk -F '-' '{ printf "%4d-%02d-%02d", $2, $3, $4 }'`
    fi  
        
    # Create new (compound) prefix if possible
    if [ -n "$obs_date" ]; then
      new_prefix="$object-$obs_date"
    else
      new_prefix="$object"  
    fi
    
    # Create new suffix
    new_suffix=$(printf "%04d" `expr $num - $offset`)

    # Add filter letter into new suffix if needed
    if ! [ -z "$letter" -o "$clear_letter" = "true" -o "$object" = "dark" ]; then
      new_suffix=${new_suffix}${letter}
    fi

    # Add GEM flip state flag into new suffix if needed
    if $flipped ; then
      new_suffix=${new_suffix}f
    fi

    # Create new filename
    new_file="$new_prefix-$new_suffix.fit"
    
    # Rename the file
    if [ -n "$debug" ]; then
      echo "mv -vi $file $new_file"
    elif [ -e "$new_file" ]; then
      echo "ccdrename: File '$new_file' already exist."
    else
      mv -v $file $new_file
    fi
  fi
done
