const std = @import("std");
const Span = @import("./span.zig").Span;

pub const Diagnostic = struct {
    span: Span,
    message: []const u8,
};
