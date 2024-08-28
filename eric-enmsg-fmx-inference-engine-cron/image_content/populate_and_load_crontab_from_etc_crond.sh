#!/bin/bash
#Supercronic is a cron implementation for containerized environments, expects to have the job schedule information on one crontab file
#This script helps to build the crontab file by reading the contents of the multiple cron jobs from etc/cron.d directory
#This script is also scheduled to run as a job in frequent interval to check and reload the crontab when required
#cronbase - source content from  etc/cron.d
#crontab  - populate on to /usr/local/bin/fmx_crontab
cronbase="/var/tmp/cronbase"
crontab="/usr/local/bin/fmx_crontab"
tempfile="/var/tmp/tmp_cronbase"

reload_crontab_if_different_from_cronbase () {
  if cmp -s "$cronbase" "$crontab"; then
      printf 'The file "%s" is the same as "%s"\n' "$cronbase" "$crontab"
  else
      printf 'The file "%s" is different from "%s"\n' "$cronbase" "$crontab"
      #Logic for getting PID for supercronic
      supercronic_process="supercronic"
      pid=$(pidof "$supercronic_process")
      if [ -n "$pid" ]; then
          echo "PID: $pid"
          cat "$cronbase" > "$crontab"
          # To reload the crontab
          kill -USR2 $pid
      else
          printf 'Failed to reload the crontab. "%s" process not found \n' "$supercronic_process"
      fi
  fi
}

read_etc_crond_dir_to_populate_cronbase () {
  create_cronbase
  for cronfile in /etc/cron.d/*; do
      if [ -f "$cronfile" ] && [ -r "$cronfile" ]; then
          cat "$cronfile" >> "$cronbase"
      fi
  done
  setup_cronbase_for_execution
}

create_cronbase () {
  echo "* * * * * root /usr/local/bin/populate_and_load_crontab_from_etc_crond.sh" > "$cronbase"
}

setup_cronbase_for_execution () {
  # deletes MAILTO entries from the schedule
  sed -i '/^[ \t]*MAILTO[ \t]*=/d' $cronbase
  # deletes empty lines
  sed -i '/^$/d' $cronbase
  # Replaces the user field with a tab ,allows for successful execution of the jobs by supercronic.
  awk '!/^[ \t]*#/{ sub($6, "\t"); } 1' $cronbase > $tempfile && mv $tempfile $cronbase
}

populate_crontab_from_cronbase_when_not_exist () {
  if ! [ -f "$crontab" ]; then
        cat "$cronbase" > "$crontab"
        printf 'The crontab file "%s" populated and loaded successfully  from "%s"\n'  "$crontab" "$cronbase"
        exit 0
  fi
}

read_etc_crond_dir_to_populate_cronbase
populate_crontab_from_cronbase_when_not_exist
reload_crontab_if_different_from_cronbase