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
         :a, [:char, 5]
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
