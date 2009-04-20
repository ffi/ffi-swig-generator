# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  begin
    load 'tasks/setup.rb'
  rescue LoadError
    raise RuntimeError, '### please install the "bones" gem ###'
  end
end

ensure_in_path 'lib'
require 'ffi-swig-generator'

task :default => 'spec:run'

PROJ.name = 'ffi-swig-generator'
PROJ.authors = 'Andrea Fazzi'
PROJ.email = 'andrea.fazzi@alcacoop.it'
PROJ.url = 'http://kenai.com/projects/ruby-ffi/sources/swig-generator/show'
PROJ.version = FFI::Generator::VERSION
PROJ.rubyforge.name = 'ffi-swig-gen'

PROJ.readme_file = 'README.rdoc'

PROJ.ann.paragraphs << 'FEATURES' << 'SYNOPSIS' << 'REQUIREMENTS' << 'DOWNLOAD' << 'EXAMPLES' << 'PROJECTS RELATED TO ffi-swig-generator'
PROJ.ann.email[:from] = 'andrea.fazzi@alcacoop.it'
PROJ.ann.email[:to] << 'dev@ruby-ffi.kenai.com' << 'users@ruby-ffi.kenai.com'
PROJ.ann.email[:server] = 'smtp.gmail.com'

PROJ.ruby_opts = []
PROJ.spec.opts << '--color'

depend_on 'rake'
depend_on 'nokogiri'

# EOF
