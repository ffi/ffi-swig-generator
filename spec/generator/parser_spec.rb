require File.join(File.dirname(__FILE__), %w[.. spec_helper])

include FFI

describe Generator::Parser do
  it_should_behave_like 'All specs'
  before :all do
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
  callback(:cb, [ :string, :string ], :void)
  callback(:cb_2, [ :string, :string ], :pointer)
  callback(:cb_3, [ :string, CamelCaseStruct ], CamelCaseStruct)
  class TestStruct2 < FFI::Struct
    layout(
           :s, TestStruct,
           :camel_case_struct, CamelCaseStruct,
           :s_3, TestStruct3,
           :e, :int,
           :func, :cb,
           :u, UnionT,
           :callback, :cb,
           :inline_callback, callback([  ], :void)
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
end
