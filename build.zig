const std = @import("std");

pub fn build(b: *std.Build) anyerror!void {
    const optimize = b.standardOptimizeOption(.{});
    // The default target is riscv64, but we also support riscv32
    const target = b.standardTargetOptions(.{ .default_target = .{
        .cpu_arch = .riscv64,
        .os_tag = .freestanding,
        .abi = .none,
    } });

    const kernel = b.addExecutable(.{
        .root_source_file = .{ .path = "src/kernel.zig" },
        .optimize = optimize,
        .target = target,
        .name = "kernel",
        .code_model = .medium,
    });

    kernel.setLinkerScriptPath(.{ .path = "src/linker.lds" });
    // Some of the boot-code changes depending on if we're targeting 32-bit
    // or 64-bit, which is why we need the pre-processor to run first.
    kernel.addCSourceFiles(.{
        .files = &.{"src/boot.S"},
        .flags = &.{
            "-x", "assembler-with-cpp",
        },
    });
    b.installArtifact(kernel);

    const qemu = switch (target.result.cpu.arch) {
        .riscv64 => "qemu-system-riscv64",
        .riscv32 => "qemu-system-riscv32",
        else => unreachable,
    };

    const qemu_cpu = switch (target.result.cpu.arch) {
        .riscv64 => "rv64",
        .riscv32 => "rv32",
        else => unreachable,
    };

    const qemu_cmd = b.addSystemCommand(&.{
        qemu,                 "-machine",
        "virt",               "-bios",
        "none",               "-kernel",
        "zig-out/bin/kernel", "-m",
        "128M",               "-cpu",
        qemu_cpu,             "-smp",
        "4",                  "-nographic",
        "-serial",            "mon:stdio",
    });

    qemu_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| qemu_cmd.addArgs(args);
    const run_step = b.step("run", "Start the kernel in qemu");
    run_step.dependOn(&qemu_cmd.step);
}
