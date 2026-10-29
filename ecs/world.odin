package ecs

// World owns all entity bookkeeping and component storage (SoA layout).
// It is roughly MAX_ENTITIES * 40 bytes, so create it with world_create
// (heap) rather than on the stack.
World :: struct {
	// Component storage: one array per component, indexed by Entity.index.
	positions:     [MAX_ENTITIES]Vec2,
	velocities:    [MAX_ENTITIES]Vec2,
	accelerations: [MAX_ENTITIES]Vec2,

	// Entity bookkeeping.
	masks:         [MAX_ENTITIES]Component_Set,
	generations:   [MAX_ENTITIES]u32,
	alive:         [MAX_ENTITIES]bool,
	free_list:     [MAX_ENTITIES]u32, // stack of recycled slot indices
	free_count:    int,
	next_index:    u32, // high-water mark: slots [0, next_index) have been used
	alive_count:   int,
}

// world_create allocates a zeroed World.
world_create :: proc(allocator := context.allocator) -> ^World {
	return new(World, allocator)
}

// world_destroy frees a World created with world_create.
world_destroy :: proc(w: ^World, allocator := context.allocator) {
	free(w, allocator)
}

// create_entity returns a fresh handle, recycling destroyed slots first.
// ok is false when the World is full.
create_entity :: proc(w: ^World) -> (e: Entity, ok: bool) {
	index: u32
	if w.free_count > 0 {
		w.free_count -= 1
		index = w.free_list[w.free_count]
	} else if int(w.next_index) < MAX_ENTITIES {
		index = w.next_index
		w.next_index += 1
	} else {
		return NULL_ENTITY, false
	}

	if w.generations[index] == 0 {
		w.generations[index] = 1
	}
	w.alive[index] = true
	w.masks[index] = {}
	w.alive_count += 1
	return Entity{index = index, generation = w.generations[index]}, true
}

// is_alive reports whether the handle still refers to a live entity.
is_alive :: proc(w: ^World, e: Entity) -> bool {
	if int(e.index) >= MAX_ENTITIES {
		return false
	}
	return w.alive[e.index] && w.generations[e.index] == e.generation
}

// destroy_entity removes an entity and all its components.
// Returns false if the handle was already stale.
destroy_entity :: proc(w: ^World, e: Entity) -> bool {
	if !is_alive(w, e) {
		return false
	}
	w.alive[e.index] = false
	w.masks[e.index] = {}
	w.generations[e.index] += 1
	w.free_list[w.free_count] = e.index
	w.free_count += 1
	w.alive_count -= 1
	return true
}

// has_components reports whether a live entity has every component in `set`.
has_components :: proc(w: ^World, e: Entity, set: Component_Set) -> bool {
	return is_alive(w, e) && set <= w.masks[e.index]
}

// remove_component detaches a component. The stored value is left in place
// but is ignored by systems because the mask bit is cleared.
remove_component :: proc(w: ^World, e: Entity, c: Component) -> bool {
	if !is_alive(w, e) {
		return false
	}
	w.masks[e.index] -= {c}
	return true
}

// --- Component setters / getters -------------------------------------------

set_position :: proc(w: ^World, e: Entity, p: Vec2) -> bool {
	if !is_alive(w, e) {
		return false
	}
	w.positions[e.index] = p
	w.masks[e.index] += {.Position}
	return true
}

set_velocity :: proc(w: ^World, e: Entity, v: Vec2) -> bool {
	if !is_alive(w, e) {
		return false
	}
	w.velocities[e.index] = v
	w.masks[e.index] += {.Velocity}
	return true
}

set_acceleration :: proc(w: ^World, e: Entity, a: Vec2) -> bool {
	if !is_alive(w, e) {
		return false
	}
	w.accelerations[e.index] = a
	w.masks[e.index] += {.Acceleration}
	return true
}

get_position :: proc(w: ^World, e: Entity) -> (p: Vec2, ok: bool) {
	if !has_components(w, e, {.Position}) {
		return {}, false
	}
	return w.positions[e.index], true
}

get_velocity :: proc(w: ^World, e: Entity) -> (v: Vec2, ok: bool) {
	if !has_components(w, e, {.Velocity}) {
		return {}, false
	}
	return w.velocities[e.index], true
}

get_acceleration :: proc(w: ^World, e: Entity) -> (a: Vec2, ok: bool) {
	if !has_components(w, e, {.Acceleration}) {
		return {}, false
	}
	return w.accelerations[e.index], true
}
