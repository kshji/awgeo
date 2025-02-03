#!/usr/local/bin/awsh
###/usr/bin/env ksh
# ksh or bash or ...
# gpkg2ocad.sh
#
# Copyright 2025 Karjalan ATK-Awot Oy
# Jukka Inkeri
# https://github.com/kshji/awgeo
# https://awot.fi
#
# Convert GeoPackage to Ocad files (DXF)
#
# gpkg2ocad.sh -a P5313L   
# - input from sourcedata/P5313L*
# - output mml/P5313L
# gpkg2ocad.sh -a P5313L    -i sourcedata/5313L -o mml/5313L
#
# $AWGEO/gpkg2ocad.sh -a N5424L -i sourcedata -o mml/N5424L -d 1 -s
#

PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0

#######################################
dbg()
{
        ((DEBUG<1)) && return
        echo "$PRG dbg: $*" 
}

#########################################
usage()
{
 echo "
        usage:$0 -a arealabel -i inputdir [ -o outputdir ] [ -d 0|1 ]
        inputdir directory include init_shp.sh results
        -s save data to the "destdir" ($outputdir)
        -o destdir , default is "$outputdir"
	-i inputdir, include init_shp.sh result files
	-c crtfile, default is $crtfile
        -d 0|1 , debug, def 0
        " >&2
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


#######################################
make_symbol_value()
{
  inf="$1"
  symid="$2"
  taf="tmp/$$.awk.tmp"
  mkdir -p tmp

  #cp $inf $inf.save
  dbg "$inf $symid"
  awk -v sym="$symid"  '
        /^LWPOLYLINE/ { cnt=1 ; print; next }
        /^POINT/  { cnt=1 ; print ; next }
        /^HATCH/  { cnt=1 ; print ; next }
        /^MTEXT/  { cnt=1 ; print ; next }
        cnt==1 { cnt++; print ; next }
        cnt==2 { cnt++; print ; next }
        cnt==3 && $1 == 100 { cnt++; print "  8"; next }
        cnt==3 && $1 != 100 { cnt++; print ; next }
        cnt==4 { cnt++; print sym; next }
        cnt==5 && $1 == 8 { cnt++; print "100"; cnt=0; next }
        cnt==5 && $1 != 8 { cnt++; print ; cnt=0; next }
        # uudessa versiossa 6 rivia ...
        # vanhassa oli 8 symboli 100 ja se kelpasi ocad
        # uudessa 100 symboli 8 ja se ei kelpaa ocad ...
        # siksi kaannetaan
        { print }
        ' $inf > $taf
        cat $taf > $inf
   #cp $taf $inf.save.awk
        rm -f $taf 2>/dev/null
}

#######################################
make_symbol_dxf()
#make_symbol_dxf "$area" "$inf"
#make_symbol_dxf "$area" "$table" "$inf"
#make_symbol_dxf N5432L kiinteistoraja N5432L.kiinteistoraja.gpkg
{
  Xarea="$1"
  Xtable="$2"
  Xdb="$3"
  Xinf="merge_$table"
  [ ! -f "$inputdir/$Xinf.csv" ] && echo "no $inputdir/$Xinf.csv" >&2 && exit 3

  dbg "process make_symbol_dxf $Xarea $Xtable $Xinf "


  rm -rf "$inputdir"/merged_$Xtable.shp 2>/dev/null

  while read Xsym str
  do
        ((line+=1))
        ((line == 1)) && continue
        # lainausmerkit ymparilta pois
        Xsym=${Xsym//\"}

	[ "$Xsym" = "0" ] && continue
	[ "$Xsym" = "symbol" ] && continue
	[ "$Xsym" = "symbol," ] && continue
        dbg "Do: $Xinf $Xsym"

	# - voisi olla tarkistus, etta jos ei on konversio crt:ssa niin vain silloin tehdaan dxf - nopeutuu hieman
	# siis tyyliin about:
        #grep " $Xsym " "joku.crt"  2>/dev/null  | read osym shpsym xxsym 
        # - if not Ocad sym then next
        #[ "$osym" = "" ] && continue
        #[ "$osym" = "-1" ] && continue
        #[ "$shpsym" = "" ] && continue

        dbg ogr2ogr -skipfailures -f DXF "$inputdir"/dxf/$Xsym.dxf -where "symbol=$Xsym" $Xdb
        ogr2ogr -skipfailures -f DXF "$inputdir"/dxf/$Xsym.dxf -where "symbol=$Xsym" $Xdb 2>/dev/null >&2

        # give name for layer = symbol value
        make_symbol_value "$inputdir"/dxf/$Xsym.dxf "$Xsym" 2>/dev/null

        # make dxf => shp
        cp -f "$inputdir"/dxf/$Xsym.dxf $inputdir/temp.dxf
        dbg ogr2ogr -f "ESRI Shapefile" $inputdir/temp.shp  $inputdir/temp.dxf 
        ogr2ogr -skipfailures -f "ESRI Shapefile" $inputdir/temp.shp  $inputdir/temp.dxf 2>/dev/null >&2

        # make one merged shp
        if [ ! -f $inputdir/merged_$Xtable.shp ] ; then # first
                dbg ogr2ogr -skipfailures -f "ESRI Shapefile" -nln merged_$Xtable "$inputdir"/merged_$Xtable.shp "$inputdir"/temp.shp   
                ogr2ogr -skipfailures -f 'ESRI Shapefile' -nln merged_$Xtable "$inputdir"/merged_$Xtable.shp "$inputdir"/temp.shp    2>/dev/null #>/dev/null 2>&1
        else # append
                dbg ogr2ogr -skipfailures -f "ESRI Shapefile" -append -update  "$inputdir"/merged_$Xtable.shp "$inputdir"/temp.shp  -nln merged_$Xtable 
                ogr2ogr -skipfailures -f 'ESRI Shapefile' -append -update  "$inputdir"/merged_$Xtable.shp "$inputdir"/temp.shp  -nln merged_$Xtable 2>/dev/null 2>&1
        fi
  done < "$inputdir"/"$Xinf.csv"

  # merged_$Xtable.shp done, include all symbols in one file

  # make dxf
  dbg ogr2ogr -skipfailures -f DXF "$inputdir"/merged_$Xtable.dxf  "$inputdir"/merged_$Xtable.shp 
  ogr2ogr -skipfailures -f DXF "$inputdir"/merged_$Xtable.dxf  "$inputdir"/merged_$Xtable.shp 2>/dev/null
  ((save>0)) && cp -f "$inputdir"/merged_$Xtable.* "$outputdir"

  mv -f "$inputdir"/merged_$Xtable.dxf "$outputdir"/${Xarea}_$Xtable.dxf
  ((DEBUG<1)) && rm -f "$inputdir"/temp.*  2>/dev/null
  

}



#########################################################################
# MAIN
#########################################################################

DXF_ENCODING=LATIN1
export DXF_ENCODING

crtfile=$AWGEO/config/FIshp2ISOM2017.crt
outputdir=""
arealabel=""
inputdir=""
indir=""
save=0

while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-d) DEBUG="$2" ; shift ;;
		-a) arealabel="$2" ; shift
                        [ "$outputdir" = "" ] && outputdir="mml/$arealabel"
                        [ "$indir" = "" ] && indir="sourcedata/$arealabel"
                        ;;
                -o) outputdir="$2" ; shift ;;
                -i) indir="$2" ; shift ;;
                -s) save=1 ;;
		-c) crtfile="$2" ; shift ;;
	esac
	shift
