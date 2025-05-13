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

const INPUT_FILE = "input.zon";

pub fn main() (utils.ReadFileZError || error{ OutOfMemory, ParseZon, LapackeError })!void {
    defer if (comptime @hasDecl(Gpa, "deinit")) Gpa.deinit();

    const gpa = Gpa.allocator();

    DPRINT("READING INPUT FROM FILE: \"{s}\"\n", .{INPUT_FILE});
    const file_buffer = try utils.readFileZ(gpa, INPUT_FILE);
    defer gpa.free(file_buffer);

    const input = try std.zon.parse.fromSlice(Input, gpa, file_buffer, null, .{
        .ignore_unknown_fields = false,
        .free_on_error = false,
    });

    const pole = input.pole;
    DPRINT("{}", .{pole});

    const force_top = input.force_top;
    DPRINT("force_top {}\n", .{force_top});

    DPRINT("BUILDING MESH...\n", .{});
    const mesh: Mesh = try pole.buildMesh(gpa, input.max_elem_size, force_top);
    defer mesh.deinit(gpa);

    const matrices = try Matrices.init(gpa, @intCast(mesh.nodes.len));
    defer matrices.deinit(gpa);

    DPRINT("ASSEMBLING STIFFNESS MATRIX...\n", .{});
    mesh.assembleGlobalK(matrices.gK, matrices.eK);
    mesh.applyBoundaryConditions(matrices.gK, matrices.gf);

    DPRINT("STARTING CALCULATION...\n", .{});
    try Matrix.solveCholesky(matrices.gK, matrices.gf);

    DPRINT("DONE!\nSOLUTION:\n", .{});
    mesh.printSolution(matrices.gf);
}

comptime {
    _ = @import("utils.zig");
    _ = @import("mat3d.zig");
    _ = @import("Matrix.zig");
    _ = @import("mesh/Beam.zig");
}
