#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"
LOGS_FOLDER="/var/log/shell-script"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1 )   # cut -d .- basically cut whatever comes after script-name.  ex:mongodb.sh
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"   # /var/log/shell-script/mongodb.log
SCRIPT_DIR=$PWD

start_time=$(date +%s)
mkdir -p $LOGS_FOLDER
echo "script executed at: $(date)"

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

cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongodb.repo
VALIDATE $? "Adding mongo repo"

dnf install mongodb-org -y  &>>$LOG_FILE
VALIDATE $? "Installing mongodb"

systemctl enable mongod 
VALIDATE $? "Enabling monodb"

systemctl start mongod 
VALIDATE $? "start mongodb"


sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "allowing remote connections to mongodb"

systemctl restart mongod
VALIDATE $? "restart mongod"

END_TIME=$(date +%s)
TOTAL_SCRIPT_TIME=$(($END_TIME-$START_TIME))
echo -e "script executed in:$G $TOTAL_SCRIPT_TIME seconds "