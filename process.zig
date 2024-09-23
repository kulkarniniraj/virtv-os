const hw = @import("hwaccess.zig");

const Context = packed struct {
    ra: u64,
    sp: u64,
    s0: u64,
    s1: u64,
    s2: u64,
    s3: u64,
    s4: u64,
    s5: u64,
    s6: u64,
    s7: u64,
    s8: u64,
    s9: u64,
    s10: u64,
    s11: u64,
};

pub const Process = struct {
    pid: u16,
    PC: u64,
    SP: u64,
    // ctx: Context
};

// const ProcessQ = .{
//     .process_list: [20]* Process = .{null} ** 20
// };

const MaxProcessCount = 20;

pub var process_list: [MaxProcessCount]Process = undefined;
// .{.pid = 0, .PC = 0} ** MaxProcessCount;
export var process_queue: [MaxProcessCount]*Process = undefined;
// .{null} ** MaxProcessCount;

pub var head: u16 = 0;
pub var tail: u16 = 0;

export var next_pid: u16 = 0;

export var current_process: *Process = undefined;
export var current_process_assigned: bool = false;

pub var process_stacks: [4096*10]u8 = .{0} ** (4096*10);

pub fn createProcess(fun: *const fn () void) void {
    process_list[next_pid].pid = next_pid;
    process_list[next_pid].PC = @intFromPtr(fun);
    process_list[next_pid].SP = @intFromPtr(&process_stacks) + 
        4096 * (10 - next_pid) - 48;
    enq(&process_list[next_pid]);
    // if(current_process == null){
    //     current_process = &process_list[next_pid];
    // }
    // else{
    //     enq(&process_list[next_pid]);
    // }
    next_pid += 1;
}

pub fn enq(p: *Process) void {
    process_queue[tail] = p;
    tail = @rem(tail + 1, MaxProcessCount);
}

pub fn deq() *Process {
    const p = process_queue[head];
    head = @rem(head + 1, MaxProcessCount);
    return p;
}

pub fn switch_ctx() void {
    if (current_process_assigned == true){
        var temp: u64 = 0;
        asm volatile("mv %[reg], sp" :  [reg] "=r" (temp): :);
        enq(current_process);        
    }

    current_process = deq();
    // asm volatile("mv ra, %[reg]" :  : [reg] "r" (current_process.PC): );
    asm volatile("mv sp, %[reg]" :  : [reg] "r" (current_process.SP): );
    const pc_loc: *u64 = @ptrFromInt(current_process.SP + 40);
    pc_loc.* = current_process.PC;
    current_process_assigned = true;
}
// pub inline fn switch_ctx() void {
//     const cur = hw.read_mepc();
//     var tmp: u32 = undefined;
//     if (current_process) |cp| {
//         cp.PC = cur;
//         asm volatile("mv %[ret], sp" : [ret] "=r" (tmp):: );
//         cp.SP = tmp;        
//         enq(cp);
//     }

//     current_process = deq();
//     if (current_process) |cp| {
//         hw.write_mepc(cp.PC);
//         asm volatile("mv sp, %[reg]" :  : [reg] "r" (cp.SP): );
//     }
    
// }