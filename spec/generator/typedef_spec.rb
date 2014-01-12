require File.expand_path('../../spec_helper', __FILE__)
include FFI
require 'ffi'

describe Generator::Typedef do
  it_should_behave_like 'All specs'
  before :all do
    @module = Module.new
    @module.module_exec do
      extend FFI::Library
      ffi_lib FFI::Library::LIBC
    end
    @parser = Generator::Parser.new
    @node = generate_xml_wrap_from('typedefs')
  end

  it 'creates a typedef alias' do
    @module.module_eval @parser.generate((@node / 'cdecl')[0])
    @module.module_eval @parser.generate((@node / 'cdecl')[1])

    expect(@module.find_type(:_size_t)).to eq(FFI::Type::Builtin::LONG);
  end

  it 'can use a typedef in another typedef' do
    @module.module_eval @parser.generate((@node / 'cdecl')[2])

    expect(@module.find_type(:__size_t)).to eq(@module.find_type(:_size_t));
  end

  it 'can use typedef in function arguments & return values' do
    @module.module_eval @parser.generate((@node / 'cdecl')[3])

    func = @module.method(:wcstombs)
    expect(func).to be_a(Method)
  end

  it 'does not generate typedef lines for opaque structs' do
    @parser.generate((@node / 'cdecl')[4]).should == ""
  end

  it 'can generate pointer typedefs' do
    @module.module_eval @parser.generate((@node / 'cdecl')[5])
    @module.find_type(:pInt).should == @module.find_type(:pointer)
  end

  it 'can generate callback typedefs' do
    @parser.generate((@node / 'cdecl')[6]).should \
      match(/ = callback\(:myfunc, \[ :int \], :void\)/)
  end
end
