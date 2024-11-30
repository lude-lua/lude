const std = @import("std");

const Build = std.Build;
const Step = Build.Step;

const BuildOptions = struct {
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
};

pub fn build(b: *std.Build) !void {
    const options = BuildOptions{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    };

    // Builds the Lude executable
    const exe = try buildExe(b, options);
    b.installArtifact(exe);

    // Step to run the Lude executable
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Only lints the Lude sources
    const check_exe = try buildExe(b, options);
    check_exe.generated_bin = null;

    // Step to check the Lude sources
    const check_step = b.step("check", "Run a check on the app sources");
    check_step.dependOn(&check_exe.step);
}

fn buildExe(b: *std.Build, options: BuildOptions) !Step.Compile {
    const exe = b.addExecutable(.{
        .name = "lude",
        .root_source_file = b.path("src/main.zig"),
        .target = options.target,
        .optimize = options.optimize,
    });

    {
        const lunaro = b.dependency("lunaro", .{
            .lua = .lua54,
            .shared = false,
            .strip = options.optimize != .Debug,
            .target = options.target,
        });
        exe.root_module.addImport("lunaro", lunaro.module("lunaro"));
    }

    return exe;
}
