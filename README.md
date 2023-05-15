# mysql-cron-backup

Run mysqldump to backup your databases periodically using the cron task manager in the container. Your backups are saved in `/backup`. You can mount any directory of your host or a docker volumes in /backup. Othwerwise, a docker volume is created in the default location.

## 优化与改动
- 支持mongo数据库的定时备份
- 支持密码登录方式远程同步备份mysql的备份数据
- `Dockerfile-origin`为原始dockerfile文件
- `Dockerfile-no-mongo`在原始dockerfile文件基础上，支持远程同步备份
- `Dockerfile-origin`为原始dockerfile文件基础上，支持远程同步备份，并支持mongo数据库定时备份

## 打包镜像
```shell
# 打包不带mongo的镜像
docker build --tag jzsg/data-backup -f Dockerfile-no-mongo .
# 打包带mongo的镜像
docker build --tag jzsg/data-backup -f Dockerfile .
```
## Usage:

```bash
docker container run -d \
       --env MYSQL_USER=root \
       --env MYSQL_PASS=my_password \
       --link mysql
       --volume /path/to/my/backup/folder:/backup
       fradelg/mysql-cron-backup
```

## Variables

- `MYSQL_HOST`: The host/ip of your mysql database.
- `MYSQL_PORT`: The port number of your mysql database.
- `MYSQL_USER`: The username of your mysql database.
- `MYSQL_PASS`: The password of your mysql database.
- `MYSQL_PASS_FILE`: The file in container where to find the password of your mysql database (cf. docker secrets). You should use either MYSQL_PASS_FILE or MYSQL_PASS (see examples below).
- `MYSQL_DATABASE`: The database name to dump. Default: `--all-databases`.
- `MYSQLDUMP_OPTS`: Command line arguments to pass to mysqldump (see [mysqldump documentation](https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html)).
- `MYSQL_SSL_OPTS`: Command line arguments to use [SSL](https://dev.mysql.com/doc/refman/5.6/en/using-encrypted-connections.html).
- `CRON_TIME`: The interval of cron job to run mysqldump. `0 3 * * sun` by default, which is every Sunday at 03:00. It uses UTC timezone.
- `MAX_BACKUPS`: The number of backups to keep. When reaching the limit, the old backup will be discarded. No limit by default.
- `INIT_BACKUP`: If set, create a backup when the container starts.
- `INIT_RESTORE_LATEST`: If set, restores latest backup.
- `TIMEOUT`: Wait a given number of seconds for the database to be ready and make the first backup, `10s` by default. After that time, the initial attempt for backup gives up and only the Cron job will try to make a backup.
- `GZIP_LEVEL`: Specify the level of gzip compression from 1 (quickest, least compressed) to 9 (slowest, most compressed), default is 6.
- `USE_PLAIN_SQL`: If set, back up and restore plain SQL files without gzip.
- `TZ`: Specify TIMEZONE in Container. E.g. "Europe/Berlin". Default is UTC.

If you want to make this image the perfect companion of your MySQL container, use [docker-compose](https://docs.docker.com/compose/). You can add more services that will be able to connect to the MySQL image using the name `my_mariadb`, note that you only expose the port `3306` internally to the servers and not to the host:

### Docker-compose with MYSQL_PASS env var:

```yaml
version: "2"
services:
  mariadb:
    image: mariadb
    container_name: my_mariadb
    expose:
      - 3306
    volumes:
      - data:/var/lib/mysql
      # If there is not scheme, restore the last created backup (if exists)
      - ${VOLUME_PATH}/backup/latest.${DATABASE_NAME}.sql.gz:/docker-entrypoint-initdb.d/database.sql.gz
    environment:
      - MYSQL_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}
      - MYSQL_DATABASE=${DATABASE_NAME}
    restart: unless-stopped

  mysql-cron-backup:
    image: fradelg/mysql-cron-backup
    depends_on:
      - mariadb
    volumes:
      - ${VOLUME_PATH}/backup:/backup
    environment:
      - MYSQL_HOST=my_mariadb
      - MYSQL_USER=root
      - MYSQL_PASS=${MARIADB_ROOT_PASSWORD}
      - MAX_BACKUPS=15
      - INIT_BACKUP=0
      # Every day at 03:00
      - CRON_TIME=0 3 * * *
      # Make it small
      - GZIP_LEVEL=9
    restart: unless-stopped

volumes:
  data:
```

### Docker-compose using docker secrets:

The database root password passed to docker container by using [docker secrets](https://docs.docker.com/engine/swarm/).

In example below, docker is in classic 'docker engine mode' (iow. not swarm mode) and secret source is a local file on host filesystem.

Alternatively, secret can be stored in docker secrets engine (iow. not in host filesystem).

```yaml
version: "3.7"

secrets:
  mysql_root_password:
    # Place your secret file somewhere on your host filesystem, with your password inside
    file: ./secrets/mysql_root_password

services:
  mariadb:
    image: mariadb:10
    container_name: my_mariadb
    expose:
      - 3306
    volumes:
      - data:/var/lib/mysql
      - ${VOLUME_PATH}/backup:/backup
    environment:
      - MYSQL_DATABASE=${DATABASE_NAME}
      - MYSQL_ROOT_PASSWORD_FILE=/run/secrets/mysql_root_password
    secrets:
      - mysql_root_password
    restart: unless-stopped

  backup:
    build: .
    image: fradelg/mysql-cron-backup
    depends_on:
      - mariadb
    volumes:
      - ${VOLUME_PATH}/backup:/backup
    environment:
      - MYSQL_HOST=my_mariadb
      - MYSQL_USER=root
      - MYSQL_PASS_FILE=/run/secrets/mysql_root_password
      - MAX_BACKUPS=10
      - INIT_BACKUP=1
      - CRON_TIME=0 0 * * *
    secrets:
      - mysql_root_password
    restart: unless-stopped

volumes:
  data:

```

## Restore from a backup

### List all available backups :

See the list of backups in your running docker container, just write in your favorite terminal:

```bash
docker container exec <your_mysql_backup_container_name> ls /backup
```

### Restore using a compose file

To restore a database from a certain backup you may have to specify the database name in the variable MYSQL_DATABASE:

```YAML
mysql-cron-backup:
    image: fradelg/mysql-cron-backup
    command: "/restore.sh /backup/201708060500.${DATABASE_NAME}.sql.gz"
    depends_on:
      - mariadb
    volumes:
      - ${VOLUME_PATH}/backup:/backup
    environment:
      - MYSQL_HOST=my_mariadb
      - MYSQL_USER=root
      - MYSQL_PASS=${MARIADB_ROOT_PASSWORD}
      - MYSQL_DATABASE=${DATABASE_NAME}
```
### Restore using a docker command

```bash
docker container exec <your_mysql_backup_container_name> /restore.sh /backup/<your_sql_backup_gz_file>
```

if no database name is specified, `restore.sh` will try to find the database name from the backup file.


# update
增加远程备份的功能
增加增量备份

> 配置相关的backup服务器，创建相关备份文件夹，配置对应的环境变量
cron配置如下：

```
minute   hour   day   month   week   command
# For details see man 4 crontabs
# Example of job definition:
.---------------------------------- minute (0 - 59) 表示分钟
|  .------------------------------- hour (0 - 23)   表示小时
|  |  .---------------------------- day of month (1 - 31)   表示日期
|  |  |  .------------------------- month (1 - 12) OR jan,feb,mar,apr ... 表示月份
|  |  |  |  .---------------------- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat  表示星期（0 或 7 表示星期天）
|  |  |  |  |  .------------------- username  以哪个用户来执行 
|  |  |  |  |  |            .------ command  要执行的命令，可以是系统命令，也可以是自己编写的脚本文件
|  |  |  |  |  |            |
*  *  *  *  * user-name  command to be executed
```

```
*/1 * * * * service httpd restart    每一分钟 重启httpd服务
0 */1 * * * service httpd restart    每一小时 重启httpd服务
30 21 * * * service httpd restart    每天 21：30 分 重启httpd服务
26 4 1,5,23,28 * * service httpd restart    每月的1号，5号 23 号 28 号 的4点26分，重启httpd服务
26 4 1-21 * * service httpd restart    每月的1号到21号 的4点26分，重启httpd服务
*/2 * * * * service httpd restart    每隔两分钟 执行，偶数分钟 重启httpd服务
1-59/2 * * * * service httpd restart    每隔两分钟 执行，奇数 重启httpd服务
0 23-7/1 * * * service httpd restart    每天的晚上11点到早上7点 每隔一个小时 重启httpd服务
0,30 18-23 * * * service httpd restart    每天18点到23点 每隔30分钟 重启httpd服务
0-59/30 18-23 * * * service httpd restart    每天18点到23点 每隔30分钟 重启httpd服务
59 1 1-7 4 * test 'date +\%w' -eq 0 && /root/a.sh    四月的第一个星期日 01:59 分运行脚本 /root/a.sh ，命令中的 test是判断，%w是数字的星期几
30 21 * * * /usr/local/etc/rc.d/lighttpd restart  表示每晚的21:30重启lighttpd 。
45 4 1,10,22 * * /usr/local/etc/rc.d/lighttpd restart 表示每月1、10、22日的4 : 45重启lighttpd 。
10 1 * * 6,0 /usr/local/etc/rc.d/lighttpd restart 上面的例子表示每周六、周日的1 : 10重启lighttpd 。
0,30 18-23 * * * /usr/local/etc/rc.d/lighttpd restart  上面的例子表示在每天18 : 00至23 : 00之间每隔30分钟重启lighttpd 。
0 23 * * 6 /usr/local/etc/rc.d/lighttpd restart  上面的例子表示每星期六的11 : 00 pm重启lighttpd 。
* */1 * * * /usr/local/etc/rc.d/lighttpd restart 每一小时重启lighttpd
* 23-7/1 * * * /usr/local/etc/rc.d/lighttpd restart 晚上11点到早上7点之间，每隔一小时重启lighttpd
0 11 4 * mon-wed /usr/local/etc/rc.d/lighttpd restart 每月的4号与每周一到周三的11点重启lighttpd
0 4 1 jan * /usr/local/etc/rc.d/lighttpd restart 一月一号的4点重启lighttpd
```