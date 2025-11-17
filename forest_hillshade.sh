#!/usr/bin/env bash
# ksh or bash or ...
# forest_hillshade.sh
#
# Copyright 2024 Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://github.com/kshji/awgeo
# https://awot.fi
#
# Make hillshade tiff from LAZ and forest "spike free" png
# ground hillshade and forest "hillshade"
#
# $AWGEO/forest_hillshade.sh -z ZNUM  -o outputdir inputlazfile(s)
# $AWGEO/forest_hillshade.sh -o tulos ../P*.laz
# $AWGEO/forest_hillshade.sh -z 3 -o tulos ../P*.laz
# $AWGEO/forest_hillshade.sh -z 3 -o tulos -d 1 ../P*.laz
#
VER="2024-11-17.a"
#
# 
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
usage:$PRG [ -z NUM ] [ -o outputdir ] lazfile(s)
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
clear_result()
{
	rm -f "$result".tif "$result".ground.laz  2>/dev/null
}

################################################################
# defaults
set_def()
{
        z=3
}

########################################################
# MAIN
########################################################
inf=""
set_def
mkdir -p tmp 2>/dev/null
id=$$ # process number = unique id for tempfiles
TEMP="tmp/$id"
outputdir="."
force=0



# parse cmdline options
while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-d) DEBUG="$2"; shift  ;;
		-z) z="$2"; shift  ;;
		-o) outputdir="$2" ; shift ;;
		-f) force=1;;
		-v) echo "$PRG Ver:$VER" >&2 ;;
		-h) usage ; exit 1 ;;
		-*) usage ; exit 1 ;;
		*) break ;;  # filenames
	esac
	shift
done

mkdir -p "$outputdir" 2>/dev/null

[ $# -lt 1 ] && usage && exit 1

# for loop input files
for lazf in $@
do
	dbg "$lazf"
	[ ! -f "$lazf" ] && continue
	fname=$(getfile "$lazf")
	name=$(getbase "$fname" .laz)
	dbg "  file:$lazf fname:$fname name:$name outputdir:$outputdir"
	inf="tmp/$id.tmp.laz"
	cp -f "$lazf" "$inf"
	outf="tmp/$id.tmp"

	# if not exists result file or force = do it
	(( force > 0 )) && rm -f "$outputdir/$name.hillshade.tif" 2>/dev/null
	dbg "$name hillshade"
	if [ ! -f "$outputdir/$name.hillshade.tif" ] ; then
		dbg $AWGEO/hillshade.sh -i "$inf" -o "$outf" -z "$z" -d "$DEBUG"
		((DEBUG<2)) && $AWGEO/hillshade.sh -i "$inf" -o "$outf" -z "$z" -d "$DEBUG"
		stat=$?
		((stat>0)) && err "hillshade exit error:$stat" && exit 1
		((DEBUG<2)) && cp -f "$inf" "$outputdir/$name.hillshade.tif" 2>/dev/null
	fi

	# if not exists result file or force = do it
	dbg "$name forest"
	(( force > 0 )) && rm -f "$outputdir/$name.forest.png" 2>/dev/null	
	if [ ! -f "$outputdir/$name.forest.png" ] ; then
		dbg $AWGEO/forest.sh -i "$lazf" -o "$outputdir" -d $DEBUG 
		((DEBUG<2)) && $AWGEO/forest.sh  -i "$lazf" -o "$outputdir" -d $DEBUG 
	fi
	rm -f "tmp/$id.tmp.*" 2>/dev/null
done
status "done, $outputdir/*.hillshade.tif"

