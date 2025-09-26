#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"
LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=mongodb.kolanu.space
SCRIPT_DIR=$PWD
echo "script_executed_time=$(date +%F)"
mkdir -p $LOGS_FOLDER
echo "script executed in: $(date)"

if [ $USERID -ne 0 ]; then
   echo -e " $R error:: please run with root user previliges $N"
   exit 1  # will exit from the script execution if encountered error
fi



dnf module disable nodejs -y  &>>$LOG_FILE

dnf module enable nodejs:20 -y  &>>$LOG_FILE

dnf install nodejs -y  &>>$LOG_FILE

id roboshop
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
   echo -e "user already exist .... $Y SKIPPING $N"
fi

mkdir  -p /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip   &>>$LOG_FILE

cd /app

unzip  -o /tmp/catalogue.zip   &>>$LOG_FILE

npm install   &>>$LOG_FILE

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload
systemctl enable catalogue 


cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongodb.repo

dnf install mongodb-mongosh -y  &>>$LOG_FILE

INDEX=$(mongosh $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")   # check if db already exist or not 
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi
systemctl restart catalogue
