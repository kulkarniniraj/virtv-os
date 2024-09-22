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

fn printInt(x: i64) void {
    var x2 = x;
    var digits: [40]u8 = .{0}**40;
    var digit_cnt: u8 = 0;
    if(x < 0){
        putChar('-');
        x2 = -x;
    }
    else if (x == 0){
        putChar('0');
        return;
    }

    while (true){
        digits[digit_cnt] = @intCast(@rem(x2, 10));
        digit_cnt += 1;
        x2 = @divFloor(x2, 10);
        if (x2 == 0){
            break;
        }
    }
    digit_cnt -= 1;

    while (true) : (digit_cnt -= 1){
        putChar(@intCast('0' + digits[digit_cnt]));
        if(digit_cnt == 0){
            break;
        }
    }
}

fn printUInt(x: u64) void {
    var x2 = x;
    var digits: [40]u8 = .{0}**40;
    var digit_cnt: u8 = 0;
    
    while (true){
        digits[digit_cnt] = @intCast(@rem(x2, 10));
        digit_cnt += 1;
        x2 = @divFloor(x2, 10);
        if (x2 == 0){
            break;
        }
    }
    digit_cnt -= 1;

    while (true) : (digit_cnt -= 1){
        putChar(@intCast('0' + digits[digit_cnt]));

        if(digit_cnt == 0){
            break;
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

fn delay() void {
    var i: u32 = 0;
    while (i < 1000*1000*100) : (i += 1){
        asm volatile("add x0, x0, 0");
    }    
}

fn delayTimer() void {
    var time: u64 = 0;
    var prev: u64 = 0;
    asm volatile("rdtime %[ret]" : [ret] "=r" (prev):: );
    while(true){
        asm volatile("rdtime %[ret]" : [ret] "=r" (time):: );
        if(time - prev > 1000*1000*10){
            break;
        }
    }

}

export fn ISR() align(4) callconv(.Naked) void {
    
}

export fn start() void {
    // var time: u64 = 0;
    uart.init();

    // var input: [80]u8 = undefined;
    const str1 = "CMD > ";
    // print("Hellow World!!!\n");
    print(str1);
    // getStr(&input, 80);
    print("\n");
    // print(&input);
    // printInt(1234);
    // print("\nUint\n");
    // printUInt(12345);

    // asm volatile("rdtime %[ret]" : [ret] "=r" (time):: );
    // print("\nTime\n");
    // printUInt(time);

    // delay();

    // asm volatile("rdtime %[ret]" : [ret] "=r" (time):: );
    // print("\nTime\n");
    // printUInt(time);

    // delay();

    // asm volatile("rdtime %[ret]" : [ret] "=r" (time):: );
    // print("\nTime\n");
    // printUInt(time);

    // delay();

    // asm volatile("rdtime %[ret]" : [ret] "=r" (time):: );
    // print("\nTime\n");
    // printUInt(time);

    // delay();

    var i: u8 = 0;
    while(i < 50) : (i += 1) {
        delayTimer();
        printInt(i);
        print(" -> ");
    }

    while(true){
        // asm volatile("add x0, x0, 0");
    }

}