FROM anapsix/alpine-java

MAINTAINER Wurstmeister

RUN apk add --update docker jq
COPY configure.sh /configure.sh
COPY zoo.cfg.initial /zoo.cfg.initial
RUN chmod +x /configure.sh

CMD ["/configure.sh"]
