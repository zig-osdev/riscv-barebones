// This is a driver for the NS16550 UART devices. It is based on the OpenSBI NS16550 driver.

// The default UART serial device is at 0x10000000 on the QEMU RISC-V virt platform
const uart_base: usize = 0x10000000;

const uart_rbr_offset = 0; // In:  Recieve Buffer Register
const uart_dll_offset = 0; // Out: Divisor Latch Low
const uart_ier_offset = 1; // I/O: Interrupt Enable Register
const uart_dlm_offset = 1; // Out: Divisor Latch High
const uart_fcr_offset = 2; // Out: FIFO Control Register
const uart_lcr_offset = 3; // Out: Line Control Register
const uart_lsr_offset = 5; // In:  Line Status Register
const uart_mdr1_offset = 8; // I/O:  Mode Register

const uart_lsr_dr = 0x01; // Receiver data ready
const uart_lsr_thre = 0x20; // Transmit-hold-register empty

fn writeReg(offset: usize, value: u8) void {
    const ptr: *volatile u8 = @ptrFromInt(uart_base + offset);
    ptr.* = value;
}

fn readReg(offset: usize) u8 {
    const ptr: *volatile u8 = @ptrFromInt(uart_base + offset);
    return ptr.*;
}

pub fn putChar(ch: u8) void {
    // Wait for transmission bit to be empty before enqueuing more characters
    // to be outputted.
    while ((readReg(uart_lsr_offset) & uart_lsr_thre) == 0) {}

    writeReg(0, ch);
}

pub fn get_char() ?u8 {
    // Check that we actually have a character to read, if so then we read it
    // and return it.
    if (readReg(uart_lsr_offset) & uart_lsr_dr == 1) {
        return readReg(uart_rbr_offset);
    } else {
        return null;
    }
}

pub fn init() void {
    const lcr = (1 << 0) | (1 << 1);
    writeReg(uart_lcr_offset, lcr);
    writeReg(uart_fcr_offset, (1 << 0));
    writeReg(uart_ier_offset, (1 << 0));
    writeReg(uart_lcr_offset, lcr | (1 << 7));

    const divisor: u16 = 592;
    const divisor_least: u8 = divisor & 0xff;
    const divisor_most: u8 = divisor >> 8;
    writeReg(uart_dll_offset, divisor_least);
    writeReg(uart_dlm_offset, divisor_most);

    writeReg(uart_lcr_offset, lcr);
}
