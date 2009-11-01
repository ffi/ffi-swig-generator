require File.join(File.dirname(__FILE__), %w[.. spec_helper])
include FFI

describe Generator::Enum do
  it_should_behave_like 'All specs'
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

