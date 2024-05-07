This Terraform script is used to create 3 AWS instances and one Load balancer
The AWS instances will be located in one Availability Zone ( i.e you can customize them to make 4 instances , 2 in two different subnets)
The script includes the following:
1. Create VPC
2. Create two subnets in this VPC
3. Create AWS EC2 instances in one subnet 
4. Create Security Groups (Allow SSH, HTTP and HTTPS) and attach to Network interfaces of the EC2 instances
5. Create Routing table and Internet Gateway to allow access to the internet for the subnets.
6. Create Application Load Balancer ( should use two Subnets in two different Availability Zones, this is why I created two subnets in this example while I'm only using one for the instances).
7. Load Balancer requires target groups, target group association and Listener.
