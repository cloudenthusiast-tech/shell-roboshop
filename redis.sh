#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"
LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"


echo "script_start_time=$(date +%s)"
mkdir -p $LOGS_FOLDER
echo "script executed in: $(date)"

if [ $USERID -ne 0 ]; then
   echo -e " $R error:: please run with root user previliges $N"
   exit 1  # will exit from the script execution if encountered error
fi

VALIDATE(){
  if [ $1 -ne 0 ]; then
   echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
   exit 1
  else
   echo -e " $2 ..... $G  SUCCESS $N"  | tee -a $LOG_FILE
fi
}


dnf module disable redis -y  &>>$LOG_FILE
VALIDATE $? "disabling default redis version"
dnf module enable redis:7 -y  &>>$LOG_FILE
VALIDATE $? "disabling  redis version:7"

dnf install redis -y  &>>$LOG_FILE
VALIDATE $? "installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g'   -e '/protected-mode/ c protected-mode no'  /etc/redis/redis.conf   # -e take extra arguments , -i permanent the changes

systemctl enable redis 
VALIDATE $? "enabling redis"
systemctl start redis 
VALIDATE $? "start redis"
