#!/bin/bash
# addcols shp-file
# addcols -f 1 N5424D N5424E
# addcols -f 0 N5424D N5424E
# -f fast use layer checking or not = trust to filename
# Area code

BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0





###############################################################################
usage()
{
	echo "usage:$PRG [ -f ] area [area ... ] ">&2 
}

###############################################################################
# MAIN
###############################################################################

AREAS=""

outputdir="data"
# check laeyr from file, it take 1 s only
fast=0

while [ $# -gt 0 ]
do
        arg="$1"
        case "$arg" in
                -f) fast="$2" ; shift ;;
                -d) DEBUG="$2" ; shift ;;
                -o) outputdir="$2" ; shift ;;
                -*) usage; exit 4 ;;
                *) break ;;
        esac
        shift
done

# files 1-n
[ $# -lt 1 ] && usage && exit 5

AREAS="$*"
[ "$AREAS" = "" ] && usage && exit 1

# Look layers from file, add new column for that and add symbol col for 
# extension using purpose
# loop layers
#ogrinfo -ro -so -q "$GPKG_FILE" | while read ID LAYER
# ogrinfo -so  "$f" N5424D_palstatunnus
mkdir -p "$outputdir"
NOW=$PWD

for AREA in $*
do
  cd $NOW
  cp -f ${AREA}_*.??? "$outputdir"
  cd "$outputdir"
  for f in ${AREA}_*.shp
  do
    LAYER=${f%.shp} # filename include it, but read from file is correct answer
    (( fast<1 )) && read id LAYER txt <<<$(ogrinfo -ro -so -q "$f" )
    table=${LAYER#*_}
    Xarea=${LAYER%%_*}

    echo "l:$LAYER a:$Xarea t:$table" >&2

    # Add new columns
    ogrinfo "$f" -q -sql "ALTER TABLE $LAYER ADD COLUMN symbol Integer"
    (($? > 0 )) && echo "error 1" >&2 && exit 10
    ogrinfo "$f" -q -sql "ALTER TABLE $LAYER ADD COLUMN layername Text"
    (($? > 0 )) && echo "error 2" >&2 && exit 11
    #ogrinfo "$f" -q -dialect postgresql -sql "ALTER TABLE $LAYER ADD COLUMN symbol integer"
    #ogrinfo "$f" -q -dialect postgresql -sql "ALTER TABLE $LAYER ADD COLUMN layername text"
    
    # Update layername column with layer name
    ogrinfo "$f" -q -dialect sqlite -sql "UPDATE $LAYER SET layername = '$LAYER'"
    (($? > 0 )) && echo "error 3" >&2 && exit 12
    # Update symbol column with NULL value
    ogrinfo "$f" -q -dialect sqlite -sql "UPDATE $LAYER SET symbol = NULL"
    (($? > 0 )) && echo "error 4" >&2 && exit 13
  done
done
