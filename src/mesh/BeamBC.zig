node_idx: u32,
beam_idx: u32,
type0: BCType,
type1: BCType,
type2: BCType,
type3: BCType,
type4: BCType,
type5: BCType,
value0: f64,
value1: f64,
value2: f64,
value3: f64,
value4: f64,
value5: f64,

const BCType = enum {
    None,
    Force,
    Support,
    StringSupport,
};

pub const format = @import("../utils.zig").structFormatFn(@This());
