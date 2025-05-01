const std = @import("std");

n_rows: u32,
n_cols: u32,
entries: []f64,

const Self = @This();

pub const Error = error{ RowIndexOutOfBounds, ColumnIndexOutOfBounds };

pub fn init(allocator: std.mem.Allocator, n_rows: u32, n_cols: u32) !Self {
    const entries = try allocator.alloc(f64, n_rows * n_cols);
    @memset(entries, 0);

    return .{
        .n_rows = n_rows,
        .n_cols = n_cols,
        .entries = entries,
    };
}

pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
    allocator.free(self.entries);
}

pub fn reset(self: Self) void {
    @memset(self.entries, 0);
}

pub fn get(self: Self, i: usize, j: usize) Error!f64 {
    if (i < 1 or i > self.n_rows) return error.RowIndexOutOfBounds;
    if (j < 1 or j > self.n_cols) return error.ColumnIndexOutOfBounds;

    return self.entries[(j - 1) * self.n_rows + i - 1];
}

pub fn set(self: Self, i: usize, j: usize, value: f64) Error!void {
    if (i < 1 or i > self.n_rows) return error.RowIndexOutOfBounds;
    if (j < 1 or j > self.n_cols) return error.ColumnIndexOutOfBounds;

    self.entries[(j - 1) * self.n_rows + i - 1] = value;
}

pub fn addTo(self: Self, i: usize, j: usize, value: f64) Error!void {
    if (i < 1 or i > self.n_rows) return error.RowIndexOutOfBounds;
    if (j < 1 or j > self.n_cols) return error.ColumnIndexOutOfBounds;

    self.entries[(j - 1) * self.n_rows + i - 1] += value;
}

pub fn setEntries(self: Self, entries: []const f64) error{WrongSize}!void {
    if (self.entries.len != entries.len) return error.WrongSize;

    for (0..self.entries.len) |i| self.entries[i] = entries[i];
}

pub fn format(
    self: Self,
    comptime fmt: []const u8,
    _: std.fmt.FormatOptions,
    out_stream: anytype,
) !void {
    if (fmt.len != 0) std.fmt.invalidFmtError(fmt, self);

    for (0..self.n_rows) |i| {
        try std.fmt.format(out_stream, "{d:3}: [{e:7.2}", .{ i + 1, self.entries[i] });
        for (1..self.n_cols) |j| try std.fmt.format(out_stream, " {e:7.2}", .{self.entries[j * self.n_rows + i]});
        try std.fmt.format(out_stream, " ]\n", .{});
    }
}

const t = std.testing;

fn expectNotEqual(comptime T: type, expected: T, actual: T) !void {
    if (actual == expected) {
        std.debug.print("Values are equal: expected {}, found {}\n", .{ expected, actual });
        return error.TestExpectedNotEqual;
    }
}

test init {
    const ta = t.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    for (0..9) |i| try t.expectEqual(0, m.entries[i]);
}

test reset {
    const ta = t.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    try m.setEntries(&.{ 1, 4, 7, 2, 5, 8, 3, 6, 9 });

    for (m.entries) |entry| try expectNotEqual(f64, 0, entry);

    m.reset();

    for (m.entries) |entry| try t.expectEqual(0, entry);
}

test get {
    const ta = t.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    try t.expectError(error.RowIndexOutOfBounds, m.get(0, 1));
    try t.expectError(error.RowIndexOutOfBounds, m.get(4, 1));
    try t.expectError(error.ColumnIndexOutOfBounds, m.get(1, 0));
    try t.expectError(error.ColumnIndexOutOfBounds, m.get(1, 4));

    // [ 1, 2, 3 ]
    // [ 4, 5, 6 ]
    // [ 7, 8, 9 ]

    try m.setEntries(&.{ 1, 4, 7, 2, 5, 8, 3, 6, 9 });

    try t.expectEqual(1.0, try m.get(1, 1));
    try t.expectEqual(2.0, try m.get(1, 2));
    try t.expectEqual(3.0, try m.get(1, 3));
    try t.expectEqual(4.0, try m.get(2, 1));
    try t.expectEqual(7.0, try m.get(3, 1));
    try t.expectEqual(9.0, try m.get(3, 3));
    try t.expectEqual(5.0, try m.get(2, 2));
}

test set {
    const ta = t.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    try t.expectError(error.RowIndexOutOfBounds, m.set(0, 1, 1.0));
    try t.expectError(error.RowIndexOutOfBounds, m.set(4, 1, 1.0));
    try t.expectError(error.ColumnIndexOutOfBounds, m.set(1, 0, 1.0));
    try t.expectError(error.ColumnIndexOutOfBounds, m.set(1, 4, 1.0));

    // [ 1, 2, 3 ]
    // [ 4, 5, 6 ]
    // [ 7, 8, 9 ]

    try m.setEntries(&.{ 1, 4, 7, 2, 5, 8, 3, 6, 9 });

    try m.set(3, 3, 99.0);
    try m.set(2, 2, 7.75);

    try t.expectEqual(1.0, try m.get(1, 1));
    try t.expectEqual(2.0, try m.get(1, 2));
    try t.expectEqual(99.0, try m.get(3, 3));
    try t.expectEqual(7.75, try m.get(2, 2));
}

test addTo {
    const ta = t.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    try t.expectError(error.RowIndexOutOfBounds, m.set(0, 1, 1.0));
    try t.expectError(error.RowIndexOutOfBounds, m.set(4, 1, 1.0));
    try t.expectError(error.ColumnIndexOutOfBounds, m.set(1, 0, 1.0));
    try t.expectError(error.ColumnIndexOutOfBounds, m.set(1, 4, 1.0));

    // [ 1, 2, 3 ]
    // [ 4, 5, 6 ]
    // [ 7, 8, 9 ]

    try m.setEntries(&.{ 1, 4, 7, 2, 5, 8, 3, 6, 9 });

    try m.addTo(1, 1, 99.0);
    try m.addTo(2, 2, 7.75);

    try t.expectEqual(100.0, try m.get(1, 1));
    try t.expectEqual(2.0, try m.get(1, 2));
    try t.expectEqual(9.0, try m.get(3, 3));
    try t.expectEqual(12.75, try m.get(2, 2));
}

test format {
    const expected =
        \\  1: [ 1.00e0  2.00e0  3.00e0 ]
        \\  2: [ 4.00e0  5.00e0  6.00e0 ]
        \\  3: [ 7.00e0  8.00e0  9.00e0 ]
        \\
    ;
    const ta = t.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    try m.setEntries(&.{ 1, 4, 7, 2, 5, 8, 3, 6, 9 });

    var line_buffer: [expected.len]u8 = undefined;
    var fbs: std.io.FixedBufferStream([]u8) = std.io.fixedBufferStream(&line_buffer);

    try fbs.writer().print("{}", .{m});

    try t.expectEqualSlices(u8, expected, fbs.getWritten());
}
