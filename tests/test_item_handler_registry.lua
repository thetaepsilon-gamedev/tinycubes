local construct = mtrequire("ds2.minetest.tinycubes.item_handler_registry")
-- fake minetest registered items table
local registered_items = {}
local apiname = "test.dummy_api"
local deps = {
	itemdef = {
		deftable = registered_items,
		entity_api_name = apiname,
	}
}
local lookup, register = construct(deps)

local mkfake = function(itemstr)
	return {
		get_name = function(self) return itemstr end,
	}
end
local fakeitem = mkfake("default:stone")





local reject = function(item)
	local handler, info = lookup(item)
	assert(handler == nil)
	assert(info == nil)
end
local acceptf = function(item, h1)
	local handler, info = lookup(item)
	assert(info ~= nil, "info nil!?")
	assert(handler == h1, "handler didn't match expected")
end

-- initially the regtable is empty, so this should fail.
reject(fakeitem)





-- register some handler for the entire mod "default"
local dummyf = function() return function() end end
local f1 = dummyf()
register.wholemod("default", f1)
-- now we expect it to return that handler.
acceptf(fakeitem, f1)

-- an unrelated item should still be rejected.
local unrelated = mkfake("randommod:item")
reject(unrelated)



-- if we now add a mod for the exact item, we expect that to take precendence.
local f2 = dummyf()
-- before...
acceptf(fakeitem, f1)
-- then...
register.exact("default:stone", f2)
-- and after
acceptf(fakeitem, f2)

-- unrelated item remains unrelated
reject(unrelated)
-- however, something else in default should fall back to the whole mod handler.
local anotherdefault = mkfake("default:cobble")
acceptf(anotherdefault, f1)





-- the highest level of precedence comes from the item's own definition.
-- this is registered from minetest.register_*item/tool etc.,
-- and ends up in the minetest.registered_items table (under mock here).
local f3 = dummyf()
-- we know default:cobble currently yields f1, from a whole-mod match;
-- override cobblestone with something more specific now.
registered_items["default:cobble"] = {
	on_entity_rightclick = {
		[apiname] = f3,
	}
}
acceptf(anotherdefault, f3)

-- we should be able to override an external exact match this way as well.
local create_subtable = function(t, k)
	local exists = t[k]
	if exists then return exists end
	t[k] = {}
	return t[k]
end
local assign = function(itemname, f)
	local k = apiname
	local def = create_subtable(registered_items, itemname)
	local rightclick = create_subtable(def, "on_entity_rightclick")
	assert(rightclick[k] == nil)
	rightclick[k] = f
end
local f4 = dummyf()
assign("default:stone", f4)
acceptf(fakeitem, f4)

-- if no other method is set, another item with a handler in it's def should work too
local n2 = "default:dirt"
local defitem = mkfake(n2)
local f5 = dummyf()
assign(n2, f5)
acceptf(defitem, f5)

-- unrelated item remains unrelated
reject(unrelated)
-- if we then make it so that the unrelated item has an entity rightclick,
-- but NOT for the one we're interested in,
-- then lookup should still fail.
registered_items["randommod:item"] = {
	on_entity_rightclick = {
		unrelated_api = dummyf(),
	}
}
reject(unrelated)



