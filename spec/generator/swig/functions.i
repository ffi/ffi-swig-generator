%module function_testlib

int func_1(char c, int i);
unsigned int func_2(int* p1, int* p2, char** p3);
void func_3(char* str);
char *func_4(int i);
extern void func_5();
void func_6(void** ptr);
void func_7(enum e e1);
enum e { E_1, E_2 };
enum e func_8();
struct test_struct {
  char c;
};
void func_9(struct test_struct s);
struct test_struct func_10();
void func_11(void);
void func_12(void (*callback)(float));
void func_13(int (*callback)(double, float));
void func_14(void (*callback)(char* str));
void func_15(void (*callback)(void));
const char* func_16();
const unsigned char * func_17();
void func_18(...);
volatile void func_19(volatile int value);
void func_20(void *p1, void (*callback)(const char* str, void *p2, void *p3 ), void *p4);
void func_21(void *p1, void (*callback)(const unsigned char uc, void *p2, void *p3 ), void *p4);

typedef struct CamelStruct {
  char c;
} CamelStruct;
void func_22(CamelStruct s);
CamelStruct func_23(void);
void func_24(char buf[12]);
void func_25(CamelStruct *s);
