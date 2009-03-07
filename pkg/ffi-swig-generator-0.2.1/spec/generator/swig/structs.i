%module test_struct

struct test_struct_1 {
  int i;
  char c;
  const char* s;
  const char a[5];
};

struct test_struct_2 {
  int* ptr;
};

struct test_struct_3 {
  char c[5];
};

struct test_struct_4 {
  struct test_struct_3 s[5];
};

struct test_struct_5 {
  struct test_struct_4 s;
};

