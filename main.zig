// __attribute__((aligned(16))) char stack0[4096];

// @export(stack, .{.name = "stack"});
export var stack0: [4096]u8 = .{0} ** 4096;
// unsigned char *uart = (unsigned char *)0x10000000; 
const UART: usize = 0x10000000;
var uartPtr: *volatile u8 = @ptrFromInt(UART);

fn putchar(c: u8) void {
    uartPtr.* = c;
}
// void putchar(char c) {
// 	*uart = c;
// 	return;
// }
 
fn print(str: []const u8) void {
    for (str) |c| {
        putchar(c);
    }

}
// void print(const char * str) {
// 	while(*str != '\0') {
// 		// putchar(*str);
//         uartputc(*str);
// 		str++;
// 	}
// 	return;
// }

export fn start() void {
    const str1 = "Hellow World 2!!!\n";
    // print("Hellow World!!!\n");
    print(str1);
    while(true){
        // asm volatile("add x0, x0, 0");
    }

}