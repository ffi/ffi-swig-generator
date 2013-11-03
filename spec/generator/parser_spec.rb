require File.join(File.dirname(__FILE__), %w[.. spec_helper])

include FFI
require 'ffi'

describe Generator::Parser do
  context 'using %import' do
    before(:all) do
      @node_1 = generate_xml_wrap_from('import_1')
      @node_2 = generate_xml_wrap_from('import_2')
      @module = Module.new
      @module.module_exec do
        extend FFI::Library
        ffi_lib FFI::Library::LIBC
      end
    end

    it 'should be able to parse %import' do
      Generator::Parser.new.generate(@node_2)
    end

    it 'should not act like %include' do
      # this is supposed to raise an exception because it has a function which uses a type declared in @node_1
      expect{@module.module_eval Generator::Parser.new.generate(@node_2)}.to raise_error(TypeError)
    end

    it 'should work when both are loaded' do
      @module.module_eval Generator::Parser.new.generate(@node_1)
      @module.module_eval Generator::Parser.new.generate(@node_2)

      expect(@module.method(:malloc)).to be_a(Method)
      expect(@module.find_type(:my_size_t)).to be_a(FFI::Type)
    end
  end

  context 'full module' do
    it_should_behave_like 'All specs'
    before do
      @node = generate_xml_wrap_from('testlib')
    end

    it 'should generate ruby ffi wrap code' do
      Generator::Parser.new.generate(@node).should == <<EOC

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
  class CamelCaseStruct < FFI::Struct
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
  Callback_cb = callback(:cb, [ :string, :string ], :void)
  Callback_cb_2 = callback(:cb_2, [ :string, :string ], :pointer)
  Callback_cb_3 = callback(:cb_3, [ :string, CamelCaseStruct ], CamelCaseStruct)
  class TestStruct2 < FFI::Struct
    layout(
           :s, TestStruct,
           :camel_case_struct, CamelCaseStruct,
           :s_3, TestStruct3,
           :e, :int,
           :func, Callback_cb,
           :u, UnionT,
           :callback, Callback_cb,
           :inline_callback, callback([ Callback_cb_2 ], :void)
    )
    def func=(cb)
      @func = cb
      self[:func] = @func
    end
    def func
      @func
    end
    def callback=(cb)
      @callback = cb
      self[:callback] = @callback
    end
    def callback
      @callback
    end
    def inline_callback=(cb)
      @inline_callback = cb
      self[:inline_callback] = @inline_callback
    end
    def inline_callback
      @inline_callback
    end

  end
  class TestStruct4 < FFI::Struct
    layout(
           :string, :pointer,
           :inline_callback, callback([  ], :void)
    )
    def string=(str)
      @string = FFI::MemoryPointer.from_string(str)
      self[:string] = @string
    end
    def string
      @string.get_string(0)
    end
    def inline_callback=(cb)
      @inline_callback = cb
      self[:inline_callback] = @inline_callback
    end
    def inline_callback
      @inline_callback
    end

  end
  class TestStruct5BigUnionFieldNestedStructField1 < FFI::Struct
    layout(
           :a, :int,
           :b, :int
    )
  end
  class TestStruct5BigUnionFieldNestedStructField2 < FFI::Struct
    layout(
           :c, :int,
           :d, :int
    )
  end
  class TestStruct5BigUnionFieldNestedStructField3 < FFI::Struct
    layout(
           :e, :int,
           :f, :int
    )
  end
  class TestStruct5BigUnionFieldUnionField < FFI::Union
    layout(
           :l, :long,
           :ll, :long_long
    )
  end
# FIXME: Nested structures are not correctly supported at the moment.
# Please check the order of the declarations in the structure below.
#   class TestStruct5BigUnionField < FFI::Union
#     layout(
#            :f, :float,
#            :union_field, TestStruct5BigUnionFieldUnionField,
#            :nested_struct_field_3, TestStruct5BigUnionFieldNestedStructField3,
#            :nested_struct_field_2, TestStruct5BigUnionFieldNestedStructField2,
#            :nested_struct_field_1, TestStruct5BigUnionFieldNestedStructField1
#     )
#   end
# FIXME: Nested structures are not correctly supported at the moment.
# Please check the order of the declarations in the structure below.
#   class TestStruct5 < FFI::Struct
#     layout(
#            :i, :int,
#            :c, :char,
#            :big_union_field, TestStruct5BigUnionField
#     )
#   end
  attach_function :get_int, [ :pointer ], :int
  attach_function :get_char, [ :pointer ], :char
  attach_function :func_with_enum, [ :int ], :int
  attach_function :func_with_enum_2, [ :int ], :int
  attach_function :func_with_typedef, [  ], :uchar

end
EOC
    end
    it 'should ignore given declarations' do
      parser = Generator::Parser.new    
      parser.ignore 'CONST_1', 'e_1', 'test_struct', 'test_struct_5'
      parser.ignore(/^func_with_enum/)
      parser.generate(@node).should == <<EOC

module TestLib
  extend FFI::Library
  CONST_2 = 0x20
  class UnionT < FFI::Union
    layout(
           :c, :char,
           :f, :float
    )
  end
  class CamelCaseStruct < FFI::Struct
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
  Callback_cb = callback(:cb, [ :string, :string ], :void)
  Callback_cb_2 = callback(:cb_2, [ :string, :string ], :pointer)
  Callback_cb_3 = callback(:cb_3, [ :string, CamelCaseStruct ], CamelCaseStruct)
  class TestStruct2 < FFI::Struct
    layout(
           :s, TestStruct,
           :camel_case_struct, CamelCaseStruct,
           :s_3, TestStruct3,
           :e, :int,
           :func, Callback_cb,
           :u, UnionT,
           :callback, Callback_cb,
           :inline_callback, callback([ Callback_cb_2 ], :void)
    )
    def func=(cb)
      @func = cb
      self[:func] = @func
    end
    def func
      @func
    end
    def callback=(cb)
      @callback = cb
      self[:callback] = @callback
    end
    def callback
      @callback
    end
    def inline_callback=(cb)
      @inline_callback = cb
      self[:inline_callback] = @inline_callback
    end
    def inline_callback
      @inline_callback
    end

  end
  class TestStruct4 < FFI::Struct
    layout(
           :string, :pointer,
           :inline_callback, callback([  ], :void)
    )
    def string=(str)
      @string = FFI::MemoryPointer.from_string(str)
      self[:string] = @string
    end
    def string
      @string.get_string(0)
    end
    def inline_callback=(cb)
      @inline_callback = cb
      self[:inline_callback] = @inline_callback
    end
    def inline_callback
      @inline_callback
    end

  end
  attach_function :get_int, [ :pointer ], :int
  attach_function :get_char, [ :pointer ], :char
  attach_function :func_with_typedef, [  ], :uchar

end
EOC
    end

    it 'should prepend struct prerequisites' do
      m = Module.new
      m.module_exec do
        extend FFI::Library
      end
      xml = generate_xml_wrap_from('parser_prereqs')
      m.module_eval Generator::Parser.new.generate(xml)
    end

    it 'should not use pointers to opaque structs' do
      m = Module.new
      m.module_exec do
        extend FFI::Library
      end
      xml = generate_xml_wrap_from('parser_opaque_struct')
      buf = Generator::Parser.new.generate(xml)
      buf.include?("OpaqueStruct.ptr").should == false
      buf.include?("OtherStruct.ptr").should == true
    end
  end
end
