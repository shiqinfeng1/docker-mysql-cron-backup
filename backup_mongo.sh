#!/bin/bash

[ -z "${MONGO_URI}" ] && { echo "=> mongdb uri cannot be empty" && exit 1; }


DATE=$(date +%Y%m%d%H%M)
echo "=> Backup mongodb started at $(date "+%Y-%m-%d %H:%M:%S")"

FILENAME=/backup/$DATE.mongodb.gz
LATEST=/backup/latest.mongodb.gz

mongodump --uri ${MONGO_URI} --gzip --archive=$FILENAME
if [ $? -ne 0 ]; then
  echo "mongodump mongo fail"
  exit 1
fi
BASENAME=$(basename "$FILENAME")
echo "==> Creating mongodb symlink to latest backup: $BASENAME"
rm "$LATEST" 2> /dev/null
cd /backup || exit && ln -s "$BASENAME" "$(basename "$LATEST")"
if [ -n "$MAX_BACKUPS" ]
then
  while [ "$(find /backup -maxdepth 1 -name "*.mongodb.gz" -type f | wc -l)" -gt "$MAX_BACKUPS" ]
  do
    TARGET=$(find /backup -maxdepth 1 -name "*.mongodb.gz" -type f | sort | head -n 1)
    echo "==> Max number of ($MAX_BACKUPS) backups mongodb reached. Deleting ${TARGET} ..."
    rm -rf "${TARGET}"
    echo "==> Backup mongodb ${TARGET} deleted"
  done
fi

echo "=> Backup mongodb process finished at $(date "+%Y-%m-%d %H:%M:%S")"
