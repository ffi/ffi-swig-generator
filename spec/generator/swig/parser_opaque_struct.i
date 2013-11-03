%module parser_opaque_struct

struct other_struct {
  int a;
};

struct opaque_struct;
struct opaque_struct *alloc_opaque_struct(void);
struct other_struct *alloc_other_struct(void);
