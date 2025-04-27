const std = @import("std");

n_rows: u32,
n_cols: u32,
entries: []f64,

const Self = @This();

pub fn init(allocator: std.mem.Allocator, n_rows: u32, n_cols: u32) !Self {
    return .{
        .n_rows = n_rows,
        .n_cols = n_cols,
        .entries = try allocator.alloc(f64, n_rows * n_cols),
    };
}

pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
    allocator.free(self.entries);
}

pub fn get(self: Self, i: usize, j: usize) error{ RowIndexOutOfBounds, ColumnIndexOutOfBounds }!f64 {
    if (i < 1 or i > self.n_rows) return error.RowIndexOutOfBounds;
    if (j < 1 or j > self.n_cols) return error.ColumnIndexOutOfBounds;

    return self.entries[(j - 1) * self.n_rows + i - 1];
}

pub fn set(self: Self, i: usize, j: usize, value: f64) error{ RowIndexOutOfBounds, ColumnIndexOutOfBounds }!void {
    if (i < 1 or i > self.n_rows) return error.RowIndexOutOfBounds;
    if (j < 1 or j > self.n_cols) return error.ColumnIndexOutOfBounds;

    self.entries[(j - 1) * self.n_rows + i - 1] = value;
}

pub fn setEntries(self: Self, entries: []const f64) error{WrongSize}!void {
    if (self.entries.len != entries.len)
        return error.WrongSize;

    for (0..self.entries.len) |i| self.entries[i] = entries[i];
}

pub fn print(self: Self) void {
    for (0..self.n_rows) |i| {
        std.debug.print("{d:3}: [ {d:.2}", .{ i + 1, self.entries[i] });
        for (1..self.n_cols) |j| std.debug.print(", {d:.2}", .{self.entries[j * self.n_rows + i]});
        std.debug.print(" ]\n", .{});
    }
}

const t = std.testing;

test init {
    const ta = t.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    for (0..9) |i| try t.expectApproxEqAbs(0.0, m.entries[i], 1e-12);
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

    try t.expectApproxEqAbs(1.0, try m.get(1, 1), 1e-12);
    try t.expectApproxEqAbs(2.0, try m.get(1, 2), 1e-12);
    try t.expectApproxEqAbs(3.0, try m.get(1, 3), 1e-12);
    try t.expectApproxEqAbs(4.0, try m.get(2, 1), 1e-12);
    try t.expectApproxEqAbs(7.0, try m.get(3, 1), 1e-12);
    try t.expectApproxEqAbs(9.0, try m.get(3, 3), 1e-12);
    try t.expectApproxEqAbs(5.0, try m.get(2, 2), 1e-12);
}

test set {
    const ta = t.allocator;

    const m = try init(ta, 3, 3);
    defer m.deinit(ta);

    try t.expectError(error.RowIndexOutOfBounds, m.set(0, 1, 1.0));
    try t.expectError(error.RowIndexOutOfBounds, m.set(4, 1, 1.0));
    try t.expectError(error.ColumnIndexOutOfBounds, m.set(1, 0, 1.0));
    try t.expectError(error.ColumnIndexOutOfBounds, m.set(1, 4, 1.0));

    try m.setEntries(&.{ 1, 4, 7, 2, 5, 8, 3, 6, 9 });

    // [ 1, 2, 3 ]
    // [ 4, 5, 6 ]
    // [ 7, 8, 9 ]

    try m.set(3, 3, 99.0);
    try m.set(2, 2, 7.75);

    try t.expectApproxEqAbs(1.0, try m.get(1, 1), 1e-12);
    try t.expectApproxEqAbs(2.0, try m.get(1, 2), 1e-12);
    try t.expectApproxEqAbs(99.0, try m.get(3, 3), 1e-12);
    try t.expectApproxEqAbs(7.75, try m.get(2, 2), 1e-12);
}
