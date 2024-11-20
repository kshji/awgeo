#!/usr/bin/env bash
# ksh or bash or ...
# forest.sh
#
# Copyright 2024 Karjalan ATK-Awot Oy
# Jukka Inkeri
#
# Make spike free digital surface model
# "forest"
#
VER="2024-11-17.a"
#
# using las2dem
#
#
# forest.sh -i lazfile -o outputdir -s step -d $DEBUG
# forest.sh -i P5331A4.laz 
#  - result file is ./P5331A4.forest.png
# forest.sh -i P5331A4.laz -o results
#  - output to the dir results
#
# forest.sh -i P5331A4.laz -o results -s 0.25 -d 1
# - step 0.25, look las2dem option -step document
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
$*
usage:$PRG -i input.laz [ -s STEP ] [ -o outputdir ] [ -d 0|1 ]
	-d 0|1 debug, default is 0
	-s NUM  # step, default 0.5
	-o outputdir, default is current
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
  
################################################################
last_slash()
{
        str="$*"
        len=${#str}
        ((len-=1))
        last=${str:$len:1}
        [ "$last" = "/" ] && str=${str:0:len}
        echo "$str"
}

################################################################
getdir()
{
        str="$*"
        strorg="$str"
        [ "$str" = "/" ] && str=""
        str=$(last_slash "$str")
        # ei saa poistaa jos on jo hakemisto !!!
        [ -d "$str" ] && print -- "$str" && return
        #[ "$strorg" = "$str" ] && print -- "." && return
        echo "${str%/*}"
}

################################################################
getfile()
{
        str="$*"
        echo "${str##*/}"
}

################################################################
getbase()
{
        str="$1"
        remove="$2"
        echo "${str%$remove}"
        #eval echo "\${str//$2/}"
}


########################################################
# MAIN
########################################################
inf=""
result=""
#step=0.25
step=0.5
outputdir="."
mkdir -p tmp "$outputdir" 2>/dev/null
id=$$ # process number = unique id for tempfiles
TEMP="tmp/$id"

# parse cmdline options
while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-i) inf="$2"; shift  ;;
		-d) DEBUG="$2"; shift  ;;
		-o) outputdir="$2" ; shift ;;
		-s) step="$2" ;: shift ;;
		-v) echo "$PRG Ver:$VER" >&2 ;;
		-h) usage ; exit 1 ;;
		-*) usage ; exit 1 ;;
	esac
	shift
done

[ "$inf" = "" ] && usage "input laz?" && exit 1
mkdir -p tmp "$outputdir" 2>/dev/null
[ ! -f "$inf" ] && err "no file:$inf" && exit 3

fname=$(getfile "$inf")
name=$(getbase "$fname" ".laz")
result="${name}.forest.png"
dbg las2dem64 -i "$inf" -spike_free 0.9  -step "$step"  -hillshade  -o "$outputdir/$result"
las2dem64 -i "$inf"  -spike_free 0.9  -step "$step"  -hillshade  -o "$outputdir/$result"

echo "result: $outputdir/$result"

