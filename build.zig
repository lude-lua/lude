const std = @import("std");
const builtin = @import("builtin");
const resolver = @import("./build/resolver.zig");

const Build = std.Build;
const Step = Build.Step;

const BuildOptions = struct {
    target: Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    version: []const u8 = "",
};

// Make sure in-sync with manifest file
const minimium_requirement = "0.13.0";

comptime {
    if (!std.mem.eql(u8, builtin.zig_version_string, minimium_requirement)) {
        @compileError("" ++
            "Lude requires Zig version " ++ minimium_requirement ++ ", while the current one has version " ++
            builtin.zig_version_string ++ ". Try download the specified Zig version to build Lude.");
    }
}

pub fn build(b: *std.Build) !void {
    var options = BuildOptions{
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    };

    const version = try resolver.resolveVersion(b, b.pathFromRoot("build.zig.zon"));
    options.version = version;

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

fn buildExe(b: *std.Build, options: BuildOptions) !*Step.Compile {
    const exe = b.addExecutable(.{
        .name = "lude",
        .version = std.SemanticVersion.parse(options.version) catch unreachable,
        .root_source_file = b.path("src/main.zig"),
        .target = options.target,
        .optimize = options.optimize,
    });

    {
        const ziglua = b.dependency("ziglua", .{
            .target = options.target,
            .optimize = options.optimize,
            .lang = .lua54,
            .shared = false,
        });
        exe.root_module.addImport("ziglua", ziglua.module("ziglua"));
    }

    return exe;
}
