#!/usr/local/bin/awsh
# push.mml.shp2postgres.sh *_kiint.shp
# push shp files from some dir to the postgresql database
# env variable to have been set
#export PGHOST=localhost
#export PGPORT=5432
#export PGUSER=myusername
#export PGPASSWORD=mypassword
#export PGDATABASE=mydatabase
#export PGCLIENTENCODING=UTF-8
# or give those using options
# or set those values in the $HOME/.pgpass

PRG=$0
BINDIR="${PRG%/*}"
[ "$PRG" = "$BINDIR" ] && BINDIR="." # - same dir as program
PRG="${PRG##*/}"

DEBUG=0


#######################################################
usage()
{
cat <<EOF >&2
usage:$PRG [ --options ] list_of_shapefiles
      $PRG *_kiinteistoraja.shp
      $PRG --pgdb gis  --pguser myusername *_kiinteistoraja.shp


EOF
}

#######################################################
timestamp()
{
	printf "%(%Y-%m-%d_%H%M%S)T" now 
}

#######################################################
log()
{
	echo "$*" >> $lf
}

#######################################################
err()
{
	echo "err: $*" >> $errf
}

#######################################################
dbg()
{
	((DEBUG<1)) && return
	echo "dbg:$*" >&2
	log "dbg:$*"
}

#######################################################
dosql()
{
	flag=""
	[ "$1" = "-t" ] && flag=" -t " && shift
	# get sql from stdin
	SQL=$(<&0)
	cat <<EOF psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER"  -q $flag "$PGDATABASE" 2>>$errf 
	\a
        \\f '$erotin'
        \pset footer off
	$SQL
	;
EOF
	pgstat=$?
	return $pgstat
	###(( pgstat>0 )) && err "dosql status:$pgstat" && exit 10
}

#######################################################
table_create()
{
	
	Ytable="$1"
	Ylayer="$2"
	Yshpfile="$3"
	dbg "table_create:$Ytable - $Ylayer - $Yshpfile"
	dosql <<EOF
		SELECT count(*) FROM $PGSCHEMA.$Ytable LIMIT 1
		;
EOF
	Cstat=$?
	dbg "table_create: check $PGSCHEMA.$Ytable $Cstat"
	(( Cstat == 0 )) && dbg "  table $Ytable exists" && return 0 # table exists
	dbg "  table $Ytable not exists"

	export PG_USE_COPY=YES

	dbg ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" "$Yshpfile" -nln $PGSCHEMA.$Ytable -lco GEOMETRY_NAME=geom -dialect postgresql -sql "SELECT CAST(id AS BIGINT) AS keyid,'CREATE' AS mapname,* FROM $Ylayer LIMIT 1" -lco FID=keyid -overwrite
	ogr2ogr -f "PostgreSQL" PG:"dbname=$PGDATABASE user=$PGUSER" "$Yshpfile" -nln $PGCHEMA.$Ytable -lco GEOMETRY_NAME=geom -dialect postgresql -sql "SELECT CAST(id AS BIGINT) AS keyid,'CREATE' AS mapname,* FROM $Ylayer LIMIT 1" -lco FID=keyid -overwrite
	Cstat=$?
	(( Cstat > 0 )) && dbg "  table $Ytable creating not success status:$Cstat" && return 1 # can't create ???


}

#######################################################
# MAIN
#######################################################
mitka=""
verbose=0
mkdir -p tmp
chmod 1777 tmp 2>/dev/null
SESID=$$
errf=$PWD/tmp/$SESID.$PRG.err
lf=$PWD/tmp/$SESID.$PRG.log
PGSCHEMA=public

while [ $# -gt 1 ]
do
	arg="$1"
	case "$arg" in
		--pguser) export PGUSER="$2"; shift ;;
		--pghost) export PGHOST="$2"; shift ;;
		--pgdatabase|--pgdb) export PGDATABASE="$2"; shift ;;
		--pgport) export PGPORT="$2"; shift ;;
		--pgpass) export PGPASSWORD="$2"; shift ;;
		--pgencode) export PGCLIENTENCODING="$2"; shift ;;
		--pgschema) PGSCHEMA="$2"; shift ;;
		--debug|-d) DEBUG="$2"; shift ;;
		-*) usage ; exit 2 ;;
		*) break ;; # datavalue list
	esac
	shift
done


[ $# -lt 1 ] && usage && exit 1

cnt=0
for shpfile in $@
do
	Xlayer=${shpfile%%.*}	
	Xarea=${Xlayer%_*}
	Xtable=${Xlayer##*_}
	dbg "Xlayer:$Xlayer Xarea:$Xarea Xtable:$Xtable"
	((cnt++))
	((cnt < 2 )) && table_create "$Xtable" "$Xlayer" "$shpfile" 
done 



