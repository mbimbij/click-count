#! /bin/bash

# making the application working directory and configuration at the same time
mkdir -p /opt/application/conf

# deleting old files just in case
rm -rf /etc/systemd/system/application.service
rm -rf /opt/application/application.jar
rm -rf /opt/application/conf/application-server.yml
