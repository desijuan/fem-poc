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

pub fn e(self: Self, i: usize, j: usize) *f64 {
    return &self.entries[(i - 1) * self.n_cols + j - 1];
}

pub fn get(self: Self, i: usize, j: usize) f64 {
    return self.entries[(i - 1) * self.n_cols + j - 1];
}

pub fn set(self: Self, i: usize, j: usize, value: f64) void {
    self.entries[(i - 1) * self.n_cols + j - 1] = value;
}

pub fn setEntries(self: Self, entries: []const f64) !void {
    if (self.entries.len != entries.len)
        return error.WrongSize;

    for (0..self.entries.len) |i|
        self.entries[i] = entries[i];
}
