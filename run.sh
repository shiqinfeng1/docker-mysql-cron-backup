#!/bin/bash

mkdir -p ~/.ssh && touch ~/.ssh/config
echo "StrictHostKeyChecking no" > ~/.ssh/config

tail -F /backup/mysql_backup.log &

if [ "${INIT_BACKUP}" -gt "0" ]; then
  echo "=> Create a backup on the startup"
  /backup.sh
elif [ -n "${INIT_RESTORE_LATEST}" ]; then
  echo "=> Restore latest backup"
  until nc -z "$MYSQL_HOST" "$MYSQL_PORT"
  do
      echo "waiting database container..."
      sleep 1
  done
  find /backup -maxdepth 1 -name '*.sql.gz' | tail -1 | xargs /restore.sh
fi

echo "${CRON_TIME} /backup.sh >> /backup/mysql_backup.log 2>&1" >> /tmp/crontab.conf
if [ -f /backup_mongo.sh ] 
then 
     echo "${CRON_TIME_RSYNC} /backup_mongo.sh >> /backup/mongo_backup.log 2>&1" >> /tmp/crontab.conf
fi

echo "${CRON_TIME_BINLOG_RSYNC} /backup_rsync_binlog.sh >> /backup/mysql_rsync_binlog.log 2>&1" >> /tmp/crontab.conf
echo "${CRON_TIME_RSYNC} /backup_rsync.sh >> /backup/mysql_backup_rsync.log 2>&1" >> /tmp/crontab.conf
crontab /tmp/crontab.conf

echo "=> Running cron task manager in foreground"
exec crond -f -l 8 -L /backup/mysql_backup.log
