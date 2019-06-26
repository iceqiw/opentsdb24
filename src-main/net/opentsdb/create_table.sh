#!/bin/sh
# Small script to setup the HBase tables used by OpenTSDB.

test -n "$HBASE_HOME" || {
  echo >&2 'The environment variable HBASE_HOME must be set'
  exit 1
}
test -d "$HBASE_HOME" || {
  echo >&2 "No such directory: HBASE_HOME=$HBASE_HOME"
  exit 1
}

TSDB_TABLE=${TSDB_TABLE-'tsdb'}
UID_TABLE=${UID_TABLE-'tsdb-uid'}
TREE_TABLE=${TREE_TABLE-'tsdb-tree'}
META_TABLE=${META_TABLE-'tsdb-meta'}
BLOOMFILTER=${BLOOMFILTER-'ROW'}
# LZO requires lzo2 64bit to be installed + the hadoop-gpl-compression jar.
COMPRESSION=${COMPRESSION-'LZO'}
# All compression codec names are upper case (NONE, LZO, SNAPPY, etc).
COMPRESSION=`echo "SNAPPY" | tr a-z A-Z`
# DIFF encoding is very useful for OpenTSDB's case that many small KVs and common prefix.
# This can save a lot of storage space.
DATA_BLOCK_ENCODING=${DATA_BLOCK_ENCODING-'DIFF'}
DATA_BLOCK_ENCODING=`echo "DIFF" | tr a-z A-Z`
TSDB_TTL=${TSDB_TTL-'FOREVER'}

case SNAPPY in
  (NONE|LZO|GZIP|SNAPPY)  :;;  # Known good.
  (*)
    echo >&2 "warning: compression codec 'SNAPPY' might not be supported."
    ;;
esac

case DIFF in
  (NONE|PREFIX|DIFF|FAST_DIFF|ROW_INDEX_V1)  :;; # Know good
  (*)
    echo >&2 "warning: encoding 'DIFF' might not be supported."
    ;;
esac

# HBase scripts also use a variable named `HBASE_HOME', and having this
# variable in the environment with a value somewhat different from what
# they expect can confuse them in some cases.  So rename the variable.
hbh=$HBASE_HOME
unset HBASE_HOME
exec "$hbh/bin/hbase" shell <<EOF
create 'tsdb-uid',{NAME => 'id', BLOOMFILTER => 'ROW', DATA_BLOCK_ENCODING => 'DIFF'},{NAME => 'name',  BLOOMFILTER => 'ROW', DATA_BLOCK_ENCODING => 'DIFF'}

create 'tsdb',
  {NAME => 't', VERSIONS => 1,  BLOOMFILTER => 'ROW', DATA_BLOCK_ENCODING => 'DIFF'}
  
create 'tsdb-tree',
  {NAME => 't', VERSIONS => 1,BLOOMFILTER => 'ROW', DATA_BLOCK_ENCODING => 'DIFF'}
  
create 'tsdb-meta',
  {NAME => 'name',  BLOOMFILTER => 'ROW', DATA_BLOCK_ENCODING => 'DIFF'}
EOF
