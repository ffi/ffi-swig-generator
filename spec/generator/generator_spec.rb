require File.join(File.dirname(__FILE__), %w[.. spec_helper])

include FFI

share_examples_for "All specs" do
  after :all do
    remove_xml
  end
end

describe Generator::Parser do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('testlib')
  end
  it 'should generate ruby ffi wrap code' do
    Generator::Parser.generate(@node).should == <<EOC

module TestLib
  extend FFI::Library
  CONST_1 = 0x10
  CONST_2 = 0x20
  ENUM_1 = 0
  ENUM_2 = 1
  ENUM_3 = 2

  class UnionT < FFI::Union
    layout(
           :c, :char,
           :f, :float
    )
  end
  class TestStruct < FFI::Struct
    layout(
           :i, :int,
           :c, :char,
           :b, :uchar
    )
  end
  class TestStruct3 < FFI::Struct
    layout(
           :c, :char
    )
  end
  callback(:cb, [ :string, :string ], :void)
  class TestStruct2 < FFI::Struct
    layout(
           :s, TestStruct,
           :s_3, TestStruct3,
           :e, :int,
           :func, :cb,
           :u, UnionT
    )
  end
  attach_function :get_int, [ :pointer ], :int
  attach_function :get_char, [ :pointer ], :char
  attach_function :func_with_enum, [ :int ], :int
  attach_function :func_with_enum_2, [ :int ], :int
  attach_function :func_with_typedef, [  ], :uchar

end
EOC
  end
end

describe Generator::Constant do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('constants')
  end
  it 'should return a ruby constant assignment' do
    Generator::Constant.new(:node => @node / 'constant').to_s.should == "CONST_1 = 0x10"
  end
end

describe Generator::Enum do
  before :all do
    @node = generate_xml_wrap_from('enums')
  end
  it 'should generate constants' do
    Generator::Enum.new(:node => (@node / 'enum')[0]).to_s.should == <<EOE
ENUM_1 = 0
ENUM_2 = 1
ENUM_3 = 2
EOE
  end
  it 'should generate constants starting from the latest assignment' do
    Generator::Enum.new(:node => (@node / 'enum')[1]).to_s.should == <<EOE
ENUM_21 = 2
ENUM_22 = 3
ENUM_23 = 4
EOE
    Generator::Enum.new(:node => (@node / 'enum')[2]).to_s.should == <<EOE
ENUM_31 = 0
ENUM_32 = 5
ENUM_33 = 6
EOE
  end
end

describe Generator::Type do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('types')
  end
  it 'should generate string type' do
    Generator::Type.new(:node => (@node / 'cdecl')[0]).to_s.should == ':string'
  end
  it 'should generate pointer type' do
    Generator::Type.new(:node => (@node / 'cdecl')[1]).to_s.should == ':pointer'
    Generator::Type.new(:node => (@node / 'cdecl')[2]).to_s.should == ':pointer'
  end
  it 'should generate array type' do
    Generator::Type.new(:node => (@node / 'cdecl')[3]).to_s.should == '[:int, 5]'
    Generator::Type.new(:node => (@node / 'cdecl')[4]).to_s.should == '[:string, 5]'
  end
  it 'should generate struct type' do
    Generator::Type.new(:node => (@node / 'cdecl')[6]).to_s.should == 'TestStruct'
  end
  it 'should generate struct array type' do
    Generator::Type.new(:node => (@node / 'cdecl')[7]).to_s.should == '[TestStruct, 5]'
  end
  it 'should generate enum array type' do
    Generator::Type.new(:node => (@node / 'cdecl')[8]).to_s.should == '[:int, 5]'
  end
  it 'should generate const type' do
    Generator::Type.new(:node => (@node / 'cdecl')[9]).to_s.should == ':int'
    Generator::Type.new(:node => (@node / 'cdecl')[10]).to_s.should == ':string'
  end
  Generator::TYPES.sort.each_with_index do |type, i|
    it "should generate #{type[0]} type" do
      Generator::Type.new(:node => (@node / 'cdecl')[i + 11]).to_s.should == type[1]
    end 
  end
end

