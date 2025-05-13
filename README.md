# FEM Poc

Finite Elements Model of an Electric Distribution Woodpole

## Example (running with max_elem_size = 6m)

```
$ zig build run >> README.md
READING INPUT FROM FILE: "input.zon"
WoodPole {
   height: 1.036e1,
   bottom_diameter: 2.911e-1,
   top_diameter: 1.86e-1,
   fiber_strength: 5.52e7,
   modulus_of_elasticity: 1.468e10,
   shear_modulus: 1e9,
   density: 5.4463e2,
}
force_top { 0e0, 5e2, 0e0 }
BUILDING MESH...
ASSEMBLING STIFFNESS MATRIX...
STARTING CALCULATION...
DONE!
SOLUTION:
* Node 0
  height = 0e0
  Displacements
    dx = 0e0
    dy = 0e0
    dz = 0e0
  Moments
    tx = 0e0
    ty = 0e0
    tz = 0e0
* Node 1
  height = 5.18e0
  Displacements
    dx = 0e0
    dy = 1.6339778290065297e-2
    dz = 0e0
  Moments
    tx = -5.6779152359300285e-3
    ty = 0e0
    tz = 0e0
* Node 2
  height = 1.036e1
  Displacements
    dx = 0e0
    dy = 6.1583776394777794e-2
    dz = 0e0
  Moments
    tx = -1.026258623475096e-2
    ty = 0e0
    tz = 0e0
```
