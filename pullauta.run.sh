#!/usr/bin/env bash
# pullauta.run.sh
VER=2025-10-22a
#
# Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://github.com/kshji/awgeo
# https://awot.fi
# pullauttelija@awot.fi
#
# This script use new pullautin
# https://github.com/rphlo/karttapullautin
#
#
# default inputdatadir = sourcedata
# default outputdatadir = pullautettu
#
# Basic pullauta using:
# pullauta.run.sh -a 11 -i 0.625 -z 3
# - northlineangle 11, intermediate curve 0.625
#
# $AWGEO/pullauta.run.sh --in sourcedata/N5424L --out pullautettu/N5424L -a 11 -i 0.625 -z 3
#    also dem, spikefree, hillshade, ...:
# $AWGEO/pullauta.run.sh all --in sourcedata/N5424L --out pullautettu/N5424L -a 11 -i 0.625 -z 3
#
# debug:
# $AWGEO/pullauta.run.sh --in src/piha --out tulos/piha -a 10.6 -i 1.25 -z 3 -d 1
#
# Full AwGeo set:
# $AWGEO/pullauta.run.sh -a 11 -i 0.625 --hillshade -z 3 --spikefree 
#
# or use option --all to process all features
#
# $AWGEO/pullauta.run.sh --all -a 11 -i 1.25 --in inputdatadir --out outputdatadir
# - northlineangle 11, intermediate curve 0.625, hillshade using z=3
# - also make spike free (sf.png) - generating spike free digital surface model
# $AWGEO/pullauta.run.sh --all -a 11 -i 1.25
#
# $AWGEO/pullauta.run.sh --onlyhillshade  -s  -z 3
# - run only hillshade after basic run - use temp files
#
# $AWGEO/pullauta.run.sh --onlyintermediate -i 0.625
# - run only intermediate curves (0.625 m) after basic run - use temp files
#
#  $AWGEO/pullauta.run.sh -p
#  - copy only pullauta.ini to the this directory
#
# config.pullauta.ini have to be:
# batch=1
# batchoutfolder=./output
# lazfolder=./input
#
# - sourcedata dir include *laz and MML (maastotietokanta) zip
# - result dir pullautettu
# mkdir -p sourcedata pullautettu # before 1st run
#
############################
# Before pullauta
# Need to get MML shp and lidardata
#
# Get MML data and make Ocadfiles
# $AWMMLDEV/mml2ocad.sh -y 2022 -a 5432L
#
#
#
#
############################

PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

#shopt -s nocaseglob

# set defaults
angle=0
DEBUG=0
configfile=$AWGEO/config/pullauta.template.ini
[ -f config/pullauta.template.ini ] && configfile=config/pullauta.ini
intermediate_curve="0"  # new version, def is 0 in the config
only_intermediate_curve=0
only_hillshade=0
hillshade=0
z=3
spikefree=0
mergepng=0

outputdir="output"
inputdir="input"


