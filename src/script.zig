const std = @import("std");
const ParseContext = @import("parse.zig").Context;
const parse = @import("parse.zig").parse;

pub fn script(allocator: std.mem.Allocator, path: []const u8) !void {
    const source = try std.fs.cwd().readFileAlloc(allocator, path, std.math.maxInt(u32));
    defer allocator.free(source);

    var ctx = ParseContext.init(allocator, source);
    defer ctx.deinit();

    var ast = try parse(&ctx);
    defer ast.deinit();

    if (ctx.errors.items.len > 0) {
        for (ctx.errors.items) |err| {
            std.debug.print("error: {s}\n", .{err.message});
        }
        return;
    }
}
