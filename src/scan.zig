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
        while (self.current < self.source.len) {
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
                ' ', '\t', '\r', '\n' => null,
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

    fn emit(self: *Self, kind: Token.Kind) Token {
        const begin = self.begin;
        const end = self.current;
        self.begin = end; // todo: is this redundant with `next`?
        return .{ .kind = kind, .span = .{ .begin = begin, .end = end } };
    }

    fn advance(self: *Self) u8 {
        const char = self.source[self.current];
        self.current += 1;
        return char;
    }
};
