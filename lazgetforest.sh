#!/usr/bin/env bash
# ksh or bash or ...
# lazgetforest.sh
#
# Copyright 2024 Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://github.com/kshji/awgeo
# https://awot.fi#
#
# Create green image from lidar data class 3,4,5
#
# $AWGEO/lazgetforest.sh -o outdir [ -d 0|1 ] lazfiles
# $AWGEO/lazgetforest.sh -o outdir -c 0.05 -s 0.5 [ -d 0|1 ] lazfiles

VER="2025-02-05.a"
#

PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0

################################################################
usage()
{
        cat <<EOF >&2
usage:$PRG [ -o outputdir ] [ -c subcisrcle ] [ -s step ] [ -d 0|1 ] inputlazfiles
        -o  # outputdir, default $outdir
	-c NNN # subciscle, default $SUBCIRCLE
	-s NNN # step, default $STEP
        -d  0|1 # debug, default 0
EOF
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

getdir()
{
        str="$*"
        strorg="$str"
        [ "$str" = "/" ] && str=""
        str=$(last_slash "$str")
        # dont remove - it's already dir
        [ -d "$str" ] && print -- "$str" && return
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
}

################################################################
notlast()
{
        Xstr="$1"
        Xdelim="\\$2"
        echo "${Xstr%${Xdelim}*}"
}

########################################################
do_green()
{
	Xinf="$1"
	Xoutd="$2"
	Xfname="$3"
	Xbasen="$4"
	dbg "  do_green $Xinf "
	for c in 3 4 5
	do
		case $c in
			#3) forest=low ; rgb="61 255 0" ;;
			3) forest=low ; rgb="37 153 0" ;; # dark green
			4) forest=middle; rgb="110 255 61"  ;; # green
			5) forest=high ; rgb="173 255 135" ;; # light green
		esac
	
		desf="$outdir/$Xbasen.green.$forest.png"
		rm -f "$desf" 2>/dev/null
		# use_bb = bounding box = whole area
		dbg lasgrid64 $DEMOMODE -i "$Xinf" -use_bb -keep_class $c -subcircle $SUBCIRCLE -set_RGB $rgb -rgb -step $STEP -o "$desf"
		lasgrid64 $DEMOMODE -i "$Xinf" -use_bb -keep_class $c -subcircle $SUBCIRCLE -set_RGB $rgb -rgb -step $STEP -o "$desf"
		((DEBUG>0)) && dbg $(identify -format "%w %h" "$desf" )
		rm -f "$outdir/$Xbasen.green.$forest.kml" 2>/dev/null
	done
	dbg convert "$outdir/$Xbasen.green.high.png" "$outdir/$Xbasen.green.middle.png" "$outdir/$Xbasen.green.low.png"  -background white -layers merge  "$outdir/$Xbasen.green.all.png"
	convert "$outdir/$Xbasen.green.high.png" "$outdir/$Xbasen.green.middle.png" "$outdir/$Xbasen.green.low.png"  -background white -layers merge  "$outdir/$Xbasen.green.all.png"
	dbg cp -f "$outdir/$Xbasen.green.high.pgw" "$outdir/$Xbasen.green.all.pgw"
	cp -f "$outdir/$Xbasen.green.high.pgw" "$outdir/$Xbasen.green.all.pgw"
}
	

########################################################
# MAIN

LC_NUMERIC=C
export LC_NUMERIC

outdir="out"
SUBCIRCLE=0.01 # more detail as 0.05, 0.10 or 0.5
STEP=1.5   # 0.5 small box = more white between trees
inputf=""

while [ $# -gt 0 ]
do
        arg="$1"
        case "$arg" in
                -o) outdir="$2" ; shift ;;
                -d) DEBUG="$2" ; shift ;;
                -c) SUBSIRCLE="$2" ; shift ;; 
                -s) STEP="$2" ; shift ;; 
                -*) usage ; exit 1 ;;
                *) break ;;
        esac
        shift

done

mkdir -p "$outdir"
[ ! -d "$outdir" ] && err "can't find dir:$outdir" && exit 2
[ $# -lt 1 ] && usage && exit 3

dbg "files:$@"
for inf in $@
do
        filen=$(getfile "$inf")
	dbg "files:$filen"
        basename=$(notlast "$filen" ".")
	
	[ ! -f "$inf" ] && err "no file:$inf" && exit 5
	dbg do_green "$inf $outdir  $filen $basename"
	do_green "$inf" "$outdir" "$filen" "$basename"
done

