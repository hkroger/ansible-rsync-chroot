#!/bin/bash
snapshotname=varmistus
backupdir=/varmistus/data
backupuser=varmistus

function log() {
    if [[ $_V -eq 1 ]]; then
        echo "$@"
    fi
}

_V=0

while getopts "v" OPTION
do
  case $OPTION in
    v) _V=1
       ;;
  esac
done


log Clearing old snapshot: $snapshotname
nodetool clearsnapshot -t $snapshotname > /dev/null
log Creating snapshot: $snapshotname
nodetool snapshot -t $snapshotname > /dev/null

log Clearing previous backups
rm -rf $backupdir/*

log Copying created files to $backupdir
for d in `find /var/lib/cassandra/data -name $snapshotname`; do
        targetdir=`dirname \`dirname $backupdir$d\``
        mkdir -p $targetdir
        cp -R $d/* $targetdir
done

log Dumping schema to $backupdir/cassandra_schema.cql
cqlsh -e "DESC FULL SCHEMA" > $backupdir/cassandra_schema.cql

chown -R $backupuser $backupdir

log Removing snapshot: $snapshotname
nodetool clearsnapshot -t $snapshotname > /dev/null
