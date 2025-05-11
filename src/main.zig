const std = @import("std");
const utils = @import("utils.zig");
const macros = @import("macros.zig");
const Input = @import("Input.zig");
const Matrices = @import("Matrices.zig");
const WoodPole = @import("WoodPole.zig");
const Matrix = @import("Matrix.zig");
const Mesh = @import("mesh/Mesh.zig");

const DPRINT = macros.DPRINT;

const Gpa = @import("allocator.zig").Gpa;

pub fn main() (utils.ReadFileZError || error{ OutOfMemory, ParseZon, LapackeError })!void {
    defer if (comptime @hasDecl(Gpa, "deinit"))
        std.debug.print("da_deinit: {}\n", .{Gpa.deinit()});

    const gpa = Gpa.allocator();

    const file_buffer = try utils.readFileZ(gpa, "zon/input.zon");
    defer gpa.free(file_buffer);

    const input = try std.zon.parse.fromSlice(Input, gpa, file_buffer, null, .{
        .ignore_unknown_fields = false,
        .free_on_error = false,
    });

    const pole = input.pole;

    DPRINT("{}", .{pole});

    const mesh: Mesh = try pole.buildMesh(gpa, input.max_elem_size, input.force_top);
    defer mesh.deinit(gpa);

    DPRINT("{}", .{mesh.mat_props[0]});

    const matrices = try Matrices.init(gpa, @intCast(mesh.nodes.len));
    defer matrices.deinit(gpa);

    mesh.assembleGlobalK(matrices.gK, matrices.eK);

    mesh.applyBoundaryConditions(matrices.gK, matrices.gf);
    DPRINT("matrices.gK =\n{}", .{matrices.gK});
    DPRINT("gF =\n{}", .{matrices.gf});

    try Matrix.solveCholesky(matrices.gK, matrices.gf);
    DPRINT("gF =\n{}", .{matrices.gf});
}

comptime {
    _ = @import("utils.zig");
    _ = @import("mat3d.zig");
    _ = @import("Matrix.zig");
    _ = @import("mesh/Beam.zig");
}
