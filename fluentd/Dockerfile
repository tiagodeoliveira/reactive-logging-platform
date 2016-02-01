FROM ruby
MAINTAINER tiago.oliveira

RUN gem install fluentd --no-ri --no-rdoc && \
  gem install fluent-plugin-kafka && \
  gem install fluent-plugin-elasticsearch && \
  fluentd --setup ./fluent

COPY confs /fluent/confs
COPY run.sh run.sh
RUN chmod +x run.sh

CMD ["/run.sh"]
