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

dnf module disable nginx -y  &>>$LOG_FILE
dnf module enable nginx:1.24 -y  &>>$LOG_FILE
dnf install nginx -y   &>>$LOG_FILE

systemctl enable nginx 
systemctl start nginx 

rm -rf /usr/share/nginx/html/*   &>>$LOG_FILE

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip  &>>$LOG_FILE

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip  &>>$LOG_FILE

cp $SCRIPT_DIR/nginx.conf  /etc/nginx/nginx.conf
systemctl daemon-reload
systemctl restart nginx 

END_TIME=$(date +%s)
TOTAL_SCRIPT_TIME=$(($END_TIME-$START_TIME))
echo -e "script executed in:$G $TOTAL_SCRIPT_TIME seconds"