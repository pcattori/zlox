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

        kw_and,
        kw_class,
        kw_else,
        kw_false,
        kw_for,
        kw_fun,
        kw_if,
        kw_nil,
        kw_or,
        kw_print,
        kw_return,
        kw_super,
        kw_this,
        kw_true,
        kw_var,
        kw_while,

        eof,
    };
};
