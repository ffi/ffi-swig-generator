%module parser_prereqs

struct outer_struct {
  struct inner_struct *in;
};

struct inner_struct {
  char *bears;
};
