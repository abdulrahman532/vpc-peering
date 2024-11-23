#!/bin/bash
set -x -e

		   
# Create the VPC peering & accept the request
peerVPCID=$(aws ec2 create-vpc-peering-connection --vpc-id "$pubVPCID" --peer-vpc-id "$pvtVPCID" --query VpcPeeringConnection.VpcPeeringConnectionId --output text)
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id "$peerVPCID"
aws ec2 create-tags --resources "$peerVPCID" --tags 'Key=Name,Value=peer-VPC'

#### Adding the private VPC CIDR block to our public VPC route table as destination
aws ec2 create-route --route-table-id "$routeTableID" --destination-cidr-block 10.0.2.0/25 --vpc-peering-connection-id "$peerVPCID"
pvtRouteTableID=$(aws ec2 create-route-table --vpc-id "$pvtVPCID" --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id "$pvtRouteTableID" --destination-cidr-block 10.0.1.0/25 --vpc-peering-connection-id "$peerVPCID"
aws ec2 associate-route-table --route-table-id "$pvtRouteTableID" --subnet-id "$pvtVPC_Subnet01ID"

### Add a rule that allows inbound SSH (from our Public Instanes source)
aws ec2 authorize-security-group-ingress --group-id "$pvtSecGrpID" --protocol tcp --port 22 --cidr 10.0.1.0/24
