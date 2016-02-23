FROM anapsix/alpine-java

RUN apk add --update wget curl jq
RUN wget http://mirror.switch.ch/mirror/apache/dist/kafka/0.9.0.0/kafka_2.10-0.9.0.0.tgz -O /opt/kafka.tgz
RUN cd /opt && tar xfz kafka.tgz && rm -rf kafka.tgz && mv kafka* kafka

ADD run.sh /run.sh
RUN chmod a+x /run.sh

EXPOSE 9092

VOLUME ["/opt/kafka/conf.d"]

WORKDIR /opt/kafka

CMD ["/run.sh"]
