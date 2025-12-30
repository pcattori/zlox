const Span = @import("span.zig").Span;
const Diagnostics = @import("./diagnostics.zig").Diagnostics;

const Token = struct {
    kind: Kind,
    span: Span,

    const Kind = enum {
        left_paren,
        right_paren,
        left_brace,
        right_brace,
        comma,
        dot,
        minus,
        plus,
        semicolon,
        star,

        bang,
        bang_equal,
        equal,
        equal_equal,
        greater,
        greater_equal,
        less,
        less_equal,
        slash,

        string,
        number,

        eof,
    };
};

pub const Scanner = struct {
    source: []const u8,
    begin: u32 = 0,
    current: u32 = 0,
    diagnostics: *Diagnostics,

    const Self = @This();

    pub fn next(self: *Self) !?Token {
        while (!self.isAtEnd()) {
            self.begin = self.current;
            const char = self.advance();
            const token: ?Token = switch (char) {
                '(' => self.emit(.left_paren),
                ')' => self.emit(.right_paren),
                '{' => self.emit(.left_brace),
                '}' => self.emit(.right_brace),
                ',' => self.emit(.comma),
                '.' => self.emit(.dot),
                '-' => self.emit(.minus),
                '+' => self.emit(.plus),
                ';' => self.emit(.semicolon),
                '*' => self.emit(.star),
                '!' => self.emit(if (self.match('=')) .bang_equal else .bang),
                '=' => self.emit(if (self.match('=')) .equal_equal else .equal),
                '<' => self.emit(if (self.match('=')) .less_equal else .less),
                '>' => self.emit(if (self.match('=')) .greater_equal else .greater),
                '/' => blk: {
                    if (self.match('/')) {
                        while (!self.isAtEnd() and self.peek() != '\n') {
                            _ = self.advance();
                        }
                        break :blk null;
                    }
                    break :blk self.emit(.slash);
                },
                ' ', '\t', '\r', '\n' => null,
                '"' => try self.string(),
                '0'...'9' => self.number(),
                else => null,
            };
            if (token) |t| return t;
        }

        if (self.current == self.source.len) {
            self.current += 1;
            return self.emit(.eof);
        }

        return null;
    }

    fn string(self: *Self) !?Token {
        while (!self.isAtEnd()) {
            const char = self.advance();
            if (char == '"') {
                return self.emit(.string);
            }
        }
        try self.diagnostics.add(.{ .begin = self.begin, .end = self.current }, "Unterminated string literal");
        return null;
    }

    fn number(self: *Self) Token {
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
        return self.emit(.number);
    }

    fn emit(self: *Self, kind: Token.Kind) Token {
        const begin = self.begin;
        const end = self.current;
        self.begin = end; // todo: is this redundant with `next`?
        return .{ .kind = kind, .span = .{ .begin = begin, .end = end } };
    }

    fn match(self: *Self, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.current] != expected) return false;
        self.current += 1;
        return true;
    }

    fn advance(self: *Self) u8 {
        const char = self.source[self.current];
        self.current += 1;
        return char;
    }

    fn peek(self: *Self) ?u8 {
        if (self.isAtEnd()) return null;
        return self.source[self.current];
    }

    fn peekNext(self: *Self) ?u8 {
        if (self.current + 1 >= self.source.len) return null;
        return self.source[self.current + 1];
    }

    fn isAtEnd(self: *Self) bool {
        return self.current >= self.source.len;
    }
};

fn isDigit(char: ?u8) bool {
    if (char) |c| {
        return c >= '0' and c <= '9';
    }
    return false;
}
