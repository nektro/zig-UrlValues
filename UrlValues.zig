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
        try uv.append(k, v);
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
        return try self.append(key, value);
    };
    values[idx] = value;
    idx += 1;
    while (true) {
        if (idx >= self.inner.len) break;
        if (!std.mem.eql(u8, keys[idx], key)) {
            idx += 1;
            continue;
        }
        self.inner.orderedRemove(idx);
    }
}

pub fn append(self: *UrlValues, key: string, value: string) !void {
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

/// if 'value' is null, will delete all the values with key 'key'
pub fn delete(self: *UrlValues, key: string, value: ?string) void {
    var offset: usize = 0;
    while (true) {
        const keys = self.inner.items(.key);
        const values = self.inner.items(.value);
        var idx = extras.indexOfSlice(u8, keys[offset..], key) orelse break;
        idx += offset;
        if (idx >= self.inner.len) break;
        if (!std.mem.eql(u8, keys[idx], key)) break;
        if (value) |v| {
            if (!std.mem.eql(u8, values[idx], v)) {
                offset += 1;
                continue;
            }
        }
        self.inner.orderedRemove(idx);
    }
}

pub fn has(self: *const UrlValues, key: string, value: ?string) bool {
    const keys = self.inner.items(.key);
    if (value == null) {
        return extras.indexOfSlice(u8, keys, key) != null;
    }
    const values = self.inner.items(.value);
    for (keys, 0..) |k, i| {
        if (std.mem.eql(u8, key, k)) {
            if (std.mem.eql(u8, value.?, values[i])) {
                return true;
            }
        }
    }
    return false;
}

pub fn size(self: *const UrlValues) usize {
    return self.inner.len;
}

pub fn encode(self: *UrlValues) !string {
    const alloc = self.allocator;
    var list = std.ArrayList(u8).init(alloc);
    errdefer list.deinit();
    for (self.inner.items(.key), self.inner.items(.value), 0..) |k, v, i| {
        if (i > 0) try list.writer().writeAll("&");
        const fk = fmtUriComponent(std.Uri.Component{ .raw = k }, is_formurlencoded_percent_char);
        const fv = fmtUriComponent(std.Uri.Component{ .raw = v }, is_formurlencoded_percent_char);
        try list.writer().print("{}={}", .{ fk, fv });
    }
    list.items.len -= std.mem.replace(u8, list.items, "%20", "+", list.items) * 2;
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

fn percentEncode(writer: anytype, raw: []const u8, isReserved: *const fn (u8) bool) !void {
    var start: usize = 0;
    for (raw, 0..) |char, index| {
        if (!isReserved(char)) continue;
        try writer.print("{s}%{X:0>2}", .{ raw[start..index], char });
        start = index + 1;
    }
    try writer.writeAll(raw[start..]);
}

fn fmtUriComponent(component: std.Uri.Component, isReserved: *const fn (u8) bool) std.fmt.Formatter(formatUriComponent) {
    return .{ .data = .{ .component = component, .isReserved = isReserved } };
}

fn formatUriComponent(data: struct { component: std.Uri.Component, isReserved: *const fn (u8) bool }, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    switch (data.component) {
        .raw => |raw| try percentEncode(writer, raw, data.isReserved),
        .percent_encoded => |percent_encoded| try writer.writeAll(percent_encoded),
    }
}

fn is_formurlencoded_percent_char(c: u8) bool {
    if (c == '!') return true;
    if (c >= '\'' and c <= ')') return true;
    if (c == '~') return true;
    return is_component_percent_char(c);
}

fn is_component_percent_char(c: u8) bool {
    if (c >= '$' and c <= '&') return true;
    if (c == '+') return true;
    if (c == ',') return true;
    return is_userinfo_percent_char(c);
}

fn is_userinfo_percent_char(c: u8) bool {
    if (c == '/') return true;
    if (c == ':') return true;
    if (c == ';') return true;
    if (c == '=') return true;
    if (c == '@') return true;
    if (c >= '[' and c <= '^') return true;
    if (c == '|') return true;
    return is_path_percent_char(c);
}

fn is_path_percent_char(c: u8) bool {
    if (c == '?') return true;
    if (c == '`') return true;
    if (c == '{') return true;
    if (c == '}') return true;
    return is_query_percent_char(c);
}

fn is_query_percent_char(c: u8) bool {
    if (c == '"') return true;
    if (c == '#') return true;
    if (c == '<') return true;
    if (c == '>') return true;
    if (c == ' ') return true;
    return is_c0control_percent_char(c);
}

fn is_c0control_percent_char(c: u8) bool {
    if (c >= 0x00 and c <= 0x1F) return true;
    return c > 0x7E;
}
