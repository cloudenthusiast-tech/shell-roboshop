#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0"

LOG_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

START_TIME=$(date +%s)

mkdir -p $SCRIPT_NAME

if [ $USERID -ne 0 ]; then
 echo -e " $R ERROR:: please run script with root previlages...  $N"
 exit 1
 fi

mkdir -p $SCRIPT_NAME

VALIDATE(){
    if [ $1 -ne 0 ]; then
    echo -e "$2 ... $R FAILURE $N"  | tee -a $LOG_FILE
    else
    echo -e "$2 .... $G SUCCESS $N"  |  tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y  &>>$LOG_FILE
VALIDATE $? "disabling default nodejs"

dnf module enable nodejs:20 -y  &>>$LOG_FILE
VALIDATE $? "enabling nodejs:20"

dnf install nodejs -y   &>>$LOG_FILE
VALIDATE $? "installing nodejs"

id roboshop  &>>$LOG_FILE
if [ $? -ne 0 ]; then
 useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>>$LOG_FILE
  VALIDATE "$?" "creating system user"
else
  echo -e "user alreday exist ... $Y SKIPPING  $N"
  fi

mkdir -p /app 
VALIDATE $? "create /app dir"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip   &>>$LOG_FILE
VALIDATE $? "download cart application to /tmp"

cd /app 
VALIDATE $? "cd to /app dir"

rm -rf /app/*
VALIDATE $? "removing existing code"

unzip /tmp/cart.zip  &>>$LOG_FILE
VALIDATE $? "unzip cart application from /tpm to /app dir"

cd /app 
VALIDATE $? "cd to /app dir"

npm install   &>>$LOG_FILE
VALIDATE $? "install dependencies"

cp $SCRIPT_DIR/cart.service  /etc/systemd/system/cart.service
VALIDATE $? " copy systemd service"

systemctl daemon-reload

systemctl enable cart 
VALIDATE $? "Enable cart"

systemctl restart cart
VALIDATE $? "restart cart"

END_TIME=$(date +%s)
TOTAL_SCRIPT_TIME=$(($END_TIME-$START_TIME))
echo "Script executed in $TOTAL_SCRIPT_TIME seconds"