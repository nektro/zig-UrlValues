const UrlValues = @This();
const string = []const u8;
const std = @import("std");

inner: std.StringArrayHashMap(string),

pub fn init(alloc: std.mem.Allocator) UrlValues {
    return .{
        .inner = std.StringArrayHashMap(string).init(alloc),
    };
}

pub fn initFromString(alloc: std.mem.Allocator, input: string) !UrlValues {
    var uv = UrlValues.init(alloc);
    var iter = std.mem.split(u8, input, "&");
    while (iter.next()) |piece| {
        if (piece.len == 0) continue;
        var jter = std.mem.split(u8, piece, "=");
        try uv.add(jter.next().?, jter.rest());
    }
    return uv;
}

pub fn add(self: *UrlValues, key: string, value: string) !void {
    try self.inner.put(key, value);
}

pub fn get(self: UrlValues, key: string) ?string {
    return self.inner.get(key);
}

pub fn take(self: *UrlValues, key: string) ?string {
    const kv = self.inner.fetchOrderedRemove(key);
    if (kv == null) return null;
    return kv.?.value;
}

pub fn encode(self: UrlValues) !string {
    const alloc = self.inner.allocator;
    var list = std.ArrayList(u8).init(alloc);
    errdefer list.deinit();
    var iter = self.inner.iterator();
    var i: usize = 0;
    while (iter.next()) |entry| : (i += 1) {
        if (i > 0) try list.writer().writeAll("&");
        try list.writer().print("{s}={s}", .{ entry.key_ptr.*, try std.Uri.escapeString(alloc, entry.value_ptr.*) });
    }
    return list.toOwnedSlice();
}
