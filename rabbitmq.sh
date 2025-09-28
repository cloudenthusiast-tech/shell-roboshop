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


cp $SCRIPT_DIR/rabbitmq.repo  /etc/yum.repos.d/rabbitmq.repo  &>>$LOG_FILE


dnf install rabbitmq-server -y  &>>$LOG_FILE
VALIDATE $? "installing rabbitmq-server"

systemctl enable rabbitmq-server  &>>$LOG_FILE
VALIDATE $? "enabling rabbitmq-server"
systemctl start rabbitmq-server  &>>$LOG_FILE
VALIDATE $? "starting rabbitmq-server"


rabbitmqctl add_user roboshop roboshop123  &>>$LOG_FILE
VALIDATE $? "adding system user for rabbitmq-server"
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"  &>>$LOG_FILE
VALIDATE $? "setting permissions for rabbitmq-server"

END_TIME=$(date +%s)
TOTAL_SCRIPT_TIME=$(($END_TIME-$START_TIME))
echo -e "script executed in:$G $TOTAL_SCRIPT_TIME seconds "