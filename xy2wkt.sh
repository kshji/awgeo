#!/usr/bin/env bash
# ksh or bash or ...
# xy2wkt.sh
#
# Copyright 2024 Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://github.com/kshji/awgeo
# https://awot.fi
#
# Convert  polyline x y coordinates textfile to the wkt polygon format
#
# Usage:
# cat area.txt | xy2wkt.sh > area.wkt
# xy2wkt.sh -i area.txt -o area.wkt
#
VER="2024-11-05.a"
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
usage:$PRG -i input.txt -o outname.wkt 
	or using pipes:
      cat input.txt | $PRG > outname.wkt
EOF
	
}


########################################################
make_wkt()
{
	Zin="$1"
	echo -n "POLYGON (("
	delim=""
	while read x y 
	do
		echo -n "$delim$x  $y"
		delim=","
	done < $Zin
	echo "))"
}

########################################################
# MAIN
########################################################
# default is pipe
inf="/dev/stdin"
result="/dev/stdout"

# parse cmdline options
while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-i) inf="$2"; shift  ;;
		-o) result="$2"; shift  ;;
		-v) echo "$PRG Ver:$VER" >&2 ;;
		-h) usage ; exit 1 ;;
		-*) usage ; exit 1 ;;
	esac
	shift
done

make_wkt "$inf" > "$result"

