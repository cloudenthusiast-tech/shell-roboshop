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

START_TIME=$(date +%s)
mkdir -p $LOGS_FOLDER
echo "script executed at:$(date)"

if [ $USERID -ne 0 ]; then
   echo -e " $R error:: please run with root user previliges $N"
   exit 1  # will exit from the script execution if encountered error
fi

VALIDATE(){
  if [ $1 -ne 0 ]; then
   echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
   exit 1
  else
   echo -e "$2 ..... $G  SUCCESS $N"  | tee -a $LOG_FILE
fi
}

dnf module disable nodejs -y  &>>$LOG_FILE
VALIDATE $? "disable default module of nodejs"

dnf module enable nodejs:20 -y  &>>$LOG_FILE
VALIDATE $? "enabling module 20 for nodejs"

dnf install nodejs -y  &>>$LOG_FILE
VALIDATE $? "installing nodejs"

id roboshop
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "creating system user"
else
   echo -e "user already exist .... $Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "create new dir  /app"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip   &>>$LOG_FILE
VALIDATE $? "download catalogue code"

cd /app
VALIDATE $? "change to /app dir" 

unzip  -o /tmp/catalogue.zip   &>>$LOG_FILE
VALIDATE $? "unzip code at app dir from tmp dir"

npm install   &>>$LOG_FILE
VALIDATE $? "install dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copied systemctl service"

systemctl daemon-reload
systemctl enable catalogue 
VALIDATE $? "enable catalogue"


cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongodb.repo
VALIDATE $? "adding mongo repo"

dnf install mongodb-mongosh -y  &>>$LOG_FILE
VALIDATE $? "installing mongo client"

INDEX=$(mongosh $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")   # check if db already exist or not 
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi
systemctl restart catalogue
VALIDATE $? "restart catalogue"

END_TIME=$(date +%s)
TOTAL_SCRIPT_TIME=$(($END_TIME-$START_TIME))
echo -e "script executed in:$G $TOTAL_SCRIPT_TIME seconds "