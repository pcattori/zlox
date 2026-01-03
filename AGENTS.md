## Zig v0.15.2

[Allocgate](https://pithlessly.github.io/allocgate.html)

- `std.heap.GeneralPurposeAllocator` is deprecated. Use `std.heap.{DebugAllocator}` instead.
- Managed data structures are deprecated. For example:

    ```zig
    // Instead of this (deprecated):
    var list = std.ArrayList(u32).init(allocator);
    try list.append(42);
    
    // Do this:
    var list: std.ArrayList(u32) = .empty;
    try list.append(allocator, 42);
    ```

[Writergate](https://github.com/ziglang/zig/pull/24329)

- `std.io` is deprecated. Use `std.Io.{Reader, Writer}` instead.
- `std.fs.File.std{in,out,err}().{print,write,writeAll}` is deprecated. Use `std.fs.File.std{in,out,err}().{reader,writer}` with explicit buffer instead.

    ```zig
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    ```
- `format` functions are now `pub fn format(self: *Self, writer: *std.Io.Writer)` and are invoked when `{f}` is specified in a format string.

    ```zig
    const Thing = struct {
        value: u32,
        
        pub fn format(self: *Self, writer: *std.Io.Writer) !void {
            try writer.print("Thing({})", self.value);
        }
    };

    const thing: Thing = .{ .value = 42 };
    try stdout.print("{f}", .{thing);
    ```
