require File.join(File.dirname(__FILE__), %w[.. spec_helper])
include FFI

describe Generator::Enum do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('enums')
  end
  it 'should generate enum constant' do
    Generator::Enum.new(:node => (@node / 'enum')[0]).to_s.should == <<EOE
e = enum :first,
         :second,
         :third
EOE
  end
  it 'should generate constants starting from the latest assignment' do
    Generator::Enum.new(:node => (@node / 'enum')[1]).to_s.should == <<EOE
e_2 = enum :first, 2,
           :second,
           :third
EOE
    Generator::Enum.new(:node => (@node / 'enum')[2]).to_s.should == <<EOE
e_3 = enum :first,
           :second, 5,
           :third
EOE
  end
  it 'should generate numeric keys correctly' do
    Generator::Enum.new(:node => (@node / 'enum')[3]).to_s.should == <<EOE
e_4 = enum :'0',
           :'1',
           :'2'
EOE
  end
  it 'should handle single-element enums' do
    Generator::Enum.new(:node => (@node / 'enum')[4]).to_s.should == <<EOE
e_5 = enum :key
EOE
  end    
end

