const std = @import("std");
const ziglua = @import("ziglua");

const Lua = ziglua.Lua;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var state = try Lua.init(allocator);
    defer state.deinit();

    _ = state.pushString("Hello from Lua");
    std.debug.print("{s}\n", .{try state.toString(-1)});
}
