## Zig v0.15.2

**Allocgate**:

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

**Writergate**:

- `std.io` is deprecated. Use `std.Io.{Reader, Writer}` instead.
- `std.fs.File.std{in,out,err}().{print,write,writeAll}` is deprecated. Use `std.fs.File.std{in,out,err}().{reader,writer}` with explicit buffer instead.

    ```zig
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    ```
