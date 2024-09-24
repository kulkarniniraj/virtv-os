const uart = @import("uart.zig");

pub fn putChar(c: u8) void {
    uart.writeReg(uart.UART, c);
}

pub fn getCharNoBlock() ?u8 {
    if (uart.readReg(uart.UART + uart.UART_LSR_OFFSET) & uart.UART_LSR_DR == 1) {
        return uart.readReg(uart.UART + uart.UART_RBR_OFFSET);
    } else {
        return null;
    }    
} 

pub fn getChar() u8 {
    while(true){
        if(getCharNoBlock()) |c| {
            putChar(c);
            return c;
        }
    }
} 

pub fn printInt(x: i64) void {
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

pub fn printUInt(x: u64) void {
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

pub fn printUIntHex(x: u64) void {
    var x2 = x;
    var digits: [40]u8 = .{0}**40;
    var digit_cnt: u8 = 0;
    const lookup: [16]u8 = .{'0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'A', 'B', 'C', 'D', 'E', 'F'};
    
    while (true){
        digits[digit_cnt] = @intCast(@rem(x2, 16));
        digit_cnt += 1;
        x2 = @divFloor(x2, 16);
        if (x2 == 0){
            break;
        }
    }
    digit_cnt -= 1;

    while (true) : (digit_cnt -= 1){
        putChar(lookup[digits[digit_cnt]]);

        if(digit_cnt == 0){
            break;
        }
    }
}

pub fn print(str: []const u8) void {
    for (str) |c| {
        if(c == 0){
            break;
        }
        putChar(c);
    }
}

pub fn getStr(buf: [] u8, max_size: u8) void{
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
