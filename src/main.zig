const std = @import("std");
const utils = @import("utils.zig");
const macros = @import("macros.zig");
const WoodPole = @import("WoodPole.zig");
const Matrix = @import("Matrix.zig");
const Mesh = @import("mesh/Mesh.zig");

const DPRINT = macros.DPRINT;

const Gpa = @import("allocator.zig").Gpa;

pub fn main() error{OutOfMemory}!void {
    defer if (comptime @hasDecl(Gpa, "deinit"))
        std.debug.print("da_deinit: {}\n", .{Gpa.deinit()});

    const gpa = Gpa.allocator();

    const pole = WoodPole{
        .height = 1.036e1,
        .bottom_diameter = 2.911e-1,
        .top_diameter = 1.86e-1,
        .fiber_strength = 5.52e7,
        .modulus_of_elasticity = 1.468e10,
        .shear_modulus = 1e9,
        .density = 5.4463e2,
    };

    DPRINT("{}", .{pole});

    const mesh: Mesh = try pole.buildMesh(gpa);
    defer mesh.deinit(gpa);

    DPRINT("{}", .{mesh.mat_props[0]});

    const matrices: [5]Matrix = blk: {
        const n_eqs: u32 = @intCast(mesh.nodes.len * 6);

        const gK = try Matrix.init(gpa, n_eqs, n_eqs);
        errdefer gK.deinit(gpa);
        const gv = try Matrix.init(gpa, n_eqs, 1);
        errdefer gv.deinit(gpa);
        const gf = try Matrix.init(gpa, n_eqs, 1);
        errdefer gf.deinit(gpa);
        const eK = try Matrix.init(gpa, 2 * 6, 2 * 6);
        errdefer eK.deinit(gpa);
        const ef = try Matrix.init(gpa, 2 * 6, 1);
        errdefer ef.deinit(gpa);

        break :blk [5]Matrix{ gK, gv, gf, eK, ef };
    };
    defer for (matrices) |m| m.deinit(gpa);

    const gK, const gv, const gf, const eK, const ef = matrices;
    _ = gv;
    _ = gf;

    for (mesh.beams) |beam| mesh.processBeam(beam, eK, ef, gK);

    DPRINT("m_K:\n{}", .{gK});
}

comptime {
    _ = @import("utils.zig");
    _ = @import("Matrix.zig");
    _ = @import("mesh/Beam.zig");
}
