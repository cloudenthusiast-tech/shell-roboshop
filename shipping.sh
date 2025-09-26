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
MYSQL_HOST=mysql.kolanu.space


mkdir -p $LOGS_FOLDER
echo "script executed in: $(date)"

if [ $USERID -ne 0 ]; then
   echo -e " $R error:: please run with root user previliges $N"
   exit 1  # will exit from the script execution if encountered error
fi

VALIDATE(){
  if [ $1 -ne 0 ]; then
   echo -e "$2 ... $R FAILURE $N" 
   exit 1
  else
   echo -e " $2 ..... $G  SUCCESS $N"  
fi
}

dnf install maven -y  &>>$LOG_FILE
VALIDATE $? "installing maven"

id roboshop
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
else
echo "user already exist"
fi
VALIDATE $? "checking user exists or not"

mkdir  -p /app 
VALIDATE $? "create new dir  /app"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip    &>>$LOG_FILE
VALIDATE $? "download shipping code"

cd /app
VALIDATE $? "change to app dir" 

unzip  -o /tmp/shipping.zip   &>>$LOG_FILE
VALIDATE $? "unzip code at app dir from tmp dir"

cd /app 
VALIDATE $? "change to /app dir"
mvn clean package   &>>$LOG_FILE
VALIDATE $? "install dependencies"
mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "moving target folder file to root"

cp shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "copying systemd service"

systemctl daemon-reload
VALIDATE $? "daemon reload"

systemctl enable shipping 
systemctl start shipping
VALIDATE $? "starting and enabling the shipping service"


dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "installing mysql"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]; then
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql  &>>$LOG_FILE
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
fi

systemctl restart shipping
VALIDATE $? "restarting shipping"


SCRIPT_END_TIME=$(date +%s)
TOTAL_SCRIPT_TIME=$(($SCRIPT_END_TIME-$SCRIPT_START_TIME))
echo -e "script executed in:$G $TOTAL_SCRIPT_TIME seconds"