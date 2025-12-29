const std = @import("std");
const Diagnostics = @import("./diagnostics.zig").Diagnostics;
const Scanner = @import("./scan.zig").Scanner;

pub fn script(allocator: std.mem.Allocator, path: []const u8) !void {
    const source = try std.fs.cwd().readFileAlloc(allocator, path, std.math.maxInt(u32));
    defer allocator.free(source);

    var diagnostics = try Diagnostics.init(allocator);
    defer diagnostics.deinit();

    var scanner: Scanner = .{ .source = source, .diagnostics = &diagnostics };
    std.debug.print("{s}", .{scanner.source});
    while (try scanner.next()) |token| {
        std.debug.print("{any}\n", .{token.kind});
    }
    for (diagnostics.list.items) |diagnostic| {
        std.debug.print("diagnostic: {s}\n", .{diagnostic.message});
    }
}
