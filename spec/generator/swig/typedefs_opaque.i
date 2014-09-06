%module test_typedef_opaque

/* this is a separate file from typedef because we need to parse both the
 * declaration of opaque_struct, and the typedef to perform the test.
 */

struct opaque_struct;
typedef struct opaque_struct opaque_struct;
