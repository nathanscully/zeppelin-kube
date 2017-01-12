# AUTHOR: Nathan SCULLY
# DESCRIPTION: Docker image to run Zeppelin to be used with an external spark cluster and run on Kubernetes
# BUILD: docker build --rm -t nathanscully/zeppelin-kube
# SOURCE: https://github.com/nathanscully/zeppelin-kube

# Base image from spark
FROM gettyimages:spark:2.0.2-hadoop-2.7
MAINTAINER Nathan SCULLY <nathan@oneflare.com>

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Deps
RUN set -ex \
    && buildDeps='git build-essential pkg-config libglib2.0-0 libxext6 libsm6 libxrender1 libpq-dev' \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        apt-utils \
        apt-transport-https \
        curl \
        wget \
        ca-certificates \
        bzip2 \
        libfontconfig

#Anaconda | MVN | nodejs | Yarn
RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh \
    && wget --quiet https://repo.continuum.io/miniconda/Miniconda3-4.1.11-Linux-x86_64.sh -O ~/miniconda.sh \
    && /bin/bash ~/miniconda.sh -b -p /opt/conda \
    && rm ~/miniconda.sh \
    && wget http://www.eu.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz \
    && tar -zxf apache-maven-3.3.9-bin.tar.gz -C /usr/local/ \
    && ln -s /usr/local/apache-maven-3.3.9/bin/mvn /usr/local/bin/mvn

ENV PATH /opt/conda/bin:$PATH

RUN condaDeps='cython scipy scikit-learn scikit-image pandas matplotlib seaborn nltk psycopg2 pytz simplejson sqlalchemy boto gensim' \
    && conda install $condaDeps -y \
    && conda install -c conda-forge geopandas  -y \
    && pip install --upgrade pip \
    && pip install --ignore-installed setuptools \
    && pipDeps='abba tensorflow progressbar2 sqlalchemy-redshift statsmodels rtree geopy descartes pysal' \
    && pip install --upgrade $pipDeps \
    && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get update  -yqq \
    && apt-get install -yqq --no-install-recommends nodejs \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update  -yqq \
    && apt-get install -yqq --no-install-recommends yarn \
    && export PYTHONPATH="$(conda info --root)/lib/python3.5"

ENV ZEPPELIN_PORT 8080
ENV ZEPPELIN_HOME /usr/zeppelin
ENV ZEPPELIN_CONF_DIR $ZEPPELIN_HOME/conf
ENV ZEPPELIN_NOTEBOOK_DIR $ZEPPELIN_HOME/notebook
ENV MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=1024m"

#Zeppelin (we need the bowerrc line due to Docker running things as root)
RUN  git clone https://github.com/apache/zeppelin.git /usr/src/zeppelin \
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
    && apt-get autoremove \
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
        /usr/src/zeppelin \
    && conda clean --tarballs --source-cache --index-cache -y

WORKDIR $ZEPPELIN_HOME
COPY startup/entrypoint.sh .
CMD ["entrypoint.sh"]
