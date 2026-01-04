const std = @import("std");
const Ast = @import("ast.zig");

const Value = union(enum) {
    number: f64,
    string: []const u8,
    bool: bool,
    nil,
};

pub fn interpret(allocator: std.mem.Allocator, ast: Ast.Expr) !Value {
    return switch (ast) {
        .nil => .nil,
        .number => |num| .{ .number = num },
        .string => |str| .{ .string = str },
        .boolean => |b| .{ .bool = b },
        .grouping => |expr| try interpret(allocator, expr.*),
        .unary => |u| {
            const operand = try interpret(allocator, u.expression.*);
            switch (u.operator) {
                .minus => switch (operand) {
                    .number => |num| return .{ .number = -num },
                    else => return error.InvalidType,
                },
                .bang => return .{ .bool = !isTruthy(operand) },
            }
        },
        .binary => |b| {
            const left = try interpret(allocator, b.left.*);
            const right = try interpret(allocator, b.right.*);

            return switch (b.operator) {
                .plus => {
                    if (left == .number and right == .number) {
                        return .{ .number = left.number + right.number };
                    }
                    if (left == .string and right == .string) {
                        var value: std.ArrayList(u8) = .empty;
                        try value.appendSlice(allocator, left.string);
                        try value.appendSlice(allocator, right.string);
                        return .{ .string = try value.toOwnedSlice(allocator) };
                    }
                    return error.InvalidType;
                },
                .minus => .{ .number = try assertNumber(left) - try assertNumber(right) },
                .star => .{ .number = try assertNumber(left) * try assertNumber(right) },
                .slash => .{ .number = try assertNumber(left) / try assertNumber(right) },
                .greater => .{ .bool = try assertNumber(left) > try assertNumber(right) },
                .greater_equal => .{ .bool = try assertNumber(left) >= try assertNumber(right) },
                .less => .{ .bool = try assertNumber(left) < try assertNumber(right) },
                .less_equal => .{ .bool = try assertNumber(left) <= try assertNumber(right) },
                .equal_equal => .{ .bool = try assertNumber(left) == try assertNumber(right) },
                .bang_equal => .{ .bool = try assertNumber(left) != try assertNumber(right) },
            };
        },
    };
}

fn isTruthy(value: Value) bool {
    return switch (value) {
        .nil => false,
        .bool => |b| b,
        else => true,
    };
}

fn assertNumber(value: Value) !f64 {
    return switch (value) {
        .number => |num| num,
        else => error.InvalidType,
    };
}

test "interpret" {
    const Compilation = @import("compilation.zig").Compilation;
    const parse = @import("parse.zig").parse;

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    const source = "1 + 2";

    var ctx = Compilation.init(arena.allocator(), source);
    defer ctx.deinit();

    var ast = try parse(&ctx);
    defer ast.deinit();

    const x = try interpret(arena.allocator(), ast.program.*);
    try std.testing.expectEqual(x, Value{ .number = 3.0 });
}
