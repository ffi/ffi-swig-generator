require File.join(File.dirname(__FILE__), %w[.. spec_helper])
include FFI

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
    Generator::Type.new(:node => (@node / 'cdecl')[6]).to_s.should == 'TestStruct.by_value'
  end
  it 'should generate struct array type' do
    Generator::Type.new(:node => (@node / 'cdecl')[7]).to_s.should == '[TestStruct.by_value, 5]'
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

  it 'should handle struct pointers' do
    node = (@node / 'cdecl//[value=struct_ptr]')[0].ancestors("cdecl")
    Generator::Type.new(:node => node).to_s.should == "TestStruct.ptr"
  end
  it 'should handle struct pointers' do
    node = (@node / 'cdecl//[value=struct_ptr_ptr]')[0].ancestors("cdecl")
    Generator::Type.new(:node => node).to_s.should == ":pointer"
  end
  it 'should handle known enums' do
    typedefs = { "TestEnum" => "enum test_enum" }
    node = (@node / 'cdecl//[value=enum_value]')[0].ancestors("cdecl")
    Generator::Type.new(:node => node, :typedefs => typedefs).to_s \
      .should == "TestEnum"
  end
  it 'should handle pointers to unsized arrays' do
    node = (@node / 'cdecl//[value=argv]')[0].ancestors("cdecl")
    Generator::Type.new(:node => node).to_s.should == ":pointer"
  end
  it 'will treat va_lists as pointers' do
    parser = Generator::Parser.new
    node = generate_xml_wrap_from('types_valist')
    code = parser.generate(node)
    code.should \
      include("attach_function :fn, :fn, [ :string, :pointer ], :int")
  end
  it 'will handle const struct pointers' do
    Generator::Type.new(:declaration => 'p.q(const).struct test_struct_9').to_s \
      .should eql("TestStruct9.ptr")
  end
end
