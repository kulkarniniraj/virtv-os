const MIE = packed struct {

};

pub const MIE_BIT = 3;
pub const MTIE_BIT = 7;
pub const CLINT_BASE = 0x2000000 + 0x4000;
pub const CLINT_MTIMECMP_OFFSET	= 0x0000;
pub const CLINT_MTIME_OFFSET = 0x7ff8;

pub fn writeReg(comptime T: type, addr: usize, val: T) void {
    const ptr: *volatile T = @ptrFromInt(addr);
    ptr.* = val;
}

pub fn readReg(comptime T: type, addr: usize) T {
    const ptr: *volatile T = @ptrFromInt(addr);
    return ptr.*;
}

// pub fn readCSR(reg_name: []const u8) u64 {

// }

pub fn read_mstatus() u64 {
    var val: u64 = 0;
    asm volatile("csrr %[ret], mstatus" : [ret] "=r" (val):: );
    return val;
}

pub fn write_mstatus(val: u64) void {
    asm volatile("csrw mstatus, %[val]" :  : [val] "r" (val): );
}

pub fn read_mie() u64 {
    var val: u64 = 0;
    asm volatile("csrr %[ret], mie" : [ret] "=r" (val):: );
    return val;
}

pub fn write_mie(val: u64) void {
    asm volatile("csrw mie, %[val]" :  : [val] "r" (val): );
}

pub fn write_mtvec(val: u64) void {
    asm volatile("csrw mtvec, %[val]" :  : [val] "r" (val): );
}

pub fn read_mip() u64 {
    var val: u64 = 0;
    asm volatile("csrr %[ret], mip" : [ret] "=r" (val):: );
    return val;
}

pub fn read_mcause() u64 {
    var val: u64 = 0;
    asm volatile("csrr %[ret], mcause" : [ret] "=r" (val):: );
    return val;
}

pub fn read_mtime() u64 {
    return readReg(u64, CLINT_BASE + CLINT_MTIME_OFFSET);
}

pub fn write_mtimecmp(val: u64) void {
    writeReg(u64, CLINT_BASE + CLINT_MTIMECMP_OFFSET, val);
}