#!/bin/bash
# This script clones the Zeppelin config directory from an S3 Bucket which contains the nessecary secrets.
# The AWS ID & Secrets and bucket name are required to be passed in at run time as Environmental Variables to clone the bucket contents down to the zeppelin/conf folder.

function add_aws_to_spark_env {
  echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" >> /usr/spark-2.0.2/conf/spark-env.sh
  echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" >> /usr/spark-2.0.2/conf/spark-env.sh
  aws s3 sync s3://${ZEPPELIN_CONF_S3_BUCKET}/spark ${SPARK_HOME}/conf
}

if [ "$1" = "zeppelin" ] ; then
  if [[ -n ${AWS_SECRET_ACCESS_KEY} ]] && [[ -n ${AWS_ACCESS_KEY_ID} ]] && [[ -n ${ZEPPELIN_CONF_S3_BUCKET} ]]; then
    echo "Cloning zeppelin config directory from S3..."
    aws s3 sync s3://${ZEPPELIN_CONF_S3_BUCKET} ${ZEPPELIN_HOME}/conf
  else
    echo "AWS Config clone not occuring, using default configuration."
    echo "The following Environmental Variables need to be set: AWS_SECRET_ACCESS_KEY, AWS_ACCESS_KEY_ID and ZEPPELIN_CONF_S3_BUCKET"
  fi
  add_aws_to_spark_env
  echo "Starting up Zeppelin..."
  (${ZEPPELIN_HOME}/bin/zeppelin.sh)
fi
if [ "$1" = "spark-master" ] ; then
  add_aws_to_spark_env
  echo "Starting up Spark Master..."
  ($SPARK_HOME/bin/spark-class org.apache.spark.deploy.master.Master)
fi
if [ "$1" = "spark-worker" ] ; then
  add_aws_to_spark_env
  echo "Starting up Spark Worker..."
  ($SPARK_HOME/bin/spark-class org.apache.spark.deploy.worker.Worker spark://sparkmaster:7077)
fi
