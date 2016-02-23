FROM ruby
MAINTAINER tiago.oliveira

RUN gem install fluentd --no-ri --no-rdoc
RUN gem install fluent-plugin-elasticsearch
RUN gem install specific_install
RUN echo "installing"
RUN gem specific_install -l https://github.com/zenvia/fluent-plugin-kafka.git
RUN fluentd --setup ./fluent

COPY confs /fluent/confs
COPY run.sh run.sh
RUN chmod +x run.sh

CMD ["/run.sh"]
