@Grab(group='org.fluentd', module='fluent-logger', version='0.3.2')
@Grab(group='org.apache.commons', module='commons-lang3', version='3.4')
import org.apache.commons.lang3.RandomStringUtils
import org.fluentd.logger.FluentLogger

class LogGenerator {
    def LOG_TYPES = ['info', 'debug', 'error', 'warn']
    def APPLICATIONS = ['bulkcontent', 'cobra', 'gateway-oi', 'gateway-vivo', 'gateway-tim', 'gateway-claro', 'jobscheduler', 'service-manager']
    def LOGGERS = Thread.currentThread().getClass().getDeclaredFields().collect{ it.type.canonicalName }
    def SOURCE = InetAddress.getLocalHost().getHostName()
    def RANDOM = new Random()

    def log() {
        def type = LOG_TYPES[RANDOM.nextInt(LOG_TYPES.size())]
        def application = APPLICATIONS[RANDOM.nextInt(APPLICATIONS.size())]
        def logger = FluentLogger.getLogger(application, "fluentdreceiver", 24224)

        def log = [
                "@type": type,
                "@logger": LOGGERS[RANDOM.nextInt(LOGGERS.size())],
                "@source": application,
                "@source_host": SOURCE,
                "@message": RandomStringUtils.randomAlphanumeric(RANDOM.nextInt(500))]

        logger.log(type, log)
    }
}

if (this.args.size() > 0) {
  def logGenerator = new LogGenerator()
  def throotle = 1000
  def time = 1000

  while (true) {
      def amount = 0
      def begin = System.currentTimeMillis()
      def end = begin + time
      def left = end - System.currentTimeMillis()
      
      while (left > 0 && amount < throotle) {
          logGenerator.log()
          amount++
          left = end - System.currentTimeMillis()
      }

      if (left > 0) {
          println "Waiting ${left}ms"
          sleep(left)
      }

      println "$amount messages in ${time - left}ms"
  }
}
