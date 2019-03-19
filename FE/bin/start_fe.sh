#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

curdir=`dirname "$0"`
curdir=`cd "$curdir"; pwd`

export DORIS_HOME=`cd "$curdir/.."; pwd`

# export env variables from fe.conf
#
# JAVA_OPTS
# LOG_DIR
# PID_DIR
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64

export JAVA_OPTS="-Xmx1024m"
export LOG_DIR="$DORIS_HOME/log"
export PID_DIR=`cd "$curdir"; pwd`

while read line; do
    envline=`echo $line | sed 's/[[:blank:]]*=[[:blank:]]*/=/g' | sed 's/^[[:blank:]]*//g' | egrep "^[[:upper:]]([[:upper:]]|_|[[:digit:]])*="`
    envline=`eval "echo $envline"`
    if [[ $envline == *"="* ]]; then
        eval 'export "$envline"'
    fi
done < $DORIS_HOME/conf/fe.conf

if [ -e $DORIS_HOME/bin/palo_env.sh ]; then
    source $DORIS_HOME/bin/palo_env.sh
fi

# java
if [ "$JAVA_HOME" = "" ]; then
  echo "Error: JAVA_HOME is not set."
  exit 1
fi
JAVA=$JAVA_HOME/bin/java

# add libs to CLASSPATH
for f in $DORIS_HOME/lib/*.jar; do
  CLASSPATH=$f:${CLASSPATH};
done
export CLASSPATH=${CLASSPATH}:${DORIS_HOME}/lib

if [ ! -d $LOG_DIR ]; then
    mkdir -p $LOG_DIR
fi

pidfile=$PID_DIR/fe.pid

if [ -f $pidfile ]; then
  if kill -0 `cat $pidfile` > /dev/null 2>&1; then
    echo Frontend running as process `cat $pidfile`.  Stop it first.
    exit 1
  fi
fi

if [ ! -f /bin/limit ]; then
    LIMIT=
else
    LIMIT=/bin/limit
fi

echo `date` >> $LOG_DIR/fe.out
nohup $LIMIT $JAVA $JAVA_OPTS org.apache.doris.PaloFe "$@" >> $LOG_DIR/fe.out 2>&1 </dev/null &

echo $! > $pidfile
