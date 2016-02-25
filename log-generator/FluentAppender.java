package com.purebros.logging.appender;

import ch.qos.logback.classic.spi.IThrowableProxy;
import ch.qos.logback.classic.spi.LoggingEvent;
import ch.qos.logback.classic.spi.StackTraceElementProxy;
import ch.qos.logback.core.UnsynchronizedAppenderBase;
import org.fluentd.logger.FluentLogger;
import org.joda.time.DateTime;
import org.joda.time.DateTimeZone;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingQueue;

;

/**
 * Created by tiagooliveira on 2/25/16.
 */
public class FluentAppender extends UnsynchronizedAppenderBase<LoggingEvent> {
    private static final Logger LOG = LoggerFactory.getLogger(FluentAppender.class);
    private static final ExecutorService THREAD_POOL = Executors.newFixedThreadPool(1);

    public FluentAppender() {

    }

    public FluentAppender(String tag, String remoteHost, int port, int maxQueueSize) {
        this.tag = tag;
        this.remoteHost = remoteHost;
        this.port = port;
        this.maxQueueSize = maxQueueSize;
    }

    private DaemonAppender appender;

    private String tag;
    private String remoteHost;
    private int port;
    private int maxQueueSize;

    @Override
    public void start() {
        super.start();
        appender = new DaemonAppender(tag, remoteHost, port, maxQueueSize);
        THREAD_POOL.execute(appender);
    }

    @Override
    protected void append(LoggingEvent eventObject) {
        appender.log(eventObject);
    }

    @Override
    public void stop() {
        super.stop();
        appender.close();
        THREAD_POOL.shutdownNow();
    }

    public String getTag() {
        return tag;
    }

    public void setTag(String tag) {
        this.tag = tag;
    }

    public int getMaxQueueSize() {
        return maxQueueSize;
    }

    public void setMaxQueueSize(int maxQueueSize) {
        this.maxQueueSize = maxQueueSize;
    }

    public String getRemoteHost() {
        return remoteHost;
    }

    public void setRemoteHost(String remoteHost) {
        this.remoteHost = remoteHost;
    }

    public int getPort() {
        return port;
    }

    public void setPort(int port) {
        this.port = port;
    }

    private static final class DaemonAppender implements Runnable {

        private final FluentLogger fluentLogger;
        private final BlockingQueue<LoggingEvent> queue;
        private String hostName;

        DaemonAppender(String tag, String remoteHost, int port, int maxQueueSize) {
            this.fluentLogger = FluentLogger.getLogger(tag, remoteHost, port);
            this.queue = new LinkedBlockingQueue<LoggingEvent>(maxQueueSize);

            try {
                hostName = InetAddress.getLocalHost().getCanonicalHostName();
            } catch (UnknownHostException e) {
                e.printStackTrace();
            }
        }

        void log(LoggingEvent eventObject) {
            if (!queue.offer(eventObject)) {
                LOG.debug("Message queue is full. Ignore the message.");
            }
        }

        @Override
        public void run() {

            try {
                for (;;) {
                    LoggingEvent event = queue.take();

                    Map<String, Object> data = new HashMap<String, Object>();

                    data.put("@timestamp", new DateTime(event.getTimeStamp()).toDateTime(DateTimeZone.UTC).toString());
                    data.put("@level", event.getLevel().toString());
                    data.put("@logger", event.getLoggerName());
                    data.put("@source", "FluentAppender");
                    data.put("@source_host", hostName);
                    data.put("message", this.getMessageFromEvent(event));

                    Map<String, String> mdc = event.getMDCPropertyMap();
                    if (mdc != null) {
                        data.putAll(mdc);
                    }

                    fluentLogger.log(event.getLevel().toString().toLowerCase(), data);
                }
            } catch (InterruptedException e) {
                LOG.error("Unknown error.", e);
                close();
            }
        }

        public String getMessageFromEvent(LoggingEvent event) {
            StringBuilder msg = new StringBuilder();
            msg.append(event.getFormattedMessage());
            IThrowableProxy tp = event.getThrowableProxy();
            while (tp != null) {
                msg.append("\n")
                        .append(tp.getClassName())
                        .append(": ")
                        .append(tp.getMessage());
                for (StackTraceElementProxy ste : tp.getStackTraceElementProxyArray()) {
                    msg.append("\n").append(ste.getSTEAsString());
                }
                tp = tp.getCause();
                if (tp != null) {
                    msg.append("\nCaused by: ");
                }
            }
            return msg.toString();
        }

        void close() {
            FluentLogger.closeAll();
            queue.clear();
        }
    }
}
