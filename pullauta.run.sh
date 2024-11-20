#!/usr/bin/env bash
# pullauta.run.sh
VER=2024-11-14a
#
# Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://awot.fi
# pullauttelija@awot.fi
#
# pullauta.run.sh -a 11 -i 0.625 -s -z 3
# - northlineangle 11, intermediate curve 0.625, hillshade using z=3
#
# pullauta.run.sh -a 11 -i 0.625 -s -z 3 --spikefree
# - northlineangle 11, intermediate curve 0.625, hillshade using z=3
# - also make spike free (sf.png) - generating spike free digital surface model
#
# pullauta.run.sh --onlyhillshade  -s  -z 3
# - run only hillshade after basic run - use temp files
#
# pullauta.run.sh --onlyintermediate -i 0.625
# - run only intermediate curves (0.625 m) after basic run - use temp files
#
#
# config.pullauta.ini have to be:
# batch=1
# batchoutfolder=./output
# lazfolder=./input
#
# - input dir include *laz and MML (maastotietokanta) zip
# - result dir output
# mkdir -p input output # before 1st run
#
PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

#shopt -s nocaseglob

# set defaults
angle=0
DEBUG=0
configfile=$AWGEO/config/pullauta.ini
[ -f config/pullauta.ini ] && configfile=config/pullauta.ini
intermediate_curve=""
only_intermediate_curve=0
only_hillshade=0
hillshade=0
z=3
spikefree=0

outputdir="output"
inputdir="input"


########################################################
usage()
{
        cat <<EOF >&2
usage:$PRG [ -a NUM ] [ -d 0|1 ]
        -a NUM, northline  angle, default = 0 = no lines
        -d 0|1 debug, default is 0
	-i 1.25 | 0.625 | 0.3125  = intermediate curve for map makers

 	The map can also have what is called an intermediate curve between the curve with smoothjoin.
	Usable for mapmakers and manual process to fix map

	Pullautin from github: https://github.com/rphlo/karttapullautin
	
EOF

}

########################################################
step()
{
        dbg "-step:$*" >&2
}

