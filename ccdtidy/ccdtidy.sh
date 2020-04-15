#!/bin/bash
#########################################################################
#									#
# 	ccdtidy				        Version: 0.1		#
#									#
# 	Author: Gabriel Szasz			19.12.2004		#
#									#
#	Copyright (C) 2004 Hlohovec Observatory                         #
#									#
#  Utility for correcting filename and header of each FITS FILE         #
#  according to Hlohovec Observatory standards.                         #
#  -------------------------------------------------------------------  #
#  Standard filename pattern of CCD FITS files at Hlohovec Observatory  #
#  compounds from two parts: prefix and suffix.                         #
#                                                                       #
#           OBJECT-YYYY-MM-DD-NNN[F].fit[s]                             #
#           |-----prefix----| |-sx-|                                    #
#                                                                       #
#    OBJECT      name of observed object (without spaces)               #
#    YYYY-MM-DD  evening date of the observation                        #
#    NNN         suffix number of the image (three digits)              #
#    F           filter letter (not used for clear filter and           #
#                  dark frames)                                         #
#  -------------------------------------------------------------------  #
#  Standard header of CCD FITS files at Hlohovec Observatory contains   #
#  following special keys:                                              #
#                                                                       #
#      OBJECT    name of observed object                                #
#      NOTE      used filter                                            #
#      OBSERVER  list of observers                                      #
#      TELESCOP  used telescope                                         #
#      DEVICE    used CCD camera                                        #
#									#
#########################################################################

# Default settings
files=`ls *.fit *.fits`
auto_correct=true

offset=0
base=0
check_offset=false
clear_letter=false
header_file=/tmp/ccdtidy-fits-header

# Argument processing
while [ -n "$1" ]; do
  if [ "$1" = "-h" -o "$1" = "--help" ]; then
    echo -e "Usage: ccdtidy [OPTIONS]... [FILE]..."
    echo -e "Utility for correcting filename and header of each FITS FILE"
    echo -e "according to Hlohovec Observatory standards.\n"
    echo -e "  -g, --debug\t\t\tdebug mode (echo commands only)"
    echo -e "  -a, --auto-correct\t\tautomatic filename and FITS header correction"
    echo -e "  -o, --object OBJECT\t\tset object name in file prefix to OBJECT"
    echo -e "  -f, --filter FILTER\t\tset filter in file suffix to FILTER (0 = clear)"
    echo -e "  -d, --correct-date\t\tcorrect date in file prefix"
    echo -e "      --observer STRING\t\tset OBSERVER key in FITS header"
    echo -e "      --telescope STRING\t\tset TELESCOP key in FITS header"
    echo -e "  --device STRING\t\tset DEVICE key in FITS header"
    echo -e "  -h, --help \t\t\tdisplay this help and exit"
    echo -e "      --version\t\t\toutput version information and exit\n"
    echo -e "Default behavior: automatic correction of all FITS files in working directory\n"
    echo -e "Standard filename structure of CCD FITS files at Hlohovec Observatory"
    echo -e "consists of two parts: prefix and suffix.\n"
    echo -e "\t\tOBJECT-YYYY-MM-DD-NNN[F].fit[s]"
    echo -e "\t\t|-----prefix----| |-sx-|\n"    
    echo -e "  OBJECT\tname of observed object (without spaces)"
    echo -e "  YYYY-MM-DD\tevening date of the observation"
    echo -e "  NNN\t\tsuffix number of the image (three digits)"
    echo -e "  F\t\tfilter letter (not used for clear filter and dark frames)\n"
    echo -e "Standard header of CCD FITS files at Hlohovec Observatory contains"
    echo -e "following special keys:\n"
    echo -e "\tOBJECT\t\tname of observed object"
    echo -e "\tNOTE\t\tused filter"
    echo -e "\tOBSERVER\tlist of observers"
    echo -e "\tTELESCOP\tused telescope"
    echo -e "\tDEVICE\t\tused CCD camera\n"
    exit 0
  elif [ "$1" = "-g" -o "$1" = "--debug" ]; then
    debug=true
  elif [ "$1" = "-a" -o "$1" = "--auto-correct"  ]; then
    correct_numbering=true
    correct_date=true
  elif [ "$1" = "-o" -o "$1" = "--object" ]; then
    shift
    object="$1"
  elif [ "$1" = "-o" -o "$1" = "--filter" ]; then
    shift
    filter="$1"
  elif [ "$1" = "-d" -o "$1" = "--correct-date" ]; then
    correct_date=true
  elif [ "$1" = "--observer" ]; then
    shift
    observer="$1"
  elif [ "$1" = "--telescope" ]; then
    shift
    telescope="$1"
  elif [ "$1" = "--device" ]; then
    shift
    device="$1"
  elif [ "$1" = "--version" ]; then
    echo -e "ccdtidy (ccdtools) 0.1"
    echo -e "Written by Gabriel Szasz.\n"
    echo -e "Copyright (C) 2004 Hlohovec Observatory"
    exit 0
  else
    files=$*
    break
  fi
  shift
