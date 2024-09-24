export var stack0: [4096*10]u8 = .{0} ** (4096*10);


const uart = @import("uart.zig");
const hw = @import("hwaccess.zig");
const process = @import("process.zig");
var timer_cnt: u32 = 0;

export fn putChar(c: u8) void {
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

fn printUIntHex(x: u64) void {
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
        if(time - prev > (1000*1000*9 + 1000 * 999 + 600)){
            break;
        }
    }

}

export fn ISR() align(4) callconv(.C) void {
    // save pre ISR context    
    asm volatile(
        \\ addi sp, sp, -256
        \\ sd ra, 0(sp)
        \\ sd sp, 8(sp)
        \\ sd gp, 16(sp)
        \\ sd tp, 24(sp)
        \\ sd t0, 32(sp)
        \\ sd t1, 40(sp)
        \\ sd t2, 48(sp)
        \\ sd a0, 72(sp)
        \\ sd a1, 80(sp)
        \\ sd a2, 88(sp)
        \\ sd a3, 96(sp)
        \\ sd a4, 104(sp)
        \\ sd a5, 112(sp)
        \\ sd a6, 120(sp)
        \\ sd a7, 128(sp)
        \\ sd t3, 216(sp)
        \\ sd t4, 224(sp)
        \\ sd t5, 232(sp)
        \\ sd t6, 240(sp)
        );
    const val = hw.read_mcause() & 0xFFFF;
    if (val == 7 ){
        print("machine timer interrupt: ");
        printInt(timer_cnt);
        print("\n");
        timer_cnt += 1;
        if (@rem(timer_cnt, 3) == 0){
            print("switching ctx\n");
            print("MEPC before\n");
            printUIntHex(hw.read_mepc());
            print("\n");
            
            // var sp: u64 = undefined;
            // asm volatile("mv %[ret], sp" : [ret] "=r" (sp):: );
            // print("SP before\n");
            // printUIntHex(sp);
            // print("\n");

            // process.switch_ctx();
            print("MEPC after\n");
            // printUIntHex(hw.read_mepc());
            // print("\n");
        }
        hw.write_mtimecmp(hw.read_mtime() + 0x1000000);
    }

    // restore pre ISR context    
    asm volatile(
        \\ ld ra, 0(sp)
        \\ ld sp, 8(sp)
        \\ ld gp, 16(sp)
        \\ # not tp (contains hartid), in case we moved CPUs
        \\ ld t0, 32(sp)
        \\ ld t1, 40(sp)
        \\ ld t2, 48(sp)
        \\ ld a0, 72(sp)
        \\ ld a1, 80(sp)
        \\ ld a2, 88(sp)
        \\ ld a3, 96(sp)
        \\ ld a4, 104(sp)
        \\ ld a5, 112(sp)
        \\ ld a6, 120(sp)
        \\ ld a7, 128(sp)
        \\ ld t3, 216(sp)
        \\ ld t4, 224(sp)
        \\ ld t5, 232(sp)
        \\ ld t6, 240(sp)
        \\ addi sp, sp, 256
        \\ # post mret restoration should be included
        \\ ld      ra,40(sp)
        \\ ld      s0,32(sp)
        \\ addi    sp,sp,48

        );

    asm volatile("mret");
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
    
    const mie = hw.read_mie();
    print("MIE\n");
    printUInt(mie);

    // var i: u8 = 0;
    // while(i < 50) : (i += 1) {
    //     delayTimer();
    //     printInt(i);
    //     print(" -> ");
    // }
    print("MIP\n");
    printUIntHex(hw.read_mtime());
    print("\n");

    // hw.write_mstatus(hw.read_mstatus() | ( 1 << hw.MIE_BIT));
    // hw.write_mie(hw.read_mie() | ( 1 << hw.MTIE_BIT));
    // hw.write_mtvec(@intFromPtr(&ISR));
    // hw.write_mtimecmp(hw.read_mtime() + 0x10000);

    delayTimer();
    print("MIP\n");
    printUIntHex(hw.read_mtime());
    print("\n");

    // print("MTIME\n");
    // var i: u8 = 0;
    // while(i < 10) : (i += 1) {
    //     delayTimer();
    //     printUInt(hw.read_mtime());
    //     print(" -> ");
    // }

    var a: [50]u8 = undefined;
    const b = string.concat(&[_][]const u8 {"first ", "second\n"}, &a) catch 0;
    print(a[0..b]);

    process.createProcess(&process1);    
    process.createProcess(&process2);
    process.createProcess(&process3);
    process.switch_ctx();
    // process1();
}

pub fn process1() void {
    // var sp: u64 = undefined;
    // asm volatile("mv %[ret], sp" : [ret] "=r" (sp):: );
    // print("SP before\n");
    // printUIntHex(sp);
    // print("\n");

    while(true){
        var i: u8 = 0;
        while(i < 10) : (i += 1) {
            delayTimer();
            print("in process 1\n");
        }
        process.switch_ctx();
    }
    
    
}

pub fn process2() void {
    while(true){
        var i: u8 = 0;
        while(i < 5) : (i += 1) {
            delayTimer();
            print("in process 2\n");
        }
        process.switch_ctx();
    }
}

pub fn process3() void {
    while(true){
        var i: u8 = 0;
        while(i < 2) : (i += 1) {
            delayTimer();
            print("in process 3\n");
        }
        process.switch_ctx();
    }
}