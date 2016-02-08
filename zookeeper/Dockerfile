FROM netflixoss/java:7
MAINTAINER tiago.oliveira

RUN mkdir /zookeeper && \
    wget -O /zookeeper/zookeeper.tar.gz http://archive.apache.org/dist/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz

WORKDIR /zookeeper

RUN tar xvfz zookeeper.tar.gz --strip-components=1 && \
  rm zookeeper.tar.gz

COPY start-server.sh /
RUN chmod +x /start-server.sh

EXPOSE 2888 3888 2181

CMD ["/start-server.sh"]
