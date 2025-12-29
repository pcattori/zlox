const std = @import("std");
const repl = @import("repl.zig").repl;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    switch (args.len) {
        0 => unreachable,
        1 => try repl(),
        2 => std.debug.print("script: {s}\n", .{args[1]}),
        else => {
            std.debug.print("Usage: zlox [script]\n", .{});
            std.process.exit(64);
        },
    }
}
