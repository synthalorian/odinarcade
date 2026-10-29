// The CLI stub: prints a banner, help, version, or runs a tiny ECS demo.
package main

import "core:fmt"
import "core:os"
import "core:strings"

import "../color"
import "../ecs"
import "../meta"

main :: proc() {
	defer free_all(context.temp_allocator)

	on := color.enabled_from_env()
	cmd := len(os.args) > 1 ? os.args[1] : "demo"

	switch cmd {
	case "-h", "--help", "help":
		print_help(on)
	case "-V", "--version", "version":
		fmt.printf("%s %s\n", color.magenta(on, meta.PROJECT_NAME), color.cyan(on, meta.VERSION))
	case "demo":
		run_demo(on)
	case:
		fmt.eprintf("unknown command: %s (try --help)\n", cmd)
		os.exit(2)
	}
}

banner :: proc(on: bool) {
	title := strings.to_upper(meta.PROJECT_NAME, context.temp_allocator)
	fmt.println(color.magenta(on, fmt.tprintf("░▒▓ %s ▓▒░", title)))
	fmt.println(color.cyan(on, meta.TAGLINE))
}

print_help :: proc(on: bool) {
	banner(on)
	fmt.println()
	fmt.printf("usage: %s [command]\n\n", meta.PROJECT_NAME)
	fmt.println("commands:")
	fmt.printf("  %s     run a few ECS ticks and print positions (default)\n", color.cyan(on, "demo"))
	fmt.printf("  %s  print version\n", color.cyan(on, "version"))
	fmt.printf("  %s     show this help\n", color.cyan(on, "help"))
	fmt.println()
	fmt.println("env: NO_COLOR=1 disables color (also off when stdout is not a TTY)")
}

run_demo :: proc(on: bool) {
	banner(on)

	w := ecs.world_create()
	defer ecs.world_destroy(w)

	// A drifter (constant velocity), a rocket (accelerating), and a statue
	// (position only, so systems leave it alone).
	drifter, _ := ecs.create_entity(w)
	ecs.set_position(w, drifter, {0, 0})
	ecs.set_velocity(w, drifter, {1, 0.5})

	rocket, _ := ecs.create_entity(w)
	ecs.set_position(w, rocket, {0, 0})
	ecs.set_velocity(w, rocket, {0, 0})
	ecs.set_acceleration(w, rocket, {0, 2})

	statue, _ := ecs.create_entity(w)
	ecs.set_position(w, statue, {5, 5})

	names := [3]string{"drifter", "rocket", "statue"}
	ents := [3]ecs.Entity{drifter, rocket, statue}

	DT :: f32(0.5)
	for tick in 0 ..= 4 {
		if tick > 0 {
			ecs.world_step(w, DT)
		}
		fmt.println(color.magenta(on, fmt.tprintf("-- tick %d --", tick)))
		for e, i in ents {
			p, _ := ecs.get_position(w, e)
			fmt.printf("  %-8s %s\n", names[i], color.cyan(on, fmt.tprintf("(%.2f, %.2f)", p.x, p.y)))
		}
	}
}
