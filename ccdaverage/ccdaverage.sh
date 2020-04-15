#!/bin/bash
#########################################################################
#									#
# 	ccdaverage		                Version: 0.1  		#
#									#
# 	Author: Gabriel Szasz			1.5.2005		#
#									#
#	Copyright (C) 2005 Hlohovec Observatory                         #
#								        #
#  Utility for creating averaged light curve datafiles using various    #
#  methods including running averages and phase binning.		#
#                                                                       #
#  Ephemeris of observed object is read from central catalog file:      #
#                                                                       #
#      /usr/local/share/ccdtools/catalog                                #
#                                                                       #
#  Used backend 'Grace' was created by  Paul J Turner (1991-1995) and   #
#  today is maintained by Evgeny Stambulchik.				#
#                                                                       #
#  Actual source code of 'Grace' (5.1.18) is available on:              # 
#                                                                       #
#    ftp://plasma-gate.weizmann.ac.il/pub/grace/src/grace5/             #
#                                                                       #
#  Source code of 'Grace 5.1.17-1' (modified version of 'Grace 5.1.17') #
#  created by Gabriel Szasz (2004), which includes some fancy features  #
#  in user interface, is distributed with package 'ccdtools'            #
#	                                                                #
#########################################################################

# Catalog path
ccd_root=/usr/local/share/ccdtools
catalog_file=$ccd_root/catalog

# Temporary file
temp=/tmp/ccdaverage.tmp

# Default settings
debug=false
method="runavg"
runavg_number=10
force_object=false
files=`echo *-var-hc.dat`

# Argument processing
while [ -n "$1" ]; do
  case $1 in 
    -h | --help )
      echo -e "Usage: ccdphase [OPTIONS]... [FILE]..."
      echo -e "Utility for creating averaged lightcurve data file from" 
      echo -e "each FILE (or *-var.dat if no files are named)\n"
      echo -e "  -g, --debug\t\t\tdebug mode (echo commands only)"
      echo -e "  -r, --runavg NUMBER\t\trunning average using NUMBER of points"
      echo -e "  -b, --phase-bin\tphase binning using phase interval 0.1"
      echo -e "  -o, --object OBJECT\t\tuse ephemeris of OBJECT"
      echo -e "  -h, --help \t\t\tdisplay this help and exit"
      echo -e "      --version\t\t\toutput version information and exit\n"
      echo -e "Default behavior: compute running averages for data files using 10 points\n"
      echo -e "Files matching masks '*-cmp-*.dat', '*-phase.dat', '*-ravg.dat' and" 
      echo -e "and '*-pbin.dat' (output files the 'ccdtools' utilities) will be skipped.\n"
      echo -e "Object name is obtained from filename structure according to Hlohovec"
      echo -e "Observatory standards, unless not specified explicitly using '-o' argument.\n" 
      echo -e "Files not complying Hlohovec Observatory standards and particular output files" 
      echo -e "of ccdtools utilities are automatically skipped.\n"
      echo -e "Ephemeris of object is read from central catalog file:\n"
      echo -e "    /usr/local/share/ccdtools/catalog\n"
      exit 0
      ;;
    --version )
      echo -e "ccdaverage (ccdtools) 0.1"
      echo -e "Written by Gabriel Szasz.\n"
      echo -e "Copyright (C) 2005 Hlohovec Observatory"
      exit 0
      ;;
    -g | --debug )     debug=true                                     ;;
    -r | --runavg )    shift; runavg_number=$1; method="runavg"       ;;
    -b | --phase-bin ) method="phasebin"                              ;;
    -o | --object )    shift; object="$1"; force_object=true          ;;
    * )                files=$* ; break                               ;;
  esac
  shift
done

