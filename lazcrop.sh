#!/usr/bin/env bash
# ksh or bash or ...
# lazcrop.sh
#
# Copyright 2024 Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://github.com/kshji/awgeo
# https://awot.fi
#
# CROP polyline from LAZ
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
usage:$PRG -i input.laz -p polyline.wkt -o outname.laz [ -d 0|1 ]
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
make_json_crop()
{
# pdal json 
Zin="$1"
polygon=$(<$Zin)
#polygon=$(cat $Zin)
dbg "dbg: polygon:$polygon"
cat <<JSON
{
  "pipeline":[
    "input.laz",
    {
      "type":"filters.crop",
      "polygon": "$polygon"
    },
    {
      "type":"writers.las",
      "filename":"output.laz"
    }
  ]
}
JSON

}

########################################################
# MAIN
########################################################
inf=""
result=""
polyfile=""
mkdir -p tmp 2>/dev/null
id=$$ # process number = unique id for tempfiles
TEMP="tmp/$id"
cropjson="$TEMP.crop.json"

# parse cmdline options
while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-i) inf="$2"; shift  ;;
		-o) result="$2"; shift  ;;
		-p) polyfile="$2"; shift  ;;
		-d) DEBUG="$2"; shift  ;;
		-v) echo "$PRG Ver:$VER" >&2 ;;
		-h) usage ; exit 1 ;;
		-*) usage ; exit 1 ;;
	esac
	shift
done

[ "$inf" = "" ] && usage && exit 1
[ "$polyfile" = "" ] && usage && exit 2
[ "$result" = "" ] && usage && exit 3

make_json_crop "$polyfile" > $cropjson

step make cropped laz
pdal pipeline --readers.las.filename="$inf" --writers.las.filename="$result" $cropjson

[ ! -f "$result" ] && err "nofile $result" && exit 5

dbg "dbg: $TEMP.* temporary files"
[ $DEBUG -lt 1 ] && rm -f $TEMP.* 2>/dev/null

echo "result $result"

