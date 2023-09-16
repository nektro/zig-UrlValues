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
    var iter = RawIterator.init(input, alloc);
    while (try iter.next()) |piece| {
        const k = piece[0];
        const v = piece[1];
        try uv.add(k, v);
    }
    return uv;
}

const RawIterator = struct {
    input: string,
    iter: std.mem.SplitIterator(u8, .scalar),
    alloc: std.mem.Allocator,

    fn init(input: string, alloc: std.mem.Allocator) RawIterator {
        return .{
            .input = input,
            .iter = std.mem.splitScalar(u8, input, '&'),
            .alloc = alloc,
        };
    }

    fn next(ri: *RawIterator) !?struct { string, string } {
        while (ri.iter.next()) |piece| {
            if (piece.len == 0) continue;
            var jter = std.mem.split(u8, piece, "=");
            var k = jter.next().?;
            var v = jter.rest();
            std.mem.replaceScalar(u8, @constCast(v), '+', ' ');
            v = try std.Uri.unescapeString(ri.alloc, v);
            return .{ k, v };
        }
        return null;
    }
};

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

pub fn IteratorFor(comptime field: string) type {
    return struct {
        raw: RawIterator,

        const Self = @This();

        pub fn init(alloc: std.mem.Allocator, input: string) Self {
            return .{
                .raw = .{
                    .input = input,
                    .iter = std.mem.splitScalar(u8, input, '&'),
                    .alloc = alloc,
                },
            };
        }

        pub fn next(self: *Self) !?string {
            while (try self.raw.next()) |piece| {
                const k = piece[0];
                const v = piece[1];
                if (!std.mem.eql(u8, k, field)) continue;
                return v;
            }
            return null;
        }
    };
}
