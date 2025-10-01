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
	cat | psql 2>>$errf >>$lf
	pgstat=$?
	(( pgstat>0 )) && err "dosql status:$pgstat" && exit 10
}

#######################################################

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
while read shpfile
do
	Xlayer=${shpfile%%.*}	
	Xarea=${Xlayer%_*}
	Xtable=${Xlayer##*_}
	dbg "Xlayer:$Xlayer Xarea:$Xarea Xtable:$Xtable"
done 



