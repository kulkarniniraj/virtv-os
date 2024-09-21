// void main(){
//     int a = cpuid();
// }

typedef unsigned long uint64;
__attribute__((aligned(16))) char stack0[4096];
unsigned char *uart = (unsigned char *)0x10000000; 

static inline uint64 r_tp()
{
    uint64 x;
    asm volatile("mv %0, tp" : "=r"(x));
    return x;
}

int cpuid()
{
    int id = r_tp();
    return id;
}

void putchar(char c) {
	*uart = c;
	return;
}
 
void print(const char * str) {
	while(*str != '\0') {
		putchar(*str);
		str++;
	}
	return;
}

void start()
{
    int a = cpuid();
    a += 2;
    print("Hellow World!!!\n");
    while(1){

    }

}