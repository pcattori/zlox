const std = @import("std");
const Span = @import("span.zig").Span;

pub const Compilation = struct {
    allocator: std.mem.Allocator,
    source: []const u8,
    diagnostics: std.ArrayList(Diagnostic),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Self {
        return .{
            .allocator = allocator,
            .source = source,
            .diagnostics = .empty,
        };
    }

    pub fn deinit(self: *Self) void {
        self.diagnostics.deinit(self.allocator);
    }

    pub fn addDiagnostic(self: *Self, span: Span, message: []const u8) !void {
        try self.diagnostics.append(self.allocator, .{ .span = span, .message = message });
    }

    const Diagnostic = struct {
        span: Span,
        message: []const u8,

        fn lessThan(_: void, a: Diagnostic, b: Diagnostic) bool {
            return a.span.begin < b.span.begin;
        }
    };
};