# Filter input files
for file in $files ; do
  file_object="$(echo $file | sed 's/\(^.*\)-[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.*\.dat$/\1/')"
  file_flag="$(echo $file | sed 's/^.*-[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\(.*\)\.dat$/\1/')"
  # Skip files not complying Hlohovec Observatory standards
  if [ -z "$file_object" -o -z "$file_flag" ]; then
    continue
  fi
  # Skip particular output files of ccdtools utilities
  if [ -n "$(echo $file_flag | grep '\(cmp\|phase\|ravg\|pbin\)')" ]; then 
    continue
  fi

  input_files=(${input_files[*]} "$file")
  input_files_count=${#input_files[*]}
done

# Process input files
for file in ${input_files[*]} ; do

  if [ "$method" = "phasebin" ]; then

    if [ ! $force_object ] ; then 
      file_object="$(echo $file | sed 's/\(^.*\)-[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.*\.dat$/\1/')"
    fi

    if [ ! "$object" = "$file_object" ]; then
      object=$file_object
      record=`grep $object $catalog_file`

      if [ -n "$record" ]; then

	epoch=`echo $record | cut -d ' ' -f 4`
	period=`echo $record | cut -d ' ' -f 5`
	if [ -z "$epoch" -o -z "$period" ]; then
	  echo "ccdget: Invalid record for object '$object' in catalog file"
	  exit 1
	fi
      else
	echo "ccdget: Object '$object' not found in catalog file"
	exit 1
      fi
    fi
  fi



  if [ "$method" = "runavg" ]; then
    if $debug ; then
      echo " cat <<EOF > $temp"
      echo "with g0"
      echo "    runavg(s0,${runavg_number})"
      echo "    move s1 to s0"
      echo "    write s0 format \"%.8lf\""
      echo "EOF"
      echo "gracebat -noprint -nosafe -settype xydy $file -batch $temp | \\"
      echo "  grep -v '^[[:blank:]]*$' > ${file%.dat}-ravg.dat"
    else
      cat <<EOF > $temp
with g0
    runavg(s0,${runavg_number})
    move s1 to s0
    write s0 format "%.8lf"
EOF
      gracebat -noprint -nosafe -settype xydy $file -batch $temp | \
	grep -v '^[[:blank:]]*$' > ${file%.dat}-ravg.dat
    fi

  elif [ "$method" = "phasebin" ]; then
    if $debug ; then
      echo -n "gawk -v epoch=$epoch -v period=$period "
      echo -n '{ jd = $1 - epoch; phase = (jd % period) / period; print $1, $2, $3, phase; }'
      echo " $file > $temp"
      echo "gawk \\"
      echo "  'BEGIN { prev_i = -1;  n = 0; sum_hjd = 0; sum_mag = 0; } \\"
      echo "   { i = int($3 * 10); n++; sum_hjd+=$1; sum_mag+=$2; \\"
      echo "     if (i != prev_i) { \\" 
      echo "       print sum_hjd/n, sum_mag/n; \\"
      echo "       n = 0; sum_hjd = 0; sum_mag = 0; \\"
      echo "     } \\"
      echo "   }' $temp > ${file%.dat}-pbin.dat"
    else
      echo "$file -> ${file%.dat}-pbin.dat"
#      ccdphase -a $file
      gawk -v epoch=$epoch -v period=$period \
        '{ \
          jd = $1 - epoch; \
          phase = (jd % period) / period; \
          print $1, $2, $3, phase; \
         }' $file > $temp
      gawk \
	'BEGIN { n = 0; sum_x = 0; sum_y_w = 0; sum_err = 0; } \
         { cur_int = int($4 * 10); \
           if (n == 0) { prev_int = cur_int; }
           else if (cur_int != prev_int) { \
             avg_x = sum_x/n; avg_y = sum_y_w/sum_w; d_avg_y = sqrt(1/sum_w); \
             printf "%.5lf %.3lf %.4lf  @ %d\n", avg_x, avg_y, d_avg_y, cur_int; \
             n = 0; sum_x = 0; sum_y_w = 0; sum_w = 0; prev_int = cur_int; \
           } \
           x[n]=$1; y[n]=$2; w[n]=1/$3^2; sum_x+=x[n]; sum_y_w+=y[n]*w[n]; sum_w+=w[n]; n++; } \
          END { avg_x = sum_x/n; avg_y = sum_y_w/sum_w; d_avg_y = sqrt(1/sum_w); \
            printf "%.5lf %.3lf %.4lf  @ %d\n", avg_x, avg_y, d_avg_y, (cur_int<9)?cur_int+1:0; \
         }' $temp > ${file%.dat}-pbin.dat
    fi
  fi
done
