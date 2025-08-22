#!/usr/local/bin/awsh
# get.area.all.sh

# run full package
#  get.area.all.sh -a 11.0 0.625 N5424R 
#  get.area.all.sh -d 1 -a 11.0 0.625 N5424R
# => sourcedata/N5424R

# input data already in dir ex. data/kanava
# run only "pullauta"
# get.area.all.sh -p 11.0 0.625 --out data/joku N5424R
# 

PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0

########################################################
usage()
{
	errmsg=""
	[ "$*" != "" ] && errmsg="err: $*"
        cat <<EOF >&2
$errmsg 
usage:$PRG [-a angle icurve ] [ -s ] [ -l ] [ -o ] [ -m ] [ -k ] [ -c ] tilename [ tilename ... ]
	tilename ex. N5432L - maastotietokannan ruudun tunnus
	-a angle icurve = get all data and pullauta
	-s = get shp file on this area - hae alueen maastotietokanta (shp)
	-l = get laz files on this area - hae alueen kaikki laz tiedostot
	-k = get cadastral index, only boundaries - kiinteistorekisteri, kiinteistorajat
	-m YEAR = get forest cutting plans - haetaan hakkuusuunnitelmat vuodesta YEAR alkaen
	-o = get ortofiles - hae alueen kaikki ortokuvat = ilmakuvat
	-c = get ortocolor - hae alueen vinovärikuvat
	-p angle icurve = do pullauta using northlineangle and intermediate curve (usually 0.625 or 1.25)
	--ca = get  canopy model tif files
	--latvusmalli = hae alueen kaikki latvusmallit (tif)
	--lp YEAR = get  logging permits on this area (shp files) after YEAR
	--hakkuuluvat VUOSI = hae alueen kaikki hakkuuluvat vuoden VUOSI jälkeiset, default $year
        -d 0|1 debug, default is 0
        --out outputdir, default is $outputdir
	ex. $PRG -a 11.0 1.25 N5432L N5432R  = get all
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
        echo "$PRG:  $*" >&2
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

##################################################
get_orto()
{
	proc="get_orto"
	Xarea="$1"
	Xdir="$2"

	lastorto="X"
	areas=""
	len=${#Xarea}
        ((len-=1))
        Xlast=${Xarea:$len:1}
	case "$Xlast" in
		L) areas="A B C D" ; lastorto=D;;
		R) areas="E F G H" ; lastorto=H;;
	esac


	dbg "$proc starting area:$Xarea"
	dbg "$proc $outputdir/$area/$masterarea$lastorto.orto.jpg"
	# if exits, not get again
	[  -f "$outputdir/$area/$masterarea$lastorto.orto.jpg" ] && return

	((DEBUG<2)) && $AWMML/get.mml.orto.sh -o "$Xdir" "$Xarea"
	# cp orto to the MML outdir
	for image in $areas
	do
		jpg="$Xdir/$Xarea/$masterarea$image.orto.jpg"
		jgw="$Xdir/$Xarea/$masterarea$image.orto.jgw"
		dbg "$proc  - cp -f $jpg $outputmmldir/$Xarea"
		mkdir -p "$outputmmldir/$Xarea"
		[ "$outputmmldir" != "" ] && [ -f "$jpg" ] && cp -f "$jpg" "$outputmmldir/$Xarea"  2>/dev/null
		[ "$outputmmldir" != "" ] && [ -f "$jgw" ] && cp -f "$jgw" "$outputmmldir/$Xarea"  2>/dev/null
	
	done

	dbg "$proc ended area:$Xarea"
}

##################################################
get_ortocolor()
{
	proc="get_orto"
	Xarea="$1"
	Xdir="$2"
	dbg "$proc starting area:$Xarea"
	#$AWMML/get.mml.ortocolor.sh -o "$Xdir" "$Xarea"
	dbg "$proc ended area:$Xarea"
}

##################################################
get_laz()
{
        proc="get_laz"
        Xarea="$1"
        Xdir="$2"

	areas=""
	lastlaz="XX"
        len=${#Xarea}
        ((len-=1))
        Xlast=${Xarea:$len:1}
        case "$Xlast" in
                L) areas="A B C D" ; lastlaz=D4;;
                R) areas="E F G H" ; lastlaz=H4 ;;
        esac


	# if exits, not get again
	[  -f "$outputdir/$area/$masterarea$lastlaz.laz" ] && return

        dbg "$proc starting area:$Xarea"
        ((DEBUG<2)) && $AWMML/get.mml.laz.sh -d "$DEBUG" -o "$Xdir" "$Xarea"
        dbg "$proc ended area:$Xarea"
}

