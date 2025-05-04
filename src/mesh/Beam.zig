const std = @import("std");
const Matrix = @import("../Matrix.zig");
const Mesh = @import("Mesh.zig");
const MaterialProperties = @import("MaterialProperties.zig");

mat_props_idx: u32,
n0_idx: u32,
n1_idx: u32,
length: f64,
cross_area: f64, // fA
moment_x: f64, // fIy
moment_y: f64, // fIy
fJp: f64, // ?
fIp: f64, // ?

const Self = @This();

pub const format = @import("../utils.zig").structFormatFn(Self);

pub fn getEquationIndices(self: Self, eq_idxs: *[12]u32) void {
    for (1..7) |k| {
        eq_idxs[k - 1] = 6 * self.n0_idx + @as(u32, @intCast(k));
        eq_idxs[k - 1 + 6] = 6 * self.n1_idx + @as(u32, @intCast(k));
    }
}

pub const BeamData = struct {
    E: f64, // Young's Modulus
    G: f64, // Shear Modulus
    A: f64, // Cross-sectional Area
    Iy: f64, // Moment of Inertia in y
    Iz: f64, // Moment of Inertia in z
    J: f64, // Torsional constant
    L: f64, // Length
};

///  fn calcLocakK(BeamData, Matrix) error{WrongSize}!void
///
///  Calculates the Local Stiffness Matrix for a Beam element.
///
///  maps:
///  .{ E, G, A, Iy, Iz, J, L }
///
///  into:
///  ek =
///  1  [ EA/L,   0,          0,          0,      0,         0,         -EA/L,  0,          0,          0,      0,         0        ]
///  2  [ 0,      12EIz/L³,   0,          0,      0,         6EIz/L²,   0,      -12EIz/L³,  0,          0,      0,         6EIz/L²  ]
///  3  [ 0,      0,          12EIy/L³,   0,      -6EIy/L²,  0,         0,      0,          -12EIy/L³,  0,      -6EIy/L²,  0        ]
///  4  [ 0,      0,          0,          GJ/L,   0,         0,         0,      0,          0,          -GJ/L,  0,         0        ]
///  5  [ 0,      0,          -6EIy/L²,   0,      4EIy/L,    0,         0,      0,          6EIy/L²,    0,      2EIy/L,    0        ]
///  6  [ 0,      6EIz/L²,    0,          0,      0,         4EIz/L,    0,      -6EIz/L²,   0,          0,      0,         2EIz/L   ]
///  7  [ -EA/L,  0,          0,          0,      0,         0,         EA/L,   0,          0,          0,      0,         0        ]
///  8  [ 0,      -12EIz/L³,  0,          0,      0,         -6EIz/L²,  0,      12EIz/L³,   0,          0,      0,         -6EIz/L² ]
///  9  [ 0,      0,          -12EIy/L³,  0,      6EIy/L²,   0,         0,      0,          12EIy/L³,   0,      6EIy/L²,   0        ]
///  10 [ 0,      0,          0,          -GJ/L,  0,         0,         0,      0,          0,          GJ/L,   0,         0        ]
///  11 [ 0,      0,          -6EIy/L²,   0,      2EIy/L,    0,         0,      0,          6EIy/L²,    0,      4EIy/L,    0        ]
///  12 [ 0,      6EIz/L²,    0,          0,      0,         2EIz/L,    0,      -6EIz/L²,   0,          0,      0,         4EIz/L   ]
///       1       2           3           4       5          6          7       8           9           10      11         12
///
///  Writes the results into the Matrix ek. Clears ek.
///  Returns error.WrongSize if ek is not 12x12.
///
pub fn calcLocalK(
    bd: BeamData,
    ek: Matrix,
) error{WrongSize}!void {
    if (ek.n_rows != Mesh.NEQ or ek.n_cols != Mesh.NEQ) return error.WrongSize;

    ek.reset();

    return for ([_]struct { idx: [2]u32, val: f64 }{
        //   1st col: (1, 1) EA/L, (7, 1) -EA/L
        .{ .idx = .{ 1, 1 }, .val = bd.E * bd.A / bd.L },
        .{ .idx = .{ 7, 1 }, .val = -bd.E * bd.A / bd.L },

        //   2nd col: (2, 2) 12EIz/L^3, (6, 2) 6EIz/L^2, (8, 2) -12EIz/L^3, (12, 2) 6EIz/L^2
        .{ .idx = .{ 2, 2 }, .val = 12 * bd.E * bd.Iz / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 6, 2 }, .val = 6 * bd.E * bd.Iz / (bd.L * bd.L) },
        .{ .idx = .{ 8, 2 }, .val = -12 * bd.E * bd.Iz / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 12, 2 }, .val = 6 * bd.E * bd.Iz / (bd.L * bd.L) },

        //   3rd col: (3, 3) 12EIy/L^3, (5, 3) -6EIy/L^2, (9, 3) -12EIy/L^3, (11, 3) -6EIy/L^2
        .{ .idx = .{ 3, 3 }, .val = 12 * bd.E * bd.Iy / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 5, 3 }, .val = -6 * bd.E * bd.Iy / (bd.L * bd.L) },
        .{ .idx = .{ 9, 3 }, .val = -12 * bd.E * bd.Iy / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 11, 3 }, .val = -6 * bd.E * bd.Iy / (bd.L * bd.L) },

        //   4th col: (4, 4) GJ/L, (10, 4) -GJ/L
        .{ .idx = .{ 4, 4 }, .val = bd.G * bd.J / bd.L },
        .{ .idx = .{ 10, 4 }, .val = -bd.G * bd.J / bd.L },

        //   5th col: (3, 5) -6EIy/L^2, (5, 5) 4EIy/L, (9, 5) 6EIy/L^2, (11, 5) 2EIy/L
        .{ .idx = .{ 3, 5 }, .val = -6 * bd.E * bd.Iy / (bd.L * bd.L) },
        .{ .idx = .{ 5, 5 }, .val = 4 * bd.E * bd.Iy / bd.L },
        .{ .idx = .{ 9, 5 }, .val = 6 * bd.E * bd.Iy / (bd.L * bd.L) },
        .{ .idx = .{ 11, 5 }, .val = 2 * bd.E * bd.Iy / bd.L },

        //   6th col: (2, 6) 6EIz/L^2, (6, 6) 4EIz/L, (8, 6) -6EIz/L^2, (12, 6) 2EIz/L
        .{ .idx = .{ 2, 6 }, .val = 6 * bd.E * bd.Iz / (bd.L * bd.L) },
        .{ .idx = .{ 6, 6 }, .val = 4 * bd.E * bd.Iz / bd.L },
        .{ .idx = .{ 8, 6 }, .val = -6 * bd.E * bd.Iz / (bd.L * bd.L) },
        .{ .idx = .{ 12, 6 }, .val = 2 * bd.E * bd.Iz / bd.L },

        //   7th col: (1, 7) -EA/L, (7, 7) EA/L
        .{ .idx = .{ 1, 7 }, .val = -bd.E * bd.A / bd.L },
        .{ .idx = .{ 7, 7 }, .val = bd.E * bd.A / bd.L },

        //   8th col: (2, 8) -12EIz/L^3, (6, 8) -6EIz/L^2, (8, 8) 12EIz/L^3, (12, 8) -6EIz/L^2
        .{ .idx = .{ 2, 8 }, .val = -12 * bd.E * bd.Iz / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 6, 8 }, .val = -6 * bd.E * bd.Iz / (bd.L * bd.L) },
        .{ .idx = .{ 8, 8 }, .val = 12 * bd.E * bd.Iz / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 12, 8 }, .val = -6 * bd.E * bd.Iz / (bd.L * bd.L) },

        //   9th col: (3, 9) -12EIy/L^3, (5, 9) 6EIy/L^2, (9, 9) 12EIy/L^3, (11, 9) 6EIy/L^2
        .{ .idx = .{ 3, 9 }, .val = -12 * bd.E * bd.Iy / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 5, 9 }, .val = 6 * bd.E * bd.Iy / (bd.L * bd.L) },
        .{ .idx = .{ 9, 9 }, .val = 12 * bd.E * bd.Iy / (bd.L * bd.L * bd.L) },
        .{ .idx = .{ 11, 9 }, .val = 6 * bd.E * bd.Iy / (bd.L * bd.L) },

        //  10th col: (4, 10) -GJ/L, (10, 10) GJ/L
        .{ .idx = .{ 4, 10 }, .val = -bd.G * bd.J / bd.L },
        .{ .idx = .{ 10, 10 }, .val = bd.G * bd.J / bd.L },

        //  11th col: (3, 11) -6EIy/L^2, (5, 11) 2EIy/L, (9, 11) 6EIy/L^2, (11, 11) 4EIy/L
        .{ .idx = .{ 3, 11 }, .val = -6 * bd.E * bd.Iy / (bd.L * bd.L) },
        .{ .idx = .{ 5, 11 }, .val = 2 * bd.E * bd.Iy / bd.L },
        .{ .idx = .{ 9, 11 }, .val = 6 * bd.E * bd.Iy / (bd.L * bd.L) },
        .{ .idx = .{ 11, 11 }, .val = 4 * bd.E * bd.Iy / bd.L },

        //  12th col: (2, 12) 6EIz/L^2, (6, 12) 2EIz/L, (8, 12) -6EIz/L^2, (12, 12) 4EIz/L
        .{ .idx = .{ 2, 12 }, .val = 6 * bd.E * bd.Iz / (bd.L * bd.L) },
        .{ .idx = .{ 6, 12 }, .val = 2 * bd.E * bd.Iz / bd.L },
        .{ .idx = .{ 8, 12 }, .val = -6 * bd.E * bd.Iz / (bd.L * bd.L) },
        .{ .idx = .{ 12, 12 }, .val = 4 * bd.E * bd.Iz / bd.L },
    }) |entry| ek.set(entry.idx[0], entry.idx[1], entry.val) catch |err| switch (err) {
        error.RowIndexOutOfBounds, error.ColumnIndexOutOfBounds => unreachable,
    };
}

