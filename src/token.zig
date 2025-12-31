const Span = @import("span.zig").Span;

pub const Token = struct {
    kind: Kind,
    span: Span,

    pub const Kind = enum {
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
        identifier,

        // keywords
        _and,
        _class,
        _else,
        _false,
        _for,
        _fun,
        _if,
        _nil,
        _or,
        _print,
        _return,
        _super,
        _this,
        _true,
        _var,
        _while,

        eof,
    };
};
