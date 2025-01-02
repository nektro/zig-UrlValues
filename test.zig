const std = @import("std");
const UrlValues = @import("UrlValues");
const expect = @import("expect").expect;

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=b&c=d");
    try expect(x.get("a")).toEqualString("b");
    try expect(x.get("c")).toEqualString("d");
    try expect(x.get("e")).toBeNull();

    try expect(try x.encode()).toEqualString("a=b&c=d");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "e=f&g=h");
    try expect(try x.encode()).toEqualString("e=f&g=h");

    try x.set("i", " j ");
    try expect(x.get("i")).toEqualString(" j ");
    try expect(try x.encode()).toEqualString("e=f&g=h&i=%20j%20");

    try x.set("e", "updated");
    try expect(x.get("e")).toEqualString("updated");
    try expect(try x.encode()).toEqualString("e=updated&g=h&i=%20j%20");
}
