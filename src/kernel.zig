const std = @import("std");
const uart = @import("uart.zig");

// Here we set up a printf-like writer from the standard library by providing
// a way to output via the UART.
const Writer = std.io.Writer(u32, error{}, uart_put_str);
const uart_writer = Writer { .context = 0 };

fn uart_put_str(_: u32, str: []const u8) !usize {
    for (str) |ch| {
        uart.put_char(ch);
    }
    return str.len;
}

pub fn println(comptime fmt: []const u8, args: anytype) void {
    uart_writer.print(fmt ++ "\n", args) catch {};
}

// This the trap/exception entrypoint, this will be invoked any time
// we get an exception (e.g if something in the kernel goes wrong) or
// an interrupt gets delivered.
export fn trap() callconv(.C) noreturn {
    while (true) {}
}

// This is the kernel's entrypoint which will be invoked by the booting
// CPU (aka hart) after the boot code has executed.
export fn kmain() callconv(.C) void {
    // All we're doing is setting up access to the serial device (UART)
    // and printing a simple message to make sure the kernel has started!
    uart.init();
    // Who knows, maybe in the future we'll have rv128...
    println("Zig is running on barebones RISC-V (rv{})!", .{ @bitSizeOf(usize) });
}
