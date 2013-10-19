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

    expect(@module.enum_type(:e)).to eq(e)

    expect(e[:first]).to eq(0)
    expect(e[:second]).to eq(1)
    expect(e[:third]).to eq(2)
  end

  it 'creates an enum starting with an assignment' do
    # enum e_2 { COMMON_FIRST = 2, COMMON_SECOND, COMMON_THIRD };

    e_2 = @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[1]).to_s + '; e_2'
    # e_2 = enum :e_2, [
    #   :first, 2,
    #   :second,
    #   :third,
    # ]

    expect(@module.enum_type(:e_2)).to eq(e_2)

    expect(e_2[:first]).to eq(2)
    expect(e_2[:second]).to eq(3)
    expect(e_2[:third]).to eq(4)
  end

  it 'creates an enum with assignment in the middle' do
    # enum e_3 { AGAIN_FIRST, AGAIN_SECOND = 5, AGAIN_THIRD };

    e_3 = @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[2]).to_s + '; e_3'
    # e_3 = enum :e_3, [
    #   :first,
    #   :second, 5,
    #   :third,
    # ]

    expect(@module.enum_type(:e_3)).to eq(e_3)

    expect(e_3[:first]).to eq(0)
    expect(e_3[:second]).to eq(5)
    expect(e_3[:third]).to eq(6)
  end

  it 'creates numeric keys' do
    # enum e_4 { E3_0, E3_1, E3_2 };

    e_4 = @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[3]).to_s + '; e_4'
    # e_4 = enum :e_4, [
    #   :'0',
    #   :'1',
    #   :'2',
    # ]

    expect(@module.enum_type(:e_4)).to eq(e_4)

    expect(e_4[:'0']).to eq(0)
    expect(e_4[:'1']).to eq(1)
    expect(e_4[:'2']).to eq(2)
  end

  it 'creates a single-element enum' do
    # enum e_5 { ABSURD_ENUM_WITH_ONE_KEY };

    e_5 = @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[4]).to_s + '; e_5'
    # e_5 = enum :e_5, [
    #   :key,
    # ]

    expect(@module.enum_type(:e_5)).to eq(e_5)

    expect(e_5[:key]).to eq(0)
  end

  it 'creates an anonymous enum' do
    # enum { ANON_FIRST, ANON_SECOND, ANON_THIRD };

    @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[5]).to_s
    # enum [
    #   :first,
    #   :second,
    #   :third,
    # ]

    # There's not much we can test here.
    # Because it's anonymous, there's no way to reference it.
    # We can only verify it generates valid syntax.
  end

  it 'creates a typedef enum' do
    # typedef enum { TYPEDEF_FIRST, TYPEDEF_SECOND, TYPEDEF_THIRD } e_7_t;

    @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[6]).to_s
    # enum :e_7_t, [
    #   :first,
    #   :second,
    #   :third,
    # ]

    expect(@module.enum_type(:e_7_t)).to be_an_instance_of(FFI::Enum)

    e_7 = @module.enum_type(:e_7_t)

    expect(e_7[:first]).to eq(0)
    expect(e_7[:second]).to eq(1)
    expect(e_7[:third]).to eq(2)
  end

  it 'creates a typedef enum with a name' do
    # typedef enum e_8 { BOTH_FIRST, BOTH_SECOND, BOTH_THIRD } e_8_t;

    e_8 = @module.module_eval Generator::Enum.new(:node => (@node / 'enum')[7]).to_s + '; e_8'
    # e_8 = enum :e_8_t, [
    #   :first,
    #   :second,
    #   :third,
    # ]

    expect(@module.enum_type(:e_8_t)).to eq(e_8)

    expect(e_8[:first]).to eq(0)
    expect(e_8[:second]).to eq(1)
    expect(e_8[:third]).to eq(2)
  end
end
