#!/bin/bash
#sudo apt-get update -y

#sudo apt-get -y install apache2 git php5 php5-curl mysql-client curl php5-mysql

#sudo curl -sS https://getcomposer.org/installer | sudo php
# &> /tmp/getcomposer.txt

#sudo php composer.phar require aws/aws-sdk-php 
#&> /tmp/runcomposer.txt


ARN=(`aws sns create-topic --name mp2`); 

echo "This is the ARN: $ARN"

aws sns set-topic-attributes --topic-arn $ARN --attribute-name DisplayName --attribute-value mp2

aws sns subscribe --topic-arn $ARN --protocol email --notification-endpoint jginesta@hawk.iit.edu


php ../itmo544-444-fall2015/MP2.php
