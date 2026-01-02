const std = @import("std");
const Compilation = @import("./compilation.zig").Compilation;
const scan = @import("./scan.zig").scan;

pub fn script(allocator: std.mem.Allocator, path: []const u8) !void {
    const source = try std.fs.cwd().readFileAlloc(allocator, path, std.math.maxInt(u32));
    defer allocator.free(source);

    var ctx = Compilation.init(allocator, source);
    defer ctx.deinit();

    const tokens = try scan(&ctx);
    defer allocator.free(tokens);

    for (tokens) |token| {
        std.debug.print("{any}\n", .{token.kind});
    }
    for (ctx.diagnostics.items) |diagnostic| {
        std.debug.print("diagnostic: {s}\n", .{diagnostic.message});
    }
}
