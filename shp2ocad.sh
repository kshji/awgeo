#!/usr/local/bin/awsh
# shp2ocad.sh
#
# init_shp.sh has done before this
# shp2ocad.sh -a 5313L   
# - input from data/5313L
# - output output/5313L
# shp2ocad.sh -a 5313L    -i data/5313L -o output/5313L
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
        -s save unziped files, default no
        -o destdir , default is output/arealabel
	-i inputdir, include init_shp.sh result files
	-c crtfile, default is $crtfile
        -d 0|1 , debug, def 0
        " >&2
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
{
  Xtype="$1"
  Xinf="merge_$Xtype"
  [ ! -f "$Xinf.csv" ] && echo "no $Xinf.csv" >&2 && exit 3

  dbg "process make_symbol_dxf $Xtype $Xinf"


  rm -rf merged_$Xtype.shp 2>/dev/null

  while read Xsym str
  do
        ((line+=1))
        ((line == 1)) && continue
        # lainausmerkit ymparilta pois
        Xsym=${Xsym//\"}

        dbg "Do: $Xinf $Xsym"

	# - voisi olla tarkistus, etta jos ei on konversio crt:ssa niin vain silloin tehdaan dxf - nopeutuu hieman
	# siis tyyliin about:
        #grep " $Xsym " "joku.crt"  2>/dev/null  | read osym shpsym xxsym 
        # - if not Ocad sym then next
        #[ "$osym" = "" ] && continue
        #[ "$osym" = "-1" ] && continue
        #[ "$shpsym" = "" ] && continue

        dbg ogr2ogr -f DXF dxf/$Xsym.dxf -where "symbol=$Xsym" $Xinf.shp 
        ogr2ogr -f DXF dxf/$Xsym.dxf -where "symbol=$Xsym" $Xinf.shp 2>/dev/null >&2

        # give name for layer = symbol value
        make_symbol_value dxf/$Xsym.dxf "$Xsym" 2>/dev/null

        # make dxf => shp
        cp dxf/$Xsym.dxf temp.dxf
        dbg ogr2ogr -f "ESRI Shapefile" temp.shp  temp.dxf 
        ogr2ogr -f "ESRI Shapefile" temp.shp  temp.dxf 2>/dev/null >&2

        # make one merged shp
        if [ ! -f merged_$Xtype.shp ] ; then # first
                dbg ogr2ogr -f "ESRI Shapefile" merged_$Xtype.shp temp.shp   
                ogr2ogr -f "ESRI Shapefile" merged_$Xtype.shp temp.shp    2>/dev/null #>/dev/null 2>&1
        else # append
                dbg ogr2ogr -f "ESRI Shapefile" -append -update  merged_$Xtype.shp temp.shp  -nln merged_$Xtype 
                ogr2ogr -f "ESRI Shapefile" -append -update  merged_$Xtype.shp temp.shp  -nln merged_$Xtype 2>/dev/null 2>&1
        fi
  done < "$Xinf.csv"

  # merged_$Xtype.shp done, include all symbols in one file

  # make dxf
  dbg ogr2ogr -f DXF merged_$Xtype.dxf  merged_$Xtype.shp 
  ogr2ogr -f DXF merged_$Xtype.dxf  merged_$Xtype.shp 2>/dev/null

  mv -f merged_$Xtype.dxf ${arealabel}_$Xtype.dxf
  rm -f temp.*  2>/dev/null

}


#########################################################################
update_some_symbols_v()
{
	Xdb="$1"
	#update_some_symbols_v "merge_$t.shp"
	# rantaviiva
        ogrinfo  merge_$t.shp   -dialect SQLite -sql "
          UPDATE  merge_$t
          SET symbol=42300
	  WHERE kartoglk=36200
        "
	# kuvioraja
        ogrinfo  merge_$t.shp   -dialect SQLite -sql "
          UPDATE  merge_$t
          SET symbol=30212
	  WHERE kartoglk=39110
        "
	# ei nayteta selva kuvioraja tiettyjen alueiden reunalla (suo yms)
        ogrinfo  merge_$t.shp   -dialect SQLite -sql "
          UPDATE  merge_$t
          SET symbol=0
	  WHERE symbol = 30211 AND kartoglk IN (32111,32112,32500,32612,32900,34100,34300,34700,35300,35400,35411,35412,35421,35422,38700)
        "
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

while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in
		-d) DEBUG="$2" ; shift ;;
		-a) arealabel="$2" ; shift
                        [ "$outputdir" = "" ] && outputdir="mml/$arealabel"
                        [ "$inputdir" = "" ] && inputdir="sourcedata/$arealabel"
                        ;;
                -o) outputdir="$2" ; shift ;;
                -i) inputdir="$2" ; shift ;;
		-c) crtfile="$2" ; shift ;;
	esac
	shift