##################################################
get_shp()
{
	proc="get_shp"
	Xarea="$1"
	Xdir="$2"
	dbg "$proc starting area:$Xarea"

	# if exits, not get again
	[  -f "$outputdir/$area/$area.v.gpkg" ] && return

	((DEBUG<2)) && $AWMML/get.mml.maastotietokanta.sh -d "$DEBUG" -o "$Xdir" "$Xarea"
	png="$Xdir/$Xarea.png"
	pgw="$Xdir/$Xarea.pgw"
	mkdir -p "$outputmmldir/$Xarea"
	[ "$outputmmldir" != "" ] && [ -f "$png" ] && cp -f "$png" "$outputmmldir/$Xarea"  2>/dev/null
	[ "$outputmmldir" != "" ] && [ -f "$pgw" ] && cp -f "$pgw" "$outputmmldir/$Xarea"  2>/dev/null
	dbg "$proc ended area:$Xarea"
}

##################################################
get_kiinteisto()
{
        proc="get_kiinteisto"
        Xarea="$1"
        Xdir="$2"
        dbg "$proc starting area:$Xarea"
	# if exits, not get again
	[  -f "$outputdir/$area/$area.kiinteistoraja.gpkg" ] && return
        ((DEBUG<2)) && $AWMML/get.mml.kiinteisto.sh -d "$DEBUG" -o "$Xdir" "$Xarea"
        dbg "$proc ended area:$Xarea"
}

##################################################
get_metsa()
{
	proc="get_metsa"
	Xarea="$1"
	Xdir="$2"
	dbg "$proc starting area:$Xarea"
	# if exits, not get again
	[  -f "$outputdir/$area/$area.metsa.gpkg" ] && return
	((DEBUG<2)) && $AWMML/get.metsa.sh -d "$DEBUG" -y "$year"-o "$Xdir" "$Xarea"
	dbg "$proc ended area:$Xarea"
}

##################################################
do_pullauta()
{
	Xarea="$1"
	Xin="$2"
	Xout="$3"

	Xin="$Xin/$Xarea"
	Xout="$Xout/$Xarea"
	#do_pullauta "$area"  "$outputdir" "$outputalldir"
	:
	#$AWGEO/pullauta.run.sh -a "$angle" -i "$icurve" -z "$z" --spikefree --hillshade --mergepng -d $DEBUG 
	dbg $AWGEO/pullauta.run.sh --all -a "$angle" -i "$icurve" -z "$z" -d $DEBUG  --in "$Xin" --out "$Xout" --id "$sesid"
	((DEBUG<2)) && $AWGEO/pullauta.run.sh --all -a "$angle" -i "$icurve" -z "$z" -d $DEBUG  --in "$Xin" --out "$Xout"
	#$AWGEO/pullauta.run.sh --all -a "11" -i "0.625" -z "3" -d 1  --in "sourcedata/P5313R" --out "pullautettu/P5313R"
}


##################################################
# MAIN
##################################################

# enable filenamegeneration
set +f
outputdir="sourcedata"
outputalldir="pullautettu"
outputmmldir="mml"
url=""
area=""
year=$(date +'%Y')
((year=year-3)) # default last 3 years

laz=0
orto=0
ortocolor=0
canopy=0
logging=0
metsa=0
kiinteisto=0
shp=0
angle="11.0"
z=3
icurve="0.625"
lazarea=""
sesid=$$

[ "$AWGEO" = "" ] && err "AWGEO env not set" && exit 1
[ "$AWMML" = "" ] && err "AWMML env not set" && exit 1

# where is your apikey.mm.txt ?
apikeyfile="apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$BINDIR/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$AWGEO/config/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && apikeyfile="$AWMML/apikey.mml.txt"
[ ! -f "$apikeyfile" ] && err "no apikeyfile: apikey.mml.txt dir: . or $BINDIR or $AWGEO/config or $AWMML" && exit 2
. $apikeyfile

