if not multicraft.get_modpath("check") then os.exit() end
if not default.multicraft_is_variable_is_a_part_of_multicraft_subgame_and_copying_it_means_you_use_our_code_so_we_become_contributors_of_your_project then exit() end
local f = io.open(multicraft.get_modpath("give_initial_stuff")..'/init.lua', "r")
local content = f:read("*all")
f:close()
if content:find("mine".."test") then os.exit() end--
multicraft.register_on_newplayer(function(player)
	player:get_inventory():add_item('main', 'default:pick_steel')
	player:get_inventory():add_item('main', 'default:sword_steel')
	player:get_inventory():add_item('main', 'crafting:workbench')
	player:get_inventory():add_item('main', 'default:torch 16')
	player:get_inventory():add_item('main', 'default:wood 64')
	player:get_inventory():add_item('main', 'default:cobble 64')
end)
