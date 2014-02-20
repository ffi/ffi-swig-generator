require 'rubygems'

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '../lib/')))

require 'ffi-swig-generator'

RSpec::configure do |config|
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
end

def generate_xml_wrap_from(fn)
  `swig -xml spec/generator/swig/#{fn + '.i'}`
  Nokogiri::XML(File.open(File.join('spec/generator/swig/', "#{fn}_wrap.xml")))
end

def remove_xml
  FileUtils.rm(Dir.glob('spec/generator/swig/*.xml'))
end

share_examples_for "All specs" do
  after :all do
    remove_xml
  end
end

# EOF