done

[ "$arealabel" = "" ] && usage && exit 1
[ "$indir" = "" ] && usage && exit 2
[ ! -d "$indir" ] && echo "no dir:$indir " >&2 && exit 3
[ ! -f "$crtfile" ] && echo "no crtfile:$crtfile" >&2 && exit 4

Xnow=$PWD

# v = viivat
# p = alueet talot, pellot, suot, tontti, kivikot
# s = symbolit

id=$$ # process number = unique id for tempfiles
TEMP="$PWD/tmp/$id"

dbg "pwd:" $PWD
dbg mkdir -p "$outputdir" "$TEMP"
mkdir -p "$outputdir" "$TEMP"
[ ! -d "$outputdir" ] && echo "no dir:$outputdir " >&2 && exit 3
[ ! -d "$TEMP" ] && echo "no dir:$TEMP " >&2 && exit 3

inputdir="$TEMP"
rm -rf "$inputdir/dxf" 2>/dev/null
rm -f "$inputdir/merge*.dxf" merged_*  2>/dev/null
rm -f "$inputdir/merged_*.*"  2>/dev/null
rm -f "$inputdir/merged*.csv"  2>/dev/null
mkdir -p "$inputdir/dxf" 2>/dev/null

dbg "inputdir:$indir tempdir:$inputdir"
oifs="$IFS"
for fpath in "$indir"/"$arealabel"*.gpkg
do

	fname=$(getfile "$fpath" )
	#NnnnnL.kiinteistoraja.gpkg
	IFS="." read area table xstr <<<$(echo "$fname")
	IFS="$oifs"
	# t = text = not yet
	[ "$table" = "t" ] && continue

	dbg "area:$area table:$table inputfile:$fpath fname:$fname"
	# already added fld symbol and set default values
	ogr2ogr  -f CSV "$inputdir"/merge_$table.csv -dialect SQLite -sql "SELECT DISTINCT symbol FROM $table " "$fpath"   2>/dev/null

	dbg make_symbol_dxf "$area" "$table" "$fpath"
	make_symbol_dxf "$area" "$table" "$fpath"
done
cd $Xnow



dbg mkdir -p "$outputdir"
mkdir -p "$outputdir"
if [ -d "$outputdir" ] && (( save >0 )) ; then
	cp -rf "$TEMP"/* "$outputdir" 2>/dev/null
fi

# some files to use data in the Ocad
cp -f $AWGEO/config/*.crt "$outputdir" 2>/dev/null
cp -f $AWGEO/config/*.ocd "$outputdir" 2>/dev/null

dbg "data saved to dir:$outputdir"
((DEBUG<1)) && rm -rf "$TEMP"  2>/dev/null

dbg "$PRG end"