echo "$PRG:start $(date '+%Y-%m-%d %H:%M:%S')"
execute=""
while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-s) shp=1; execute="get_shp" ;;  # FI:maastotietokanta shp
		-k) kiinteisto=1 ; execute="$execute get_kiinteisto" ;; # all laz on the area
		-m) metsa=1 ; year="$2"; shift; execute="$execute get_metsa" ;; # all laz on the area
		-l) laz=1 ; execute="$execute get_laz" ;; # all laz on the area
		-o) orto=1 ; execute="$execute get_orto" ;; # all orto on the area
		-c) ortocolor=1 ; execute="$execute get_ortocolor" ;; # all ortocolor on the area
		-a) angle="$2"; icurve="$3" ; shift; shift 
			execute="get_shp get_kiinteisto get_metsa get_orto get_laz"
			shp=1
			laz=1
			kiinteisto=1
			metsa=1	
			orto=1
			pullauta=1
			;; 
		-p) pullauta=1 ; angle="$2"; icurve="$3" ; shift; shift ;; # execute="$execute get_pullauta" ;; # 
		-z) z="$2"; shift ;;
		-d) DEBUG="$2" ; shift ;;
		--ca|--latvusmalli) canopy=1 ; execute="$execute get_canopymodel" ;; # canopy model = FI:latvusmalli
		--lp|--hakkuuluvat) logging=1 ; year="$2" ; shift ; execute="$execute get_loggingpermits" ;;  #  logging permits = FI:hakkuuluvat
		--in) outputdir="$2" ; shift ;;
		--outmml) outputmmldir="$2"; shift ;;
		--out) outputalldir="$2"; shift ;;
		-*) usage ; exit 3 ;;
		*) break ;;
	esac
	shift
done

echo "tiles:$*"
[ $# -lt 1 ] && usage && exit 1

errmsg="out dir have to be something else as input or output or temp or tmp"
[ "$outputdir" = "input" ] && err  "$errmsg" && exit 4
[ "$outputdir" = "output" ] && err "$errmsg"  && exit 5
[ "$outputalldir" = "input" ] && err "$errmsg"  && exit 5
[ "$outputalldir" = "output" ] && err "$errmsg"  && exit 5
[ "$outputmmldir" = "input" ] && err "$errmsg"  && exit 5
[ "$outputmmldir" = "output" ] && err "$errmsg"  && exit 5
[ "$angle" = "" ] && err "need angle" && usage"$errmsg"  && exit 2

mkdir -p "$outputdir" 2>/dev/null
mkdir -p "$outputalldir" 2>/dev/null
mkdir -p "$outputmmldir" 2>/dev/null

for area in $*
do
	dbg "execute:$execute"
	masterarea=${area:0:5}
	mkdir -p "$outputmmldir/$area"

	# run the steps
	for prg in $execute
	do
		dbg $prg "$area" "$outputdir" 
		$prg "$area" "$outputdir" 
	done

	
	# 50 Mbps download
	# => 20 min download total

	dbg "shape:$shp"
	((shp<1)) && continue
	mkdir -p "$outputdir/$area"
	dbg "$outputdir/$area/$area.shp.zip" 
	[ ! -f "$outputdir/$area/$area.shp.zip" ] && continue  # need area shp - not have to but for us it's
	# shp process
	[ -f "$outputmmldir/$area" ] && rm -f "$outputmmldir/$area" 2>/dev/null
	mkdir -p "$outputmmldir/$area"
	if [ ! -f "$outputmmldir/$area/${area}_v.dxf" ] ; then # do the dxf
		dbg  $AWGEO/mml2ocad.sh -d "$DEBUG" -a "$area" "$angle" -y "$year" -o "$outputmmldir/$area"
		((DEBUG<2)) && $AWGEO/mml2ocad.sh -d "$DEBUG" -a "$area" "$angle" -y "$year" -o "$outputmmldir/$area"
	fi

	# 3 min mml2ocad.sh

	dbg "laz:$laz"
	((laz<1)) && continue    # need laz to make pullauta
	dbg "pullauta:$pullauta"
	((pullauta<1)) && continue
	dbg "$outputdir/$area/$area.shp.zip" 
	[ ! -f "$outputdir/$area/$area.shp.zip" ] && continue  # need area shp - not have to but for us it's

	read laz1 lazstr <<<$(echo "$outputdir"/$area/${masterarea}*.laz)
	dbg "laz1:$laz1"
	[ ! -f "$laz1" ] && continue
	# - pullautetaan
	dbg "execute pullauta $area"
	dbg do_pullauta "$area"  "$outputdir" "$outputalldir"
	mkdir -p "$outputalldir/$area"

	# if done, not again - manually need to remove if need rerun
	[ ! -f "$outputalldir/$area/laser.crt" ] && do_pullauta "$area"  "$outputdir" "$outputalldir"

	# 23 +    2 h 10 min
	# little over 3 hours i7, 4 cores


done

dbg "done:$outputdir $outputalldir"
echo "$PRG:end $(date '+%Y-%m-%d %H:%M:%S')"