done

[ "$arealabel" = "" ] && usage && exit 1
[ "$inputdir" = "" ] && usage && exit 2
[ ! -d "$inputdir" = "" ] && echo "no dir:$inputdir " >&2 && exit 3
[ ! -f "$crtfile" ] && echo "no crtfile:$crtfile" >&2 && exit 4

[ ! -f "$inputdir/merge_v.shp" ] && echo "init_shp.sh not done? No merge_?.shp files in $inputdir" >&2 exit 6

Xnow=$PWD

# v = viivat
# p = alueet talot, pellot, suot, tontti, kivikot
# s = symbolit

rm -rf "$inputdir/dxf" 2>/dev/null
rm -f "$inputdir/merge*.dxf" merged_*  2>/dev/null
rm -f "$inputdir/merged_*.*"  2>/dev/null
rm -f "$inputdir/merged*.csv"  2>/dev/null
mkdir -p "$inputdir/dxf" 2>/dev/null

dbg "inputdir $inputdir"
cd "$inputdir"
for t in s p v  #t teksti ei  # 
do

	#if ((1<1)) ; then 
	dbg ogrinfo  merge_$t.shp -sql "ALTER TABLE merge_$t ADD COLUMN angle character(254)" 
	ogrinfo  merge_$t.shp -sql "ALTER TABLE merge_$t ADD COLUMN angle character(254)" 
	
	dbg ogrinfo  merge_$t.shp   -dialect SQLite -sql "UPDATE angle ..."
	ogrinfo  merge_$t.shp   -dialect SQLite -sql "
          UPDATE  merge_$t
                SET angle=CAST(SUUNTA*1.0/10000.0/3.14159*180.0  AS  character(254) )
          WHERE SUUNTA IS NOT NULL
        "

	# unique symbol col add
        dbg  ogrinfo merge_$t.shp -sql "ALTER TABLE merge_$t ADD COLUMN symbol integer(6)"
        ogrinfo  merge_$t.shp -sql "ALTER TABLE merge_$t ADD COLUMN symbol integer(6)"
        # default 0
        dbg ogrinfo  merge_$t.shp   -dialect SQLite -sql "update symbol=0"
        ogrinfo  merge_$t.shp   -dialect SQLite -sql "
          UPDATE  merge_$t
          SET symbol=0
        "

        dbg ogrinfo  merge_$t.shp   -dialect SQLite -sql "SET symbol=luokka"
        ogrinfo  merge_$t.shp   -dialect SQLite -sql "
          UPDATE  merge_$t
          SET symbol=luokka
        "

	# if v = viiva = polygon - update some symbols
	[ "$t" = "v" ] && update_some_symbols_v "merge_$t.shp"

	dbg ogr2ogr  -f CSV merge_$t.csv -dialect SQLite -sql "SELECT DISTINCT symbol FROM merge_$t " merge_$t.shp   
	ogr2ogr  -f CSV merge_$t.csv -dialect SQLite -sql "SELECT DISTINCT symbol FROM merge_$t " merge_$t.shp   2>/dev/null
	dbg make_symbol_dxf "$t"

	make_symbol_dxf "$t"

done






cd $Xnow

mkdir -p "$outputdir"
dbg mv -f $inputdir/${arealabel}_?.dxf "$outputdir"
mv -f $inputdir/${arealabel}_?.dxf "$outputdir"

