require File.join(File.dirname(__FILE__), %w[.. spec_helper])
include FFI
require 'ffi'

describe Generator::Enum do
  it_should_behave_like 'All specs'
  before :all do
    @node = generate_xml_wrap_from('enums')
    @module = Module.new
    @module.module_exec do
      extend FFI::Library
    end
  end

  it 'creates a sequential enum' do
    # enum e { PREFIX_FIRST, PREFIX_SECOND, PREFIX_THIRD };

    e = @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[0]).to_s + '; e'
    # e = enum :e, [
    #   :first,
    #   :second,
    #   :third,
    # ]
    # PREFIX_FIRST = 0
    # PREFIX_SECOND = PREFIX_FIRST + 1
    # PREFIX_THIRD = PREFIX_SECOND + 1

    expect(@module.enum_type(:e)).to eq(e)

    expect(e[:first]).to eq(0)
    expect(e[:second]).to eq(1)
    expect(e[:third]).to eq(2)

    expect(@module::PREFIX_FIRST).to eq(0)
    expect(@module::PREFIX_SECOND).to eq(1)
    expect(@module::PREFIX_THIRD).to eq(2)
  end

  it 'creates an enum starting with an assignment' do
    # enum e_2 { COMMON_FIRST = 2, COMMON_SECOND, COMMON_THIRD };

    e_2 = @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[1]).to_s + '; e_2'
    # e_2 = enum :e_2, [
    #   :first, 2,
    #   :second,
    #   :third,
    # ]
    # COMMON_FIRST = 2
    # COMMON_SECOND = COMMON_FIRST + 1
    # COMMON_THIRD = COMMON_SECOND + 1

    expect(@module.enum_type(:e_2)).to eq(e_2)

    expect(e_2[:first]).to eq(2)
    expect(e_2[:second]).to eq(3)
    expect(e_2[:third]).to eq(4)

    expect(@module::COMMON_FIRST).to eq(2)
    expect(@module::COMMON_SECOND).to eq(3)
    expect(@module::COMMON_THIRD).to eq(4)
  end

  it 'creates an enum with assignment in the middle' do
    # enum e_3 { AGAIN_FIRST, AGAIN_SECOND = 5, AGAIN_THIRD };

    e_3 = @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[2]).to_s + '; e_3'
    # e_3 = enum :e_3, [
    #   :first,
    #   :second, 5,
    #   :third,
    # ]
    # AGAIN_FIRST = 0
    # AGAIN_SECOND = 5
    # AGAIN_THIRD = AGAIN_SECOND + 1

    expect(@module.enum_type(:e_3)).to eq(e_3)

    expect(e_3[:first]).to eq(0)
    expect(e_3[:second]).to eq(5)
    expect(e_3[:third]).to eq(6)

    expect(@module::AGAIN_FIRST).to eq(0)
    expect(@module::AGAIN_SECOND).to eq(5)
    expect(@module::AGAIN_THIRD).to eq(6)
  end

  it 'creates numeric keys' do
    # enum e_4 { E3_0, E3_1, E3_2 };

    e_4 = @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[3]).to_s + '; e_4'
    # e_4 = enum :e_4, [
    #   :'0',
    #   :'1',
    #   :'2',
    # ]
    # E3_0 = 0
    # E3_1 = E3_0 + 1
    # E3_2 = E3_1 + 1

    expect(@module.enum_type(:e_4)).to eq(e_4)

    expect(e_4[:'0']).to eq(0)
    expect(e_4[:'1']).to eq(1)
    expect(e_4[:'2']).to eq(2)

    expect(@module::E3_0).to eq(0)
    expect(@module::E3_1).to eq(1)
    expect(@module::E3_2).to eq(2)
  end

  it 'creates a single-element enum' do
    # enum e_5 { ABSURD_ENUM_WITH_ONE_KEY };

    e_5 = @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[4]).to_s + '; e_5'
    # e_5 = enum :e_5, [
    #   :key,
    # ]
    # ABSURD_ENUM_WITH_ONE_KEY = 0

    expect(@module.enum_type(:e_5)).to eq(e_5)

    expect(e_5[:key]).to eq(0)

    expect(@module::ABSURD_ENUM_WITH_ONE_KEY).to eq(0)
  end

  it 'creates an anonymous enum' do
    # enum { ANON_FIRST, ANON_SECOND, ANON_THIRD };

    @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[5]).to_s
    # enum [
    #   :first,
    #   :second,
    #   :third,
    # ]
    # ANON_FIRST = 0
    # ANON_SECOND = ANON_FIRST + 1
    # ANON_THIRD = ANON_SECOND + 1

    expect(@module::ANON_FIRST).to eq(0)
    expect(@module::ANON_SECOND).to eq(1)
    expect(@module::ANON_THIRD).to eq(2)
  end

  it 'creates a typedef enum' do
    # typedef enum { TYPEDEF_FIRST, TYPEDEF_SECOND, TYPEDEF_THIRD } e_7_t;

    @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[6]).to_s
    # enum :e_7_t, [
    #   :first,
    #   :second,
    #   :third,
    # ]
    # TYPEDEF_FIRST = 0
    # TYPEDEF_SECOND = TYPEDEF_FIRST + 1
    # TYPEDEF_THIRD = TYPEDEF_SECOND + 1

    expect(@module.enum_type(:e_7_t)).to be_an_instance_of(FFI::Enum)

    e_7 = @module.enum_type(:e_7_t)

    expect(e_7[:first]).to eq(0)
    expect(e_7[:second]).to eq(1)
    expect(e_7[:third]).to eq(2)

    expect(@module::TYPEDEF_FIRST).to eq(0)
    expect(@module::TYPEDEF_SECOND).to eq(1)
    expect(@module::TYPEDEF_THIRD).to eq(2)
  end

  it 'creates a typedef enum with a name' do
    # typedef enum e_8 { BOTH_FIRST, BOTH_SECOND, BOTH_THIRD } e_8_t;

    e_8 = @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[7]).to_s + '; e_8'
    # e_8 = enum :e_8_t, [
    #   :first,
    #   :second,
    #   :third,
    # ]
    # BOTH_FIRST = 0
    # BOTH_SECOND = BOTH_FIRST + 1
    # BOTH_THIRD = BOTH_SECOND + 1

    expect(@module.enum_type(:e_8_t)).to eq(e_8)

    expect(e_8[:first]).to eq(0)
    expect(e_8[:second]).to eq(1)
    expect(e_8[:third]).to eq(2)

    expect(@module::BOTH_FIRST).to eq(0)
    expect(@module::BOTH_SECOND).to eq(1)
    expect(@module::BOTH_THIRD).to eq(2)
  end
end
