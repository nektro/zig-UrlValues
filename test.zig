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
    try expect(try x.encode()).toEqualString("e=f&g=h&i=+j+");

    try x.set("e", "updated");
    try expect(x.get("e")).toEqualString("updated");
    try expect(try x.encode()).toEqualString("e=updated&g=h&i=+j+");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("a", "b");
    try expect(try x.encode()).toEqualString("a=b");
    try x.append("a", "b");
    try expect(try x.encode()).toEqualString("a=b&a=b");
    try x.append("a", "c");
    try expect(try x.encode()).toEqualString("a=b&a=b&a=c");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("", "");
    try expect(try x.encode()).toEqualString("=");
    try x.append("", "");
    try expect(try x.encode()).toEqualString("=&=");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("first", "1");
    try x.append("second", "2");
    try x.append("third", "");
    try x.append("first", "10");
    try expect(x.get("first")).not().toBeNull();
    try expect(x.get("first")).toEqualString("1");
    try expect(x.get("second")).toEqualString("2");
    try expect(x.get("third")).toEqualString("");
    try x.append("first", "10");
    try expect(x.get("first")).toEqualString("1");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try expect(try x.encode()).toEqualString("");
    try x.append("a", "b");
    try expect(try x.encode()).toEqualString("a=b");
    try x.append("a", "c");
    try expect(try x.encode()).toEqualString("a=b&a=c");
    try expect(x.take("a")).toEqualString("b");
    try expect(try x.encode()).toEqualString("a=c");
    try expect(x.take("a")).toEqualString("c");
    try expect(try x.encode()).toEqualString("");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=b&c=d");
    x.delete("a", null);
    try expect(try x.encode()).toEqualString("c=d");
    x = try UrlValues.initFromString(alloc, "a=a&b=b&a=a&c=c");
    x.delete("a", null);
    try expect(try x.encode()).toEqualString("b=b&c=c");
    x = try UrlValues.initFromString(alloc, "a=a&=&b=b&c=c");
    x.delete("", null);
    try expect(try x.encode()).toEqualString("a=a&b=b&c=c");
    x = try UrlValues.initFromString(alloc, "a=a&null=null&b=b");
    x.delete("null", null);
    try expect(try x.encode()).toEqualString("a=a&b=b");
    x = try UrlValues.initFromString(alloc, "a=a&undefined=undefined&b=b");
    x.delete("undefined", null);
    try expect(try x.encode()).toEqualString("a=a&b=b");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("first", "1");
    try expect(x.has("first", null)).toEqual(true);
    try expect(x.get("first")).toEqualSlice("1");
    x.delete("first", null);
    try expect(x.has("first", null)).toEqual(false);
    try x.append("first", "1");
    try x.append("first", "10");
    x.delete("first", null);
    try expect(x.has("first", null)).toEqual(false);
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("a", "b");
    try x.append("a", "c");
    try x.append("a", "d");
    x.delete("a", "c");
    try expect(try x.encode()).toEqualString("a=b&a=d");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("a", "b");
    try x.append("a", "c");
    try x.append("b", "c");
    try x.append("b", "d");
    x.delete("b", "c");
    x.delete("a", null);
    try expect(try x.encode()).toEqualString("b=d");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=b&c=d");
    try expect(x.get("a")).toEqualString("b");
    try expect(x.get("c")).toEqualString("d");
    try expect(x.get("e")).toBeNull();
    x = try UrlValues.initFromString(alloc, "a=b&c=d&a=e");
    try expect(x.get("a")).toEqualString("b");
    x = try UrlValues.initFromString(alloc, "=b&c=d");
    try expect(x.get("")).toEqualString("b");
    x = try UrlValues.initFromString(alloc, "a=&c=d&a=e");
    try expect(x.get("a")).toEqualString("");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "first=second&third&&");
    try expect(x.has("first", null)).toEqual(true);
    try expect(x.get("first")).toEqualString("second");
    try expect(x.get("third")).toEqualString("");
    try expect(x.get("fourth")).toBeNull();
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=b&c=d");
    try expect(try x.getAll("a")).toEqualStringSlice(&.{"b"});
    try expect(try x.getAll("c")).toEqualStringSlice(&.{"d"});
    try expect(try x.getAll("e")).toEqualStringSlice(&.{});
    x = try UrlValues.initFromString(alloc, "a=b&c=d&a=e");
    try expect(try x.getAll("a")).toEqualStringSlice(&.{ "b", "e" });
    x = try UrlValues.initFromString(alloc, "=b&c=d");
    try expect(try x.getAll("")).toEqualStringSlice(&.{"b"});
    x = try UrlValues.initFromString(alloc, "a=&c=d&a=e");
    try expect(try x.getAll("a")).toEqualStringSlice(&.{ "", "e" });
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=1&a=2&a=3&a");
    try expect(x.has("a", null)).toEqual(true);
    var matches = try x.getAll("a");
    try expect(matches).not().toBeNull();
    try expect(matches.?.len).toEqual(4);
    try expect(matches).toEqualStringSlice(&.{ "1", "2", "3", "" });
    try x.set("a", "one");
    try expect(x.get("a")).toEqualString("one");
    try expect(try x.encode()).toEqualString("a=one");
    matches = try x.getAll("a");
    try expect(matches).not().toBeNull();
    try expect(matches.?.len).toEqual(1);
    try expect(matches).toEqualStringSlice(&.{"one"});
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=b&c=d");
    try expect(x.has("a", null)).toEqual(true);
    try expect(x.has("c", null)).toEqual(true);
    try expect(x.has("e", null)).toEqual(false);
    x = try UrlValues.initFromString(alloc, "a=b&c=d&a=e");
    try expect(x.has("a", null)).toEqual(true);
    x = try UrlValues.initFromString(alloc, "=b&c=d");
    try expect(x.has("", null)).toEqual(true);
    x = try UrlValues.initFromString(alloc, "null=a");
    try expect(x.has("null", null)).toEqual(true);
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=b&c=d&&");
    try x.append("first", "1");
    try x.append("first", "2");
    try expect(x.has("a", null)).toEqual(true);
    try expect(x.has("c", null)).toEqual(true);
    try expect(x.has("first", null)).toEqual(true);
    try expect(x.has("d", null)).toEqual(false);
    x.delete("first", null);
    try expect(x.has("first", null)).toEqual(false);
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=b&a=d&c&e&");
    try expect(x.has("a", "b")).toEqual(true);
    try expect(x.has("a", "c")).toEqual(false);
    try expect(x.has("a", "d")).toEqual(true);
    try expect(x.has("e", "")).toEqual(true);
    try x.append("first", "null");
    try expect(x.has("first", "")).toEqual(false);
    try expect(x.has("first", "null")).toEqual(true);
    x.delete("a", "b");
    try expect(x.has("a", "d")).toEqual(true);
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=b&a=d&c&e&");
    try expect(x.has("a", "b")).toEqual(true);
    try expect(x.has("a", "c")).toEqual(false);
    try expect(x.has("a", "d")).toEqual(true);
    try expect(x.has("a", null)).toEqual(true);
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=b&c=d");
    try x.set("a", "B");
    try expect(try x.encode()).toEqualString("a=B&c=d");
    x = try UrlValues.initFromString(alloc, "a=b&c=d&a=e");
    try x.set("a", "B");
    try expect(try x.encode()).toEqualString("a=B&c=d");
    try x.set("e", "f");
    try expect(try x.encode()).toEqualString("a=B&c=d&e=f");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=1&a=2&a=3");
    try expect(x.has("a", null)).toEqual(true);
    try expect(x.get("a")).toEqualString("1");
    try x.set("first", "4");
    try expect(x.has("a", null)).toEqual(true);
    try expect(x.get("a")).toEqualString("1");
    try x.set("a", "4");
    try expect(x.has("a", null)).toEqual(true);
    try expect(x.get("a")).toEqualString("4");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=1&b=2&a=3");
    try expect(x.size()).toEqual(3);
    x.delete("a", null);
    try expect(x.size()).toEqual(1);
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=1&b=2&a=3");
    try expect(x.size()).toEqual(3);
    try x.append("b", "4");
    try expect(x.size()).toEqual(4);
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=1&b=2&a=3");
    try expect(x.size()).toEqual(3);
    x.delete("a", null);
    try expect(x.size()).toEqual(1);
    try x.append("b", "4");
    try expect(x.size()).toEqual(2);
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("a", "b c");
    try expect(try x.encode()).toEqualString("a=b+c");
    x.delete("a", null);
    try x.append("a b", "c");
    try expect(try x.encode()).toEqualString("a+b=c");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("a", "");
    try expect(try x.encode()).toEqualString("a=");
    try x.append("a", "");
    try expect(try x.encode()).toEqualString("a=&a=");
    try x.append("", "b");
    try expect(try x.encode()).toEqualString("a=&a=&=b");
    try x.append("", "");
    try expect(try x.encode()).toEqualString("a=&a=&=b&=");
    try x.append("", "");
    try expect(try x.encode()).toEqualString("a=&a=&=b&=&=");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("", "b");
    try expect(try x.encode()).toEqualString("=b");
    try x.append("", "b");
    try expect(try x.encode()).toEqualString("=b&=b");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("", "");
    try expect(try x.encode()).toEqualString("=");
    try x.append("", "");
    try expect(try x.encode()).toEqualString("=&=");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("a", "b+c");
    try expect(try x.encode()).toEqualString("a=b%2Bc");
    x.delete("a", null);
    try x.append("a+b", "c");
    try expect(try x.encode()).toEqualString("a%2Bb=c");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("=", "a");
    try expect(try x.encode()).toEqualString("%3D=a");
    try x.append("b", "=");
    try expect(try x.encode()).toEqualString("%3D=a&b=%3D");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("&", "a");
    try expect(try x.encode()).toEqualString("%26=a");
    try x.append("b", "&");
    try expect(try x.encode()).toEqualString("%26=a&b=%26");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("a", "*-._");
    try expect(try x.encode()).toEqualString("a=*-._");
    x.delete("a", null);
    try x.append("*-._", "c");
    try expect(try x.encode()).toEqualString("*-._=c");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("a", "b%c");
    try expect(try x.encode()).toEqualString("a=b%25c");
    x.delete("a", null);
    try x.append("a%b", "c");
    try expect(try x.encode()).toEqualString("a%25b=c");
    x = try UrlValues.initFromString(alloc, "id=0&value=%");
    try expect(try x.encode()).toEqualString("id=0&value=%25");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("a", "b\x00c");
    try expect(try x.encode()).toEqualString("a=b%00c");
    x.delete("a", null);
    try x.append("a\x00b", "c");
    try expect(try x.encode()).toEqualString("a%00b=c");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    // try x.append("a", "b\uD83D\uDCA9c");
    try x.append("a", "b\xf0\x9f\x92\xa9c");
    try expect(try x.encode()).toEqualString("a=b%F0%9F%92%A9c");
    x.delete("a", null);
    // try x.append("a\uD83D\uDCA9b", "c");
    try x.append("a\xf0\x9f\x92\xa9b", "c");
    try expect(try x.encode()).toEqualString("a%F0%9F%92%A9b=c");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    x = try UrlValues.initFromString(alloc, "a=b&c=d&&e&&");
    try expect(try x.encode()).toEqualString("a=b&c=d&e=");
    x = try UrlValues.initFromString(alloc, "a = b &a=b&c=d%20");
    try expect(try x.encode()).toEqualString("a+=+b+&a=b&c=d+");
    // The lone "=" _does_ survive the roundtrip.
    x = try UrlValues.initFromString(alloc, "a=&a=b");
    try expect(try x.encode()).toEqualString("a=&a=b");
    x = try UrlValues.initFromString(alloc, "b=%2sf%2a");
    try expect(try x.encode()).toEqualString("b=%252sf*");
    x = try UrlValues.initFromString(alloc, "b=%2%2af%2a");
    try expect(try x.encode()).toEqualString("b=%252*f*");
    x = try UrlValues.initFromString(alloc, "b=%%2a");
    try expect(try x.encode()).toEqualString("b=%25*");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = try UrlValues.initFromString(alloc, "a=b,c");
    try expect(try x.encode()).toEqualString("a=b%2Cc");
    try x.append("x", "y");
    try expect(try x.encode()).toEqualString("a=b%2Cc&x=y");
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var x = UrlValues.init(alloc);
    try x.append("a\nb", "c\rd");
    try x.append("e\n\rf", "g\r\nh");
    try expect(try x.encode()).toEqualString("a%0Ab=c%0Dd&e%0A%0Df=g%0D%0Ah");
}
