#!/usr/bin/env bash
# ksh or bash or ...
# raw2wkt.sh
#
# Copyright 2025 Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://github.com/kshji/awgeo
# https://awot.fi
#
# Convert  Ocad polygon textfile to wkt polygon format
#
# Usage:
# cat area.raw | raw2wkt.sh > area.wkt
# raw2wkt.sh -i area.raw -o area.wkt
#
VER="2025-02-03.a"
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
usage:$PRG -i input.raw -o outname.wkt 
	or using pipes:
      cat input.raw | $PRG > outname.wkt
EOF
	
}


################################################################
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
        eval print -- "\${Xstr%${Xdelim}*}"
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
mkdir -p tmp
ID="$PID"
tmpf="tmp/$ID.tmp"

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


make_xy "$inf" > "$tmpf"
make_wkt "$tmpf" > "$result"
rm -f "$tmpf" 2>/dev/null
