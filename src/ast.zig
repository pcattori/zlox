const std = @import("std");

pub const Expr = union(enum) {
    number: f64,
    string: []const u8,
    boolean: bool,
    nil,

    grouping: *Expr,
    unary: Unary,
    binary: Binary,

    pub fn format(self: Expr, w: *std.Io.Writer) std.Io.Writer.Error!void {
        switch (self) {
            .number => |n| try w.print("{d}", .{n}),
            .string => |s| try w.print("\"{s}\"", .{s}),
            .boolean => |b| try w.print("{s}", .{if (b) "true" else "false"}),
            .nil => try w.writeAll("nil"),

            .grouping => |expr| {
                try w.writeAll("(group ");
                try expr.format(w);
                try w.writeAll(")");
            },

            .unary => |u| try u.format(w),
            .binary => |b| try b.format(w),
        }
    }
};

pub const Unary = struct {
    operator: Operator,
    expression: *Expr,

    pub const Operator = enum {
        minus,
        bang,
    };

    fn format(self: Unary, w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.writeAll("(");
        const op = switch (self.operator) {
            .minus => "-",
            .bang => "!",
        };
        try w.print("{s} ", .{op});
        try self.expression.format(w);
        try w.writeAll(")");
    }
};

pub const Binary = struct {
    left: *Expr,
    operator: Operator,
    right: *Expr,

    pub const Operator = enum {
        plus,
        minus,
        star,
        slash,
        greater,
        greater_equal,
        less,
        less_equal,
        equal_equal,
        bang_equal,
    };

    fn format(self: Binary, w: *std.Io.Writer) std.Io.Writer.Error!void {
        try w.writeAll("(");
        const op = switch (self.operator) {
            .plus => "+",
            .minus => "-",
            .star => "*",
            .slash => "/",
            .greater => ">",
            .greater_equal => ">=",
            .less => "<",
            .less_equal => "<=",
            .equal_equal => "==",
            .bang_equal => "!=",
        };
        try w.print("{s} ", .{op});
        try self.left.format(w);
        try w.writeAll(" ");
        try self.right.format(w);
        try w.writeAll(")");
    }
};
