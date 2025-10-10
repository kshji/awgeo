#!/usr/local/bin/awsh
# csv2dxf.sh
#
# symbol, point
#   csv2dxf.sh --type s  --csv csvin.csv > xxx.dxf
# text
#   csv2dxf.sh --type t  --csv csvin.csv > xxx.dxf
#


PRG="$0"
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0


#############################################
dbg()
{
	((DEBUG<1)) && return
	echo "$*" >&2
}

#############################################
dxf_begin()
{
	cat <<ENDBLOCK
999
DXF Created from AwGeo
  0
ENDBLOCK
}

#############################################
dxf_layer_begin()
{
        cat <<ENDBLOCK
SECTION
  2
TABLES
  0
TABLE
  2
LAYER
  2
2
100
AcDbSymbolTable
 70
     2
  0
ENDBLOCK
}

#############################################
dxf_layer_item()
{
	Xsymbol="$1"
        cat <<ENDBLOCK
LAYER
  5
25
100
AcDbSymbolTableRecord
100
AcDbLayerTableRecord
  2
$Xsymbol
 70
     0
 62
     7
  6
CONTINUOUS
  0
ENDBLOCK
}

#############################################
dxf_layer_end()
{
        cat <<ENDBLOCK
ENDTAB
  0
ENDSEC
  0
ENDBLOCK
}


#############################################
dxf_block_begin()
{
        cat <<ENDBLOCK
SECTION
  2
ENTITIES
  0
ENDBLOCK
}

#############################################
dxf_end()
{
	cat <<ENDBLOCK
ENDSEC
  0
EOF
ENDBLOCK
}

#############################################
dxf_text()
{
	# dxf_text "$LUOKKA" "$ANGLE" "$lat" "$lon"
	Xluokka="$1"
	Xangle="$2"
	Xlat="$3"
	Xlon="$4"
	Xtext="$5"
	Xcnt="$6"

	cat <<ENDBLOCK
MTEXT
 5
$Xcnt
100
AcDbEntity
  8
$Xluokka
100
AcDbMText
 10
$Xlat
 20
$Xlon
  1
$Xtext
 50
$Xangle
 71
7
  0
ENDBLOCK
}

#############################################
dxf_symbol()
{
        # dxf_symbol "$LUOKKA" "$ANGLE" "$lat" "$lon" "$cnt"
        Xluokka="$1"
        Xangle="$2"
        Xlat="$3"
        Xlon="$4"
        Xcnt="$5"

        cat <<ENDBLOCK
POINT
 5
100
AcDbEntity
  8
$Xluokka
100
AcDbMText
 10
$Xlat
 20
$Xlon
 50
$Xangle
  0
ENDBLOCK
}

#############################################
# MAIN
#############################################
csvin=""
dxfout="out.dxf"
dxftype=""
DEBUG=0

while [ $# -gt 0 ]
do
	arg="$1"
	case "$arg" in 
		--csv|-c) csvin="$2"; shift ;;
		--debug|-d) DEBUG="$2"; shift ;;
		--type|-t) dxftype="$2" ; shift ;;
	esac
	shift
done


case "$dxftype" in
	t|s) ;;
	*) dxftype="" ;;
esac

[ "$dxftype" = "" ] && echo "usage:$PRG --csv file.csv --type t|s " >&2 && exit 1
[ "$csvin" = "" ] && echo "usage:$PRG --csv --type t|s file.csv " >&2 && exit 1
[ ! -f "$csvin"  ] && echo "Can't read file $csvinf" >&2 && exit 2

#geom;LUOKKA;SUUNTA;ANGLE;TEXT
#"POINT (620664.88 6942901.823)";52191;-9371;"-53.6919203333344";"80"

oifs="$IFS"

variables=variables
cnt=0
dxf_begin 
#dxf_layer_begin
#dxf_layer item 35040 
#dxf_layer item 36201
#dxf_layer_end

dxf_block_begin

mmtextcnt=27
while IFS=";" read line
do
	((cnt++))
	IFS="$oifs"
	# remove "
	line="${line//\"/}"
	IFS=";" 
	read $variables <<<$line
	IFS="$oifs"
	(( cnt <= 1 )) &&  continue
	# maybe more to look geom or GEOMETRY fld ...
	#dbg "$SYMBOL - $ANGLE - $TEXT - $geom" >&2
	((DEBUG>1)) && dbg "symbol:$SYMBOL - angle:$ANGLE - text:$TEXT - $GEOMETRY" >&2


	IFS=" ()"
	#read x lat lon <<<$geom
	read x lat lon <<<$GEOMETRY
	IFS="$oifs"
	((DEBUG>1)) && dbg "     $lat $lon" >&2
	case "$dxftype" in
		t) dxf_text "$SYMBOL" "$ANGLE" "$lat" "$lon" "$TEXT" "$mmtextcnt"
		   ;;
		s) dxf_symbol "$SYMBOL" "$ANGLE" "$lat" "$lon" "$mmtextcnt"
		   ;;
	esac
	((mmtextcnt ++))
	
done < "$csvin"
dxf_end
