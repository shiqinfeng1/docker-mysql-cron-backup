FROM fradelg/mysql-cron-backup

RUN apk add --update \
    rsync \
    openssh-client \
    sshpass

RUN apk add --no-cache mongodb-tools 

ENV CRON_TIME="0 3 * * sun" \
    CRON_TIME_RSYNC="0 3 * * *" \
    MYSQL_HOST="mysql" \
    MYSQL_PORT="3306" \
    TIMEOUT="10s" \
    MYSQLDUMP_OPTS="--quick"

COPY ["run.sh", "backup.sh", "backup_mongo.sh", "restore.sh", "backup_rsync_binlog.sh","backup_rsync.sh", "/"]
RUN chmod 777 /backup && \ 
    chmod 755 /run.sh /backup.sh /backup_mongo.sh /restore.sh /backup_rsync_binlog.sh /backup_rsync.sh && \
    touch /backup/mysql_backup.log && \
    chmod 666 /backup/mysql_backup.log

VOLUME ["/backup"]

CMD dockerize -wait tcp://${MYSQL_HOST}:${MYSQL_PORT} -timeout ${TIMEOUT} /run.sh
