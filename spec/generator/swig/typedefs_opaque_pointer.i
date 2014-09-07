%module test_typedef_opaque_pointer

typedef struct opaque_struct* opaque_pointer;
opaque_pointer func(void);
