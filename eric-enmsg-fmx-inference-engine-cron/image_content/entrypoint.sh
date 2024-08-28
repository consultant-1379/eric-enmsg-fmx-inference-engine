#!/bin/bash
umask 002
remove_cron_config_not_applicable_to_cenm_from_tmp_directory () {
  rm -rf /var/tmp/cron.d_copy/fmxstack
}

restore_cron_config () {
  remove_cron_config_not_applicable_to_cenm_from_tmp_directory
  mv /var/tmp/cron.d_copy/* /etc/cron.d
}

/sbin/rsyslogd -i /tmp/rsyslogd.pid
/etc/rabbitmq/rabbitmqconf.sh
restore_cron_config
/usr/local/bin/populate_and_load_crontab_from_etc_crond.sh
rm -rf /etc/rabbitmq/rabbitmqconf.sh
/usr/bin/supercronic -overlapping /usr/local/bin/fmx_crontab 2>&1 | logger -t "supercronic" -p local0.info
