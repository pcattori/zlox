const std = @import("std");

const Compilation = @import("compilation.zig").Compilation;
const Token = @import("token.zig").Token;
const Ast = @import("ast.zig");
const scan = @import("scan.zig").scan;

pub fn parse(ctx: *Compilation) !Parsed {
    const tokens = try scan(ctx);
    defer ctx.allocator.free(tokens);
    return parseTokens(ctx, tokens);
}

pub fn parseTokens(ctx: *Compilation, tokens: []const Token) !Parsed {
    var parser = Parser.init(ctx, tokens);
    return parser.parse();
}

const ParseError = error{
    OutOfMemory,
    UnexpectedToken,
    InvalidCharacter,

    ZloxParserPanic,
};

const Parsed = struct {
    arena: std.heap.ArenaAllocator,
    program: *Ast.Expr,

    pub fn deinit(self: *Parsed) void {
        self.arena.deinit();
    }
};

const Parser = struct {
    ctx: *Compilation,
    tokens: []const Token,

    arena: std.heap.ArenaAllocator,
    current: u32 = 0,

    const Self = @This();

    fn init(ctx: *Compilation, tokens: []const Token) Self {
        return .{
            .ctx = ctx,
            .tokens = tokens,
            .arena = std.heap.ArenaAllocator.init(ctx.allocator),
        };
    }

    fn parse(self: *Self) ParseError!Parsed {
        const program = try self.expression();
        return .{
            .arena = self.arena,
            .program = program,
        };
    }

    fn expression(self: *Self) ParseError!*Ast.Expr {
        return self.equality();
    }

    fn equality(self: *Self) ParseError!*Ast.Expr {
        var expr = try self.comparison();

        while (self.matchAny(&.{ .bang_equal, .equal_equal })) |token| {
            const op: Ast.Binary.Operator = switch (token.kind) {
                .bang_equal => .bang_equal,
                .equal_equal => .equal_equal,
                else => unreachable,
            };

            const right = try self.comparison();
            expr = try self.boxBinary(expr, op, right);
        }
        return expr;
    }

    fn comparison(self: *Self) ParseError!*Ast.Expr {
        var expr = try self.term();

        while (self.matchAny(&.{ .less, .greater, .less_equal, .greater_equal })) |token| {
            const op: Ast.Binary.Operator = switch (token.kind) {
                .less => .less,
                .greater => .greater,
                .less_equal => .less_equal,
                .greater_equal => .greater_equal,
                else => unreachable,
            };

            const right = try self.term();
            expr = try self.boxBinary(expr, op, right);
        }
        return expr;
    }

    fn term(self: *Self) ParseError!*Ast.Expr {
        var expr = try self.factor();

        while (self.matchAny(&.{ .minus, .plus })) |token| {
            const op: Ast.Binary.Operator = switch (token.kind) {
                .minus => .minus,
                .plus => .plus,
                else => unreachable,
            };

            const right = try self.factor();
            expr = try self.boxBinary(expr, op, right);
        }
        return expr;
    }

    fn factor(self: *Self) ParseError!*Ast.Expr {
        var expr = try self.unary();

        while (self.matchAny(&.{ .star, .slash })) |token| {
            const op: Ast.Binary.Operator = switch (token.kind) {
                .star => .star,
                .slash => .slash,
                else => unreachable,
            };

            const right = try self.unary();
            expr = try self.boxBinary(expr, op, right);
        }
        return expr;
    }

    fn unary(self: *Self) ParseError!*Ast.Expr {
        if (self.matchAny(&.{ .bang, .minus })) |token| {
            const expr = try self.primary();
            const op: Ast.Unary.Operator = switch (token.kind) {
                .bang => .bang,
                .minus => .minus,
                else => unreachable,
            };
            return self.boxUnary(op, expr);
        }
        return self.primary();
    }

    fn primary(self: *Self) ParseError!*Ast.Expr {
        // number
        if (self.match(.number)) |token| {
            const value = try std.fmt.parseFloat(f64, token.span.lexeme(self.ctx.source));
            return self.box(Ast.Expr, .{ .number = value });
        }

        // string
        if (self.match(.string)) |token| {
            const lexeme = token.span.lexeme(self.ctx.source);
            const text = lexeme[1 .. lexeme.len - 1];
            const value = try self.arena.allocator().dupe(u8, text);
            return self.box(Ast.Expr, .{ .string = value });
        }
        // boolean
        if (self.match(._true)) |_| return self.box(Ast.Expr, .{ .boolean = true });
        if (self.match(._false)) |_| return self.box(Ast.Expr, .{ .boolean = false });

        // nil
        if (self.match(._nil)) |_| return self.box(Ast.Expr, .nil);

        // grouping
        if (self.match(.left_paren)) |_| {
            const expr = try self.expression();
            _ = try self.consume(.right_paren);
            return self.box(Ast.Expr, .{ .grouping = expr });
        }

        // todo: self.diagnostics.add(span: Span, message: []const u8)
        return error.ZloxParserPanic;
    }

    fn consume(self: *Self, comptime kind: Token.Kind) !?Token {
        const token = self.advance();
        if (token.kind == kind) return token;
        try self.ctx.addDiagnostic(token.span, "wow");
        return error.ZloxParserPanic;
    }

    fn match(self: *Self, comptime kind: Token.Kind) ?Token {
        const token = self.peek();
        if (token.kind == kind) {
            return self.advance();
        }
        return null;
    }

    fn matchAny(self: *Parser, comptime kinds: []const Token.Kind) ?Token {
        inline for (kinds) |kind| {
            if (self.match(kind)) |token| {
                return token;
            }
        }
        return null;
    }

    fn advance(self: *Self) Token {
        const token = self.peek();
        self.current += 1;
        return token;
    }

    fn peek(self: *Self) Token {
        return self.tokens[self.current];
    }

    fn boxBinary(self: *Self, left: *Ast.Expr, operator: Ast.Binary.Operator, right: *Ast.Expr) !*Ast.Expr {
        return self.box(Ast.Expr, .{
            .binary = .{
                .left = left,
                .operator = operator,
                .right = right,
            },
        });
    }

    fn boxUnary(self: *Self, operator: Ast.Unary.Operator, expr: *Ast.Expr) !*Ast.Expr {
        return self.box(Ast.Expr, .{
            .unary = .{
                .operator = operator,
                .expression = expr,
            },
        });
    }

    fn box(self: *Self, comptime T: type, value: T) !*T {
        const ptr = try self.arena.allocator().create(T);
        ptr.* = value;
        return ptr;
    }
};

