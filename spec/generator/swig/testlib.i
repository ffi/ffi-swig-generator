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

int get_int(struct test_struct* s);
char get_char(struct test_struct* s);
int func_with_enum(enum e_1 e);
int func_with_enum_2(enum_t e);
byte func_with_typedef();
%{
end
%}
