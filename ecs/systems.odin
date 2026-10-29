package ecs

// Systems iterate the SoA arrays linearly over slots [0, next_index) and act
// only on live entities whose mask is a superset of what they require.
// Destroyed entities have an empty mask, so the `required <= mask` test
// alone filters them out; the alive check is kept for clarity.

// velocity_system integrates acceleration into velocity: v += a * dt.
// Requires {Velocity, Acceleration}.
velocity_system :: proc(w: ^World, dt: f32) {
	required :: Component_Set{.Velocity, .Acceleration}
	for i in 0 ..< int(w.next_index) {
		if w.alive[i] && required <= w.masks[i] {
			w.velocities[i] += w.accelerations[i] * dt
		}
	}
}

// movement_system integrates velocity into position: p += v * dt.
// Requires {Position, Velocity}.
movement_system :: proc(w: ^World, dt: f32) {
	required :: Component_Set{.Position, .Velocity}
	for i in 0 ..< int(w.next_index) {
		if w.alive[i] && required <= w.masks[i] {
			w.positions[i] += w.velocities[i] * dt
		}
	}
}

// world_step runs one fixed tick: velocity first, then movement
// (semi-implicit Euler).
world_step :: proc(w: ^World, dt: f32) {
	velocity_system(w, dt)
	movement_system(w, dt)
}
