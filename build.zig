const std = @import("std");

const _target = std.zig.CrossTarget{
    .cpu_arch = .riscv64,
    .os_tag = .freestanding,
    .abi = .none,
};

pub fn build(b: *std.Build) anyerror!void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{ .default_target = _target });

    const kernel = b.addExecutable(.{
        .root_source_file = .{ .path = "src/kernel.zig" },
        .optimize = optimize,
        .target = target,
        .name = "kernel",
    });

    kernel.setLinkerScriptPath(.{ .path = "src/linker.lds" });
    kernel.addAssemblyFile("src/boot.s");
    b.installArtifact(kernel);

    const qemu_cmd = b.addSystemCommand(&.{
        "qemu-system-riscv64", "-machine",   "virt",               "-bios",
        "none",                "-kernel",    "zig-out/bin/kernel", "-m",
        "128M",                "-cpu",       "rv64",               "-smp",
        "4",                   "-nographic", "-serial",            "mon:stdio",
    });

    qemu_cmd.step.dependOn(&kernel.step);
    if (b.args) |args| qemu_cmd.addArgs(args);
    const run_step = b.step("run", "Start the kernel in qemu");
    run_step.dependOn(&qemu_cmd.step);
}
