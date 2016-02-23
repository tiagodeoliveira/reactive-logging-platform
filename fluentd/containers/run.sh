#!/bin/bash

export FLUENTD_CONFIG_PATH=/fluent/fluent.conf
if [[ -n "$FLUENTD_CONFIG" ]]; then
  export FLUENTD_CONFIG_PATH=/fluent/confs/$FLUENTD_CONFIG.conf
fi

exec fluentd -c $FLUENTD_CONFIG_PATH -v
