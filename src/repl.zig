const std = @import("std");

pub fn repl() !void {
    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin = &stdin_reader.interface;

    var stdout_writer = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_writer.interface;

    while (true) {
        try stdout.writeAll("zlox> ");
        const line = try stdin.takeDelimiter('\n') orelse continue;
        if (line.len == 0) continue;
        try stdout.print("echo: {s}\n", .{line});
    }
}
