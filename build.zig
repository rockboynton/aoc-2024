const std = @import("std");
const testing = std.testing;

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const day = b.option(u8, "day", "Specify the day to build and run").?;

    var buffer: [32]u8 = undefined;
    var result = try std.fmt.bufPrint(&buffer, "day{d:02}", .{day});
    const dayName = result[0..result.len];
    var buffer2: [32]u8 = undefined;
    result = try std.fmt.bufPrint(&buffer2, "src/{s}.zig", .{dayName});
    const dayFile = result[0..result.len];

    const exe = b.addExecutable(.{
        .name = dayName,
        .root_source_file = b.path(dayFile),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path(dayFile),
        .target = target,
        .optimize = optimize,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
