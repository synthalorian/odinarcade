// Package ecs is a tiny, documented 2D Entity-Component-System.
//
// Design in one breath:
//   - An Entity is a generational handle: {index, generation}.
//   - Components live in Structure-of-Arrays form: one fixed-size array per
//     component type, indexed by Entity.index.
//   - A per-entity bit_set (Component_Set) records which components are attached.
//   - Systems are plain procedures that loop over the arrays and touch only
//     entities whose mask contains the components they need.
//
// Storage is fixed-capacity (MAX_ENTITIES) so the World is a single allocation
// with no hidden resizing. Bump MAX_ENTITIES if you need more.
package ecs

MAX_ENTITIES :: 1024

// Vec2 is a 2D vector. Odin arrays support element-wise arithmetic, so
// `a + b` and `v * dt` just work.
Vec2 :: [2]f32

// Entity is a generational handle. Destroying an entity bumps the generation
// stored in its slot, so stale handles stop resolving even after the slot is
// reused. Generations start at 1, so the zero value (NULL_ENTITY) is never alive.
Entity :: struct {
	index:      u32,
	generation: u32,
}

NULL_ENTITY :: Entity{}

// Component enumerates every component type the World knows about.
// Add a variant here plus a storage array in World to add a component.
Component :: enum u8 {
	Position,
	Velocity,
	Acceleration,
}

// Component_Set is the per-entity signature / mask.
Component_Set :: bit_set[Component;u8]
