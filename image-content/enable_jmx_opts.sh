#!/bin/bash
file=$1
port=$2

if ! grep "eval splitJvmOpts" $file | grep -q "\$JMX_OPTS"; then
    sed -i '/^eval splitJvmOpts/ s/$/ \$JMX_OPTS/' $file
    echo "Appending JMX_OPTS variable to \"splitJvmOpts\" in $file"
fi

if grep "eval splitJvmOpts" $file; then
    line=$(egrep -n "eval splitJvmOpts" $file | cut -f1 -d:)
    sed -i "${line} i JMX_OPTS=\"-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=$port -Dcom.sun.management.jmxremote.rmi.port=$port -Djava.rmi.server.hostname=localhost -Dcom.sun.management.jmxremote.local.only=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false\"" $file
    echo "Appending JMX_OPTS to $file"
fi
