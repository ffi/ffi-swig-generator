require File.join(File.dirname(__FILE__), %w[.. spec_helper])
include FFI

describe Generator::Constant do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('constants')
  end
  it 'should return a ruby constant assignment' do
    Generator::Constant.new(:node => (@node / 'constant')[0]).to_s.should == "CONST_1 = 0x10"
  end
  it 'should ignore constant qualifiers' do
    Generator::Constant.new(:node => (@node / 'constant')[1]).to_s.should == "CONST_2 = 1234"
    Generator::Constant.new(:node => (@node / 'constant')[2]).to_s.should == "CONST_3 = 1234"
    Generator::Constant.new(:node => (@node / 'constant')[3]).to_s.should == "CONST_4 = 1234"
  end
end
