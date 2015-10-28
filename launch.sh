#!/bin/bash
########################################################
# This code will execute instances in EC2
# The variables needed are in this order:
# ami image-id
# count
# instance-type
# security-groups-ids
# subnet
# key name
# load balancer name
# For example: ./launch.sh ami-d05e75b8 3 t2.micro itmo-spring-virtualbox sg-6e7a9708 subnet-e42819cf jessicaginesta 


###############################################
./cleanup.sh
declare -a InstanceArray

mapfile -t InstanceArray< <(aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --key-name $4 --security-group-ids $5 --subnet-id $6 --associate-public-ip-address --iam-instance-profile Name=$7 --user-data file://../itmo-544-444-env/install-env.sh --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g")

echo ${InstanceArray[@]}
aws ec2 wait instance-running --instance-ids ${InstanceArray[@]}
echo "Instances are running successfully"

LoadBalancerURL=(`aws elb create-load-balancer --load-balancer-name itmo544-jgl-lb --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --subnets $6 --security-groups $5 --output=text`); echo $LoadBalancerURL

echo -e "\nFinished launching the load balancer and sleeping for 30 seconds"
for i in {0..30}; do echo -ne '.';sleep 1;done

aws elb register-instances-with-load-balancer  --load-balancer-name itmo544-jgl-lb --instances ${InstanceArray[@]}

aws elb configure-health-check --load-balancer-name itmo544-jgl-lb --health-check Target=HTTP:80/index.html,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3

echo -e "\nWaiting for 3:30 minutes for LB to create before opening in the web browser"
for i in {0..210}; do echo -ne '.';sleep 1;done

#aws elb create-lb-cookie-stickiness-policy --load-balancer-name itmo544-jgl-lb --policy-name my-duration-cookie-policy --cookie-expiration-period 60

#Creating a launch configuration
aws autoscaling create-launch-configuration --launch-configuration-name itmo544-launch-config-jgl --image-id $1 --key-name $4  --security-groups $5 --instance-type $3 --user-data file://../itmo-544-444-env/install-env.sh --iam-instance-profile $7

aws autoscaling create-auto-scaling-group --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --launch-configuration-name itmo544-launch-config-jgl --load-balancer-names itmo544-jgl-lb  --health-check-type ELB --min-size 3 --max-size 6 --desired-capacity 3 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier $6
aws autoscaling put-scaling-policy --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --policy-name CloudMetricsUp --scaling-adjustment 1 --adjustment-type ChangeInCapacity --cooldown 60  

aws cloudwatch put-metric-alarm --alarm-name cpugreaterthan30 --alarm-description "Alarm when CPU exceeds 30 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 30 --comparison-operator GreaterThanOrEqualToThreshold  --dimensions Name=itmo-544-extended-auto-scaling-group-2,Value=itmo-544-extended-auto-scaling-group-2 --evaluation-periods 2 --alarm-actions arn:aws:sns:us-east-1:111122223333:MyTopic --unit Percent
aws cloudwatch put-metric-alarm --alarm-name cpulessthan10 --alarm-description "Alarm when CPU is less than 10 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 30 --comparison-operator LessThanOrEqualToThreshold  --dimensions Name=itmo-544-extended-auto-scaling-group-2,Value=itmo-544-extended-auto-scaling-group-2 --evaluation-periods 2 --alarm-actions arn:aws:sns:us-east-1:111122223333:MyTopic --unit Percent

firefox $LoadBalancerURL &
export LoadBalancerURL
./launch-rds.sh


