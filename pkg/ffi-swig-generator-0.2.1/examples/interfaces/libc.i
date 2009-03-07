%module libc

%{
require 'rubygems'
require 'ffi'

module LibC
  extend FFI::Library
%}

typedef unsigned int size_t;

struct timeval {
  unsigned long tv_sec;
  unsigned long tv_usec;
};

size_t strlen (const char *s);
char * strcat (char *restrict to, const char *restrict from);
int strcmp (const char *s1, const char *s2);

int gettimeofday (struct timeval *tp, struct timezone *tzp);

%{
end
%}
