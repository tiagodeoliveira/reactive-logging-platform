FROM elasticsearch:2.1

COPY run.sh /run.sh
RUN chmod a+x /run.sh
RUN chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/data

CMD ["/run.sh"]
