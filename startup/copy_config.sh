#!/bin/bash
# This script copies the default contents of the /config folder to the
# persistent volume for later use
# This script is only used in a kubernetes job, not the production container

cp ${ZEPPELIN_HOME}/conf/* /tmp/conf/
