/obj/machinery/mass_driver
	name = "mass driver"
	desc = "Shoots things into space."
	icon = 'icons/obj/objects.dmi'
	icon_state = "mass_driver"
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 2
	active_power_usage = 50

	var/power = 1.0
	var/code = 1.0
	var/id_tag = "default"
	var/drive_range = 50 //this is mostly irrelevant since current mass drivers throw into space, but you could make a lower-range mass driver for interstation transport or something I guess.

/obj/machinery/mass_driver/init_multitool_menu()
	multitool_menu = new /datum/multitool_menu/idtag/mass_driver(src)

/obj/machinery/mass_driver/multitool_act(mob/user, obj/item/I)
	. = TRUE
	multitool_menu.interact(user, I)

/obj/machinery/mass_driver/screwdriver_act(mob/user, obj/item/I)
	. = TRUE
	to_chat(user, "You begin to unscrew the bolts off [src]...")
	playsound(get_turf(src), I.usesound, 50, 1)
	if(do_after(user, 30 * I.toolspeed * gettoolspeedmod(user), target = src))
		var/obj/machinery/mass_driver_frame/F = new(get_turf(src))
		F.dir = dir
		F.anchored = TRUE
		F.build = 4
		F.update_icon()
		qdel(src)

/obj/machinery/mass_driver/proc/drive(amount)
	if(stat & (BROKEN|NOPOWER))
		return
	use_power(500*power)
	var/O_limit = 0
	var/atom/target = get_edge_target_turf(src, dir)
	for(var/atom/movable/O in loc)
		if((!O.anchored && O.move_resist != INFINITY) || istype(O, /obj/mecha)) //Mechs need their launch platforms. Also checks if something is anchored or has move resist INFINITY, which should stop ghost flinging.
			O_limit++
			if(O_limit >= 20)//so no more than 20 items are sent at a time, probably for counter-lag purposes
				break
			use_power(500)
			spawn()
				var/coef = 1
				if(emagged)
					coef = 5
				O.throw_at(target, drive_range * power * coef, power * coef)
	flick("mass_driver1", src)
	return

/obj/machinery/mass_driver/emp_act(severity)
	if(stat & (BROKEN|NOPOWER))
		return
	drive()
	..(severity)

/obj/machinery/mass_driver/emag_act(mob/user)
	if(!emagged)
		emagged = 1
		if(user)
			to_chat(user, "You hack the Mass Driver, radically increasing the force at which it'll throw things. Better not stand in its way.")
		return 1
	return -1

////////////////MASS BUMPER///////////////////

/obj/machinery/mass_driver/bumper
	name = "mass bumper"
	desc = "Now you're here, now you're over there."
	density = 1

/obj/machinery/mass_driver/bumper/Bumped(atom/movable/moving_atom)
	..()

	density = 0
	step(moving_atom, get_dir(moving_atom, src))
	spawn(1)
		density = 1
	drive()
	return

////////////////MASS DRIVER FRAME///////////////////

/obj/machinery/mass_driver_frame
	name = "mass driver frame"
	icon = 'icons/obj/objects.dmi'
	icon_state = "mass_driver_frame"
	density = 0
	anchored = FALSE
	var/build = 0

