# Zeppelin Kube

A config file and accompanying docker image to run a Standalone Spark cluster (2.0.2) with Zeppelin.


## Credit

Images based off:
- https://github.com/kubernetes/kubernetes/tree/master/examples/spark
- https://github.com/dylanmei/docker-zeppelin

## Goal

The kubernetes enviornment should consist of a Standalone spark cluster (in its own pod) with a single worker. More workers can be added in future, or separated out to their own pod. Additionally Zeppelin should be run in its own pod with the ability to communicate to the Spark Master.

The Zeppelin image should be based off the master branch of Zeppelin (https://github.com/apache/zeppelin). Python dependencies and libraries are handled by a mix of Conda[http://conda.pydata.org/docs/intro.html] and pip (where Conda does not provide the library).

## Build dependencies

The current spark image used is: https://hub.docker.com/r/gettyimages/spark/

We are using tag: **gettyimages/spark:2.0.2-hadoop-2.7**

This adds the required Spark and Hadoop libraries for the Zeppelin image and keeps consistency between Spark and Zeppelin in the Kubernetes deployment.

## Building

There is a CircleCI build file that will compile the docker image and ensure Zeppelin boots. By default Zeppelin will use default configuration (including using local spark).

## Running

Start up the cluster by running:

    $ kubectl create -f spark-cluster.yaml

Note, by default, if no additional configuration is added (see below) the Spark instances will not be used by Zeppelin.


## Configuration

At run time the zeppelin-kube docker image supports passing in AWS credentials to clone down configuration for zeppelin and syncs the files into the *$ZEPPELIN_HOME/conf* directory. If these are not passed, Zeppelin uses default config.

The following Environmental Variables need to be set: AWS_SECRET_ACCESS_KEY, AWS_ACCESS_KEY_ID and ZEPPELIN_CONF_S3_BUCKET". E.g.

    docker run -d -p 8080:8080 -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e ZEPPELIN_CONF_S3_BUCKET=$ZEPPELIN_CONF_S3_BUCKET nathanscully/zeppelin-kube

The *ZEPPELIN_CONF_S3_BUCKET* references a bucket on S3 which contains any Zeppelin configuration files you wish to override. E.g. Adding in a custom *interpreter.json* or *shiro.ini* file.

For the Kubernetes deployment, these are exposed through Secrets. E.g.:

    env:
      - name: AWS_SECRET_ACCESS_KEY
        valueFrom:
          secretKeyRef:
            name: zeppelin-deploy-secrets
            key: AWS_SECRET_ACCESS_KEY

These secrets can be added by creating a file like this (be sure to replace the actual values with a base64 encoded string):

    apiVersion: v1
    kind: Secret
    metadata:
      name: zeppelin-deploy-secrets
    type: Opaque
    data:
      AWS_SECRET_ACCESS_KEY: ${mysecret | base64}
      AWS_ACCESS_KEY_ID: ${mykey | base64}
      ZEPPELIN_CONF_S3_BUCKET: ${conf_bucket | base64}

Then running:

    $ kubectl create -f zeppelin-deploy-secrets.yaml
    
For great profit
