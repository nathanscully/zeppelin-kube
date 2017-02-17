kops create cluster \
  --cloud=aws \
  --zones=ap-southeast-2b,ap-southeast-2c \
  --master-zones=ap-southeast-2b \
  --node-count=2 \
  --node-size=r4.xlarge \
  --master-size=t2.micro \
  --vpc=vpc-dbd607bf \
  --network-cidr=10.6.0.0/16 \
  --associate-public-ip=false \
  --admin-access=59.100.238.210/32 \
  --networking=weave \
  --topology=private \
  ${NAME}
