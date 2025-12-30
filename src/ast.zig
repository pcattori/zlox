const Token = @import("token.zig").Token;

pub const Expr = union(enum) {
    number: f64,
    string: []const u8,
    boolean: bool,
    nil,

    grouping: *Expr,
    unary: Unary,
    binary: Binary,

    pub const Unary = struct {
        operator: Operator,
        right: *Expr,

        pub const Operator = enum {
            minus,
            bang,
        };
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
    };
};
