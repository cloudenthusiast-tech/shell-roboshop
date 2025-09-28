#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"
LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
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
   echo -e "$2 ... $R FAILURE $N" 
   exit 1
  else
   echo -e "$2 ..... $G  SUCCESS $N"  
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

mkdir  -p /app 
VALIDATE $? "create new dir /app"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip    &>>$LOG_FILE
VALIDATE $? "download cart code"

cd /app
VALIDATE $? "change to /app dir" 

unzip -o /tmp/cart.zip   &>>$LOG_FILE
VALIDATE $? "unzip code at /app dir from /tmp dir"

npm install   &>>$LOG_FILE
VALIDATE $? "install dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "copied systemctl service"

systemctl daemon-reload
VALIDATE $? "reload systemd process"
systemctl enable cart  &>>$LOG_FILE
VALIDATE $? "enable cart"
systemctl restart cart
VALIDATE $? "restart cart"

END_TIME=$(date +%s)
TOTAL_SCRIPT_TIME=$(($END_TIME-$START_TIME))
echo -e "script executed in:$G $TOTAL_SCRIPT_TIME seconds"