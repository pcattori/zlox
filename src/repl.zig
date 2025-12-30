const std = @import("std");

pub fn repl() !void {
    var stdin_buffer: [1024]u8 = undefined;
    var stdin = std.fs.File.stdin().reader(&stdin_buffer);

    var stdout = std.fs.File.stdout().writer(&.{});

    while (true) {
        try stdout.interface.writeAll("zlox> ");
        const line = try stdin.interface.takeDelimiter('\n') orelse continue;
        if (line.len == 0) continue;
        try stdout.interface.print("echo: {s}\n", .{line});
    }
}
