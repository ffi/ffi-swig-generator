%module test_typedefs_struct

typedef struct typedefed_struct {
  int i;
  char c;
} typedefed_struct;

struct other_struct {
  typedefed_struct s;
  int i;
};

int func(typedefed_struct *s);
