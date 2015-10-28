#!/bin/bash


mapfile -t dbInstanceARR < <(aws rds describe-db-instances --output json | grep "\"DBInstanceIdentifier" | sed "s/[\"\:\, ]//g" | sed "s/DBInstanceIdentifier//g" )

if [ ${#dbInstanceARR[@]} -gt 0 ]
   then
   echo "Deleting existing RDS database-instances"
   LENGTH=${#dbInstanceARR[@]}

      for (( i=0; i<${LENGTH}; i++));
      do
      if [ ${dbInstanceARR[i]} == "jrh-db" ] 
     then 
      echo "db exists"
     else
     aws rds create-db-instance --db-name customerrecords --db-instance-identifier mp1-jgl --db-instance-class db.t1.micro --engine MySQL --master-username controller --master-user-password letmein888 --allocated-storage 5 --vpc-security-group-ids sg-6e7a9708 --db-subnet-group-name default-vpc-58cc1f3c 
#--subnet-ids subnet-e42819cf subnet-140de262
      fi  
     done
fi