done

r_numbering () {
	if ! echo $PATH | /bin/egrep -q "(^|:)$1($|:)" ; then
	    [ -z "$PATH" ] && PATH=$1 || PATH=$PATH:$1
	fi
}


for file in $files ; do
  extension=`echo $file | gawk -F "." '{ print $NF }'`
  mv $file ${object}-${unix-time}.$extension
done

# check offset
if [ "$check_offset" = "true" ]; then
  for file in $files ; do
    # Get raw filename and file extension
    raw_file=`echo $file | cut -d '.' -f 1`
    extension=`echo $file | cut -d '.' -f 2`

    if [ "$extension" = "fit" -o "$extension" = "fits" ]; then

      # Get filename prefix and suffix
      suffix=`echo $raw_file | gawk -F '-' '{ print $NF }'`

      # Analyze file suffix
      num=`echo $suffix | sed 's/^.*\([0-9]*\).*$/\1/'`
      break
    fi
  done

  offset=`expr $num - 1 - $base`
fi

#automatic numbering
if [ "$auto_numbering" = "true" ]; then
  for file in $files ; do
    fitshead $file | grep 
    # Get raw filename and file extension
    raw_file=`echo $file | cut -d '.' -f 1`
    extension=`echo $file | cut -d '.' -f 2`

    if [ "$extension" = "fit" -o "$extension" = "fits" ]; then

      # Get filename prefix and suffix
      suffix=`echo $raw_file | gawk -F '-' '{ print $NF }'`

      # Analyze file suffix
      num=`echo $suffix | sed 's/^.*\([0-9]*\).*$/\1/'`
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
   
    # Get information from FITS header
    fitshead $file > $header_file
    # date and time
    date=`cat $header_file | grep DATE | cut -d "'" -f 2`
    time=`cat $header_file | grep TIME-OBS | cut -d "'" -f 2`
    hour=`echo $time | cut -d ":" -f 1`

    # compute evening date
    if [ $hour -lt 11 ]; then
      date=`date -d "yesterday $date" -I`
    fi
    
    # compute UNIX time
    unix_time=`date -d "$date $time" +%s`

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
    nf=`echo $prefix | gawk -F '-' '{ print NF }'`
    
    # Analyze file suffix
    num=`echo $suffix | sed 's/^.*\([0-9]*\).*$/\1/'`
    if [ -z "$letter" ]; then      
      letter=`echo $suffix | sed 's/^.*[0-9]*\(.*\)$/\1/'`
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
    if [ -z "$letter" -o "$clear_letter" = "true" -o "$object" = "dark" ]; then
      new_suffix=$(printf "%03d" `expr $num - $offset`)
    else
      new_suffix=$(printf "%03d%s" `expr $num - $offset` $letter)
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
