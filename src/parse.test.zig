const std = @import("std");
const Context = @import("parse.zig").Context;
const parse = @import("parse.zig").parse;

const allocator = std.testing.allocator;

fn expectParse(source: []const u8, expected: []const u8) !void {
    var ctx = Context.init(allocator, source);
    defer ctx.deinit();

    var ast = try parse(&ctx);
    defer ast.deinit();

    const actual = try std.fmt.allocPrint(allocator, "{f}", .{ast.program});
    defer allocator.free(actual);

    try std.testing.expectEqualStrings(expected, actual);
}

test "parse number" {
    try expectParse("4", "4");
    try expectParse("4.5", "4.5");
    // todo error for 4.
    // todo error for .4
}

test "parse string" {
    try expectParse("\"hello\"", "\"hello\"");
    try expectParse("\"hello\\nworld\"", "\"hello\\nworld\"");
    // todo error for unterminated string
}

test "parse boolean" {
    try expectParse("true", "true");
    try expectParse("false", "false");
}

test "parse nil" {
    try expectParse("nil", "nil");
}

test "parse group" {
    try expectParse("(4)", "(group 4)");
    try expectParse("(4.5)", "(group 4.5)");
    try expectParse("(\"hello\")", "(group \"hello\")");
    try expectParse("(true)", "(group true)");
    try expectParse("(false)", "(group false)");
    try expectParse("(nil)", "(group nil)");
}

test "parse unary" {
    try expectParse("-4", "(- 4)");
    try expectParse("!true", "(! true)");
}

test "parse binary" {
    try expectParse("4 + 5", "(+ 4 5)");
    try expectParse("4 - 5", "(- 4 5)");
    try expectParse("4 * 5", "(* 4 5)");
    try expectParse("4 / 5", "(/ 4 5)");
    try expectParse("4 > 5", "(> 4 5)");
    try expectParse("4 >= 5", "(>= 4 5)");
    try expectParse("4 < 5", "(< 4 5)");
    try expectParse("4 <= 5", "(<= 4 5)");
    try expectParse("4 == 5", "(== 4 5)");
    try expectParse("4 != 5", "(!= 4 5)");
}

test "parse combinations" {
    try expectParse(
        "1 + 2.2 + (!true * nil) >= \"hello\"",
        "(>= (+ (+ 1 2.2) (group (* (! true) nil))) \"hello\")",
    );
}
