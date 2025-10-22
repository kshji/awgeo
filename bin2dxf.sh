#!/bin/bash
# bin2dxf.sh [ -o outdir  ] input.bin.dxf(s)
# Convert pullautin dxf.bin to dxf format
# $AWGEO/bin2dxf.sh -o pullautettu/N5424L sourcedata/N5424/*.dxf.bin

PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0

################################################
usage()
{
	echo "usage:$PRG [ -o outdir ] inputdxf.bin [ inputdxf.bin ... ]
        -o outdir # default dxf
	" >&2
}


################################################
# MAIN
################################################

outd="dxf"

while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-o|--outputdir) odir="$2"; shift ;;
		-*) usage && exit 1 ;;
		*) break ;;
	esac
	shift
done

[ $# -lt 1 ] && usage && exit 2
mkdir -p "$outd"

for inf in $*
do
	ifile=${inf##*/}
	basename=${ifile%.bin}
	pullauta bin2dxf $inf $outd/"$basename"
done
