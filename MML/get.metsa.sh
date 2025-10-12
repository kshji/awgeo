#!/usr/local/bin/awsh
# get.metsa.sh
# metsahallitus metsankayttoilmoitukset
# $AWMML/get.metsa.sh -y "2020" -o "metsa"  "N5424L"

BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0


########################################################
usage()
{
        cat <<EOF >&2
usage:$PRG [ -o outdir ] [ -d 0|1 ] tilename [ tilename ... ]
        -o outdir # default is $outdir
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
get_metsa()
{
	xfunc="get_metsa"
	Xarea="$1"
	dbg "$xfunc: begin"
	#https://avoin.metsakeskus.fi/aineistot/Metsankayttoilmoitukset/Karttalehti/MKI_N5424A.zip
        # could be more than one, select newest (sort)
        mastertile=${Xarea:0:5}
        last=${Xarea:5:1}
	# def L
	parts="A B C D"
	[ "$last" = "R" ] && parts="E F G H"

	rm -rf "$TEMP" 2>/dev/null
        mkdir -p "$TEMP"

	for part in $parts
	do
		file="$mastertile$part"
        	url="/Metsankayttoilmoitukset/Karttalehti/MKI_$file.zip"
		outfile="$Xarea.metsa.$file.gpkg.zip"
        	dbg "mastertile:$mastertile file:$file $outfile url:$url"
        	dbg wget --no-check-certificate -O "$outdir/$outfile" "$metsaurl$url?api_key=$apikey"
        	wget --no-check-certificate -O "$TEMP/$outfile" "$metsaurl$url?api_key=$apikey"
		unzip -ojq -d "$TEMP" "$TEMP/$outfile"
        	[ ! -f "$TEMP/$outfile" ] && exit 8
		((DEBUG<1)) && rm -f "$TEMP/$outfile" 2>/dev/null

	done

	# merge 4 files to one file
	XNOW="$PWD"
	cd "$TEMP"

	# db forestusedeclaration
	#cuttingrealizationpractice	1	Ylispuiden poisto  419.002
	#cuttingrealizationpractice	2	Ensiharvennus      419.003
	#cuttingrealizationpractice	3	Harvennushakkuu    419.003
	#cuttingrealizationpractice	4	Kaistalehakkuu     419.003
	#cuttingrealizationpractice	5	Avohakkuu          419.002
	#cuttingrealizationpractice	6	Verhopuuhakkuu     419.003
	#cuttingrealizationpractice	7	Suojuspuuhakkuu    419.003
	#cuttingrealizationpractice	8	Siemenpuuhakkuu    419.002


	tablename="metsa" # rename forestusedeclaration to metsa
	destfile="$Xarea.$tablename.gpkg"
	#ogrmerge.py -skipfailures -single -nln forestusedeclaration  -o merged.gpkg M*.gpkg 2>/dev/null
	dbg ogrmerge.py -f 'GPKG' -skipfailures -single -nln "$tablename" -o $Xarea.metsa.gpkg M*.gpkg   
	ogrmerge.py -f 'GPKG' -skipfailures -single -nln "$tablename" -o $Xarea.metsa.gpkg M*.gpkg   2>/dev/null

	ogrinfo "$destfile" -sql "ALTER TABLE $tablename ADD COLUMN symbol text" 
        ogrinfo  "$destfile" -dialect SQLite -sql "
                UPDATE  $tablename
                SET symbol=cast(98000+cuttingrealizationpractice AS text)
		WHERE standarrivaldate>='$startyear-01-01'
                "
	#dbg zip "$outdir"/$Xarea.metsa.gpkg.zip $Xarea.metsa.gpkg
	#zip $Xarea.metsa.gpkg.zip $Xarea.metsa.gpkg

	cd $XNOW
	#cp -f "$TEMP"/$Xarea.metsa.gpkg.zip "$outdir" 2>/dev/null
	dbg cp -f "$TEMP"/"$destfile" "$outdir" 
	cp -f "$TEMP"/"$destfile" "$outdir" 2>/dev/null
	((DEBUG<1)) && [ -d "$TEMP" ] && rm -rf "$TEMP"
	dbg "$xfunc: end"
	
	
}


######################################################################################
# MAIN
######################################################################################
url=""
outputdir="sourcedata"
startyear=$(date +'%Y')
((startyear=startyear-3)) # default last 3 years
dounzip=1

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
                -y) startyear="$2" ; shift ;;
		-u) dounzip="$2" ; shift ;;
                -*) usage; exit 4 ;;
                *) break ;;
        esac
        shift
done

# files 1-n
[ $# -lt 1 ] && usage && exit 5

id=$$ # process number = unique id for tempfiles
TEMP="$PWD/tmp/$id"
mkdir -p "$TEMP" "$outputdir"

for metsa in $*
do
	dbg "get_metsa $metsa"
	outdir="$outputdir/$metsa"
	mkdir -p "$output" "$outdir"
	get_metsa "$metsa"
done

dbg "done:$outputdir"
#https://avoin.metsakeskus.fi/aineistot/Metsankayttoilmoitukset/Karttalehti/MKI_N5424A.zip

