#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"
LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MYSQL_HOST=mysql.kolanu.space
SCRIPT_DIR=$PWD

START_TIME=$(date +%s)
mkdir -p $LOGS_FOLDER
echo "script executed at: $(date)"

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

dnf install python3 gcc python3-devel -y  &>>$LOG_FILE
VALIDATE $? "installing python"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
echo "user already exist"
fi


mkdir  -p /app 
VALIDATE $? "create new dir /app"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip    &>>$LOG_FILE
VALIDATE $? "download payment code"

cd /app
VALIDATE $? "change to /app dir" 

unzip  -o /tmp/payment.zip   &>>$LOG_FILE
VALIDATE $? "unzip code at app dir from tmp dir"

cd /app 
VALIDATE $? "change to /app dir"

pip3 install -r requirements.txt   &>>$LOG_FILE
VALIDATE $? "install dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload
systemctl enable payment 
systemctl start payment
VALIDATE $? "start payment"

END_TIME=$(date +%s)
TOTAL_SCRIPT_TIME=$(($END_TIME-$START_TIME))
echo -e "script executed in:$G $TOTAL_SCRIPT_TIME seconds"