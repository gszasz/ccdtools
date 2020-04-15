#!/bin/bash
#
# ccdexport.sh -- Export lightcurve file to different formats
#
# Copyright (C) 2005, 2020  Gabriel Szasz <gabriel.szasz1@gmail.com>
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

ini_file="ini.alc"

dos2unix -q $*

count=0
for file in $* ; do
  count=$(expr $count + 1)
done

touch $ini_file

cat > $ini_file <<EOF
[Asteroid]
AsterId=Variable Star
ProjectId=FRO
MagSystem=r R
OpenMsg=dfjlfls
OpenMsgDisplayMode=2
T0=2400000.50000
G= 0.15
PhaseRef= 10.00
Period=   5.6785120000
PeriodErr=   0.0000090000
IsBestFit=1
UseLCerrorsInPlots=0
Epoch=  53039.38866
EphType=
EphFile=
ElmFile=
CompLCplot=1
PlottedGrpMin=1
PlottedGrpMax=4
LegendSpacing=20
MethodFF=1
FourierFitted=1
KeepAx=0
Y0=15.02124
Yaxrozsah=0.792480000000001
PointsAveraged=0
FourierOrder=10
FittedGrpMin=1
FittedGrpMax=4
[LCurves]
NumLCs=$count
EOF

id=1
for file in $* ; do
  cat $file | sed '/^$/d' | tail -n +3 | gawk '{ print $1, $2 }' | sed '/^.*99\.999$/d' > ${file%.dat}.lc
  cat >> $ini_file <<EOF
LC#${id}=${file%.dat}.lc
LC#${id}Take=1
LC#${id}Group=1
LC#${id}deltaT=      0.00000
LC#${id}LTcPredone=0
LC#${id}MagCS=00.000
LC#${id}Calibrated=1
LC#${id}MagSystem=R
LC#${id}deltaM=  0.000
LC#${id}trendMdT= 0.000
LC#${id}MagCSunc=  0.000
EOF
  id=$(expr $id + 1)
done

unix2dos -q $*
unix2dos -q $ini_file
