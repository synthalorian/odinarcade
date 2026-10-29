// Run with: odin test tests
package tests

import "core:testing"

import "../ecs"

@(test)
create_and_destroy_entities :: proc(t: ^testing.T) {
	w := ecs.world_create()
	defer ecs.world_destroy(w)

	a, ok_a := ecs.create_entity(w)
	b, ok_b := ecs.create_entity(w)
	testing.expect(t, ok_a && ok_b, "entities should be created")
	testing.expect(t, a != b, "handles should differ")
	testing.expect_value(t, w.alive_count, 2)
	testing.expect(t, ecs.is_alive(w, a))

	testing.expect(t, ecs.destroy_entity(w, a), "first destroy succeeds")
	testing.expect(t, !ecs.is_alive(w, a), "destroyed entity is not alive")
	testing.expect(t, !ecs.destroy_entity(w, a), "double destroy fails")
	testing.expect_value(t, w.alive_count, 1)
}

@(test)
null_entity_is_never_alive :: proc(t: ^testing.T) {
	w := ecs.world_create()
	defer ecs.world_destroy(w)

	_, ok := ecs.create_entity(w)
	testing.expect(t, ok)
	testing.expect(t, !ecs.is_alive(w, ecs.NULL_ENTITY), "zero handle must not resolve")
}

@(test)
recycled_slot_invalidates_stale_handle :: proc(t: ^testing.T) {
	w := ecs.world_create()
	defer ecs.world_destroy(w)

	old, _ := ecs.create_entity(w)
	ecs.destroy_entity(w, old)
	fresh, ok := ecs.create_entity(w)
	testing.expect(t, ok)
	testing.expect_value(t, fresh.index, old.index)
	testing.expect(t, fresh.generation != old.generation, "generation must bump")
	testing.expect(t, !ecs.is_alive(w, old), "stale handle must not resolve")
	testing.expect(t, !ecs.set_position(w, old, {1, 1}), "stale handle cannot add components")
	testing.expect(t, ecs.is_alive(w, fresh))
}

@(test)
world_capacity_is_enforced :: proc(t: ^testing.T) {
	w := ecs.world_create()
	defer ecs.world_destroy(w)

	for _ in 0 ..< ecs.MAX_ENTITIES {
		_, ok := ecs.create_entity(w)
		testing.expect(t, ok)
	}
	_, ok := ecs.create_entity(w)
	testing.expect(t, !ok, "world should be full")
}

@(test)
components_set_get_remove :: proc(t: ^testing.T) {
	w := ecs.world_create()
	defer ecs.world_destroy(w)

	e, _ := ecs.create_entity(w)
	_, has_pos := ecs.get_position(w, e)
	testing.expect(t, !has_pos, "new entity has no position")

	ecs.set_position(w, e, {3, 4})
	p, ok := ecs.get_position(w, e)
	testing.expect(t, ok)
	testing.expect_value(t, p, ecs.Vec2{3, 4})
	testing.expect(t, ecs.has_components(w, e, {.Position}))
	testing.expect(t, !ecs.has_components(w, e, {.Position, .Velocity}))

	ecs.remove_component(w, e, .Position)
	_, still := ecs.get_position(w, e)
	testing.expect(t, !still, "position removed")
}

@(test)
movement_system_applies_velocity :: proc(t: ^testing.T) {
	w := ecs.world_create()
	defer ecs.world_destroy(w)

	e, _ := ecs.create_entity(w)
	ecs.set_position(w, e, {1, 1})
	ecs.set_velocity(w, e, {2, -4})

	ecs.movement_system(w, 0.5)
	p, _ := ecs.get_position(w, e)
	testing.expect_value(t, p, ecs.Vec2{2, -1})
}

@(test)
velocity_system_applies_acceleration :: proc(t: ^testing.T) {
	w := ecs.world_create()
	defer ecs.world_destroy(w)

	e, _ := ecs.create_entity(w)
	ecs.set_velocity(w, e, {0, 0})
	ecs.set_acceleration(w, e, {0, 4})

	ecs.velocity_system(w, 0.5)
	v, _ := ecs.get_velocity(w, e)
	testing.expect_value(t, v, ecs.Vec2{0, 2})
}

@(test)
systems_skip_entities_missing_components :: proc(t: ^testing.T) {
	w := ecs.world_create()
	defer ecs.world_destroy(w)

	statue, _ := ecs.create_entity(w)
	ecs.set_position(w, statue, {5, 5})

	ghost, _ := ecs.create_entity(w)
	ecs.set_position(w, ghost, {0, 0})
	ecs.set_velocity(w, ghost, {10, 10})
	ecs.destroy_entity(w, ghost)

	ecs.world_step(w, 1)
	p, _ := ecs.get_position(w, statue)
	testing.expect_value(t, p, ecs.Vec2{5, 5})
	// The destroyed entity's stale storage must not have been integrated.
	testing.expect_value(t, w.positions[ghost.index], ecs.Vec2{0, 0})
}

@(test)
world_step_is_semi_implicit_euler :: proc(t: ^testing.T) {
	w := ecs.world_create()
	defer ecs.world_destroy(w)

	e, _ := ecs.create_entity(w)
	ecs.set_position(w, e, {0, 0})
	ecs.set_velocity(w, e, {0, 0})
	ecs.set_acceleration(w, e, {0, 2})

	// v = 0 + 2*0.5 = 1, then p = 0 + 1*0.5 = 0.5
	ecs.world_step(w, 0.5)
	p, _ := ecs.get_position(w, e)
	testing.expect_value(t, p, ecs.Vec2{0, 0.5})
}
