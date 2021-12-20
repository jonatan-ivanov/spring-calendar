#! /bin/bash

yum update -y
amazon-linux-extras enable corretto8
yum install -y git java-1.8.0-amazon-corretto-devel
git --version
java -version

useradd -g users spring-calendar
id spring-calendar

git clone https://github.com/spring-io/spring-calendar.git
cd spring-calendar || return
./gradlew assemble

mkdir /opt/spring-calendar
cp build/libs/spring-calendar.jar /opt/spring-calendar

cat > /opt/spring-calendar/spring-calendar.service <<EOF
[Unit]
Description=Spring Calendar Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=spring-calendar
Group=users
WorkingDirectory=/opt/spring-calendar
# StandardOutput=append:/var/log/spring-calendar.log
# StandardError=append:/var/log/spring-calendar.log
ExecStart=/usr/bin/java -Dspring.profiles.active=aws -jar spring-calendar.jar
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat > /opt/spring-calendar/application-aws.properties <<EOF
calendar.github.username=user
calendar.github.password=secret
EOF

chown -R spring-calendar /opt/spring-calendar
chmod 755 /opt/spring-calendar
chmod 440 /opt/spring-calendar/spring-calendar.service
chmod 550 /opt/spring-calendar/spring-calendar.jar
chmod 440 /opt/spring-calendar/application-aws.properties

# only root can open low ports like 80
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

ln -s /opt/spring-calendar/spring-calendar.service /lib/systemd/system/spring-calendar.service
systemctl daemon-reload
systemctl enable spring-calendar
systemctl start spring-calendar

# logs: journalctl -fu spring-calendar.service
