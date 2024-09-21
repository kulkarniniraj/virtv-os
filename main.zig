export var stack0: [4096]u8 = .{0} ** 4096;
const uart = @import("uart.zig");

fn putChar(c: u8) void {
    uart.writeReg(uart.UART, c);
}

fn getCharNoBlock() ?u8 {
    if (uart.readReg(uart.UART + uart.UART_LSR_OFFSET) & uart.UART_LSR_DR == 1) {
        return uart.readReg(uart.UART + uart.UART_RBR_OFFSET);
    } else {
        return null;
    }    
} 

fn getChar() u8 {
    while(true){
        if(getCharNoBlock()) |c| {
            putChar(c);
            return c;
        }
    }
} 

fn print(str: []const u8) void {
    for (str) |c| {
        if(c == 0){
            break;
        }
        putChar(c);
    }
}

fn getStr(buf: [] u8, max_size: u8) void{
    var i: u8 = 0;
    while (i < max_size) : (i += 1) {
        const c = getChar();
        
        if((c == '\n') or (c == '\r')){
            buf[i] = 0;
            return;
        }

        buf[i] = c;
    }
}

export fn start() void {
    uart.init();

    var input: [80]u8 = undefined;
    const str1 = "CMD > ";
    // print("Hellow World!!!\n");
    print(str1);
    getStr(&input, 80);
    print("\n");
    print(&input);
    while(true){
        // asm volatile("add x0, x0, 0");
    }

}