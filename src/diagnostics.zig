const std = @import("std");
const Span = @import("./span.zig").Span;

pub const Diagnostic = struct {
    span: Span,
    message: []const u8,
};

pub const Diagnostics = struct {
    allocator: std.mem.Allocator,
    list: std.ArrayList(Diagnostic),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !Self {
        return .{
            .allocator = allocator,
            .list = .empty,
        };
    }

    pub fn deinit(self: *Self) void {
        self.list.deinit(self.allocator);
    }

    pub fn add(self: *Self, span: Span, message: []const u8) !void {
        try self.list.append(self.allocator, .{ .span = span, .message = message });
    }
};
