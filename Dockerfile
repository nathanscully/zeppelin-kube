# AUTHOR: Nathan SCULLY
# DESCRIPTION: Docker image to run Zeppelin to be used with an external spark cluster and run on Kubernetes
# BUILD: docker build --rm -t nathanscully/zeppelin-kube
# SOURCE: https://github.com/nathanscully/zeppelin-kube

# Base image from spark
FROM gettyimages/spark:2.0.2-hadoop-2.7
MAINTAINER Nathan SCULLY <nathan@oneflare.com>

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Deps
RUN set -ex \
    && buildDeps='git build-essential pkg-config libglib2.0-0 libxext6 libsm6 libxrender1 libpq-dev gcc' \
    && apt-get update -yqq \
    && apt-get remove --purge -yqq python3 python3-setuptools \
    && apt-get clean \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        apt-transport-https \
        apt-utils \
        bzip2 \
        ca-certificates \
        curl \
        libfontconfig \
        telnet \
        vim \
        wget \
    && echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh \
    && wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.1.11-Linux-x86_64.sh -O ~/miniconda.sh \
    && /bin/bash ~/miniconda.sh -b -p /opt/conda \
    && rm ~/miniconda.sh \
    && wget --quiet http://www.eu.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz \
    && tar -zxf apache-maven-3.3.9-bin.tar.gz -C /usr/local/ \
    && ln -s /usr/local/apache-maven-3.3.9/bin/mvn /usr/local/bin/mvn \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*



ENV PATH /opt/conda/bin:$PATH
ENV ZEPPELIN_PORT 8080
ENV ZEPPELIN_HOME /usr/zeppelin
ENV ZEPPELIN_CONF_DIR $ZEPPELIN_HOME/conf
ENV ZEPPELIN_NOTEBOOK_DIR $ZEPPELIN_HOME/notebook
ENV MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=1024m"

# 1. Install python dependencies. Mix of conda and pip due to conda not having everything.
# 2. Zeppelin (we need the bowerrc line due to Docker running things as root)
# 3. Cleanup
RUN condaDeps='cython scipy scikit-learn scikit-image pandas matplotlib nltk psycopg2 pytz simplejson sqlalchemy boto gensim' \
    && conda install -q nomkl \
    && conda install -q $condaDeps -y \
    && pip install -q --upgrade pip \
    && pip install -q --ignore-installed setuptools \
    && pipDeps='abba tensorflow progressbar2 sqlalchemy-redshift statsmodels awscli' \
    && pip install -q --upgrade $pipDeps \
    && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get update  -yqq \
    && apt-get install -yqq --no-install-recommends nodejs \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends yarn \
    && git clone https://github.com/apache/zeppelin.git /usr/src/zeppelin \
    && cd /usr/src/zeppelin \
    && dev/change_scala_version.sh "2.11" \
    && mkdir -m 777 zeppelin-web/bower_components \
    && echo '{ "allow_root": true }' > /root/.bowerrc \
    && cd /usr/src/zeppelin \
    && mvn -e -Pbuild-distr --batch-mode package -DskipTests -Pscala-2.11 -Ppyspark -Phadoop-2.7 -pl 'angular,jdbc,markdown,python,shell,spark,spark-dependencies,zeppelin-display,zeppelin-distribution,zeppelin-interpreter,zeppelin-server,zeppelin-web,zeppelin-zengine' \
    && tar xvf /usr/src/zeppelin/zeppelin-distribution/target/zeppelin*.tar.gz -C /usr/ \
    && mv /usr/zeppelin* $ZEPPELIN_HOME \
    && mkdir -p $ZEPPELIN_HOME/logs \
    && mkdir -p $ZEPPELIN_HOME/run \
    && cd /usr \
    && conda clean --tarballs --source-cache --index-cache -y \
    && apt-get autoremove  -yqq \
    && apt-get remove --purge -yqq $buildDeps yarn nodejs npm \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base \
        /root/.m2 \
        /root/.npm \
        /root/.cache \
        /usr/src/zeppelin

WORKDIR $ZEPPELIN_HOME
COPY startup/entrypoint.sh .
RUN chmod +x "./entrypoint.sh"
ENTRYPOINT ["./entrypoint.sh"]
