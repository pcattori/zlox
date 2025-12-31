const std = @import("std");
const Diagnostic = @import("./diagnostic.zig").Diagnostic;
const scan = @import("./scan.zig").scan;

pub fn script(allocator: std.mem.Allocator, path: []const u8) !void {
    const source = try std.fs.cwd().readFileAlloc(allocator, path, std.math.maxInt(u32));
    defer allocator.free(source);

    var diagnostics: std.ArrayList(Diagnostic) = .empty;
    defer diagnostics.deinit(allocator);

    const tokens = try scan(allocator, source, &diagnostics);
    defer allocator.free(tokens);

    for (tokens) |token| {
        std.debug.print("{any}\n", .{token.kind});
    }
    for (diagnostics.items) |diagnostic| {
        std.debug.print("diagnostic: {s}\n", .{diagnostic.message});
    }
}
