--[[
Extra items for tinycubes work.
]]




-- a debug probe tool;
-- prints out info about a tiny cube when used on one.
local apiname = _mod.entity.apiname
local msg = "STUB debug probe not implemented"
local rightclick = function(api, clicker, itemstack)
	-- stub for now, will use api later when defined
	if clicker:is_player() then
		local n = clicker:get_player_name()
		minetest.chat_send_player(n, msg)
	end
end
local mn = _mod.modname
local name = mn..":debug_probe"
minetest.register_craftitem(name, {
	inventory_image = "tinycubes_debugprobe.png",
	on_entity_rightclick = {
		[apiname] = rightclick,
	},
})

