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
# For example: ./launch.sh ami-d05e75b8 2 t2.micro sg-6e7a9708 subnet-2fdbc658 itmo-spring-virtualbox 


###############################################
aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --key-name $6 --security-group-ids $4 --subnet-id $5 --associate-public-ip-address --user-data file://../itmo-544-444-env/install-env.sh --debug