/obj/machinery/mass_driver_frame/attackby(var/obj/item/W as obj, var/mob/user as mob)
	switch(build)
		if(0) // Loose frame
			if(W.tool_behaviour == TOOL_WRENCH)
				to_chat(user, "You begin to anchor \the [src] on the floor.")
				playsound(get_turf(src), W.usesound, 50, 1)
				if(do_after(user, 10 * W.toolspeed * gettoolspeedmod(user), target = src) && (build == 0))
					add_fingerprint(user)
					to_chat(user, span_notice("You anchor \the [src]!"))
					anchored = TRUE
					build++
				return 1
			return
		if(1) // Fixed to the floor
			if(W.tool_behaviour == TOOL_WRENCH)
				to_chat(user, "You begin to de-anchor \the [src] from the floor.")
				playsound(get_turf(src), W.usesound, 50, 1)
				if(do_after(user, 10 * W.toolspeed * gettoolspeedmod(user), target = src) && (build == 1))
					add_fingerprint(user)
					build--
					anchored = FALSE
					to_chat(user, span_notice("You de-anchored \the [src]!"))
				return 1
		if(2) // Welded to the floor
			if(istype(W, /obj/item/stack/cable_coil))
				var/obj/item/stack/cable_coil/C = W
				to_chat(user, "You start adding cables to \the [src]...")
				playsound(get_turf(src), C.usesound, 50, 1)
				if(do_after(user, 20 * C.toolspeed * gettoolspeedmod(user), target = src) && (C.get_amount() >= 2) && (build == 2))
					add_fingerprint(user)
					C.use(2)
					to_chat(user, span_notice("You've added cables to \the [src]."))
					build++
			return
		if(3) // Wired
			if(W.tool_behaviour == TOOL_WIRECUTTER)
				to_chat(user, "You begin to remove the wiring from \the [src].")
				if(do_after(user, 10 * W.toolspeed * gettoolspeedmod(user), target = src) && (build == 3))
					add_fingerprint(user)
					new /obj/item/stack/cable_coil(loc,2)
					playsound(get_turf(src), W.usesound, 50, 1)
					to_chat(user, span_notice("You've removed the cables from \the [src]."))
					build--
				return 1
			if(istype(W, /obj/item/stack/rods))
				var/obj/item/stack/rods/R = W
				to_chat(user, "You begin to complete \the [src]...")
				playsound(get_turf(src), R.usesound, 50, 1)
				if(do_after(user, 20 * R.toolspeed * gettoolspeedmod(user), target = src) && (R.get_amount() >= 2) && (build == 3))
					add_fingerprint(user)
					R.use(2)
					to_chat(user, span_notice("You've added the grille to \the [src]."))
					build++
				return 1
			return
		if(4) // Grille in place
			if(W.tool_behaviour == TOOL_CROWBAR)
				to_chat(user, "You begin to pry off the grille from \the [src]...")
				playsound(get_turf(src), W.usesound, 50, 1)
				if(do_after(user, 30 * W.toolspeed * gettoolspeedmod(user), target = src) && (build == 4))
					add_fingerprint(user)
					new /obj/item/stack/rods(loc,2)
					build--
				return 1
			if(W.tool_behaviour == TOOL_SCREWDRIVER)
				add_fingerprint(user)
				to_chat(user, "You finalize the Mass Driver...")
				playsound(get_turf(src), W.usesound, 50, 1)
				var/obj/machinery/mass_driver/M = new(get_turf(src))
				M.dir = src.dir
				qdel(src)
				return 1
			return
	return ..()

/obj/machinery/mass_driver_frame/welder_act(mob/user, obj/item/I)
	if(build != 0 && build != 1 && build != 2)
		return
	. = TRUE
	if(!I.tool_use_check(user, 0))
		return
	if(build == 0) //can deconstruct
		WELDER_ATTEMPT_SLICING_MESSAGE
		if(I.use_tool(src, user, 30, volume = I.tool_volume))
			WELDER_SLICING_SUCCESS_MESSAGE
			new /obj/item/stack/sheet/plasteel(drop_location(),3)
			qdel(src)
	else if(build == 1) //wrenched but not welded down
		WELDER_ATTEMPT_FLOOR_WELD_MESSAGE
		if(I.use_tool(src, user, 40, volume = I.tool_volume) && build == 1)
			WELDER_FLOOR_WELD_SUCCESS_MESSAGE
			build = 2
	else if(build == 2) //welded down
		WELDER_ATTEMPT_FLOOR_SLICE_MESSAGE
		if(I.use_tool(src, user, 40, volume = I.tool_volume) && build == 2)
			WELDER_FLOOR_SLICE_SUCCESS_MESSAGE
			build = 1

/obj/machinery/mass_driver_frame/verb/rotate()
	set category = "Object"
	set name = "Rotate Frame"
	set src in view(1)

	if( usr.stat || usr.restrained()  || HAS_TRAIT(usr, TRAIT_FAKEDEATH))
		return

	src.dir = turn(src.dir, -90)
	return
