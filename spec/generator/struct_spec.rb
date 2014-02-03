require File.join(File.dirname(__FILE__), %w[.. spec_helper])

include FFI

describe Generator::Struct do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('structs')
  end
  it 'should properly generate the layout of a FFI::Struct class' do
    Generator::Struct.new(:node => (@node / 'class')[0]).to_s.should == <<EOC
class TestStruct1 < FFI::Struct
  layout(
         :i, :int,
         :c, :char,
         :s, :pointer,
         :a, [:char, 5],
         :b, [:char, 5+1]
  )
  def s=(str)
    @s = FFI::MemoryPointer.from_string(str)
    self[:s] = @s
  end
  def s
    @s.get_string(0)
  end

end
EOC

  end
  it 'should properly generate the layout of a FFI::Struct containing pointer field' do
    Generator::Struct.new(:node => (@node / 'class')[1]).to_s.should == <<EOC
class TestStruct2 < FFI::Struct
  layout(
         :ptr, :pointer
  )
end
EOC
end
  it 'should properly generate the layout of a FFI::Struct containing array field' do
    Generator::Struct.new(:node => (@node / 'class')[2]).to_s.should == <<EOC
class TestStruct3 < FFI::Struct
  layout(
         :c, [:char, 5]
  )
end
EOC

  end
  it 'should properly generate the layout of a FFI::Struct containing array field' do
    Generator::Struct.new(:node => (@node / 'class')[3]).to_s.should == <<EOC
class TestStruct4 < FFI::Struct
  layout(
         :s, [TestStruct3.by_value, 5]
  )
end
EOC
  end

  it 'should properly generate the layout for struct containing struct' do
    node = (@node / "class//[value='test_struct_5']")[0].ancestors("class")[0]
    Generator::Struct.new(:node => node).to_s.should == <<EOC
class TestStruct5 < FFI::Struct
  layout(
         :s, TestStruct4.by_value
  )
end
EOC
  end

  it 'should properly generate the layout for struct containing struct pointer' do
    node = (@node / "class//[value='test_struct_6']")[0].ancestors("class")[0]
    Generator::Struct.new(:node => node).to_s.should == <<EOC
class TestStruct6 < FFI::Struct
  layout(
         :s, TestStruct4.ptr
  )
end
EOC
  end
  it 'should prepend struct dependencies' do
    node = (@node / "class//[value='test_struct_7']")[0].ancestors("class")[0]
    Generator::Struct.new(:node => node).to_s.should == <<EOC
class TestStruct7 < FFI::Struct
  layout(
         :s, UndefinedStruct.ptr
  )
end
EOC
  end

  it 'should handle nested anonymous unions' do

    # This is the typedef that is created when the anonymous union within
    # test_struct_8 is parsed.
    typedefs = { "test_struct_8_data" => "union test_struct_8_data" }

    # Find our test struct
    node = (@node / "class//[value='test_struct_8']")[0].ancestors("class")[0]

    # Parse it and verify we're referencing the union in the typedef
    Generator::Struct.new(:node => node, :typedefs => typedefs).to_s \
      .should == <<EOC
class TestStruct8 < FFI::Struct
  layout(
         :data, TestStruct8Data
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
