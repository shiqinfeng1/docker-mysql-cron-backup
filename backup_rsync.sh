#!/bin/bash

# the directory for story your backup file.  #

if [ ! -n "$BACKUP_SRC_DIR" ]; then 
   BACKUP_SRC_DIR="/backup"
fi

rsync_mysql_backup()
{
    # rsync 同步到其他Server中 #
    for j in ${REMOTE_BACKUP_SSH_IP}
    do                
        echo "[mysql_backup_rsync] to ${j} *begin* at "$(date +'%Y-%m-%d %T')
        ### 同步 ###
         sshpass -p ${REMOTE_BACKUP_PASS} rsync -avz --progress --delete --include="*" ${BACKUP_SRC_DIR} ${REMOTE_BACKUP_USER}@${j}:$REMOTE_BACKUP_PATH 
        if [ $? -ne 0 ]; then 
            echo "[mysql_backup_rsync] to ${j} *fail* at "$(date +'%Y-%m-%d %T')
            continue
        fi
        echo "[mysql_backup_rsync] to ${j} *done* at "$(date +'%Y-%m-%d %T')
    done
}

rsync_mysql_backup
