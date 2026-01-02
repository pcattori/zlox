const std = @import("std");

const Compilation = @import("compilation.zig").Compilation;
const Token = @import("token.zig").Token;

pub fn scan(ctx: *Compilation) ![]const Token {
    var scanner = Scanner.init(ctx);
    defer scanner.deinit();
    return scanner.scan();
}

const Scanner = struct {
    ctx: *Compilation,

    tokens: std.ArrayList(Token),
    begin: u32 = 0,
    current: u32 = 0,

    const Self = @This();

    fn init(ctx: *Compilation) Self {
        return .{ .ctx = ctx, .tokens = .empty };
    }

    fn deinit(self: *Self) void {
        self.tokens.deinit(self.ctx.allocator);
    }

    fn scan(self: *Self) ![]const Token {
        while (!self.isAtEnd()) {
            self.begin = self.current;
            const char = self.advance();
            switch (char) {
                '(' => try self.add(.left_paren),
                ')' => try self.add(.right_paren),
                '{' => try self.add(.left_brace),
                '}' => try self.add(.right_brace),
                ',' => try self.add(.comma),
                '.' => try self.add(.dot),
                '-' => try self.add(.minus),
                '+' => try self.add(.plus),
                ';' => try self.add(.semicolon),
                '*' => try self.add(.star),
                '!' => try self.add(if (self.match('=')) .bang_equal else .bang),
                '=' => try self.add(if (self.match('=')) .equal_equal else .equal),
                '<' => try self.add(if (self.match('=')) .less_equal else .less),
                '>' => try self.add(if (self.match('=')) .greater_equal else .greater),
                '/' => {
                    if (self.match('/')) {
                        while (!self.isAtEnd() and self.peek() != '\n') {
                            _ = self.advance();
                        }
                        continue;
                    }
                    try self.add(.slash);
                },
                '"' => try self.string(),
                '0'...'9' => try self.number(),
                'a'...'z', 'A'...'Z', '_' => try self.identifier(),
                ' ', '\t', '\r', '\n' => continue,
                else => continue,
            }
        }
        try self.add(.eof);

        return self.tokens.toOwnedSlice(self.ctx.allocator);
    }

    fn identifier(self: *Self) !void {
        while (isAlphaNumeric(self.peek())) {
            _ = self.advance();
        }

        // keywords
        const lexeme = self.ctx.source[self.begin..self.current];
        inline for (keywords) |keyword| {
            if (std.mem.eql(u8, lexeme, keyword.name)) {
                return self.add(keyword.kind);
            }
        }

        return self.add(.identifier);
    }

    fn string(self: *Self) !void {
        while (!self.isAtEnd()) {
            const char = self.advance();
            if (char == '"') {
                return self.add(.string);
            }
        }
        try self.ctx.addDiagnostic(
            .{ .begin = self.begin, .end = self.current },
            "Unterminated string literal",
        );
    }

    fn number(self: *Self) !void {
        while (!self.isAtEnd() and isDigit(self.peek())) {
            _ = self.advance();
        }
        if (self.peek() == '.' and isDigit(self.peekNext())) {
            // consume the `.`
            _ = self.advance();

            while (isDigit(self.peek())) {
                _ = self.advance();
            }
        }
        return self.add(.number);
    }

    fn add(self: *Self, kind: Token.Kind) !void {
        const begin = self.begin;
        const end = self.current;
        self.begin = end; // todo: is this redundant with `next`?

        try self.tokens.append(self.ctx.allocator, .{ .kind = kind, .span = .{ .begin = begin, .end = end } });
    }

    fn match(self: *Self, expected: u8) bool {
        if (self.peek() != expected) return false;
        self.current += 1;
        return true;
    }

    fn advance(self: *Self) u8 {
        const char = self.ctx.source[self.current];
        self.current += 1;
        return char;
    }

    fn peek(self: *Self) ?u8 {
        if (self.isAtEnd()) return null;
        return self.ctx.source[self.current];
    }

    fn peekNext(self: *Self) ?u8 {
        if (self.current + 1 >= self.ctx.source.len) return null;
        return self.ctx.source[self.current + 1];
    }

    fn isAtEnd(self: *Self) bool {
        return self.current >= self.ctx.source.len;
    }
};

fn isDigit(char: ?u8) bool {
    if (char) |c| {
        return c >= '0' and c <= '9';
    }
    return false;
}

fn isAlpha(char: ?u8) bool {
    if (char) |c| {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
    }
    return false;
}

fn isAlphaNumeric(char: ?u8) bool {
    if (char) |c| {
        return isAlpha(c) or isDigit(c);
    }
    return false;
}

const keywords = [_]struct {
    name: []const u8,
    kind: Token.Kind,
}{
    .{ .name = "and", .kind = ._and },
    .{ .name = "class", .kind = ._class },
    .{ .name = "else", .kind = ._else },
    .{ .name = "false", .kind = ._false },
    .{ .name = "for", .kind = ._for },
    .{ .name = "fun", .kind = ._fun },
    .{ .name = "if", .kind = ._if },
    .{ .name = "nil", .kind = ._nil },
    .{ .name = "or", .kind = ._or },
    .{ .name = "print", .kind = ._print },
    .{ .name = "return", .kind = ._return },
    .{ .name = "super", .kind = ._super },
    .{ .name = "this", .kind = ._this },
    .{ .name = "true", .kind = ._true },
    .{ .name = "var", .kind = ._var },
    .{ .name = "while", .kind = ._while },
};
