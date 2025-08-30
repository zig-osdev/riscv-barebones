const std = @import("std");
const uart = @import("uart.zig");

// Here we set up a printf-like writer from the standard library by providing
// a way to output via the UART.
pub fn drainUart(w: *std.io.Writer, data: []const []const u8, splat: usize) !usize {
    _ = try uartPutStr(w.buffer);
    w.end = 0;
    var bytes_written: usize = 0;
    for (data) |slice| {
        bytes_written += try uartPutStr(slice);
    }
    if (splat == 0 or data.len < 1) return bytes_written;
    const last_data = data[data.len - 1];
    var i: usize = 0;
    while (i < splat) : (i += 1) {
        bytes_written += try uartPutStr(last_data);
    }
    return bytes_written;
}

var uart_writer = std.io.Writer{
    .buffer = &[_]u8{} ** 1024,
    .end = 0,
    .vtable = &.{ .drain = drainUart },
};

fn uartPutStr(str: []const u8) !usize {
    for (str) |ch| {
        uart.putChar(ch);
    }
    return str.len;
}

pub fn println(comptime fmt: []const u8, args: anytype) void {
    uart_writer.print(fmt ++ "\n", args) catch {};
}

// This the trap/exception entrypoint, this will be invoked any time
// we get an exception (e.g if something in the kernel goes wrong) or
// an interrupt gets delivered.
export fn trap() align(4) callconv(.c) noreturn {
    while (true) {}
}

// This is the kernel's entrypoint which will be invoked by the booting
// CPU (aka hart) after the boot code has executed.
export fn kmain() callconv(.c) void {
    // All we're doing is setting up access to the serial device (UART)
    // and printing a simple message to make sure the kernel has started!
    uart.init();
    // Who knows, maybe in the future we'll have rv128...
    println("Zig is running on barebones RISC-V (rv{})!", .{@bitSizeOf(usize)});
}
