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
