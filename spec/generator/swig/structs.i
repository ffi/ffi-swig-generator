%module test_struct

struct test_struct_1 {
  int i;
  char c;
  const char* s;
  const char a[5];
  const char b[5+1];
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

struct test_struct_6 {
  struct test_struct_4 *s;
};

struct test_struct_7 {
  struct undefined_struct *s;
};

struct test_struct_8 {
  union {
    int arg;
  } data;
};

struct test_struct_9 {
  const struct test_struct_9 *(*fn)(int);
};
