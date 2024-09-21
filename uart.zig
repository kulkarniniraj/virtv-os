pub const UART: usize = 0x10000000;
pub const UART_RBR_OFFSET = 0;   // In:  Recieve Buffer Register
pub const UART_DLL_OFFSET = 0;   // Out: Divisor Latch Low
pub const UART_IER_OFFSET = 1;   // I/O: Interrupt Enable Register
pub const UART_DLM_OFFSET = 1;   // Out: Divisor Latch High
pub const UART_FCR_OFFSET = 2;   // Out: FIFO Control Register
pub const UART_LCR_OFFSET = 3;   // Out: Line Control Register
pub const UART_LSR_OFFSET = 5;   // In:  Line Status Register
pub const UART_MDR1_OFFSET = 8;  // I/O:  Mode Register
pub const UART_LSR_DR = 0x01;    // Receiver data ready
pub const UART_LSR_THRE = 0x20;  // Transmit-hold-register empty

var uartPtr: *volatile u8 = @ptrFromInt(UART);

pub fn writeReg(addr: usize, c: u8) void {
    const ptr: *volatile u8 = @ptrFromInt(addr);
    ptr.* = c;
}

pub fn readReg(addr: usize) u8 {
    const ptr: *volatile u8 = @ptrFromInt(addr);
    return ptr.*;
}

pub fn init() void {
    writeReg(UART + UART_FCR_OFFSET, (1 << 0));
}
