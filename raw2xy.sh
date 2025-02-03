#!/usr/bin/env bash
# ksh or bash or ...
# raw2xy.sh
#
# Copyright 2024 Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://github.com/kshji/awgeo
# https://awot.fi
#
# Convert  Oacd polygon textfile to polyline x y coordinates 
#
# Usage:
# cat area.raw | raw2xy.sh > area.txt
# raw2xy.sh -i area.raw -o area.txt
#
VER="2024-11-06.a"
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
usage:$PRG -i input.raw -o outname.txt 
	or using pipes:
      cat input.raw | $PRG > outname.txt
EOF
	
}


########################################################
make_xy()
{
	Zin="$1"
	sed 's/,/./g' "$Zin" | awk '
        { cnt++ }
        NR == 1  { next }
        NR == 2  {
                        x=$2
                        y=$3
                        }

        NR > 2 {
                print prevx,prevy
                prevx=$2
                prevy=$3
                }
        {
                        prevx=$2
                        prevy=$3
        }
END {
        print x,y
}'
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

make_xy "$inf" > "$result"

