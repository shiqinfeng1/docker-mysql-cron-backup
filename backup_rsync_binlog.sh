#!/bin/bash

binlog_dir="$BINLOG_DIR"
###定义备份服务器的ip###
remote_backup_ssh_ip=$REMOTE_BACKUP_SSH_IP
###ssh端口号###
remote_backup_ssh_port=$REMOTE_BACKUP_SSH_PORT
remote_backup_id_rsa_user=$REMOTE_BACKUP_USER
remote_backup_id_rsa_pass=$REMOTE_BACKUP_PASS

###定义要同步的远程服务器的目录路径（必须是绝对路径）###
remote_backup_binlog_path=$REMOTE_BACKUP_BINLOG_PATH


rsync_mysql_binlog()
{
    # rsync 同步到其他Server中 #
    for j in ${remote_backup_ssh_ip}
    do                
        echo "mysql_backup_binlog_rsync to ${j} begin at "$(date +'%Y-%m-%d %T')
        ### 同步 ###
        rsync -avz --progress --delete --include="binlog.*" --exclude="*" $binlog_dir -e "sshpass -p "${remote_backup_id_rsa_pass}" ssh -p "${remote_backup_ssh_port} ${remote_backup_id_rsa_user}@${j}:$remote_backup_binlog_path 
        if [ $? -ne 0 ]; then 
            echo "mysql_backup_binlog_rsync to ${j} *fail* at "$(date +'%Y-%m-%d %T')
            continue
        fi
        echo "mysql_backup_binlog_rsync to ${j} done at "$(date +'%Y-%m-%d %T')
    done
}

cd ${binlog_dir}
rsync_mysql_binlog
cd -