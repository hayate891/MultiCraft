-- minetest/fire/init.lua

-- Global namespace for functions

fire = {}
fire.mod = "redo"

-- Register flame nodes

minetest.register_node("fire:basic_flame", {
	drawtype = "plantlike", --"firelike",
	tiles = {
		{
			name = "fire_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "fire_basic_flame.png",
	paramtype = "light",
	light_source = 14,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	damage_per_second = 4,
	groups = {igniter = 2, dig_immediate = 3},
	drop = "",

	on_timer = function(pos)

		local f = minetest.find_node_near(pos, 1, {"group:flammable"})

		if not f then
			minetest.swap_node(pos, {name = "air"})
			return
		end

		-- restart timer
		return true
	end,

	on_construct = function(pos)
		minetest.get_node_timer(pos):start(math.random(30, 60))
--		minetest.after(0, fire.on_flame_add_at, pos)
	end,

--	on_destruct = function(pos)
--		minetest.after(0, fire.on_flame_remove_at, pos)
--	end,

	on_blast = function()
	end, -- unaffected by explosions
})

minetest.register_node("fire:permanent_flame", {
	description = "Permanent Flame",
	drawtype = "firelike",
	tiles = {
		{
			name = "fire_basic_flame_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1
			},
		},
	},
	inventory_image = "fire_basic_flame.png",
	paramtype = "light",
	light_source = 14,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	damage_per_second = 4,
	groups = {igniter = 2, dig_immediate = 3},
	drop = "",

	on_blast = function()
	end,
})

minetest.register_tool("fire:flint_and_steel", {
	description = "Flint and Steel",
	inventory_image = "fire_flint_steel.png",

	on_use = function(itemstack, user, pointed_thing)

		local player_name = user:get_player_name()
		local pt = pointed_thing

		if pt.type == "node"
		and minetest.get_node(pt.above).name == "air" then

			itemstack:add_wear(1000)

			local node_under = minetest.get_node(pt.under).name

			if minetest.get_item_group(node_under, "flammable") >= 1 then

				if not minetest.is_protected(pt.above, player_name) then
					minetest.set_node(pt.above, {name = "fire:basic_flame"})
				else
					minetest.chat_send_player(player_name, "This area is protected")
				end
			end
		end
		
		if not minetest.setting_getbool("creative_mode") then
			return itemstack
		end
	end
})

minetest.register_craft({
	output = "fire:flint_and_steel",
	recipe = {
		{"default:flint", "default:steel_ingot"}
	}
})

-- Get sound area of position

fire.D = 6 -- size of sound areas

function fire.get_area_p0p1(pos)
	local p0 = {
		x = math.floor(pos.x / fire.D) * fire.D,
		y = math.floor(pos.y / fire.D) * fire.D,
		z = math.floor(pos.z / fire.D) * fire.D,
	}

	local p1 = {
		x = p0.x + fire.D - 1,
		y = p0.y + fire.D - 1,
		z = p0.z + fire.D - 1
	}

	return p0, p1
end


-- Fire sounds table
-- key: position hash of low corner of area
-- value: {handle=sound handle, name=sound name}
fire.sounds = {}


-- Update fire sounds in sound area of position

function fire.update_sounds_around(pos)

	local p0, p1 = fire.get_area_p0p1(pos)
	local cp = {x = (p0.x + p1.x) / 2, y = (p0.y + p1.y) / 2, z = (p0.z + p1.z) / 2}
	local flames_p = minetest.find_nodes_in_area(p0, p1, {"fire:basic_flame"})

	--print("number of flames at "..minetest.pos_to_string(p0).."/"
	--		..minetest.pos_to_string(p1)..": "..#flames_p)

	local should_have_sound = (#flames_p > 0)
	local wanted_sound = nil

	if #flames_p >= 9 then
		wanted_sound = {name = "fire_large", gain = 0.7}
	elseif #flames_p > 0 then
		wanted_sound = {name = "fire_small", gain = 0.9}
	end

	local p0_hash = minetest.hash_node_position(p0)
	local sound = fire.sounds[p0_hash]

	if not sound then

		if should_have_sound then

			fire.sounds[p0_hash] = {
				handle = minetest.sound_play(wanted_sound,
					{pos = cp, max_hear_distance = 16, loop = true}),
				name = wanted_sound.name,
			}
		end
	else
		if not wanted_sound then

			minetest.sound_stop(sound.handle)
			fire.sounds[p0_hash] = nil

		elseif sound.name ~= wanted_sound.name then

			minetest.sound_stop(sound.handle)

			fire.sounds[p0_hash] = {
				handle = minetest.sound_play(wanted_sound,
					{pos = cp, max_hear_distance = 16, loop = true}),
				name = wanted_sound.name,
			}
		end
	end
end


-- Update fire sounds on flame node construct or destruct

function fire.on_flame_add_at(pos)
	fire.update_sounds_around(pos)
end


function fire.on_flame_remove_at(pos)
	fire.update_sounds_around(pos)
end


-- Return positions for flames around a burning node

function fire.find_pos_for_flame_around(pos)
	return minetest.find_node_near(pos, 1, {"air"})
end


-- Detect nearby extinguishing nodes

function fire.flame_should_extinguish(pos)
	return minetest.find_node_near(pos, 1, {"group:puts_out_fire"})
end


-- Extinguish all flames quickly with water, snow, ice

minetest.register_abm({
	nodenames = {"fire:basic_flame", "fire:permanent_flame"},
	neighbors = {"group:puts_out_fire"},
	interval = 3,
	chance = 1,
	catch_up = false,
	action = function(p0, node, _, _)
		minetest.swap_node(p0, {name = "air"})
		minetest.sound_play("fire_extinguish_flame",
			{pos = p0, max_hear_distance = 16, gain = 0.25})
	end,
})


-- Enable the following ABMs according to 'disable fire' setting

if minetest.setting_getbool("disable_fire") then

	-- Remove basic flames only

	minetest.register_abm({
		nodenames = {"fire:basic_flame"},
		interval = 7,
		chance = 1,
		catch_up = false,
		action = function(p0, node, _, _)
			minetest.swap_node(p0, {name = "air"})
		end,
	})

else

	-- Ignite neighboring nodes, add basic flames

	minetest.register_abm({
		nodenames = {"group:flammable"},
		neighbors = {"group:igniter"},
		interval = 7,
		chance = 12,
		catch_up = false,
		action = function(p0, node, _, _)
			-- If there is water or stuff like that around node, don't ignite
			if fire.flame_should_extinguish(p0) then
				return
			end
			local p = fire.find_pos_for_flame_around(p0)
			if p then
				minetest.swap_node(p, {name = "fire:basic_flame"})
			end
		end,
	})

	-- Remove basic flames and flammable nodes

	minetest.register_abm({
		nodenames = {"fire:basic_flame"},
		interval = 5,
		chance = 6,
		catch_up = false,
		action = function(p0, node, _, _)
			-- If there are no flammable nodes around flame, remove flame
			local p = minetest.find_node_near(p0, 1, {"group:flammable"})

			if p and math.random(1, 4) == 1 then
				-- remove flammable nodes around flame
				local node = minetest.get_node(p)
				local def = minetest.registered_nodes[node.name]
				if def.on_burn then
					def.on_burn(p)
				else
					minetest.remove_node(p)
					nodeupdate(p)
				end
			end
		end,
	})

end


-- used to drop items inside a chest or container
function fire.drop_items(pos, invstring)

	local meta = minetest.get_meta(pos)
	local inv  = meta:get_inventory()

	for i = 1, inv:get_size(invstring) do

		local m_stack = inv:get_stack(invstring, i)
		local obj = minetest.add_item(pos, m_stack)

		if obj then

			obj:setvelocity({
				x = math.random(-1, 1),
				y = 3,
				z = math.random(-1, 1)
			})
		end
	end

end


-- override chest node so that it's flammable
minetest.override_item("default:chest", {

	groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 3},

	on_burn = function(p)
		fire.drop_items(p, "main")
		minetest.remove_node(p)
	end,

})