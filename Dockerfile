ARG java_image_tag=11-jre-slim
FROM openjdk:${java_image_tag}

ARG spark_version=3.2.1
ARG spark_release=3.2.1-bin-without-hadoop
ARG hadoop_version=3.3.1
ARG aws_java_sdk=1.11.901
ARG spark_uid=185
ARG trevas_version=0.4.8
ARG postgresql_version=42.3.3
ARG postgis_version=2021.1.0

ENV HADOOP_HOME="/opt/hadoop"
ENV SPARK_HOME="/opt/spark"
ENV PATH=$PATH:$SPARK_HOME/bin
ENV PATH=$PATH:$HADOOP_HOME/bin
ENV LD_LIBRARY_PATH=$HADOOP_HOME/lib/native

RUN set -ex && \
    sed -i 's/http:\/\/deb.\(.*\)/https:\/\/deb.\1/g' /etc/apt/sources.list && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt install -y wget bash tini libc6 libpam-modules krb5-user libnss3 && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/* /var/lib/apt/lists/*

RUN mkdir -p $SPARK_HOME && wget -q -O- -i https://archive.apache.org/dist/spark/spark-${spark_version}/spark-${spark_version}-bin-without-hadoop.tgz \
  | tar xzv -C $SPARK_HOME --strip-components=1

RUN mkdir -p $HADOOP_HOME && wget -q -O- -i https://archive.apache.org/dist/hadoop/core/hadoop-${hadoop_version}/hadoop-${hadoop_version}.tar.gz \
  | tar xzv -C $HADOOP_HOME --strip-components=1

RUN wget -q https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${hadoop_version}/hadoop-aws-${hadoop_version}.jar \
      -P $SPARK_HOME/jars
RUN wget -q https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${aws_java_sdk}/aws-java-sdk-bundle-${aws_java_sdk}.jar \
      -P $SPARK_HOME/jars
RUN wget -q https://repo1.maven.org/maven2/org/postgresql/postgresql/${postgresql_version}/postgresql-${postgresql_version}.jar \
      -P $SPARK_HOME/jars
RUN wget -q https://repo1.maven.org/maven2/net/postgis/postgis-jdbc/${postgis_version}/postgis-jdbc-${postgis_version}.jar \
      -P $SPARK_HOME/jars
RUN wget -q https://repo1.maven.org/maven2/fr/insee/trevas/vtl-engine/${trevas_version}/vtl-engine-${trevas_version}.jar \
      -P $SPARK_HOME/jars
RUN wget -q https://repo1.maven.org/maven2/fr/insee/trevas/vtl-model/${trevas_version}/vtl-model-${trevas_version}.jar \
      -P $SPARK_HOME/jars
RUN wget -q https://repo1.maven.org/maven2/fr/insee/trevas/vtl-parser/${trevas_version}/vtl-parser-${trevas_version}.jar \
      -P $SPARK_HOME/jars
RUN wget -q https://repo1.maven.org/maven2/fr/insee/trevas/vtl-spark/${trevas_version}/vtl-spark-${trevas_version}.jar \
      -P $SPARK_HOME/jars

COPY entrypoint.sh /opt/
RUN chown -R ${spark_uid} /opt/
RUN chmod u+x /opt/entrypoint.sh

WORKDIR /opt/spark/work-dir
RUN chmod g+w /opt/spark/work-dir

ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Specify the User that the actual main process will run as
USER ${spark_uid}
