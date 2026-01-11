const std = @import("std");
const Span = @import("span.zig").Span;
const Token = @import("token.zig").Token;

pub const Compilation = struct {
    allocator: std.mem.Allocator,
    source: []const u8,
    errors: std.ArrayList(Error),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Self {
        return .{
            .allocator = allocator,
            .source = source,
            .errors = .empty,
        };
    }

    pub fn deinit(self: *Self) void {
        self.errors.deinit(self.allocator);
    }

    pub fn err(self: *Self, span: Span, message: []const u8) !void {
        try self.errors.append(self.allocator, .{ .span = span, .message = message });
    }

    pub fn getErrors(self: *Self) []Error {
        return self.errors.items;
    }
};

const Error = struct {
    span: Span,
    message: []const u8,

    fn lessThan(_: void, a: Error, b: Error) bool {
        return a.span.begin < b.span.begin;
    }
};
