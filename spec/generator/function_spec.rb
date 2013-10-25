require File.join(File.dirname(__FILE__), %w[.. spec_helper])
include FFI

describe Generator::Function do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('functions')
  end
  it 'should return a properly generated attach_method' do
    Generator::Function.new(:node => (@node / 'cdecl')[0]).to_s.should == "attach_function :func_1, :func_1, [ :char, :int ], :int"
  end
  it 'should properly generate pointer arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[1]).to_s.should == "attach_function :func_2, :func_2, [ :pointer, :pointer, :pointer ], :uint"
  end
  it 'should properly generate string arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[2]).to_s.should == "attach_function :func_3, :func_3, [ :string ], :void"
  end
  it 'should properly generate string return type' do
    Generator::Function.new(:node => (@node / 'cdecl')[3]).to_s.should == "attach_function :func_4, :func_4, [ :int ], :string"
  end
  it 'should generate string type only in case of pointer of type char (char *)' do
    Generator::Function.new(:node => (@node / 'cdecl')[17]).to_s.should == "attach_function :func_17, :func_17, [  ], :pointer"
  end
  it 'should properly generate void return type' do
    Generator::Function.new(:node => (@node / 'cdecl')[4]).to_s.should == "attach_function :func_5, :func_5, [  ], :void"
  end
  it 'should properly generate pointer of pointer arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[5]).to_s.should == "attach_function :func_6, :func_6, [ :pointer ], :void"
  end
  it 'should properly generate enum arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[6]).to_s.should == "attach_function :func_7, :func_7, [ :int ], :void"
  end
  it 'should properly generate enum return type' do
    Generator::Function.new(:node => (@node / 'cdecl')[7]).to_s.should == "attach_function :func_8, :func_8, [  ], :int"
  end
  it 'should properly generate struct arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[9]).to_s.should == "attach_function :func_9, :func_9, [ TestStruct ], :void"
  end
  it 'should properly generate struct return type' do
    Generator::Function.new(:node => (@node / 'cdecl')[10]).to_s.should == "attach_function :func_10, :func_10, [  ], TestStruct"
  end
  it 'should properly generate a function with no parameters' do
    Generator::Function.new(:node => (@node / 'cdecl')[11]).to_s.should == "attach_function :func_11, :func_11, [  ], :void"
  end
  it 'should properly generate a function that takes a callback as argument' do
    Generator::Function.new(:node => (@node / 'cdecl')[12]).to_s.should == "attach_function :func_12, :func_12, [ callback([ :float ], :void) ], :void"
    Generator::Function.new(:node => (@node / 'cdecl')[13]).to_s.should == "attach_function :func_13, :func_13, [ callback([ :double, :float ], :int) ], :void"
    Generator::Function.new(:node => (@node / 'cdecl')[14]).to_s.should == "attach_function :func_14, :func_14, [ callback([ :string ], :void) ], :void"
    Generator::Function.new(:node => (@node / 'cdecl')[15]).to_s.should == "attach_function :func_15, :func_15, [ callback([  ], :void) ], :void"
  end
  it 'should handle const qualifier return type' do
    Generator::Function.new(:node => (@node / 'cdecl')[16]).to_s.should == "attach_function :func_16, :func_16, [  ], :string"
  end
  it 'should generate a function with variadic args' do
    Generator::Function.new(:node => (@node / 'cdecl')[18]).to_s.should == "attach_function :func_18, :func_18, [ :varargs ], :void"
  end
  it 'should generate a function with volatile args' do
    Generator::Function.new(:node => (@node / 'cdecl')[19]).to_s.should == "attach_function :func_19, :func_19, [ :int ], :void"
  end
  it 'should properly generate func_20' do
    Generator::Function.new(:node => (@node / 'cdecl')[20]).to_s.should == "attach_function :func_20, :func_20, [ :pointer, callback([ :string, :pointer, :pointer ], :void), :pointer ], :void"
  end
  it 'should properly generate func_20' do
    Generator::Function.new(:node => (@node / 'cdecl')[21]).to_s.should == "attach_function :func_21, :func_21, [ :pointer, callback([ :uchar, :pointer, :pointer ], :void), :pointer ], :void"
  end
  it 'should handle typedef struct arguments' do
    node = (@node / '[value="func_22"]').first.ancestors("cdecl").first
    Generator::Function.new(:node => node, :typedefs => {"CamelStruct" => "struct CamelStruct"}).to_s.should == "attach_function :func_22, :func_22, [ CamelStruct ], :void"
  end
  it 'should handle typedef struct return' do
    node = (@node / '[value="func_23"]').first.ancestors("cdecl").first
    Generator::Function.new(:node => node, :typedefs => {"CamelStruct" => "struct CamelStruct"}).to_s.should == "attach_function :func_23, :func_23, [  ], CamelStruct"
  end
  it 'should handle array argument' do
    node = (@node / '[value="func_24"]').first.ancestors("cdecl").first
    Generator::Function.new(:node => node).to_s.should == "attach_function :func_24, :func_24, [ :pointer ], :void"
  end   
  it 'should handle typedef struct pointer argument' do
    node = (@node / '[value="func_25"]').first.ancestors("cdecl").first
    Generator::Function.new(:node => node, :typedefs => {"CamelStruct" => "struct CamelStruct"}).to_s.should == "attach_function :func_25, :func_25, [ :pointer ], :void"
  end   
  it 'should handle typedef struct pointer return value' do
    node = (@node / '[value="func_26"]').first.ancestors("cdecl").first
    Generator::Function.new(:node => node, :typedefs => {"CamelStruct" => "struct CamelStruct"}).to_s.should == "attach_function :func_26, :func_26, [  ], :pointer"
  end   
end
