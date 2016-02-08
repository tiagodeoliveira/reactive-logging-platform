FROM maven:3-jdk-7
MAINTAINER Justin Plock <justin@plock.net>

RUN wget -q -O /opt/pom.xml https://raw.githubusercontent.com/Netflix-Skunkworks/zerotodocker/master/exhibitor-zookeeper/pom.xml

ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
RUN cd /opt && mvn assembly:single

EXPOSE 8080
ENTRYPOINT ["/usr/bin/java", "-jar", "/opt/target/exhibitor-1.0-jar-with-dependencies.jar"]
CMD ["--help"]
