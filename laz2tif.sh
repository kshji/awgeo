#!/usr/bin/env bash
# ksh or bash or ...
# laz2tif.sh
#
# Copyright 2024 Karjalan ATK-Awot Oy
# Jukka Inkeri
#
# Create GeoTiff from LAZ file
#
VER="2024-11-04.a"
#
# using PDAL 
#

PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0

########################################################
usage()
{
	cat <<EOF >&2
usage:$PRG -i input.laz -o outname.tif [ -d 0|1 ]
	-d 0|1 debug, default is 0
EOF
	
}

########################################################
step()
{
	dbg "-step:$*" 
}

########################################################
status()
{
	dbg "-status:$*" 
}

########################################################
err()
{
	echo "err:$*" >&2
}

########################################################
dbg()
{
	[ $DEBUG -lt 1 ]  && return
	echo "  $*" >&2
}
  
########################################################
clear_result()
{
	rm -f "$result"   2>/dev/null
}

################################################################
make_json_tiff()
{
# pdal json 
cat <<JSON
{
    "pipeline":[
        "base.laz",
        {
            "type":"filters.range",
            "limits": "Classification[2:2]"
        },
        {
            "type":"writers.gdal",
            "filename":"result.tif",
            "resolution":1.0,
            "output_type":"all",
            "gdaldriver": "GTiff"
        }
    ]
}
JSON

}

################################################################
laz2tif()
{
        # if done, not again
	IN="$1"
	OUT="$2"
        [ -f "$OUT" ] && return
        #pdal pipeline --readers.las.filename="$IN" --writers.gdal.filename="$TEMP.$name.raw.tif" laz2tiff.json 2>/dev/null
        dbg dbg:pdal pipeline --readers.las.filename="$IN" --writers.gdal.filename="$TEMP.$name.raw.tif" $laz2tiff 
        pdal pipeline --readers.las.filename="$IN" --writers.gdal.filename="$TEMP.$name.raw.tif" $laz2tiff  2>/dev/null

        dbg dbg:gdal_fillnodata.py  "$TEMP.$name".raw.tif  "$OUT" 
        gdal_fillnodata.py  "$TEMP.$name".raw.tif  "$OUT"  
}

########################################################
# MAIN
########################################################
inf=""
result=""
mkdir -p tmp 2>/dev/null
id=$$ # process number = unique id for tempfiles
TEMP="tmp/$id"
laz2tiff="$TEMP.laz2tif.json"
status laz2tiff $laz2tiff
make_json_tiff > $laz2tiff



# parse cmdline options
while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-i) inf="$2"; shift  ;;
		-o) result="$2"; shift  ;;
		-d) DEBUG="$2"; shift  ;;
		-v) echo "$PRG Ver:$VER" >&2 ;;
		-h) usage ; exit 1 ;;
		-*) usage ; exit 1 ;;
	esac
	shift
done

[ "$inf" = "" ] && usage && exit 1
name=$(basename "$inf" .laz)
[ "$result" = "" ] && result="$name"

clear_result

step make tiff
dbg dbg:laz2tif "$inf" "$result"
laz2tif  "$inf" "$result"

[ ! -f "$result" ] && err "nofile $result" && exit 5

dbg "dbg: $TEMP.* temporary files"
[ $DEBUG -lt 1 ] && rm -f $TEMP.* 2>/dev/null

echo "result $result"

