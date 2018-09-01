--[[
The right-click callback for entities doesn't retrieve the itemstack.
This callback adapter will provide this;
the outer function (with signature:
on_rightclick(self, clicker)
) will query the clicker for their wielded item,
then call the inner function with signature:
on_rightclick_item(self, clicker, itemstack).

If the inner function returns non-nil,
it's return value is then passed to set_wielded_item().
In this way, the inner on_rightclick_item() can then behave
like on_place() callbacks do for items (when items aren't used on an entity).
]]

local mk_itemstack_adapter = function(innerf)
	assert(type(innerf) == "function")

	return function(self, clicker)
		-- surprisingly this is defined for all entities.
		local itemstack = clicker:get_wielded_item()
		local result = innerf(self, clicker, itemstack)
		if result ~= nil then
			-- XXX: log if this returns failure?
			clicker:set_wielded_item(result)
		end
	end
end

return mk_itemstack_adapter

