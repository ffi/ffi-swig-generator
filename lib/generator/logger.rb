require 'logger'

module FFI
  module Generator
    module Logger
      @logger = ::Logger.new(STDOUT)
      @logger.progname = 'ffi-swig-generator'
      def self.fatal(message)
        @logger.fatl(message)
      end
      def self.error(message)
        @logger.error(message)
      end
      def self.warn(message)
        @logger.warn(message)
      end
      def self.info(message)
        @logger.info(message)
      end
      def self.debug(message)
        @logger.debug(message)
      end
      def set_level(level)
        @logger.level = level
      end
    end
  end
end

