#!/bin/bash

# simple logging
syslog_tag=fmxie-postinstall
syslog_fac=user

function config_fmxie() {
	# configure fmx engine ID
	engine_id=`hostname`
	logger -t ${syslog_tag} -p ${syslog_fac}.info "Setting fmxie engine_id: '$engine_id'..."
	cp -p /etc/opt/ericsson/fmx/engine/kernel.properties /etc/opt/ericsson/fmx/engine/kernel.properties.${TIMESTAMP}
	sed -i "s/^engineId=.*/engineId=${engine_id}/" /etc/opt/ericsson/fmx/engine/kernel.properties
}

# configure fmxie
config_fmxie

