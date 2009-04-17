class Scenario1

class << self

def interface_dir
  '.'
end

def create_file(fn, &blk)
  File.open(fn, 'w') do |file|
    yield file
  end  
end
 
def generate
  FileUtils.mkdir interface_dir unless File.exists?(interface_dir)
  create_file(File.join(interface_dir, 'interface.i')) { |file| file << interface_template }
  create_file('Rakefile') { |file| file << rakefile_template }
end

def interface_template
<<-EOF
%module testlib

%{
module TestLib
  extend FFI::Library
%}

#define CONST_1 0x10
#define CONST_2 0x20

typedef unsigned char byte;
typedef enum e_1 { 
  ENUM_1, ENUM_2, ENUM_3 
} enum_t;

union union_t {
  char c;
  float f;
};

struct test_struct {
  int i;
  char c;
  byte b;
};

struct CamelCaseStruct {
  int i;
  char c;
  byte b;
};

typedef struct {
  char c;
} test_struct_3;

typedef void (*cb)(char*, char*);
typedef void * (*cb_2)(char*, const char *);
typedef CamelCaseStruct (*cb_3)(char*, CamelCaseStruct);

struct test_struct_2 {
  struct test_struct s;
  CamelCaseStruct camel_case_struct;
  test_struct_3 s_3;
  enum_t e;
  cb func;
  union_t u;
  cb callback;
  void (*inline_callback)();
};

// struct with getter/setter method for strings and callbacks

struct _test_struct_4 {
  char* string;
  void (*inline_callback)();
};

struct test_struct_5 {
  int i;
  union {
    struct {
      int a;
      int b;
    } nested_struct_field_1;
    struct {
      int c;
      int d;
    } nested_struct_field_2;
    struct {
      int e;
      int f;
    } nested_struct_field_3;
    union {
      long l;
      long long ll;
    } union_field;
    float f;
  } big_union_field;
  char c;
};

int get_int(struct test_struct* s);
char get_char(struct test_struct* s);
int func_with_enum(enum e_1 e);
int func_with_enum_2(enum_t e);
byte func_with_typedef();
%{
end
%}
EOF
end

def result_template
<<-EOF

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
EOF
end

def rakefile_template
<<-EOF
require '../lib/ffi-swig-generator'

FFI::Generator::Task.new
EOF
end

end

end

class Scenario2 < Scenario1
  
class << self

def interface_dir
  'interfaces'
end

def rakefile_template
<<-EOF
require 'rubygems'
require 'ffi-swig-generator'

FFI::Generator::Task.new :input_fn => 'interfaces/*.i', :output_dir => 'generated/'

EOF
end

end

end

class Scenario3 < Scenario2
  
class << self

def rakefile_template
<<-EOF
require 'rubygems'
require '../lib/ffi-swig-generator'

FFI::Generator::Task.new do |task|
  task.input_fn = 'interfaces/*.i'
  task.output_dir = 'generated/'
end

EOF
end

end

end

class Scenario4 < Scenario3
  
class << self

def generate
  super
  create_file(File.join(interface_dir, 'interface.rb')) { |file| file << config_template }
end

def rakefile_template
<<-EOF
require 'rubygems'
require '../lib/ffi-swig-generator'

FFI::Generator::Task.new do |task|
  task.input_fn = 'interfaces/*.i'
  task.output_dir = 'generated/'
end

EOF
end

def interface_template
<<-EOF
%module my_interface

#define CONST_1 0xff1;
#define CONST_2 0Xff2;

typedef struct {
  char a;
  char b;
} my_struct_1;

typedef struct {
  char c;
  char d;
} my_struct_2;

EOF
end

def result_template
<<-EOF
  CONST_1 = 0xff1
  class MyStruct1 < FFI::Struct
    layout(
           :a, :char,
           :b, :char
    )
  end
EOF
end

def config_template
<<-EOF
ignore 'my_struct_2', 'CONST_2'
EOF
end

end

end