########################################################
status()
{
        echo "-status:$*" >&2
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
parse_file()
{
 	[ "$*" = "" ] && return
 	[ ! -f "$1" ] && return
 	eval echo  "\"$(cat $1 | sed 's+\"+\\"+g'   )\""
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

################################################################
clean_temp()
{

	i=1
	# if we have already data and like to make intermediate curve, then no clean
	(( only_intermediate_curve > 0 )) && return
	rm -rf temp* 2>/dev/null
	rm -r $outputdir/* 2>/dev/null
	rm -f *.tif header*.xyz laz*.txt pullautus_depr*.* pullautus?.png temp*.xyz ziplist*.txt list*.txt 2>/dev/null
}

################################################################
process_spike_free()
{
	# https://rapidlasso.de/generating-spike-free-digital-surface-models-from-lidar/
	# output AREALABEL.sf.png - generating spike free digital surface model 
	xfunc="process_spike_free"
	dbg "$xfunc: start"
	for laz in $inputdir/*.laz
	do
		[ ! -f "$laz" ] && continue
		fname=$(getfile "$laz")
		Xname=$(getbase "$fname" ".laz")
		las2dem64 -i "$laz" -spike_free 0.9  -step 0.5  -hillshade  -o "$outputdir/$Xname.sf.png" 2>/dev/null
		# -step 0.25 not needed ...
	done
	dbg "$xfunc: end"

}


################################################################
process_hillshade()
{

	xfunc="process_intermediate_curves"
	dbg "$xfunc: start"
	for laz in $inputdir/*.laz
	do
		[ ! -f "$laz" ] && continue
		fname=$(getfile "$laz")
		Xname=$(getbase "$fname" ".laz")
		dbg "$xfunc: $laz $fname $name"
		dbg "   $AWGEO/hillshade.sh -i $laz -z $z -o $Xname -d $DEBUG "
		$AWGEO/hillshade.sh -i "$laz" -z $z -o "$Xname" -d $DEBUG
		rm -f "$Xname.ground.laz" 2>/dev/null
		cp -f "$Xname.tif" "$outputdir/$Xname.hillshade.tif" 2>/dev/null
	done
	dbg "$xfunc: end"
}

################################################################
make_curve()
{
	Xi=$1 
	Xicurve=$2

	rm -rf temp 2>/dev/null
	mkdir -p temp
	cp -f temp$Xi/*.xyz temp
	pullauta xyz2contours $Xicurve xyz2.xyz null out.dxf
	pullauta smoothjoin
	cp -f temp/out2.dxf temp$Xi/countours$Xicurve.dxf
}

################################################################
process_intermediate_curves()
{
	# pullautin make basecurves but not run smootjoin for those curves
	Zcurve="$1"
	xfunc="process_intermediate_curves"

	# test value, have to be some of next
	case "$Zcurve" in
		1.25) ;;
		0.625) ;;
		0.3125) ;;
		*) Zcurve="" ;; # not ok
	esac
	[ "$Zcurve" = "" ] && return

	cnt=0
	set +f
	set +o noglob
	#echo  $outputdir/*.laz.png  | while read area
	for area in $outputdir/*.laz.png 
	do
		[ "$area" = "" ] && continue
		[ "$area" = "$outputdir/*.laz.png" ] && continue # no files
		((cnt+=1))
		fname=$(getfile "$area" )
		name=$(getbase "$fname" ".laz.png")
		dbg "$xfunc: fname:$fname name:$name"
		
		make_curve $cnt $Zcurve
		destfile=$outputdir/${name}.laz_contours_$Zcurve.dxf
		cp -f temp$cnt/countours$Zcurve.dxf "$destfile" 
		status "$xfunc done $destfile"
	done 
	dbg "$xfunc done"
	((cnt < 1 )) && return

	
}

################################################################

################################################################
# MAIN
################################################################
# parse cmdline options

step=0

if [ "AWGEO" = "" ] ; then
	# set AWGEO
	awgeoinifile="awgeo.ini"
	[ -f "$awgeoinifile" ] && awgeoinifile="config/awgeo.ini"
	[ -f "$awgeoinifile" ] && awgeoinifile="$AWGEO/config/awgeo.ini"
	[ -f "$awgeoinifile" ] && err "no awgeo.ini file dir: . or ./config or $AWGEO/config" >&2 && exit 2
	. "$awgeoinifile"
fi
export AWGEO
[ "$AWGEO" = "" ] && err "AWGEO env not set" && exit 1

while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-a|--angle) angle="$2" ; shift ;;
		-i|--curve) intermediate_curve="$2" ; shift ;;
		--onlyintermediate ) only_intermediate_curve=1 ; ((step+=1));;
		-d|--debug) DEBUG="$2" ; shift ;;
		--onlyhillshade ) only_hillshade=1 ;  hillshade=1 ; ((step+=1));;
		-s|--hillshade) hillshade=1 ;;
		--spikefree) spikefree=1 ;;
		-z) z="$2" ; shift ;;
		-c|--config) configfile="$2" ; shift ;;
		-h) usage ;;
		-*) usage ;;
	esac
	shift
done

dbg "clean_temp"
clean_temp
mkdir -p tmp input output 2>/dev/null
id=$$ # process number = unique id for tempfiles
TEMP="tmp/$id"


(( step < 1 )) && dbg "parse_file $configfile"
(( step < 1 )) && parse_file "$configfile"  > pullauta.ini

# 1st make pullauta, if not already done
(( step < 1 )) && dbg "pullauta"
(( step < 1 )) && pullauta



# The map can also have what is called an intermediate curve between the curve 
[ "$intermediate_curve" != "" ] && process_intermediate_curves "$intermediate_curve"

(( hillshade>0 )) && process_hillshade 

(( spikefree > 0 )) && process_spike_free

((DEBUG<1)) && rm -f $TEMP.??* 2>/dev/null

status "$(date) done"




