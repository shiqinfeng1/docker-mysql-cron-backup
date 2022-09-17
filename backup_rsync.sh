#!/bin/bash

# the directory for story your backup file.  #
backup_dir="/backup/"
###定义备份服务器的ip###
remote_backup_ssh_ip=$REMOTE_BACKUP_SSH_IP
###ssh端口号###
remote_backup_ssh_port=$REMOTE_BACKUP_SSH_PORT
remote_backup_id_rsa_pass=$REMOTE_BACKUP_PASS
remote_backup_id_rsa_user=$REMOTE_BACKUP_USER

###定义要同步的远程服务器的目录路径（必须是绝对路径）###
remote_backup_path=$REMOTE_BACKUP_PATH

rsync_mysql_backup()
{
    # rsync 同步到其他Server中 #
    for j in ${remote_backup_ssh_ip}
    do                
        echo "mysql_backup_rsync to ${j} *begin* at "$(date +'%Y-%m-%d %T')
        ### 同步 ###
        rsync -avz --progress --delete ${backup_dir} -e "sshpass -p "${remote_backup_id_rsa_pass}" ssh -p "${remote_backup_ssh_port} ${remote_backup_id_rsa_user}@${j}:$remote_backup_path 
        if [ $? -ne 0 ]; then 
            echo "mysql_backup_rsync to ${j} *fail* at "$(date +'%Y-%m-%d %T')
            continue
        fi
        echo "mysql_backup_rsync to ${j} *done* at "$(date +'%Y-%m-%d %T')
    done
}

rsync_mysql_backup
