require 'rake/tasklib'

module FFI
  module Generator
    class Task < Rake::TaskLib
      attr_accessor :input_fn, :output_dir
      def initialize(options = {}, &blk)
        @options = { :input_fn => '*.i', :output_dir => 'generated/' }.merge(options)
        @input_fn = @options[:input_fn]
        @output_dir = @options[:output_dir]
        yield self if block_given?
        namespace 'ffi' do
          define_generate_task
          define_clean_task
        end
      end
      private
      def define_file_task(fn, xml_fn, output_fn)
        desc "Generate #{output_fn} from #{fn}"
        file output_fn => fn do
          mkdir_p @output_dir, :verbose => false
          Logger.info("#{fn} -> #{xml_fn}")
          `swig -xml #{xml_fn} #{fn}`
          Logger.info("#{xml_fn} -> #{output_fn}")
          parser = Parser.new
          config_basename = File.basename(fn, File.extname(fn))
          config_dir = File.dirname(fn)
          config_fn = File.join(config_dir, "#{config_basename}.rb")
          if File.exists?(config_fn)
            Logger.info("Using configuration in #{config_fn}...")
            parser.load_config(config_fn)
          end
          File.open(output_fn, 'w') do |file|
            file << parser.generate(Nokogiri::XML(File.open(xml_fn)))
          end
        end
      end
      def define_file_tasks
        Dir.glob(@input_fn).inject([]) do |output_fns, fn|
          output_fn = File.join(@output_dir, "#{File.basename(fn, '.i')}_wrap.rb")
          xml_fn = File.join(@output_dir, "#{File.basename(fn, '.i')}_wrap.xml")
          define_file_task(fn, xml_fn, output_fn)
          output_fns << output_fn
        end
      end
      def define_generate_task
        (task :generate => define_file_tasks).add_description('Generate all files')
      end
      def define_clean_task
        desc 'Remove all generated files'
        task :clean do
          rm_rf @output_dir unless @output_dir == '.'
        end
      end
    end
  end
end
