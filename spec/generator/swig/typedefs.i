%module test_typedef

// We have to use a legitimate function as FFI needs it to exist in a library
// So we use wcstombs() since it's defined in POSIX

typedef long _size_t;
typedef unsigned short _wchar_t;
typedef _size_t __size_t;
_size_t wcstombs(char *restrict, const _wchar_t *restrict, __size_t);
struct opaque_struct;
typedef struct opaque_struct opaque_struct;
