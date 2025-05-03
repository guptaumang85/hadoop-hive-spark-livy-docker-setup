FROM apache/hadoop:3
USER root
ENV JAVA_HOME="/usr/lib/jvm/jre/"
ENV HADOOP_HOME="/opt/hadoop"
RUN mkdir -p /opt/hadoop/dfs/namenode
VOLUME /opt/hadoop/dfs/namenode
RUN mkdir -p /opt/hadoop/dfs/data
VOLUME /opt/hadoop/dfs/data
EXPOSE 9870 9864 8088
EXPOSE 9864

# CentOS 7 EOL'd on June 30 and they took down mirrorlist.centos.org with it. Hence need to update yum repos
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo
RUN sed -i s/^#.*baseurl=http/baseurl=https/g /etc/yum.repos.d/*.repo
RUN sed -i s/^mirrorlist=http/#mirrorlist=https/g /etc/yum.repos.d/*.repo
RUN echo "sslverify=false" >> /etc/yum.conf

# install ssh-server
RUN yum -y update && yum install -y openssh-server

# Create the directory for SSHD if it doesn't exist
RUN mkdir -p /var/run/sshd

# Set the password
RUN echo 'root:mysecret' | chpasswd

# Configure SSH to allow root login
RUN sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -ri 's/^#?UsePAM\s+.*/#UsePAM yes/' /etc/ssh/sshd_config

# Expose port 22 for SSH
EXPOSE 22

RUN yum -y install make gcc bzip2-devel libffi-devel zlib-devel
RUN yum -y install perl-IPC-Cmd perl-Test-Simple
WORKDIR /usr/src
RUN wget --no-check-certificate https://www.openssl.org/source/openssl-3.0.7.tar.gz
RUN tar -zxf openssl-3.0.7.tar.gz
RUN rm openssl-3.0.7.tar.gz
WORKDIR /usr/src/openssl-3.0.7
RUN ./config
RUN make
RUN make install
RUN ln -s /usr/local/lib64/libssl.so.3 /usr/lib64/libssl.so.3
RUN ln -s /usr/local/lib64/libcrypto.so.3 /usr/lib64/libcrypto.so.3
RUN wget --no-check-certificate https://www.python.org/ftp/python/3.9.18/Python-3.9.18.tgz -P /opt/
RUN tar -xzf /opt/Python-3.9.18.tgz -C /opt/
WORKDIR /opt/Python-3.9.18
RUN ./configure --enable-optimizations
RUN make altinstall
RUN rm /opt/Python-3.9.18.tgz

# Install Spark
WORKDIR /opt
RUN wget --no-check-certificate https://archive.apache.org/dist/spark/spark-3.3.2/spark-3.3.2-bin-hadoop3.tgz -P /opt/
RUN tar -xzf /opt/spark-3.3.2-bin-hadoop3.tgz -C /opt/
RUN rm spark-3.3.2-bin-hadoop3.tgz
ENV SPARK_HOME /opt/spark-3.3.2-bin-hadoop3
ENV SPARK_MASTER="spark://spark-master:7077"
ENV SPARK_MASTER_HOST spark-master
ENV SPARK_MASTER_PORT 7077
ENV PYSPARK_PYTHON python3.9
COPY conf/spark-defaults.conf "$SPARK_HOME/conf"
RUN chmod u+x /opt/spark-3.3.2-bin-hadoop3/sbin/* && \
    chmod u+x /opt/spark-3.3.2-bin-hadoop3/bin/*
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9.5-src.zip:$PYTHONPATH

RUN wget --no-check-certificate https://archive.apache.org/dist/hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz -P /opt/
RUN tar -xzf /opt/apache-hive-3.1.3-bin.tar.gz -C /opt/
RUN rm -rf apache-hive-3.1.3-bin.tar.gz
RUN mkdir -p /shared_data
ENV HIVE_HOME=/opt/apache-hive-3.1.3-bin
COPY conf/hive-site.xml $HIVE_HOME/conf
RUN cp /opt/apache-hive-3.1.3-bin/conf/hive-env.sh.template /opt/apache-hive-3.1.3-bin/conf/hive-env.sh
RUN echo "export HADOOP_HOME=/opt/hadoop" >> /opt/apache-hive-3.1.3-bin/conf/hive-env.sh
RUN chmod +x /opt/apache-hive-3.1.3-bin/conf/hive-env.sh
ENV PATH $SPARK_HOME/bin:$SPARK_HOME/sbin:$HIVE_HOME/bin:/usr/lib/postgresql/*/bin:$PATH
COPY ./postgresql/postgresql-42.6.2.jar $HIVE_HOME/lib/
COPY ./postgresql/postgresql-42.6.2.jar $SPARK_HOME/jars

# Install apache livy
RUN yum -y install zip unzip
RUN wget --no-check-certificate https://downloads.apache.org/incubator/livy/0.8.0-incubating/apache-livy-0.8.0-incubating_2.12-bin.zip -P /opt/
RUN unzip apache-livy-0.8.0-incubating_2.12-bin.zip
RUN mv "apache-livy-0.8.0-incubating_2.12-bin" /opt/livy-0.8.0
RUN rm -rf apache-livy-0.8.0-incubating_2.12-bin.zip
RUN mkdir /opt/livy-0.8.0/logs
RUN mv /opt/livy-0.8.0/conf/livy.conf.template /opt/livy-0.8.0/conf/livy.conf
RUN echo "livy.spark.master = spark://spark-master:7077" >> /opt/livy-0.8.0/conf/livy.conf
RUN echo "livy.file.local-dir-whitelist =/opt/shared" >> /opt/livy-0.8.0/conf/livy.conf
RUN mv /opt/livy-0.8.0/conf/livy-env.sh.template /opt/livy-0.8.0/conf/livy-env.sh
RUN mv /opt/livy-0.8.0/conf/log4j.properties.template /opt/livy-0.8.0/conf/log4j.properties
RUN echo "export SPARK_HOME=/opt/spark-3.3.2-bin-hadoop3" >> /opt/livy-0.8.0/conf/livy-env.sh
# COPY conf/livy/pom.xml /opt/livy-0.8.0/
ENV LIVY_HOME=/opt/livy-0.8.0
ENV PROJECT_DIR=/opt/shared/etl-project

EXPOSE 8080 7077 8081 8042 8998
# Configure pip
# RUN mkdir -p /etc/pip
# COPY conf/master.crt /etc/pip/

# commands to be run after creating pip.conf from confluence.
# RUN python3.9 -m pip install --upgrade pip
# RUN pip3 install poetry==1.8.3