pub const Span = struct {
    begin: u32,
    end: u32,

    pub fn lexeme(self: Span, source: []const u8) []const u8 {
        return source[self.begin..self.end];
    }
};
