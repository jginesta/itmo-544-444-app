#!/bin/bash
########################################################
# This code will execute instances in EC2
# The variables needed are 7 in this order:
# ami image-id
# count
# instance-type
# security-groups-ids
# subnet
# key name
# iam-profile
# For example: ./launch.sh ami-d05e75b8 3 t2.micro itmo-spring-virtualbox sg-6e7a9708 subnet-e42819cf jessicaginesta 


###############################################

# Cleanup Script to remove old instances, databases, etc
./cleanup.sh
###sudo apt-get install php5-cli php5-mysql
declare -a InstanceArray

mapfile -t InstanceArray< <(aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --key-name $4 --security-group-ids $5 --subnet-id $6 --associate-public-ip-address --iam-instance-profile Name=$7 --user-data file://../itmo-544-444-env/install-env.sh --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g")
echo ${InstanceArray[@]}
sudo aws ec2 wait instance-running --instance-ids ${InstanceArray[@]}
echo "Instances are running successfully"

# Create a Load Balancer
LoadBalancerURL=(`aws elb create-load-balancer --load-balancer-name itmo544-jgl-lb --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --subnets $6 --security-groups $5 --output=text`); echo $LoadBalancerURL
echo -e "\nFinished launching the load balancer and sleeping for 30 seconds"
for i in {0..30}; do echo -ne '.';sleep 1;done
aws elb register-instances-with-load-balancer  --load-balancer-name itmo544-jgl-lb --instances ${InstanceArray[@]}
aws elb configure-health-check --load-balancer-name itmo544-jgl-lb --health-check Target=HTTP:80/index.html,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3
#aws elb create-lb-cookie-stickiness-policy --load-balancer-name itmo544-jgl-lb --policy-name my-duration-cookie-policy --cookie-expiration-period 60

#Creating a Launch Configuration and Autoscaling group
aws autoscaling create-launch-configuration --launch-configuration-name itmo544-launch-config-jgl --image-id $1 --key-name $4  --security-groups $5 --instance-type $3 --user-data file://../itmo-544-444-env/install-env.sh --iam-instance-profile $7
aws autoscaling create-auto-scaling-group --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --launch-configuration-name itmo544-launch-config-jgl --load-balancer-names itmo544-jgl-lb  --health-check-type ELB --min-size 3 --max-size 6 --desired-capacity 3 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier $6
aws autoscaling put-scaling-policy --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --policy-name CloudMetricsUp --scaling-adjustment 1 --adjustment-type ChangeInCapacity --cooldown 60  

#Creating a topic
ARN=(`aws sns create-topic --name mp2-alarm`); 
echo "This is the ARN for the alarm topic: $ARN"
aws sns set-topic-attributes --topic-arn $ARN --attribute-name DisplayName --attribute-value mp2
aws sns subscribe --topic-arn $ARN --protocol email --notification-endpoint jessicaginesta@hotmail.com

# Making a cloudwatch metric over 30 and under 10
aws cloudwatch put-metric-alarm --alarm-name cpugreaterthan30 --alarm-description "Alarm when CPU exceeds 30 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 30 --comparison-operator GreaterThanOrEqualToThreshold  --dimensions Name=itmo-544-extended-auto-scaling-group-2,Value=itmo-544-extended-auto-scaling-group-2 --evaluation-periods 2 --alarm-actions $ARN --unit Percent
aws cloudwatch put-metric-alarm --alarm-name cpulessthan10 --alarm-description "Alarm when CPU is less than 10 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 10 --comparison-operator LessThanOrEqualToThreshold  --dimensions Name=itmo-544-extended-auto-scaling-group-2,Value=itmo-544-extended-auto-scaling-group-2 --evaluation-periods 2 --alarm-actions $ARN --unit Percent


#Testing alarm for cloudwatch
aws cloudwatch set-alarm-state  --alarm-name cpugreaterthan30 --state-reason "initializing" --state-value OK
aws cloudwatch set-alarm-state  --alarm-name cpugreaterthan30 --state-reason "initializing" --state-value ALARM

#Creating and RDS instance
sudo aws rds create-db-subnet-group --db-subnet-group-name itmo544-mp1-sgn  --subnet-ids subnet-e42819cf subnet-140de262 --db-subnet-group-description "itmosg-jgl"

sudo aws rds create-db-instance --db-name customerrecords --db-instance-identifier mp1-jgl --db-instance-class db.t1.micro --engine MySQL --master-username controller --master-user-password letmein888 --allocated-storage 5 --vpc-security-group-ids sg-6e7a9708 --db-subnet-group-name itmo544-mp1-sgn --publicly-accessible

sudo aws rds wait db-instance-available --db-instance-identifier mp1-jgl
echo "db instance created"         

#Creating a read replica
sudo aws rds create-db-instance-read-replica --db-instance-identifier mp1-jgl-read --source-db-instance-identifier mp1-jgl --publicly-accessible
echo "read replica created"  

#Creating a table in the database
sudo php ../itmo544-444-fall2015/setup-lite.php
echo "db table created"  

echo -e "\nWaiting for 3:30 minutes for LB to create before opening in the web browser"
for i in {0..210}; do echo -ne '.';sleep 1;done

firefox $LoadBalancerURL &

echo -e "Everything worked correctly"
