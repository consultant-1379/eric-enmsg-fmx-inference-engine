#!/bin/bash
umask 002

restore_cron_config_from_image() {
  mv -f /var/tmp/cron.d_from_image/fmxstats /etc/cron.d
}

/sbin/rsyslogd  -i /tmp/rsyslogd.pid
restore_cron_config_from_image
/var/run/fmx/scripts/fmx_preconfig.sh
/var/run/fmx/scripts/enable_jmx_opts.sh "/opt/ericsson/fmx/engine/bin/fmxie.sh" 9093
/opt/ericsson/fmx/engine/bin/fmxie.sh
/var/run/fmx/scripts/postInstall.sh &
