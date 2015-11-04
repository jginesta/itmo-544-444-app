#!/bin/bash

mapfile -t dbInstanceARR < <(aws rds describe-db-instances --output json | grep "\"DBInstanceIdentifier" | sed "s/[\"\:\, ]//g" | sed "s/DBInstanceIdentifier//g" )
echo ${#dbInstanceARR[@]}

if [ ${#dbInstanceARR[@]} -gt 0 ]
   then
  # echo "Deleting existing RDS database-instances"
   LENGTH=${#dbInstanceARR[@]}

      for (( i=0; i<=${LENGTH}; i++));
      do
      if [[ ${dbInstanceARR[i]} == "mp1-jgl" ]] 
     then 
      echo "db exists"
     else
      sudo aws rds create-db-subnet-group --db-subnet-group-name itmo544-mp1-sgn  --subnet-ids subnet-e42819cf subnet-140de262 --db-subnet-group-description "itmosg-jgl"

      sudo aws rds create-db-instance --db-name customerrecords --db-instance-identifier mp1-jgl --db-instance-class db.t1.micro --engine MySQL --master-username controller --master-user-password letmein888 --allocated-storage 5 --vpc-security-group-ids sg-6e7a9708 --db-subnet-group-name itmo544-mp1-sgn --publicly-accessible
      fi  
      sudo aws rds wait db-instance-available --db-instance-identifier mp1-jgl
    # rds-describe-db-instances
     #$link = mysqli_connect($endpoint,"controller","letmein888","customerrecords"); 

#--subnet-ids subnet-e42819cf subnet-140de262
   
    
     done
fi
sudo apt-get install php5-cli php5-mysql
sudo php ../itmo544-444-fall2015/setup-lite.php