test "Parser - primary expressions" {
    const allocator = std.testing.allocator;

    // Test number
    {
        const source = "42.5";

        var ctx = Compilation.init(allocator, source);
        defer ctx.deinit();

        var ast = try parse(&ctx);
        defer ast.deinit();
        const expr = ast.program;

        try std.testing.expectEqual(42.5, expr.number);
    }

    // Test string
    {
        const source = "\"hello\"";

        var ctx = Compilation.init(allocator, source);
        defer ctx.deinit();

        var ast = try parse(&ctx);
        defer ast.deinit();
        const expr = ast.program;

        try std.testing.expectEqualStrings("hello", expr.string);
    }

    // Test boolean true
    {
        const source = "true";

        var ctx = Compilation.init(allocator, source);
        defer ctx.deinit();

        var ast = try parse(&ctx);
        defer ast.deinit();

        const expr = ast.program;
        try std.testing.expectEqual(true, expr.boolean);
    }

    // Test boolean false
    {
        const source = "false";

        var ctx = Compilation.init(allocator, source);
        defer ctx.deinit();

        var ast = try parse(&ctx);
        defer ast.deinit();

        const expr = ast.program;
        try std.testing.expectEqual(false, expr.boolean);
    }

    // Test nil
    {
        const source = "nil";

        var ctx = Compilation.init(allocator, source);
        defer ctx.deinit();

        var ast = try parse(&ctx);
        defer ast.deinit();

        const expr = ast.program;
        try std.testing.expect(expr.* == .nil);
    }

    {
        const source = "-1";

        var ctx = Compilation.init(allocator, source);
        defer ctx.deinit();

        var ast = try parse(&ctx);
        defer ast.deinit();

        const expr = ast.program;
        try std.testing.expect(expr.* == .unary);
        try std.testing.expectEqual(expr.unary.operator, .minus);
        try std.testing.expectEqual(expr.unary.expression.number, @as(f64, 1.0));
    }

    {
        const source = "4 > 1 + 2 + (false * 12.0) <= nil";

        var ctx = Compilation.init(allocator, source);
        defer ctx.deinit();

        var ast = try parse(&ctx);
        defer ast.deinit();

        const expr = ast.program;
        try std.testing.expect(expr.* == .binary);
    }
}
