#!/usr/bin/env bash
# ksh or bash or ...
# hillshade.sh
#
# hillshade.sh -i input.laz # default -g 1 -z 3, outputfile input.hillshade.tif
# hillshade.sh -i input.laz -o out.tif -g 1 -z 3
#
# Copyright 2024 Karjalan ATK-Awot Oy
# Jukka Inkeri
#
# Make hillshade tiff from LAZ
#
VER="2025-01-23.a"
#
# using PDAL gdal GDAL
# katso varjo4.sh, sama Lastools:lla
# developer playground doc:
#       Src/Geo/Lastools/sotku1
#
# Using programs:
#	proj
# 	gdal
# 	pdal
#	python3
#
# https://pdal.io/   BSD License
# https://gdal.org/  MIT License, Some files are licensed under BSD 2-clause, BSD 3-clause or other non-copyleft licenses
# https://proj.org/  X/MIT 
# The full licence terms can be found on the individual pages of the following tools
# 
#
# Linux Ubuntu, Debian installing
#
#	sudo apt-get install proj-bin libproj-dev
# 	sudo apt-get install python3-dev python3.8-dev
# GDAL
# Official stable UbuntuGIS packages.
#	sudo add-apt-repository ppa:ubuntugis/ppa
#	sudo apt-get update
# 	apt-get install gdal-bin libgdal-dev
#	Check:
#	ogrinfo --version
#
#	sudo apt-get install python3-gdal 
# If using perl, then
#	sudo apt-get install libgd-gd2-perl
# PDAL
#	sudo apt-get install pdal
#
# User
#	- look version using: ogrinfo --version
#	- in this example version is 3.3.2
#	pip install GDAL==3.3.2
#	pip install pygdal=="3.3.2.*"

PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0

########################################################
usage()
{
	cat <<EOF >&2
usage:$PRG -i inputlaz -o outname [ -g 0|1 ]  [ -z NUM ]
Result is outname.tif
  - g 0|1, 1 is default - use 1st ground filter before making hillshade
  - z NUM , default is 3
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
	rm -f "$result".tif "$result".ground.laz  2>/dev/null
}

################################################################
make_json_ground()
{
# pdal json 
cat <<JSON
{
    "pipeline":[
        {
                "type":"filters.assign",
                "assignment": "Classification[:]=0"
        },
        {
                "type":"filters.elm"
        },
                {
                "type":"filters.outlier"

        },
        {
                "type":"filters.smrf",
                "ignore": "Classification[7:7]",
                "slope": 0.10,
                "window": 18,
                "threshold": 0.5,
                "scalar":1.25
         },
         {
                "type":"filters.range",
                "limits": "Classification[2:2]"
        }
    ]
}
JSON

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
# defaults
set_def()
{
        s=1.0
        az=200
        #az=250 # darker slope
        #az=335 # too dark slope
        #alt=55
        alt=60
        z=3
        alg=Horn
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
        gdal_fillnodata.py  "$TEMP.$name".raw.tif  "$OUT"  2>/dev/null
}

########################################################
# MAIN
########################################################
inf=""
result=""
ground=1
slope=0
set_def
mkdir -p tmp 2>/dev/null
id=$$ # process number = unique id for tempfiles
TEMP="tmp/$id"
groundfilter="$TEMP.ground_filter.json"
laz2tiff="$TEMP.laz2tif.json"


outaddon=".hillshade"

# parse cmdline options
while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-i) inf="$2"; shift  ;;
		-o) result="$2"; outaddon=""; shift  ;;
		-g) ground="$2"; shift  ;;
		-d) DEBUG="$2"; shift  ;;
		-z) z="$2"; shift  ;;
		-v) echo "$PRG Ver:$VER" >&2 ;;
		-h) usage ; exit 1 ;;
		-*) usage ; exit 1 ;;
	esac
	shift
done

[ "$inf" = "" ] && usage && exit 1
name=$(basename "$inf" .laz)
[ "$result" = "" ] && result="$name"

status groundfilter $groundfilter
status laz2tiff $laz2tiff
make_json_ground > $groundfilter
make_json_tiff > $laz2tiff

clear_result

step make ground
#[ "$ground" = 1 ] && status "ground $inf" && pdal translate "$inf" "$result".ground.laz --json ground_filter.json  2>/dev/null
[ "$ground" = 1 -a "$DEBUG" -gt 0 ] && dbg dbg:pdal translate "$inf" "$result".ground.laz --json $groundfilter  
[ "$ground" = 1 ] && status "ground $inf" && pdal translate "$inf" "$result".ground.laz --json $groundfilter  2>/dev/null
[ "$ground" = 0 ] && cp -f  "$inf" "$result".ground.laz
[ ! -f "$result".ground.laz ] && err "no file: "$result".ground.laz" && exit 3

step make tiff
dbg dbg:laz2tif "$result".ground.laz "$result".ground.tif 
laz2tif "$result".ground.laz "$TEMP.$result".ground.tif 

[ ! -f "$TEMP.$result".ground.tif ] && err "nofile $TEMP.$result.ground.tif" && exit 4
step make result file
#dbg dbg:gdaldem hillshade -co compress=lzw -s $s -compute_edges -az $az -alt $alt -z $z -alg "$alg" "$TEMP.$result".ground.tif "$result".tif  
#gdaldem hillshade -co compress=lzw -s $s -compute_edges -az $az -alt $alt -z $z -alg "$alg" "$TEMP.$result".ground.tif "$result".tif  2>/dev/null
dbg gdaldem hillshade -co compress=lzw -s $s -compute_edges -multidirectional -alt $alt -z $z -alg "$alg" "$TEMP.$result".ground.tif "$result".tif  
gdaldem hillshade -co compress=lzw -s $s -compute_edges -multidirectional -alt $alt -z $z -alg "$alg" "$TEMP.$result".ground.tif "$result"${outaddon}.tif  2>/dev/null
step done

[ ! -f "$result".tif ] && err "nofile $result.tif" && exit 5

dbg "dbg: $TEMP.* temporary files"
[ $DEBUG -lt 1 ] && rm -f $TEMP.* 2>/dev/null

donestr="result $result.tif"
[ "$ground" = 1 ] && donestr="$donestr $result.ground.laz"

echo "$donestr"

