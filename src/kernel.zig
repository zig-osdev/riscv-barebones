export fn trap() callconv(.C) noreturn {
    while (true) {}
}

export fn kmain() callconv(.C) void {
    // Kernel entrypoint goes here
}
