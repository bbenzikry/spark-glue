ARG java_image_tag=8-jre-slim
FROM python:3.7-slim-buster

# Build options
ARG hive_version=2.3.7
ARG spark_version=3.0.0
ARG hadoop_version=3.3.0

ENV SPARK_VERSION=${spark_version}
ENV HIVE_VERSION=${hive_version}
ENV HADOOP_VERSION=${hadoop_version}

# maven
ENV MAVEN_VERSION=3.6.3
ENV PATH=/opt/apache-maven-$MAVEN_VERSION/bin:$PATH

WORKDIR /

# JDK repo
RUN echo "deb http://ftp.us.debian.org/debian sid main" >> /etc/apt/sources.list \
  &&  apt-get update \
  &&  mkdir -p /usr/share/man/man1

# install deps
RUN apt-get install -y git curl wget openjdk-8-jdk patch && rm -rf /var/cache/apt/*

# maven
RUN cd /opt \
  &&  wget https://downloads.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  &&  tar zxvf /opt/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  &&  rm apache-maven-${MAVEN_VERSION}-bin.tar.gz

WORKDIR /

# Glue support
RUN git clone https://github.com/bbenzikry/aws-glue-data-catalog-client-for-apache-hive-metastore catalog
ADD https://github.com/apache/hive/archive/rel/release-${hive_version}.tar.gz hive.tar.gz
RUN mkdir hive && tar xzf hive.tar.gz --strip-components=1 -C hive 

## Build patched hive
WORKDIR /hive
ADD https://issues.apache.org/jira/secure/attachment/12958418/HIVE-12679.branch-2.3.patch hive.patch
RUN patch -p0 <hive.patch &&\
  mvn clean install -DskipTests

## Build glue hive client jars
WORKDIR /catalog
RUN mvn clean package -DskipTests -pl -aws-glue-datacatalog-hive2-client

WORKDIR /
