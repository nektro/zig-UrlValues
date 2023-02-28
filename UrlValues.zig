const UrlValues = @This();
const string = []const u8;
const std = @import("std");
const uri = @import("uri");

inner: std.StringArrayHashMap(string),

pub fn init(alloc: std.mem.Allocator) UrlValues {
    return .{
        .inner = std.StringArrayHashMap(string).init(alloc),
    };
}

pub fn add(self: *UrlValues, key: string, value: string) !void {
    try self.inner.putNoClobber(key, value);
}

pub fn encode(self: UrlValues) !string {
    const alloc = self.inner.allocator;
    var list = std.ArrayList(u8).init(alloc);
    errdefer list.deinit();
    var iter = self.inner.iterator();
    var i: usize = 0;
    while (iter.next()) |entry| : (i += 1) {
        if (i > 0) try list.writer().writeAll("&");
        try list.writer().print("{s}={s}", .{ entry.key_ptr.*, try uri.escapeString(alloc, entry.value_ptr.*) });
    }
    return list.toOwnedSlice();
}