describe Generator::Function do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('functions')
  end
  it 'should return a properly generated attach_method' do
    Generator::Function.new(:node => (@node / 'cdecl')[0]).to_s.should == "attach_function :func_1, [ :char, :int ], :int"
  end
  it 'should properly generate pointer arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[1]).to_s.should == "attach_function :func_2, [ :pointer, :pointer, :pointer ], :uint"
  end
  it 'should properly generate string arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[2]).to_s.should == "attach_function :func_3, [ :string ], :void"
  end
  it 'should properly generate return type' do
    Generator::Function.new(:node => (@node / 'cdecl')[3]).to_s.should == "attach_function :func_4, [ :int ], :string"
  end
  it 'should properly generate void return type' do
    Generator::Function.new(:node => (@node / 'cdecl')[4]).to_s.should == "attach_function :func_5, [  ], :void"
  end
  it 'should properly generate pointer of pointer arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[5]).to_s.should == "attach_function :func_6, [ :pointer ], :void"
  end
  it 'should properly generate enum arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[6]).to_s.should == "attach_function :func_7, [ :int ], :void"
  end
  it 'should properly generate enum return type' do
    Generator::Function.new(:node => (@node / 'cdecl')[7]).to_s.should == "attach_function :func_8, [  ], :int"
  end
  it 'should properly generate struct arguments' do
    Generator::Function.new(:node => (@node / 'cdecl')[9]).to_s.should == "attach_function :func_9, [ TestStruct ], :void"
  end
  it 'should properly generate struct return type' do
    Generator::Function.new(:node => (@node / 'cdecl')[10]).to_s.should == "attach_function :func_10, [  ], TestStruct"
  end
  it 'should properly generate a function with no parameters' do
    Generator::Function.new(:node => (@node / 'cdecl')[11]).to_s.should == "attach_function :func_11, [  ], :void"
  end
  it 'should properly generate a function that takes a callback as argument' do
    Generator::Function.new(:node => (@node / 'cdecl')[12]).to_s.should == "attach_function :func_12, [ callback(:callback, [ :float ], :void) ], :void"
    Generator::Function.new(:node => (@node / 'cdecl')[13]).to_s.should == "attach_function :func_13, [ callback(:callback, [ :double, :float ], :int) ], :void"
    Generator::Function.new(:node => (@node / 'cdecl')[14]).to_s.should == "attach_function :func_14, [ callback(:callback, [ :string ], :void) ], :void"
    Generator::Function.new(:node => (@node / 'cdecl')[15]).to_s.should == "attach_function :func_15, [ callback(:callback, [  ], :void) ], :void"
  end
end

describe Generator::Structure do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('structs')
  end
  it 'should properly generate the layout of a FFI::Struct class' do
    Generator::Structure.new(:node => (@node / 'class')[0]).to_s.should == <<EOC
class TestStruct1 < FFI::Struct
  layout(
         :i, :int,
         :c, :char,
         :s, :string,
         :a, [:char, 5]
  )
end
EOC

  end
  it 'should properly generate the layout of a FFI::Struct containing pointer field' do
    Generator::Structure.new(:node => (@node / 'class')[1]).to_s.should == <<EOC
class TestStruct2 < FFI::Struct
  layout(
         :ptr, :pointer
  )
end
EOC
end
  it 'should properly generate the layout of a FFI::Struct containing array field' do
    Generator::Structure.new(:node => (@node / 'class')[2]).to_s.should == <<EOC
class TestStruct3 < FFI::Struct
  layout(
         :c, [:char, 5]
  )
end
EOC

  end
  it 'should properly generate the layout of a FFI::Struct containing array field' do
    Generator::Structure.new(:node => (@node / 'class')[3]).to_s.should == <<EOC
class TestStruct4 < FFI::Struct
  layout(
         :s, [TestStruct3, 5]
  )
end
EOC

  end
end

describe Generator::Union do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('unions')
  end
  it 'should properly generate the layout of a FFI::Union class' do
    Generator::Union.new(:node => (@node / 'class')[0]).to_s.should == <<EOC
class UnionT < FFI::Union
  layout(
         :c, :char,
         :f, :float
  )
end
EOC
  end
end

