#!/bin/bash
# This script clones the Zeppelin config directory from an S3 Bucket which contains the nessecary secrets.
# The AWS ID & Secrets and bucket name are required to be passed in at run time as Environmental Variables to clone the bucket contents down to the zeppelin/conf folder.


if [[ -n ${AWS_SECRET_ACCESS_KEY} ]] && [[ -n ${AWS_ACCESS_KEY_ID} ]] && [[ -n ${ZEPPELIN_CONF_S3_BUCKET} ]]; then
  echo "Cloning zeppelin config directory from S3..."
  aws s3 sync s3://${ZEPPELIN_CONF_S3_BUCKET} ${ZEPPELIN_HOME}/conf
else
  echo "AWS Config clone not occuring, using default configuration."
  echo "The following Environmental Variables need to be set: AWS_SECRET_ACCESS_KEY, AWS_ACCESS_KEY_ID and ZEPPELIN_CONF_S3_BUCKET"
fi

echo "Starting up Zeppelin..."
(${ZEPPELIN_HOME}/bin/zeppelin.sh)
