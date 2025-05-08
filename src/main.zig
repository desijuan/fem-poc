const std = @import("std");
const utils = @import("utils.zig");
const macros = @import("macros.zig");
const Matrices = @import("Matrices.zig");
const WoodPole = @import("WoodPole.zig");
const Matrix = @import("Matrix.zig");
const Mesh = @import("mesh/Mesh.zig");

const DPRINT = macros.DPRINT;

const Gpa = @import("allocator.zig").Gpa;

pub fn main() error{ OutOfMemory, LapackeError }!void {
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

    const matrices = try Matrices.init(gpa, @intCast(mesh.nodes.len));
    defer matrices.deinit(gpa);

    mesh.assembleGlobalK(matrices.gK, matrices.eK);
    DPRINT("gK =\n{}", .{matrices.gK});

    // try Matrix.solveCholesky(matrices.gK, matrices.gf);
    // DPRINT("gF =\n{}", .{matrices.gf});
}

comptime {
    _ = @import("utils.zig");
    _ = @import("mat3d.zig");
    _ = @import("Matrix.zig");
    _ = @import("mesh/Beam.zig");
}
