%module types_test

char *string;
void *ptr;
char **ptr_2;

int array[5];
char* ptr_array[5];

struct test_struct {
  char c;
};

enum e { E_1, E_2, E_3 };

struct test_struct ts;
struct test_struct a[5];
enum e enum_array[5];

const int ci;
const char* cstring;

bool b;
char c;
double d;
float f;
int i;
int8_t i8;
int16_t i16;
int32_t i32;
int64_t i64;
intptr_t iptr;
long l;
long int li;
long long ll;
long long int lli;
long unsigned int lui;
short s;
signed char sc;
signed int si;
signed long sl;
signed long int sli;
signed long long sll;
signed long long int slli;
signed short ss;
signed short int ssi;
size_t sizet;
unsigned char uc;
unsigned int ui;
uint8_t u8;
uint16_t u16;
uint32_t u32;
uint64_t u64;
unsigned long ul;
unsigned long int uli;
unsigned long long ull;
unsigned long long int ulli;
unsigned short us;
unsigned short int usi;
void v;



