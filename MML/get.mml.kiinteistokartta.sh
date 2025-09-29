#!/usr/local/bin/awsh
# get.mml.kiinteistokartta.sh
# Haetaan MML kiinteistokartta dataa, tuotos on Mapinfo formaatissa
# haetaan karttalehti kerrallaan
# joko 4 karttaa L/R aluekoodista tai suoraan tietty A-D tai E-H kartta

BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0


########################################################
usage()
{
        cat <<EOF >&2
usage:$PRG [ -o outdir ] [ -d 0|1 ] tilename [ tilename ... ]
        -o outdir # default is $outputdir/tilename
        -d 0|1    # debug, default 0
        tilenames  # list of tiles ex. P5114A P5114B
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


########################################################
get_map()
{
        Xarea="$1"
        # could be more than one, select newest (sort)
        mastertile=${Xarea:0:5}
        subarea=${Xarea:0:3}
        last=${Xarea:5:1}
        # def L
        parts="$last"  # only one needed, not all 4 (A-H)
        [ "$last" = "L" ] && parts="A B C D"
        [ "$last" = "R" ] && parts="E F G H"
        dbg "parts:$parts outdir:$outdir"


        for part in $parts
        do
                file="$mastertile$part"
        	dbg grep "^$file.zip" $AWMML/xmldata/kiinteistorek/kiintrek.all.txt
		# could be more than one, select newest (sort)
        	read name moddate url x <<<$(grep "^$file.zip" $AWMML/xmldata/kiinteistorek/kiintrek.all.txt | sort  -t "/" -nrk 5,5  )
        	dbg "name:$name url:$url"
        	dbg wget --no-check-certificate -O $outdir/$file.zip $apihost$url?api_key=$apikey
        	((DEBUG<2)) && wget --no-check-certificate -O "$outdir/$file.zip" "$apihost$url?api_key=$apikey"
        	[ ! -f "$outdir/$file.zip" ] && continue
		unzip -o "$outdir/$file.zip" -d "$outdir"
		rm -f "$outdir/$file.zip"
        	dbg "done $outdir/$file.zip"
        done
}



######################################################################################
# MAIN
######################################################################################
url=""
outputdir="sourcedata"

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

while [ $# -gt 0 ]
do
        arg="$1"
        case "$arg" in
                -d) DEBUG="$2" ; shift ;;
                -o) outputdir="$2" ; shift ;;
                -*) usage; exit 4 ;;
                *) break ;;
        esac
        shift
done

# files 1-n
[ $# -lt 1 ] && usage && exit 5

mkdir -p "$outputdir"

# you order one orto A,B, ....H or all 4 in area L/R
for area in $*
do
	len=${#area}
	((len=len-1)) # last
	last=${area:${len}:1}
	masterarea=${area:0:$len}
	# ei tehda sita, kaikki haluttuun kansioon
	box="$masterarea$last"
	case "$last" in
		L) box=$area ;;
		R) box=$area ;;
		A|B|C|D) box="${masterarea}L" ;;
		E|F|G|H) box="${masterarea}R" ;;
	esac
	#always to the outdir, not to the subdir
        outdir="$outputdir"
        #outdir="$outputdir/$box"
        mkdir -p "$outdir"
        dbg "get_map $area to dir $outdir"
        get_map "$area"
done

dbg "done:$outdir"

#https://tiedostopalvelu.maanmittauslaitos.fi/tp/tilauslataus/tuotteet/orto/ortokuvat?api_key=$apikey

