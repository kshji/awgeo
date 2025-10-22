#!/usr/local/bin/awsh
# $AWMML/get.mml.laz.sh
# $AWMML/get.mml.laz.sh N5424L  # outputdir/N5424L dir include laz-files

BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0


########################################################
usage()
{
        cat <<EOF >&2
usage:$PRG [ -o outdir ] [ -d 0|1 ] tilename [ tilename ... ]
        -o outdir # default is $outputdir/mastertilename
        -d 0|1    # debug, default 0
        tilenames  # list of tiles ex. P5114A1 P5114A2
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

######################################################################################
# MAIN
######################################################################################
url=""
outputdir="sourcedata"
quit=" -q "

[ "$AWGEO" = "" ] && err "AWGEO env not set" && exit 1
[ "$AWMML" = "" ] && err "AWMML env not set" && exit 1

# where is your apikey.mm.txt ?
apikeyfile="apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$BINDIR/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$AWGEO/config/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$AWMML/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && err "no apikeyfile: apikey.mml.txt dir: . or $BINDIR or $AWGEO/config or $AWMML" && exit 2
. $apikeyfile

[ "$apikey" = "" ] && err "no apikey?" && exit 2
[ "$apihost" = "" ] && err "no apihost?" && exit 3

laser="$1"

while [ $# -gt 0 ]
do
        arg="$1"
        case "$arg" in
                -d) DEBUG="$2" ; quit=" "; shift ;;
                -o) outputdir="$2" ; shift ;;
                -*) usage; exit 4 ;;
                *) break ;;
        esac
        shift
done

# files 1-n
[ $# -lt 1 ] && usage && exit 5

mkdir -p "$outputdir"

# give every laz or give area and we get all laz from that box (L/R)
for laserm in $*
do
	len=${#laserm}
	((len=len-1)) # last
	last=${laserm:${len}:1}

	lasers=$laserm
	masterarea=${lasers:0:$len}
	case "$last" in
		L) 	lasers=""
			for la in A1 A2 A3 A4 B1 B2 B3 B4 C1 C2 C3 C4 D1 D2 D3 D4
			do
				lasers="$lasers $masterarea$la"
			done
			;;	
		R)	lasers=""
			for la in E1 E2 E3 E4 F1 F2 F3 F4 G1 G2 G3 G4 H1 H2 H3 H4
			do
				lasers="$lasers $masterarea$la"
			done
			;;
	esac

	dbg "lasers:$lasers"
	for laser in $lasers
	do 
		# could be more than only one, select newest (=sort)
		dbg grep "^$laser.laz" $AWMML/xmldata/laser.all.txt
		read name url x <<<$(grep "^$laser.laz" $AWMML/xmldata/laser.all.txt | sort  -t "/" -nrk 5,5  )
		dbg "name:$name url:$url"
	
		# main area ??? = outputdir
		len=${#laser}
		((len=len-1)) # last
		last=${laser:${len}:1}
		((len=len-1)) # 2nd last
		last2=${laser:${len}:1}
		masterarea=${laser:0:$len}
		mtk=""
		case "$last2" in 
			A|B|C|D) mtk=L ;;
			E|F|G|H) mtk=R ;;
		esac
		area="$masterarea$mtk"
		outdir="$outputdir/$area"
		mkdir -p "$outdir"
		dbg wget $quit --no-check-certificate -O "$outdir/$laser.laz" "$apihost$url?api_key=$apikey" 
		wget $quit --no-check-certificate -O "$outdir/$laser.laz" "$apihost$url?api_key=$apikey" 
		dbg "done $outdir/$laser.laz"	
	done
done

dbg "done:$outdir"

#https://tiedostopalvelu.maanmittauslaitos.fi/tp/tilauslataus/tuotteet/laser/automaattinen/2024/20240203_Swissphoto_Joensuu_kesa/Harvennettu/P5313A1.laz?api_key=$apikey
