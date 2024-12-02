const std = @import("std");

const Build = std.Build;

const awk_snippet =
    \\ $1 ~ /\.(version)/ {
    \\   str = substr($3, 2)
    \\   print substr(str, 1, length(str)-2)
    \\ }
;

pub fn resolveVersion(b: *Build, manifest_file: []const u8) ![]const u8 {
    var args = try std.ArrayList([]const u8).initCapacity(b.allocator, 4);
    defer args.deinit();

    args.appendAssumeCapacity(@constCast("awk"));
    args.appendAssumeCapacity(@constCast("-F "));
    args.appendAssumeCapacity(@constCast(awk_snippet));
    args.appendAssumeCapacity(manifest_file);

    var exit_code: u8 = undefined;
    const version = b.runAllowFail(args.items, &exit_code, .Ignore) catch "0.0.0";
    if (exit_code != 0)
        return "0.0.0"; // Fallback

    return version;
}