########################################################
usage()
{
        cat <<EOF >&2
usage:$PRG [ -a NUM ] [ -d 0|1 ]
	--in sourcedata dir, default sourcedata
	--out result dir, default pullautettu
        -a NUM, northline  angle, default = 0 = no lines
	-all , process all features hillshade, spikefree,  intermediate curve 0.625, ...
	-i 1.25 | 0.625 | 0.3125  = intermediate curve for map makers, default 0.625
	--hillshade , make hillshade
	--spikefree , make hillshade
	-c configfile, default $configfile
	-z NUM, default 3
	--onlycountours, only countours from the laz
        --onlyvege, only vege pullauta from laz
        --greenlevel NUM, default $greenshade, 0.10-0.15 is good, 0.10 less green, 0.15 more green
        -d 0|1 debug, default is 0

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
msg()
{
        echo "$*" >&2
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
	##(( only_intermediate_curve > 0 )) && return
	## previous not usable anymore
	rm -rf temp* 2>/dev/null
	rm -r $outputdir/* 2>/dev/null
	rm -f merged*.* *.tif header*.xyz laz*.txt pullautus_depr*.* pullautus?.png temp*.xyz temp*.xyz.bin ziplist*.txt list*.txt 2>/dev/null 
}


################################################################
# conver aux.ml to worldfile
# some.png.aux.xml
#<PAMDataset>
  #<GeoTransform>  6.2000000000000000e+05,  4.2333333333333334e-01,  0.0000000000000000e+00,  6.9659999900000002e+06,  0.0000000000000000e+00, -4.2333333333333334e-01</GeoTransform>
#</PAMDataset>
#1. => 5
#2. => 1
#3. => 2.
#4. => 6
#5. => 3
#6. => 4
#
#some.pgw
#0.4233333333
#0.0000000000
#0.0000000000
#-0.4233333333
#620000.2116666667
#6965999.7783333333

################################################################
merge_png()
{

	xin="$1" 
	#gdal_merge.py -o P5313L.tif P5313??.laz_depr.png
	# convert GeoTiff to basic tif with worldfile
	#gdal_translate -co  PROFILE=BASELINE -co "TFW=YES" -of PNG  P5313L.tif  P5313L.basic.tif
  	# convert geoTiff to PNG and create worldfile
	# gdal_translate -co WORLDFILE=YES -of PNG  P5313L.tif  P5313L.png
	# make one big png
	xfunc="merge_png"
	dbg "$xfunc: start"
	xnow=$PWD
	mergename=""

	# mergename = shpnames ...
	cd "$inputdir"	
	for img in *.shp.zip
	do
		[ "$img" = "*.shp.zip" ] && continue
		label=$(getbase "$img" ".shp.zip")
		mergename="$mergename$label"
	done
	cd $xnow

	# if not shp's then use laz_depr.png names
	if [ "$mergename" = "" ] ; then # there wasn't any shp.zip, then use laz
		cd "$xin"
		for img in *.laz_depr.png
		do
			[ "$img" = "*.laz_depr.png" ] && continue
			label=$(getbase "$img" ".laz_depr.png")
			mergename="$mergename$label"
		done
		cd $xnow
	fi

	[ "$mergename" = "" ] && return # no input files in this directory?	

	cd "$xin"
	gdal_merge.py -o fullarea.depr.tif *.laz_depr.png
	gdal_translate -co WORLDFILE=YES -of PNG  fullarea.depr.tif  $mergename.depr.png
	rm -f fullarea.depr.tif fullarea*aux.xml 2>/dev/null
	mv $mergename.depr.wld $mergename.depr.pgw

	#ex. Windows, Ocad, ... cannot handle 16xlaz size png's
	#16xlaz = >2GT tif, PNG about 60 MB
	cd $xnow
	dbg "$xfunc: done: $mergename.depr.png"
	dbg "$xfunc: ended"
}


################################################################
make_forest_images()
{
	xfunc="make_forest_images"
	dbg "$xfunc: start"
	Zinf="$1"
	Zoutd="$2"
	Zfname="$3"
	Zlabel="$4"

	# ground
        dbg lasground64 -i "$Zinf" -wilderness -ultra_fine -o $TEMP.ground.laz
        lasground64 -i "$Zinf" -wilderness -ultra_fine -o $TEMP.ground.laz
	# normalize
        dbg lasheight64 -i $TEMP.ground.laz  -replace_z -o $TEMP.normalized.laz
        lasheight64 -i $TEMP.ground.laz  -replace_z -o $TEMP.normalized.laz
        #
        #dbg las2dem64 -i $TEMP.normalized.laz -spike_free 0.9 -step 0.5 -o $TEMP.normalized.tif
        #las2dem64 -i $TEMP.normalized.laz -spike_free 0.9 -step 0.5 -o $TEMP.normalized.tif
        dbg las2dem64 -i $TEMP.normalized.laz -first_only -step 0.5 -o $TEMP.fo.tif
        las2dem64 -i $TEMP.normalized.laz  -first_only -step 0.5 -o $TEMP.fo.tif
        dbg gdaldem color-relief -co WORLDFILE=YES $TEMP.fo.tif "$AWGEO/config/rgb.rainbow.txt"  "$Zoutd/$Zlabel.color.fo.png"
        gdaldem color-relief -co WORLDFILE=YES $TEMP.fo.tif "$AWGEO/config/rgb.rainbow.txt"  "$Zoutd/$Zlabel.color.fo.png" 
        cp -f "$Zoutd/$Zlabel.color.fo.wld" "$Zoutd/$Zlabel.color.fo.pgw"
        rm -f "$Zoutd"/"$Zlabel".*.xml 2>/dev/null

	$AWGEO/lazgetforest.sh -d $DEBUG -s "1.5" -c "0.01" -o "$Zoutd" "$Zinf"

	dbg "$xfunc: end"
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
		dbg las2dem64 -i "$laz" -spike_free 0.9  -step 0.5  -hillshade  -o "$outputdir/$Xname.sf.png" 
		las2dem64 -i "$laz" -spike_free 0.9  -step 0.5  -hillshade  -o "$outputdir/$Xname.sf.png" 2>/dev/null
		[ -f "$AWGEO/config/rgb.rainbow.txt" ] && make_forest_images "$laz" "$outputdir" "$fname" "$Xname" 
		# -step 0.25 not needed ...
	done
	dbg "$xfunc: end"

}


################################################################
process_hillshade()
{

	xfunc="process_hillshade"
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
		mv -f "$Xname.tif" "$outputdir/$Xname.hillshade.tif" 2>/dev/null
	done
	dbg "$xfunc: end"
}

################################################################
make_vege()
{
	Xi=$1 

	# make only one laz!!!
	rm -rf temp 2>/dev/null
	mkdir -p temp
	# new pullautin do xyz.bin, not xyz
	for xyz in temp$Xi/*.xyz.bin
	do
		xyzfile=${xyz##*/}
        	xyzbasename=${xyzfile%.bin}
		pullauta internal2xyz "$xyz" $temp/$xyzbasename.xyz
	done	
	# old pullautin, new next line do nothing
	cp -f temp$Xi/*.xyz temp 2>/dev/null
	pullauta makevege
	mv -f temp/vegetation.png temp$Xi/vegetation.png
	mv -f temp/vegetation.pgw temp$Xi/vegetation.pgw
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
	mv -f temp/out2.dxf temp$Xi/countours$Xicurve.dxf
}

################################################################
process_rerun_vege()
{
        # pullauta can't handle batch mode to re-run vege
        xfunc="process_rerun_vege"

        cnt=0
        set +f
        set +o noglob
        for area in $outputdir/*.laz_vege.png
        do
                [ "$area" = "" ] && continue
                [ "$area" = "$outputdir/*.laz_vege.png" ] && continue # no files
                ((cnt+=1))
                fname=$(getfile "$area" )
                name=$(getbase "$fname" ".laz_vege.png")
                dbg "$xfunc: fname:$fname name:$name"

                make_vege $cnt 
                destfile=$outputdir/${name}.laz_vege
                cp -f temp$cnt/vegetation.png "$destfile.png"
                cp -f temp$cnt/vegetation.pgw "$destfile.pgw"
                status "$xfunc done $destfile.p??"
        done
        dbg "$xfunc done"
        ((cnt < 1 )) && return


}


################################################################
process_intermediate_curves()
{
	return
	# not anymore, base pullautin process do it

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
process_shp()
{

	xfunc="pullauta_this_set"
	dbg "$xfunc: start"
	for shp in "$indir"/*.shp.zip
	do
		[ "$shp" = "$indir/*.shp.zip" ] && continue 
		xfile=$(getfile "$shp")
		label=$(getbase "$xfile" ".shp.zip")
		dbg $AWGEO/get.mmlshp2ocad.sh -a $label -i "$indir" -o "$outdir"/shp
		$AWGEO/get.mmlshp2ocad.sh -a $label -i "$indir" -o "$outdir"/shp
	done
	dbg "$xfunc: end"
}

################################################################
press_enter()
{
	echo -n "Enter:"
	read Enter
}

################################################################
pullauta_this_set()
{
	 # make pullauta
	 xfunc="pullauta_this_set"
	 Xtilename="$1"
	 dbg "$xfunc: start tilename:$Xtilename outdir:$outdir outputdir:$outputdir"
	 # ex. outdir: tulos/piha  outputdir usually:output

	

         # clean previous output
         #rm -rf "$outputdir" pullautus*.png pullautus*.pgw temp/* temp?/* 2>/dev/null
         rm -rf pullautus*.png pullautus*.pgw temp/* temp?/* 2>/dev/null
	 rm -f *.xyz *.xyz.bin 2>/dev/null
	 ((DEBUG>1)) && ls "$outputdir" && press_enter
         mkdir -p "$outputdir"
	 
	 #((DEBUG>0)) && ls "$inputdir" && echo -n "Continue:" && read continue || echo -n "Continue:" && read continue
	
	 # pullauta process threated, temp[1-n] subdir and result locate is $outputdir = merged in this set
	 # need to copy to the my result file
         pullauta

         # do add on
         # The map can also have what is called an intermediate curve between the curve
	 # not anymore in the new pullautin, vbase process include it in the config file
	 # basemapinterval=0 or 1.25 or 0.625 or ....
         ###[ "$intermediate_curve" != "" ] && process_intermediate_curves "$intermediate_curve"

         (( hillshade>0 )) && process_hillshade

         (( spikefree > 0 )) && process_spike_free

         (( mergepng > 0 )) && merge_png "$outputdir"

         # mv pullauta results to the user outdir
	 dbg "   " rm -f "$outputdir"/"*basemap.*"   # not needed
	 rm -f "$outputdir"/*basemap.*   # not needed
	 mkdir -p "$outputdir"/.save
	 # not merge this
	 mv -f "$outputdir"/*contours03*.dxf* "$outputdir"/.save 2>/dev/null
	 # rest files merge
	 ((DEBUG>1)) && press_enter
	 pullauta dxfmerge
	 # currentdir include lot of merged file, but merged.dxf include all
	 msg "DXF merge tehty : $outputdir"
	 cp merged.dxf $outputdir/"$Xtilename.all.dxf"
	 # return back to dir after merge
	 mv -f "$outputdir"/.save/*.dxf "$outputdir" 2>/dev/null
	 rm -rf "$outputdir"/.save 2>/dev/null
	 ((DEBUG>1)) && ls -1 $outputdir
	 msg "________________________________________________"
         mv -f "$outputdir"/*.* "$outdir" 2>/dev/null
	 
	 # some datafiles to subdir - all dxf except all.dxf
	 mkdir -p "$outdir/addon" 
	 mv -f "$outdir"/*_undergrowth.dxf "$outdir/addon" 2>/dev/null
	 mv -f "$outdir"/*_dotknolls.dxf "$outdir/addon" 2>/dev/null
	 mv -f "$outdir"/*_contours.dxf "$outdir/addon" 2>/dev/null
	 mv -f "$outdir"/*_contours_0*.dxf "$outdir/addon" 2>/dev/null
	 mv -f "$outdir"/*_contours_1*.dxf "$outdir/addon" 2>/dev/null
	 mv -f "$outdir"/*_contours03*.dxf "$outdir/addon" 2>/dev/null
	 mv -f "$outdir"/*.bin "$outdir/addon" 2>/dev/null

         # make clean to the next process block input
	 # output not removed, posible to run pullauta again ex. change vege
         rm -rf "$inputdir" 2>/dev/null
	 status "pullauta_this_set done"
         mkdir -p "$inputdir" 
	 dbg "$xfunc: end"
}

################################################################
get_pullauta()
{
        # angle
        # icurve
        [ "$angle" = "" ] && angle=11
        [ "$icurve" = "" ] && icurve=0.625
	xfunc="pullauta"
        dbg "$xfunc starting angle:$angle icurve:$icurve"

        # need to read pullauta.ini max. process
        pullautaini="$configfile"
        [ ! -f "$pullautaini" ] && err "Can't read $pullautaini" && return 1

        prosnum=$(grep "^processes.*=.*" "$pullautaini" 2>/dev/null)
        batch=$(grep "^batch.*=.*1" "$pullautaini" 2>/dev/null)

        [ "$batch" = "" ] && err "$pullautaini have to be batch=1" && exit 1

        prosnum=${prosnum// /}   # remove spaces
        [ "$prosnum" = "" ] && prosnum=1  # single


	read lazfiles <<<$(echo $indir/*.laz)
	[ "$lazfiles" = "$indir/*.laz" ] && err "no laz files in dir: $inputdir" && exit 6
        dbg "$proc  lazfiles:$lazfiles"
	

        dbg "result dir:$outdir concurrent process:$prosnum"
        rm -rf "$inputdir" "$outputdir"  2>/dev/null
        mkdir -p "$inputdir" "$outputdir" "$outdir"

	# copy source data to the pullautin input dir
	# cp if exists ...
        cp -f "$indir"/*.shp.zip "$inputdir" 2>/dev/null

	# process all laz files using prosnum block size!! = concurrent process/tasks
	tilename=""
	subdir=$(last_slash "$outdir")
	[ "$subdir" = "." -o "$subdir" = "" ] && subdir="all"
	tilename=${subdir##*/}
	dbg " - tilename: $tilename"

        count=0
        for Xa in $lazfiles
        do
		lazfile=$(getfile "$Xa")
		lazbase=$(getbase "$lazfile" ".laz")
		#((count==0)) && tilename="$lazbase"
		#dbg "   $Xa $count $tilename"
		
                # build input
                if ((count < prosnum )) ; then
                        dbg "$proc   $PWD"
                        cp -f $Xa "$inputdir"
                        ((count+=1))
                fi
                if ((count >= prosnum )) ; then # max. files -> process
                        count=0
			#tilename="$lazbase"
         		rm -rf "$outputdir" 2>/dev/null
         		mkdir -p "$outputdir" "$outputdir"
			dbg "Next pullauta set, dir:$PWD"
			pullauta_this_set  "$tilename"
         		rm -rf "$inputdir" 2>/dev/null
         		mkdir -p "$inputdir" "$outputdir"
        		cp -f "$indir"/*.shp.zip "$inputdir"
                fi
        done

	# pullauta last set if not yet done
	(( count>0 && DEBUG>0 )) && dbg "Next pullauta, dir:$PWD $tilename:$tilename"
	(( count>0 )) && pullauta_this_set "$tilename"

	# some files to use data in the Ocad
	cp -f $AWGEO/config/*.crt "$outdir" 2>/dev/null
	cp -f $AWGEO/config/*.ocd "$outdir" 2>/dev/null

	dbg "$xfunc: end"
}

################################################################
# MAIN
################################################################
# parse cmdline options


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

outdir="pullautettu"
indir="sourcedata"
vegererun=0
year=2022
sesid=$$
# pullauta.ini template variables
contoursonly=0
vegeonly=0
greenshade=0.12  # 0.10 - 0.15 , 0.10 less green, 0.15 more green
parse_config_only=0


while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-a|--angle) angle="$2" ; shift ;;
		--all) intermediate_curve=0.625
			hillshade=1
			spikefree=1
			#mergepng=1	
			;;
		-i|--curve) intermediate_curve="$2" ; shift ;;
		#--onlyintermediate ) only_intermediate_curve=1 ; ((step+=1));;
		-d|--debug) DEBUG="$2" ; shift ;;
		#--onlyhillshade ) only_hillshade=1 ;  hillshade=1 ; ((step+=1));;
		--onlycountours) contoursonly=1 ;;
		--onlyvege) vegeonly=1 ;;
		--greenlevel) greenshade=$2 ; shift ;;
		--vegererun ) vegererun=1 ;;
		-s|--hillshade) hillshade=1 ;;
		--spikefree) spikefree=1 ;;
		-m|--mergepng) mergepng=1 ;;
		-z) z="$2" ; shift ;;
		-c|--config) configfile="$2" ; shift ;;
		-p|--parseconfig) parse_config_only=1  ;;
		--in) indir="$2"; shift ;;
		--out) outdir="$2"; shift ;;
		--id) sesid="$2" ; shift ;;
		-h) usage ; exit 1 ;;
		-*) usage ; exit 1 ;;
	esac
	shift
done

errmsg="out dir have to be something else as input or output or temp or tmp"
[ "$outdir" = "input" ] && err "out dir have to be something else as input or output or temp or tmp" && exit 4
[ "$outdir" = "output" ] && err "out dir have to be something else as input or output or temp or tmp" && exit 4
[ "$outdir" = "temp" ] && err "out dir have to be something else as input or output or temp or tmp" && exit 4
[ "$outdir" = "tmp" ] && err "out dir have to be something else as input or output or temp or tmp" && exit 4
[ "$indir" = "input" ] && err "out dir have to be something else as input or output or temp or tmp" && exit 5
[ "$indir" = "output" ] && err "out dir have to be something else as input or output or temp or tmp" && exit 5
[ "$indir" = "temp" ] && err "out dir have to be something else as input or output or temp or tmp" && exit 5
[ "$indir" = "tmp" ] && err "out dir have to be something else as input or output or temp or tmp" && exit 5
mkdir -p "$outdir"
[ ! -d "$outdir" ] && err "can't make dir $outdir" && exit 6

# special: re-run vege - don't clean temp and copy ini template
(( vegererun>0 )) && process_rerun_vege 
(( vegererun>0 )) && exit

# pullauta process ...
# 
dbg "clean_temp"
clean_temp
mkdir -p tmp input output 2>/dev/null
id=$$ # process number = unique id for tempfiles
TEMP="tmp/$id"


dbg "parse_file $configfile"
parse_file "$configfile"  > pullauta.ini

(( parse_config_only > 0 )) && dbg "only parse config: pullauta.ini" && exit 0

dbg "pullauta"
get_pullauta
dbg "shp"

