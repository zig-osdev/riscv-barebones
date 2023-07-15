// This is a driver for the NS16550 UART devices. It is based on the OpenSBI NS16550 driver.

// The default UART serial device is at 0x10000000 on the QEMU RISC-V virt platform
const uart_base: usize = 0x10000000;

const UART_RBR_OFFSET = 0;   // In:  Recieve Buffer Register
const UART_DLL_OFFSET = 0;   // Out: Divisor Latch Low
const UART_IER_OFFSET = 1;   // I/O: Interrupt Enable Register
const UART_DLM_OFFSET = 1;   // Out: Divisor Latch High
const UART_FCR_OFFSET = 2;   // Out: FIFO Control Register
const UART_LCR_OFFSET = 3;   // Out: Line Control Register
const UART_LSR_OFFSET = 5;   // In:  Line Status Register
const UART_MDR1_OFFSET = 8;  // I/O:  Mode Register

const UART_LSR_DR = 0x01;    // Receiver data ready
const UART_LSR_THRE = 0x20;  // Transmit-hold-register empty

fn write_reg(offset: usize, value: u8) void {
    const ptr: *volatile u8 = @ptrFromInt(uart_base + offset);
    ptr.* = value;
}

fn read_reg(offset: usize) u8 {
    const ptr: *volatile u8 = @ptrFromInt(uart_base + offset);
    return ptr.*;
}

pub fn put_char(ch: u8) void {
    // Wait for transmission bit to be empty before enqueuing more characters
    // to be outputted.
    while ((read_reg(UART_LSR_OFFSET) & UART_LSR_THRE) == 0) {}

    write_reg(0, ch);
}

pub fn get_char() ?u8 {
    // Check that we actually have a character to read, if so then we read it
    // and return it.
    if (read_reg(UART_LSR_OFFSET) & UART_LSR_DR == 1) {
        return read_reg(UART_RBR_OFFSET);
    } else {
        return null;
    }
}

pub fn init() void {
    const lcr = (1 << 0) | (1 << 1);
    write_reg(UART_LCR_OFFSET, lcr);
    write_reg(UART_FCR_OFFSET, (1 << 0));
    write_reg(UART_IER_OFFSET, (1 << 0));
    write_reg(UART_LCR_OFFSET, lcr | (1 << 7));

    const divisor: u16 = 592;
    const divisor_least: u8 = divisor & 0xff;
    const divisor_most:  u8 = divisor >> 8;
    write_reg(UART_DLL_OFFSET, divisor_least);
    write_reg(UART_DLM_OFFSET, divisor_most);

    write_reg(UART_LCR_OFFSET, lcr);
}