const t = std.testing;

inline fn pair(i: comptime_int, j: comptime_int) u64 {
    comptime return (i << 32) | j;
}

test calcLocalK {
    const ta = t.allocator;

    const ek = try Matrix.init(ta, 12, 12);
    defer ek.deinit(ta);

    try calcLocalK(BeamData{
        .E = 2.0,
        .G = 5.0,
        .A = 3.0,
        .Iy = 11.0,
        .Iz = 17.0,
        .J = 23.0,
        .L = 7.0,
    }, ek);

    for (1..Mesh.NEQ + 1) |ui| for (1..Mesh.NEQ + 1) |uj| {
        const i: u32 = @intCast(ui);
        const j: u32 = @intCast(uj);

        const value: f64 = switch ((@as(u64, i) << 32) | @as(u64, j)) {
            pair(1, 1) => 2.0 * 3.0 / 7.0,
            pair(7, 1) => -2.0 * 3.0 / 7.0,

            pair(2, 2) => 12.0 * 2.0 * 17.0 / (7.0 * 7.0 * 7.0),
            pair(6, 2) => 6.0 * 2.0 * 17.0 / (7.0 * 7.0),
            pair(8, 2) => -12.0 * 2.0 * 17.0 / (7.0 * 7.0 * 7.0),
            pair(12, 2) => 6.0 * 2.0 * 17.0 / (7.0 * 7.0),

            pair(3, 3) => 12.0 * 2.0 * 11.0 / (7.0 * 7.0 * 7.0),
            pair(5, 3) => -6.0 * 2.0 * 11.0 / (7.0 * 7.0),
            pair(9, 3) => -12.0 * 2.0 * 11.0 / (7.0 * 7.0 * 7.0),
            pair(11, 3) => -6.0 * 2.0 * 11.0 / (7.0 * 7.0),

            pair(4, 4) => 5.0 * 23.0 / 7.0,
            pair(10, 4) => -5.0 * 23.0 / 7.0,

            pair(3, 5) => -6.0 * 2.0 * 11.0 / (7.0 * 7.0),
            pair(5, 5) => 4.0 * 2.0 * 11.0 / 7.0,
            pair(9, 5) => 6.0 * 2.0 * 11.0 / (7.0 * 7.0),
            pair(11, 5) => 2.0 * 2.0 * 11.0 / 7.0,

            pair(2, 6) => 6.0 * 2.0 * 17 / (7.0 * 7.0),
            pair(6, 6) => 4.0 * 2.0 * 17 / 7.0,
            pair(8, 6) => -6.0 * 2.0 * 17 / (7.0 * 7.0),
            pair(12, 6) => 2.0 * 2.0 * 17 / 7.0,

            pair(1, 7) => -2.0 * 3.0 / 7.0,
            pair(7, 7) => 2.0 * 3.0 / 7.0,

            pair(2, 8) => -12.0 * 2.0 * 17.0 / (7.0 * 7.0 * 7.0),
            pair(6, 8) => -6.0 * 2.0 * 17.0 / (7.0 * 7.0),
            pair(8, 8) => 12.0 * 2.0 * 17.0 / (7.0 * 7.0 * 7.0),
            pair(12, 8) => -6.0 * 2.0 * 17.0 / (7.0 * 7.0),

            pair(3, 9) => -12.0 * 2.0 * 11.0 / (7.0 * 7.0 * 7.0),
            pair(5, 9) => 6.0 * 2.0 * 11.0 / (7.0 * 7.0),
            pair(9, 9) => 12.0 * 2.0 * 11.0 / (7.0 * 7.0 * 7.0),
            pair(11, 9) => 6.0 * 2.0 * 11.0 / (7.0 * 7.0),

            pair(4, 10) => -5.0 * 23.0 / 7.0,
            pair(10, 10) => 5.0 * 23.0 / 7.0,

            pair(3, 11) => -6.0 * 2.0 * 11.0 / (7.0 * 7.0),
            pair(5, 11) => 2.0 * 2.0 * 11.0 / 7.0,
            pair(9, 11) => 6.0 * 2.0 * 11.0 / (7.0 * 7.0),
            pair(11, 11) => 4.0 * 2.0 * 11.0 / 7.0,

            pair(2, 12) => 6.0 * 2.0 * 17.0 / (7.0 * 7.0),
            pair(6, 12) => 2.0 * 2.0 * 17.0 / 7.0,
            pair(8, 12) => -6.0 * 2.0 * 17.0 / (7.0 * 7.0),
            pair(12, 12) => 4.0 * 2.0 * 17.0 / 7.0,

            else => 0.0,
        };

        try t.expectEqual(value, try ek.get(i, j));
    };
}
