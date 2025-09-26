#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"
LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

SCRIPT_START_TIME=$(date +%s)
script_start_time=$(date +%s)
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


dnf install mysql-server -y  &>>$LOG_FILE
VALIDATE $? "installing mysql"

systemctl enable mysqld  &>>$LOG_FILE
VALIDATE $? "enabling mysqld"
systemctl start mysqld  
VALIDATE $? "starting mysql"   &>>$LOG_FILE


password_set_up=$(mysql_secure_installation --set-root-pass RoboShop@1)  &>>$LOG_FILE
if [ $? -ne 0 ]; then
 echo "mysql root password setup is $R .... FAILURE $N"
 else
  echo "mysql root password setup is $R ....  SUCCESS $N"
  fi
VALIDATE $? "setting mysql root password mysql"


SCRIPT_END_TIME=$(date +%s)
TOTAL_SCRIPT_TIME=$(($SCRIPT_END_TIME-$SCRIPT_START_TIME))
echo -e "script executed in:$G $TOTAL_SCRIPT_TIME seconds "