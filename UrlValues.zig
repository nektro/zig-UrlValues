const UrlValues = @This();
const string = []const u8;
const std = @import("std");
const extras = @import("extras");
const KV = struct { key: string, value: string };

allocator: std.mem.Allocator,
inner: std.MultiArrayList(KV),

pub fn init(alloc: std.mem.Allocator) UrlValues {
    return .{
        .allocator = alloc,
        .inner = std.MultiArrayList(KV){},
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
            const k = jter.next().?;
            var v = jter.rest();
            std.mem.replaceScalar(u8, @constCast(v), '+', ' ');
            v = std.Uri.percentDecodeInPlace(try ri.alloc.dupe(u8, v));
            return .{ k, v };
        }
        return null;
    }
};

pub fn set(self: *UrlValues, key: string, value: string) !void {
    const keys = self.inner.items(.key);
    const values = self.inner.items(.value);
    var idx = extras.indexOfSlice(u8, keys, key) orelse {
        return try self.add(key, value);
    };
    values[idx] = value;
    while (true) {
        idx += 1;
        if (idx >= self.inner.len) break;
        if (!std.mem.eql(u8, keys[idx], key)) break;
        self.inner.orderedRemove(idx);
    }
}

pub fn add(self: *UrlValues, key: string, value: string) !void {
    try self.inner.append(self.allocator, .{ .key = key, .value = value });
}

pub fn get(self: *UrlValues, key: string) ?string {
    const keys = self.inner.items(.key);
    const idx = extras.indexOfSlice(u8, keys, key) orelse return null;
    const values = self.inner.items(.value);
    return values[idx];
}

pub fn getAll(self: *UrlValues, key: string) !?[]const string {
    const keys = self.inner.items(.key);
    const values = self.inner.items(.value);
    var backer: [256]usize = undefined;
    @memset(&backer, 0);
    var bset = std.bit_set.DynamicBitSetUnmanaged{ .bit_length = self.inner.len, .masks = &backer };
    var prev: bool = false;
    var phase_count: usize = 0;
    for (keys, 0..) |k, i| {
        const this = std.mem.eql(u8, k, key);
        defer prev = this;
        if (this != prev) phase_count += 1;
        if (this == true) bset.set(i);
    }
    if (prev == true) phase_count += 1;
    const count = bset.count();
    if (count == 0) return null;
    if (count == 1) return values[bset.findFirstSet().?..][0..1];
    if (phase_count == 2) return values[bset.findFirstSet().? .. findLastSet(bset).? + 1];
    const items = try self.allocator.alloc(string, count);
    var iter = bset.iterator(.{});
    var i: usize = 0;
    while (iter.next()) |idx| : (i += 1) items[i] = values[idx];
    return items;
}

pub fn take(self: *UrlValues, key: string) ?string {
    const keys = self.inner.items(.key);
    const idx = extras.indexOfSlice(u8, keys, key) orelse return null;
    const values = self.inner.items(.value);
    defer self.inner.orderedRemove(idx);
    return values[idx];
}

pub fn encode(self: *UrlValues) !string {
    const alloc = self.allocator;
    var list = std.ArrayList(u8).init(alloc);
    errdefer list.deinit();
    for (self.inner.items(.key), self.inner.items(.value), 0..) |k, v, i| {
        if (i > 0) try list.writer().writeAll("&");
        try list.writer().print("{s}={%}", .{ k, std.Uri.Component{ .raw = v } });
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

/// Finds the index of the last set bit.
/// If no bits are set, returns null.
pub fn findLastSet(self: std.bit_set.DynamicBitSetUnmanaged) ?usize {
    if (self.bit_length == 0) return null;
    const bs = @bitSizeOf(usize);
    var len = self.bit_length / bs;
    if (self.bit_length % bs != 0) len += 1;
    var offset: usize = len * bs;
    var idx: usize = len - 1;
    while (self.masks[idx] == 0) : (idx -= 1) {
        offset -= bs;
        if (idx == 0) return null;
    }
    offset -= @clz(self.masks[idx]);
    offset -= 1;
    return offset;
}
