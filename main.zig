export var stack0: [4096*10]u8 = .{0} ** (4096*10);


const uart = @import("uart.zig");
const hw = @import("hwaccess.zig");
const process = @import("process.zig");
const string = @import("string.zig");
const stdio = @import("stdio.zig");
extern var _isr: u64;

var timer_cnt: u32 = 0;

export fn putChar(c: u8) void {
    uart.writeReg(uart.UART, c);
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

// export fn ISR() align(4) callconv(.C) void {
export fn ISR() align(4) callconv(.C) void {
    
    
    var val = hw.read_mcause();

    const itype = val & 0x8000000000000000;

    if(itype != 0) {
        stdio.print("interrupt\n");
    }
    else {
        stdio.print("exception ");
        stdio.printUIntHex(val);
        stdio.print("\nmepc: ");
        stdio.printUIntHex(hw.read_mepc());
        stdio.print("\n");
        
    }
    
    val &= 0xFFFF;

    // if (val != 1){
    if(true){
        stdio.print("mcause register: ");
        stdio.printUIntHex(val);
        stdio.print("\n");
    }
    

    
    if (val == 7 ){
        stdio.print("machine timer interrupt: ");
        stdio.printInt(timer_cnt);
        stdio.print("\n");
        timer_cnt += 1;
        if (@rem(timer_cnt, 3) == 0){
            // stdio.print("switching ctx\n");
            // stdio.print("MEPC before\n");
            // stdio.printUIntHex(hw.read_mepc());
            // stdio.print("\n");
            
            // var mysp: u64 = 0;
            // asm volatile("mv %[ret], sp" : [ret] "=r" (mysp):: );
            // stdio.print("SP before\n");
            // stdio.printUIntHex(sp);
            // stdio.print("\n");

            // process.switch_ctx();
            stdio.print("MEPC after\n");
            // stdio.printUIntHex(hw.read_mepc());
            // stdio.print("\n");
        }
        hw.write_mtimecmp(hw.read_mtime() + 0x1000000);
    }else if (val == 9){
        stdio.print("disk interrup detected\n");
    }

    
}

export fn start() void {
    // var time: u64 = 0;
    uart.init();

    // var input: [80]u8 = undefined;
    const str1 = "CMD > ";
    stdio.print(str1);
    // getStr(&input, 80);
    stdio.print("\n");
    
    const mie = hw.read_mie();
    stdio.print("MIE\n");
    stdio.printUInt(mie);

    stdio.print("MIP\n");
    stdio.printUIntHex(hw.read_mtime());
    stdio.print("\n");

    hw.write_mstatus(hw.read_mstatus() | ( 1 << hw.MIE_BIT));
    // hw.write_mie(hw.read_mie() | ( 1 << hw.MTIE_BIT) | (1 << hw.MSIE_BIT) | (1 << hw.MEIE_BIT));
    hw.write_mie(hw.read_mie() | ( 1 << hw.MTIE_BIT));
    hw.write_mtvec(@intFromPtr(&_isr));
    // hw.write_mtvec(@intFromPtr(&ISR));
    hw.write_mtimecmp(hw.read_mtime() + 0x10000);

    delayTimer();
    stdio.print("MIP\n");
    stdio.printUIntHex(hw.read_mtime());
    stdio.print("\n");

    // stdio.print("MTIME\n");
    // var i: u8 = 0;
    // while(i < 10) : (i += 1) {
    //     delayTimer();
    //     stdio.printUInt(hw.read_mtime());
    //     stdio.print(" -> ");
    // }


    var a: [50]u8 = undefined;
    const b = string.concat(&[_][]const u8 {"first ", "second\n"}, &a) catch 0;
    stdio.print(a[0..b]);

    process.createProcess(&process1);    
    process.createProcess(&process2);
    process.createProcess(&process3);
    process.switch_ctx();    
}

pub fn process1() void {
    // var sp: u64 = undefined;
    // asm volatile("mv %[ret], sp" : [ret] "=r" (sp):: );
    // stdio.print("SP before\n");
    // stdio.printUIntHex(sp);
    // stdio.print("\n");

    while(true){
        var i: u8 = 0;
        while(i < 10) : (i += 1) {
            delayTimer();
            stdio.print("in process 1: ");
            stdio.printInt(i);
            stdio.print("\n");
        }
        process.switch_ctx();
    }
    
    
}

pub fn process2() void {
    while(true){
        var i: u8 = 0;
        while(i < 5) : (i += 1) {
            delayTimer();
            stdio.print("in process 2\n");
        }
        process.switch_ctx();
    }
}

pub fn process3() void {
    while(true){
        var i: u8 = 0;
        while(i < 2) : (i += 1) {
            delayTimer();
            stdio.print("in process 3\n");
        }
        process.switch_ctx();
    }
}