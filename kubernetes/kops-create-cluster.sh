kops create cluster \
  --cloud=aws \
  --zones=ap-southeast-2b,ap-southeast-2c \
  --master-zones=ap-southeast-2b \
  --node-count=2 \
  --node-size=m4.large \
  --master-size=t2.micro \
  --vpc=vpc-dbd607bf \
  --network-cidr=10.6.0.0/16 \
  ${NAME}
