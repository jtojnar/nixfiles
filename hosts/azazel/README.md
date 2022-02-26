# azazel

This is my VPS on [vpsfree.cz](https://vpsfree.cz). It is hosting various web services for me and my family, as well as few web sites from the past.

## Installation

Provision a new VPS on [vpsfree.cz](https://vpsfree.cz), add SSH key, set up DNS record `azazel.ogion.cz` to point, and run `deploy azazel switch`.

## Backing up

1. Download websites `rsync --archive --checksum --verbose --partial --progress root@ogion.cz:/var/www`
2. On server, export PostgreSQL database `sudo -u postgres pg_dumpall | gzip > postgres.sql.gz`
3. On server, export MySQL database `mysqldump -u root -p --all-databases --extended-insert --add-drop-database --disable-keys --flush-privileges --quick --routines --triggers | gzip > mysql.sql.gz`
4. Download the SQL backups `scp root@ogion.cz:{postgres,mysql}.sql.gz .`

### Restoring

1. Back up the PostgreSQL data `cp -a /var/lib/postgresql /var/lib/postgresql.bak`
2. Back up the MySQL data `cp -a /var/lib/mysql/mysql /var/lib/mysql/mysql.bak`
3. Restore the PostgreSQL back-up `cat postgres.sql.gz | gunzip | psql -f - postgres`
4. Restore the MySQL back-up `cat mysql.sql.gz | gunzip | mysql -uroot`
