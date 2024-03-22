#!/bin/bash

# Pfad zur Logdatei festlegen
log="/var/www/html/docker_service.log"

# Funktion zum Schreiben von Logs
log_message() {
    echo "$(date +%FT%T) $1" >>"$log"
}

# Signalbehandler
trap 'on_exit' SIGTERM
trap 'on_interrupt' SIGINT

on_interrupt() {
    log_message "Signal INT erhalten"
    ps -ef >>"$log"
}

on_exit() {
    log_message "Herunterfahren gestartet"

    # Prozess-IDs lesen
    read -r apache_pid <"/run/apache2/apache2.pid"
    read -r redis_pid <"/var/run/redis/redis-server.pid"
    read -r mariadb_pid <"/var/run/mysqld/mysqld.pid"
    read -r sshd_pid <"/var/run/sshd.pid"

    # Dienste stoppen
    service ssh stop
    apachectl stop
    if [ -f "/var/run/mysqld/mysqld.pid" ]; then
        service mariadb stop
        rm "/var/run/mysqld/mysqld.pid"
    fi
    kill "$redis_pid" 2>/dev/null

    # Auf Beendigung der Prozesse warten
    for pid in $sshd_pid $apache_pid $redis_pid $mariadb_pid; do
        if [ -n "$pid" ]; then
            wait "$pid" 2>/dev/null
        fi
    done

    log_message "Alle Dienste wurden gestoppt"
    exit
}

# Dienste starten
log_message "Dienste werden gestartet"
service ssh start
apachectl start
service mariadb start

# Redis spezifische Vorbereitung und Start
mkdir -p /var/run/redis
chown redis:redis /var/run/redis
sudo -u redis redis-server /etc/redis/redis.conf &

sleep 1
ps -ef >>"$log"

# Regelmäßige Statusmeldungen
while true; do
    log_message "Ping"
    sleep 60
done
ghassan
