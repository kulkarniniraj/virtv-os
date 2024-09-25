pub fn memset(ptr: []u8, val: u8) void {
    for(ptr) |*p| {
        p = val;
    }
}

pub fn delay(val: u32) void {
    var i: u32 = 0;
    while (i < 1000*1000*val) : (i += 1){
        asm volatile("add x0, x0, 0");
    }    
}