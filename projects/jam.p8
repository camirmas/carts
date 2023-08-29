pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

-- CONSTANTS

debug = ""
debug_hitbox = false

k_left=0
k_right=1
k_up=2
k_down=3
k_O = 4
k_X = 5
k_rock_start = 19
k_rock_ice = 50
k_rock_sharp = 73
k_rocks = {k_rock_start, k_rock_ice, k_rock_sharp}
k_ice_block = 49
k_crabs = {34, 35}
k_hook = 11 -- soon to have more
k_alert = 21

g = 1 -- gravity

n_waves = 10
n_waves_max = 30
n_fishing_spots = 5

time_to_bite_max = 5 * 30 -- max sec to wait before a bite

missed = 0

fishing_spots = {}
waves = {}
objects = {}
boat_particles = {}

-- OBJECT DEFINITIONS

item_types = {
	fish = 1,
	junk = 2,
	item = 3
}

fish = {
	bass = {
		name = "bass",
		disp_name = "bass",
		k = 44,
		t_col = 12, -- transparency color
		type = item_types.fish,
		dim = 2 -- 2x2
	},
	salmon = {
		name = "salmon",
		disp_name = "salmon",
		k = 12,
		t_col = 11, -- transparency color
		type = item_types.fish,
		dim = 2 -- 2x2
	},
	puffer = {
		name = "puffer",
		disp_name = "puffer",
		k = 14,
		t_col = 12,
		type = item_types.fish,
		dim = 2
	},
	eel = {
		name = "eel",
		disp_name = "eel",
		k = 46,
		t_col = 12,
		type = item_types.fish,
		dim = 2
	},
	sardine = {
		name = "sardine",
		disp_name = "sardine",
		k = 96,
		t_col = 12,
		type = item_types.fish,
		dim = 2
	},
	gold_anchovy = {
		name = "gold_anchovy",
		disp_name = "gold anchovy",
		k = 64,
		t_col = 12,
		legendary = true,
		type = item_types.fish,
		dim = 2
	}
}

junk = {
	metal = {
		name = "metal",
		disp_name = "metal",
		k = 37,
		type = item_types.junk,
		t_col = 0,
		dim = 1, -- 1x1
		off = {x = 2, y = 0}
	},
	wood = {
		name = "wood",
		disp_name = "wood",
		t_col = 0,
		k = 38,
		type = item_types.junk,
		dim = 1, -- 1x1
		off = {x = 2, y = 0}
	},
}

items = {
	cassette = {
		name = "cassette",
		disp_name = "cassette",
		k = 43,
		type = item_types.item,
		dim = 1,
		-- trade for music box at seal
		items = { music_box = 1 },
		off = {x = 2, y = 4},
	},
	sm_box = {
		name = "sm_box",
		disp_name = "sm. box",
		k = 41,
		type = item_types.item,
		dim = 1,
		junk = {
			wood = 5,
			metal = 2,
		},
		fish = {
			bass = 5
		},
		off = {x = 3, y = 4},
	},
	lg_box = {
		name = "lg_box",
		disp_name = "lg. box",
		k = 40,
		type = item_types.item,
		dim = 1,
		junk = {
			wood = 8,
			metal = 4,
		},
		fish = {
			sardine = 5
		},
		off = {x = 1, y = 3},
	},
	coin = {
		name = "coin",
		disp_name = "coin",
		k = 42,
		type = item_types.item,
		dim = 1,
		-- trade for boombox at crabs
		items = {boombox = 1},
		off = {x = 2, y = 4},
	},
	super_rod = {
		name = "super_rod",
		disp_name = "super rod",
		k = 103,
		type = item_types.item,
		dim = 2,
		items = {bamboo = 1, coin = 1},
		off = {x = 0, y = -2}
	},
	music_box = {
		name = "music_box",
		disp_name = "music box",
		k = 100,
		type = item_types.item,
		dim = 1,
		items = { sm_box = 1 },
		junk = { metal = 3 },
		fish = { salmon = 3 },
		t_col = 12,
		off = {x = 1, y = 3}
	},
	boombox = {
		name = "boombox",
		disp_name = "boombox",
		k = 68,
		type = item_types.item,
		dim = 2,
		items = {cassette = 1, lg_box = 1},
		fish = { eel = 5 },
		t_col = 12,
		off = {x = 0, y = -2}
	},
	bamboo = {
		name = "bamboo",
		disp_name = "bamboo",
		k = 39,
		type = item_types.item,
		dim = 1,
		-- trade for rare fish at octopus
		fish = {
			puffer = 3,
			salmon = 3,
		},
		off = {x = 2, y = 3}
	}
}

-- map regions
regions = {
	start = {
		id = 1,
		fish = {
			common = {fish.bass},
			rare = {fish.salmon},
		},
		junk = {junk.metal, junk.wood}
	},
	island = {
		id = 2,
		fish = {
			common = {fish.bass, fish.sardine},
			rare = {fish.puffer},
		},
		junk = {junk.wood}
	},
	ice = {
		id = 3,
		fish = {
			common = {fish.sardine},
			rare = {fish.salmon},
		},
		junk = {junk.metal, junk.wood}
	},
	junk = {
		id = 4,
		fish = {
			common = {fish.eel},
			rare = {fish.eel},
		},
		junk = {junk.metal, junk.wood}
	}
}

-- UTILITIES

function collide(obj, other, dx, dy)
	if other.x+other.hitbox.x+other.hitbox.w > obj.x+obj.hitbox.x+dx and 
		other.y+other.hitbox.y+other.hitbox.h > obj.y+obj.hitbox.y+dy and
		other.x+other.hitbox.x < obj.x+obj.hitbox.x+obj.hitbox.w+dx and 
		other.y+other.hitbox.y < obj.y+obj.hitbox.y+obj.hitbox.h+dy then
		return other
	end
	return nil
end

function contains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

function draw_fish(fish, x, y)
	palt(0, false)
	palt(fish.t_col, true)
	spr(fish.k, x, y, fish.dim, fish.dim)
	palt(0, true)
	palt(fish.t_col, false)
end

function draw_item(item, x, y)
	palt(item.t_col or 0, true)
	spr(item.k, x + item.off.x, y + item.off.y, item.dim, item.dim)
	palt(item.t_col or 0, false)
end

function draw_junk(junk, x, y)
	palt(junk.t_col, true)
	spr(junk.k, x + junk.off.x, y + junk.off.y, junk.dim, junk.dim)
	palt(junk.t_col, false)
end

function get_region(x, y)
    -- Define the quadrant boundaries
    local half_width = 128 * 8 / 2
    local half_height = 64 * 8 / 2
    
    -- Determine the quadrant based on x, y location
    if x < half_width and y < half_height then
		-- top left
        return regions.start
    elseif x >= half_width and y < half_height then
		-- top right
        return regions.island
    elseif x < half_width and y >= half_height then
		-- bottom left
        return regions.ice
    else
		-- bottom right
        return regions.junk
    end
end

function sample(l)
	return l[flr(rnd(#l)+1)]
end

function draw_hitbox(obj)
	if debug_hitbox then
		rect(
			obj.x + obj.hitbox.x, obj.y + obj.hitbox.y, 
			obj.x + obj.hitbox.x + obj.hitbox.w, obj.y + obj.hitbox.y + obj.hitbox.h,
			11
		)
	end
end

function gauss_rng()
    local sum = 0
    for i=1,12 do
        sum = sum + rnd(1)
    end
    return sum - 6
end

function magnitude(x, y)
	return sqrt(x^2+y^2)
end

-- OBJECT CREATION

function create_trader()
	local t = {
		x = 0,
		y = 16*8,
		hitbox = {x = 0, y = 0, w = 16, h = 12},

		draw = function(self)
			spr(9, self.x, self.y, 2, 2)

			palt(0, false)
			palt(11, true)

			spr(56, self.x + 2, self.y + 1)

			palt(0, true)
			palt(11, false)

			draw_hitbox(self)
		end
	}

	add(objects, t)

	return t
end

function create_octopus()
	local x = 113*8
	local y = 45 * 8
	local o = {
		x = x,
		y = y,
		k = 66,
		t_col = 12,
		dim = 2,
		hitbox = {x = 0, y = 0, w = 16, h = 16},

		enter_zone = {
			x = x - 8,
			y = y - 4,
			hitbox = {x=0, y=0, w=32, h=30}
		},

		update = {

		},
		
		draw = function(self)
			palt(0, false)	
			palt(self.t_col, true)
			spr(self.k, self.x, self.y, self.dim, self.dim)
			palt(0, true)	
			palt(self.t_col, false)

			draw_hitbox(self.enter_zone)
		end
	}

	add(objects, o)

	return o
end

function create_seal()
	local x = 37*8
	local y = 57 * 8
	local o = {
		x = x,
		y = y,
		k = 98,
		t_col = 12,
		dim = 2,
		hitbox = {x = 0, y = 0, w = 16, h = 16},

		enter_zone = {
			x = x - 8,
			y = y - 4,
			hitbox = {x=0, y=0, w=32, h=30}
		},

		update = {

		},
		
		draw = function(self)
			palt(0, false)	
			palt(self.t_col, true)
			spr(self.k, self.x, self.y, self.dim, self.dim)
			palt(0, true)	
			palt(self.t_col, false)

			draw_hitbox(self.enter_zone)
		end
	}

	add(objects, o)

	return o
end

function create_crabs()
	local x = 122*8
	local y = 2 * 8
	local crabs = {
		{x=122*8 + 1, y=2*8},
		{x=122*8 + 3, y=3*8},
		{x=122*8 + 2, y=4*8},
		{x=126*8 + 2, y=2*8 + 1},
		{x=124*8 + 2, y=6*8},
		{x=125*8 + 2, y=8*8},
	}

	local o = {
		x = x,
		y = y,
		t_col = 0,
		dim = 1,
		hitbox = {x = 0, y = 0, w = 16, h = 16},

		enter_zone = {
			x = x - 8,
			y = y,
			hitbox = {x=0, y=0, w=16, h=30}
		},

		update = {

		},
		
		draw = function(self)
			for c in all(crabs) do
				palt(self.t_col, true)
				spr(k_crabs[1], c.x, c.y, self.dim, self.dim)
				palt(self.t_col, false)
			end

			draw_hitbox(self.enter_zone)
		end
	}

	add(objects, o)

	return o
end

function create_boat_particles(spd)
	local x, y
	local vx, vy
	if player.cast_dir.x == 1 then
		x = player.x	
		y = player.y + player.hitbox.y + rnd(player.hitbox.h)
		vx = -.3 * rnd()
		vy = .2 * gauss_rng()
	elseif player.cast_dir.x == -1 then
		x = player.x + player.hitbox.x + player.hitbox.w
		y = player.y + player.hitbox.y + rnd(player.hitbox.h)
		vx = .3 * rnd()
		vy = .2 * gauss_rng()
	elseif player.cast_dir.y == 1 then
		x = player.x + player.hitbox.x + rnd(player.hitbox.w)
		y = player.y
		vx = .2 * gauss_rng()
		vy = -.3 * rnd()
	elseif player.cast_dir.y == -1 then
		x = player.x + player.hitbox.x + rnd(player.hitbox.w)
		y = player.y + player.hitbox.y + player.hitbox.h
		vx = .2 * gauss_rng()
		vy = .3 * rnd()
	end

	for i=1,5 do
		local particle = {
			x = x,
			y = y,
			vx = vx,
			vy = vy,
			lifetime = 1.5*30 + 10 * gauss_rng(),
			t = 0, -- time alive

			update = function(self)
				self.t += 1

				if self.t >= self.lifetime then
					del(boat_particles, self)
					return
				end

				if self.x ~= 0 then
					self.x += self.vx
					self.y += self.vy * cos(self.t)
				elseif self.y ~= 0 then
					self.x += self.vx * cos(self.t)
					self.y += self.vy
				end
			end,

			draw = function(self)
				pset(self.x, self.y, 6)
			end
		}
		
		add(boat_particles, particle)
	end
end

function create_waves()
	for i=1,n_waves do
		local x = cam.x + flr(rnd(128))
		local y = cam.y + flr(rnd(128))
		local r = get_region(x, y)

		local t_col = 12
		k = rnd() > .5 and 17 or 18

		if (r == regions.ice) then
			k = rnd() > .5 and 51 or 52
			t_col = 1
		end

		local wave = {
			x = x,
			y = y,
			k = k,
			region = r,
			lifetime = rnd(30 * 2), -- sec @ 30fps
			t = 0, -- time alive

			update = function(self)
				self.t += 1

				-- remove waves that are outside the camera view
				if (self.t >= self.lifetime or 
				    self.x < cam.x or 
				    self.x > cam.x + 128 or 
				    self.y < cam.y or 
				    self.y > cam.y + 128) then
					del(waves, self)
				end
			end,

			draw = function(self)
				palt(t_col, true)
				spr(self.k, self.x, self.y)
				palt(t_col, false)
			end,
		}	
		add(waves, wave)
	end
end

function create_splash(x, y)
	local wait_frames = 30 * 2.5
	local dr = .4
	local r_max = 6

	local splash = {
		x = x,
		y = y,
		r = 0,
		wait_time = 0,

		update = function(self)
			if (self.r == r_max) then 
				self.r = 0
				self.wait_time = wait_frames
			elseif self.wait_time > 0 then
				self.wait_time -= 1
			else
				self.r = min(self.r + dr, r_max)
			end
		end,

		draw = function(self)
			if self.wait_time == 0 then
				circ(self.x, self.y, self.r, 7)
			end
		end,
	}

	return splash
end

function create_fishing_spot(x, y, is_junk, is_legendary)
	local spot = {
		x = x,
		y = y,
		region = get_region(x, y),
		hitbox = {x=-8, y=-8, w=16, h=16},
		t = rnd(30 * 20), -- time remaining
		time_to_bite = 0, -- time until bite
		is_legendary = is_legendary,
		is_junk = is_junk, -- is this a junk spot
		bite = false,
		bite_start = nil, -- when the bite started
		bubbles = {},
		to_delete = false,
		hook = nil,

		set_hook = function(self, hook)
			self.bite = false
			if (hook ~= nil) self.hook = hook
			self.time_to_bite = mid(1*30, rnd(time_to_bite_max), self.t)
		end,

		check_catch = function(self)
			if (not self.bite) return

			local dt = time() - self.bite_start

			local catch

			-- check legendary catch (super rod only)
			if self.is_legendary then
				if dt < .34 and player.backpack.items.super_rod.quantity > 0 then
					self.to_delete = true
					catch = fish.gold_anchovy
				else
					-- missed
					self.hook:missed()
				end

			elseif self.is_junk then
				-- check junk catch
				if 	dt < .68 then
					catch = sample(self.region.junk)
				else
					self.hook:missed()
				end

				self.to_delete = true

			-- check fish catch
			else
				if dt < .34 then
					-- extra roll for rare
					if rnd() > .68 then
						-- rare
						catch = sample(self.region.fish.rare)
					else
						-- common
						catch = sample(self.region.fish.common)
					end
				elseif dt < .68 then
					-- common
					catch = sample(self.region.fish.common)
				else
					-- missed
					self.hook:missed()
				end
			end

			return catch
		end,

		update = function(self)
			if self.to_delete then
				del(fishing_spots, self)
				return 
			end

			self.t -= 1

			-- always update bubbles
			for bubble in all(self.bubbles) do
				bubble:update()
			end

			-- remove spots that are outside the camera view
			if not self.is_legendary and (self.t <= 0 or 
				self.x < cam.x or 
				self.x > cam.x + 128 or 
				self.y < cam.y or 
				self.y > cam.y + 128) then
				self.to_delete = true
				return
			end

			-- time to bite
			if self.hook ~= nil and not self.bite then
				if self.time_to_bite > 0 then
					self.time_to_bite -= 1
				elseif not (self.bite or self.hook.caught ~= nil) then
					sfx(3)
					self.bite = true
					self.bite_start = time()
				end
			-- time since bite
			elseif self.bite then
				local dt = time() - self.bite_start
				-- debug = "dt: " .. dt

				if dt >= 0.68 then
					self.hook:missed()

					if (not self.is_legendary) self.to_delete = true
				end
			end
		end,

		draw = function(self)
			for bubble in all(self.bubbles) do
				bubble:draw()
			end

			draw_hitbox(self)
		end
	}

	-- don't make bubbles if fishing for junk
	if (is_junk) return spot

	local n_bubbles = max(3, flr(rnd(6)))

	for i=1,n_bubbles do
		local bubble = {
			x = spot.x + 2 * gauss_rng(),
			y = spot.y + 2 * gauss_rng(),
			region = spot.region,
			r_max = max(2, 2.7 * gauss_rng()),
			dr = .1,
			r = 0,

			update = function(self)
				local nr = self.r + self.dr

				if nr >= self.r_max then
					self.r = 0
					self.r_max = max(2, 2.7 * gauss_rng())
				else
					self.r = nr
				end
			end,

			draw = function(self)
				local col
				if spot.is_legendary then
					col = 10
				elseif self.regions == regions.start then
					col = 1	
				elseif self.region == regions.ice then
					col = 6
				end

				circ(self.x, self.y, self.r, col)
			end
		}
		add(spot.bubbles, bubble)
	end

	add(fishing_spots, spot)
end

function create_fishing_spots()
	for i=1,n_fishing_spots do
		local x = cam.x + flr(rnd(128))
		local y = cam.y + flr(rnd(128))
		create_fishing_spot(x, y)	
	end
end

function create_hook(start, dir)
	-- debug = "x: " .. dir.x .. ", y: " .. dir.y

	-- basic offsets for cast
	local xo = 0
	local yo = 0
	if (dir.x ~= 0) yo = 1
	if (dir.x == -1) xo = xo - 1
	if (dir.y == -1) yo = yo - 1
	xo = dir.y * -1

	local hook = {
		start = start,
		x = start.x + xo,
		y = start.y + yo,		
		hitbox = {x=0, y=0, w=2, h=3},
		dir = dir,
		z = 15,
		k = k_hook,
		splash = nil,
		spot = nil,
		caught = nil,

		missed = function(self)
			if (self.spot == nil) return
			missed += 1
			self.spot = nil
		end,

		retrieve = function(self)
			if self.spot and self.spot.bite then
				local f = self.spot:check_catch()

				self.caught = f
			end

			self.spot = nil
		end,

		update = function(self)
			local z = self.z - g

			if z >= 0 then
				-- apply physics

				self.z = z
				self.x += 1.5 * self.dir.x
				self.y += 1.5 * self.dir.y

				-- apply user control for rod

				local dx = 0
				local dy = 0

				if (btn(k_left)) dx = -1
				if (btn(k_right)) dx = 1
				if (btn(k_down)) dy = 1
				if (btn(k_up)) dy = -1

				if (self.dir.x ~= dx) self.x += dx
				if (self.dir.y ~= dy) self.y += dy
			else
				if self.splash == nil then
					sfx(6)	
					self.splash = create_splash(self.x, self.y)
				else
					self.splash:update()
				end

				if self.spot == nil then
					-- check if within a fishing spot
					local spot_found
					for spot in all(fishing_spots) do
						if self:collide(spot, 0, 0) then
							spot_found = spot
						end
					end

					if spot_found == nil then
						-- fish for junk
						local spot = create_fishing_spot(self.x, self.y, true)
						add(fishing_spots, spot)
						self.spot = spot
						self.spot:set_hook(self)
					else
						self.spot = spot_found
						self.spot:set_hook(self)
					end
				end
			end
		end,

		draw = function(self)
			-- draw fishing line
			local y = self.y
			if self.z > 0 then
				y = y - self.z / 2
			end
	
			if self.splash == nil then
				-- draw shadow
				spr(27, self.x - 3, self.y)
			else
				self.splash:draw()
			end

			line(self.start.x, self.start.y, self.x, y, 10)

			-- draw hook
			spr(self.k, self.x, y, 1, 1)

			-- draw hitbox (debug)
			draw_hitbox(self)
		end,

        collide = function(self, other, dx, dy)
			return collide(self, other, dx, dy)
        end,
	}

	return hook
end

function create_backpack()
	local held_junk = {}
	local held_fish = {}
	local held_items = {}

	for k, v in pairs(junk) do
		held_junk[k] = { quantity = 0 }
	end

	for k, v in pairs(fish) do
		held_fish[k] = { quantity = 0 }
	end

	for k, v in pairs(items) do
		held_items[k] = { quantity = 0 }
	end

	local backpack = {
		junk = held_junk,
		fish = held_fish,
		items = held_items,

		add = function(self, i, qty)
			if (i.type == item_types.junk) then 
				self:add_junk(i.name, qty)
			elseif (i.type == item_types.item) then
				self:add_item(i.name, qty)
			else
				self:add_fish(i.name, qty)
			end
		end,

		rm = function(self, i, qty)
			if (i.type == item_types.junk) then 
				self:rm_junk(i.name, qty)
			elseif (i.type == item_types.item) then
				self:rm_item(i.name, qty)
			else
				self:rm_fish(i.name, qty)
			end
		end,

		add_junk = function(self, j, qty)
			if self.junk[j] then
				self.junk[j].quantity = self.junk[j].quantity + qty
			end
		end,

		rm_junk = function(self, j, qty)
			if self.junk[j] and self.junk[j].quantity - qty >= 0 then
				self.junk[j].quantity = self.junk[j].quantity - qty
			end
		end,

		add_fish = function(self, f, qty)
			if self.fish[f] then
				self.fish[f].quantity = self.fish[f].quantity + qty
			end
		end,

		rm_fish = function(self, f, qty)
			if self.fish[f] and self.fish[f].quantity - qty >= 0 then
				self.fish[f].quantity = self.fish[f].quantity - qty
			end
		end,

		add_item = function(self, i, qty)
			if self.items[i] then
				self.items[i].quantity = self.items[i].quantity + qty
			end
		end,

		rm_item = function(self, i, qty)
			if self.items[i] and self.items[i].quantity - qty >= 0 then
				self.items[i].quantity = self.items[i].quantity - qty
			end
		end,
	}

    return backpack
end

function create_player(x, y)
	return {
		x = x, -- raft x
		y = y, -- raft y
		spd = {x=0, y=0}, -- raft speed
		acc = {x=0, y=0}, -- raft acceleration
		dir = {x=0, y=0}, -- movement dir
		cast_dir = {x=0, y=1}, -- casting dir (L/R/U/D)
        hitbox = {x=0, y=0, w=12, h=16}, -- raft hitbox
		rod_start = {x=0, y=0},
		rod_end = {x=0, y=0},
		k_player = 4,
		k_raft = 7,
		flip = {x=false, y=true}, -- initially facing down
		max_spd = 1,
		hook = nil,
		casting = false,
		backpack = create_backpack(),
		info_timer = 0,
		info_caught = nil,

		get_spr_location = function(self)
			local px = self.x + self.hitbox.w / 2 - 4
			local py = self.y + self.hitbox.h / 2 - 4

			return {x=px, y=py}
		end,

		update_hitbox = function(self)
			if self.k_raft == 9 then
				self.hitbox = {x=0, y=0, w=16, h=12}
			else
				self.hitbox = {x=0, y=0, w=12, h=16}
			end
		end,

		move = function(self, dx, dy)
			for obj in all(objects) do
				if self:collide(obj, dx, dy) then
					dx = 0
					dy = 0
				end
			end

			self.x += dx
			self.y += dy
		end,
		
		cast = function(self)
			self.casting = true

			local rod_length = 8

			local p = self:get_spr_location()
			local rod_start, rod_end

			-- right
			if self.cast_dir.x == 1 and self.cast_dir.y == 0 then
				rod_start = {x = p.x + 4, y = p.y + 3}
				rod_end = {x = rod_start.x + 3, y = p.y - 4}
			--left 
			elseif self.cast_dir.x == -1 and self.cast_dir.y == 0 then
				rod_start = {x = p.x + 2, y = p.y + 3}
				rod_end = {x = rod_start.x - 3, y = p.y - 4}
			-- up
			elseif self.cast_dir.x == 0 and self.cast_dir.y == -1 then
				rod_start = {x = p.x + 1, y = p.y + 3}
				rod_end = {x = rod_start.x, y = rod_start.y - rod_length}
			-- down
			elseif self.cast_dir.x == 0 and self.cast_dir.y == 1 then
				rod_start = {x = p.x + 6, y = p.y + 5}
				rod_end = {x = rod_start.x, y = rod_start.y + rod_length}
			end

			self.rod_start = rod_start
			self.rod_end = rod_end

			self.hook = create_hook(self.rod_end, self.cast_dir)

			sfx(5)
		end,

		set_info_timer = function(self)
			self.info_caught = self.hook.caught
			self.info_timer = 2 * 30 -- 2.5s @ 30fps
		end,

		retrieve = function(self)
			self.hook:retrieve()
			-- check fishing
			if self.hook.caught then
				self:set_info_timer()
				self.backpack:add(self.hook.caught, 1)
				self.hook.caught = nil
				sfx(4)
			end

			self.casting = false
			self.hook = nil
		end,

		update = function(self)
			if self.casting and self.hook ~= nil then			
				self.hook:update()
				self.spd = {x=0, y=0}
				return 
			end

			self:update_hitbox()

			if not (btn(k_left) or btn(k_right)) then
				self.spd.x = self.spd.x * .85
			end

			if not (btn(k_up) or btn(k_down)) then
				self.spd.y = self.spd.y * .85
			end

			if btn(k_left) then
				self.spd.x = .7
				self.dir.x = -1
				self.cast_dir = {x=-1, y=0}
				self.k_raft = 9
				self.k_player = 6
				self.flip = {x=true, y=false}
			end

			if btn(k_right) then
				self.spd.x = .7
				self.dir.x = 1
				self.cast_dir = {x=1, y=0}
				self.k_raft = 9
				self.k_player = 6
				self.flip = {x = false, y = false}
			end

			if btn(k_up) then
				self.spd.y = .7
				self.dir.y = -1
				self.cast_dir = {x=0, y=-1}
				self.k_raft = 7
				self.k_player = 5
				self.flip = {x = false, y = false}
			end

			if btn(k_down) then
				self.spd.y = .7
				self.dir.y = 1
				self.cast_dir = {x=0, y=1}
				self.k_raft = 7
				self.k_player = 4
				self.flip = {x = false, y = true}
			end

			-- debug = "x: " .. self.dir.x .. ", y: " .. self.dir.y

			player:move(self.dir.x * self.spd.x, self.dir.y * self.spd.y)

			if self.info_timer > 0 then
				self.info_timer -= 1
			end
		end,

        draw = function(self)
			palt(0, true)

			-- draw raft
            spr(self.k_raft, self.x, self.y, 2, 2, self.flip.x, self.flip.y)

			if self.casting then
				-- draw hook
				self.hook:draw()

				-- draw rod
				line(self.rod_start.x, self.rod_start.y, self.rod_end.x, self.rod_end.y, 2)
			end

			palt(0, false)
			palt(11, true)

			-- draw player
			local p = self:get_spr_location()
            spr(self.k_player, p.x, p.y, 1, 1, self.flip.x, false)

			palt(0, true)
			palt(11, false)

			-- draw fishing bite alert
			if self.hook ~= nil and self.hook.spot ~= nil and self.hook.spot.bite then
				spr(k_alert, p.x + 2, p.y - 6)
			-- draw fish/junk caught
			elseif self.info_caught ~= nil and self.info_timer > 0 then
				-- fish are 2x2
				draw_fish(self.info_caught, p.x + 2, p.y - 6)
			end

			-- draw hitbox (debug)
			draw_hitbox(self)
        end,

        collide = function(self, other, dx, dy)
			return collide(self, other, dx, dy)
        end,
	}
end

function create_obs(x, y, k)
    return {
        x = x,
        y = y,
        k = k,
        hitbox = {x=0, y=0, w=8, h=8},
        move = function(self, dx, dy)
            self.x += dx
            self.y += dy
        end,
        draw = function(self)
            spr(self.k, self.x, self.y)

			-- draw hitbox (debug)
			draw_hitbox(self)
        end
    }
end

function create_rock(x, y, k)
    local rock = create_obs(x, y, k)
    rock.hitbox = {x=1, y=3, w=7, h=5}

    return rock
end

function create_ice_block(x, y)
    local r = create_obs(x, y, k_ice_block)
    r.hitbox = {x=0, y=3, w=7, h=4}

    return r
end

function create_land(x, y, k)
    local r = create_obs(x, y, k)
    r.hitbox = {x=0, y=0, w=8, h=8}

    return r
end

function create_land_corner(x, y, k)
    local r = create_obs(x, y, k)

	if k == 116 then
		r.hitbox = {x=0, y=2, w=4, h=6}
	elseif k == 117 then
		r.hitbox = {x=3, y=0, w=4, h=6}
	elseif k == 118 then
		r.hitbox = {x=2, y=3, w=4, h=6}
	elseif k == 102 then
		r.hitbox = {x=0, y=0, w=5, h=6}
	end

    return r
end

function create_map_bounds()
	local top = {
		x = 0,
		y = -8,
		hitbox = {x=0, y=0, w=128*8, h=8},

		draw = function(self)
			draw_hitbox(self)
		end
	}
	local right = {
		x = 128*8 - 1,
		y = 0,
		hitbox = {x=0, y=0, w=8, h=64*8},

		draw = function(self)
			draw_hitbox(self)
		end
	}
	local bottom = {
		x = 0,
		y = 64*8-1,
		hitbox = {x=0, y=0, w=128*8, h=8},

		draw = function(self)
			draw_hitbox(self)
		end
	}
	local left = {
		x = -8,
		y = 0,
		hitbox = {x=0, y=0, w=8, h=64*8},

		draw = function(self)
			draw_hitbox(self)
		end
	}

	add(objects, top)
	add(objects, right)
	add(objects, bottom)
	add(objects, left)
end

-- MENUS

function create_octopus_ui()
	return create_trade_ui(items.bamboo)
end

function create_crabs_ui()
	return create_trade_ui(items.coin)
end

function create_seal_ui()
	return create_trade_ui(items.cassette)
end

function create_trade_ui(trade_item, qty)
	local w = 14 * 8
	local h = 15 * 8
	local bg = {2*8, 2*8, w, h}
	local bp = {bg[1] + 4, bg[2] + 4, bg[3] - 4, bg[4] - 4}
	local ilist = {bp[1] + 2, bp[2] + 8, bp[3] - 2, bp[4] - 2}

	local t = {
		x = 0,
		y = 16 * 8,
		w = w,
		h = h,
		bg = bg, -- background rect
		bp = bp, -- backpack overlay rect
		ilist = ilist, -- item list rect

		selected = 1,
		item = trade_item,
		qty = qty or 1,

		on_left = function(self)
			if (self.selected == 2) self.selected = 1	
		end,

		on_right = function(self)
			if (self.selected == 1) self.selected = 2
		end,

		on_up = function(self)

		end,

		on_down = function(self)

		end,

		on_O = function(self)
			if self.selected == 1 and self.qty > 0 then
				self:trade()
				self.qty -= 1
			else
				-- exit
				menu_state = nil
			end
		end,

		update = function(self)
		end,

		tradeable = function(self)
			if (not self.item) return
			if (self.qty == 0) return

			for name, qty in pairs(self.item.junk) do
				local p_qty = player.backpack.junk[name].quantity
				if (p_qty < qty) return false
			end

			for name, qty in pairs(self.item.fish) do
				local f_qty = player.backpack.fish[name].quantity
				if (f_qty < qty) return false
			end

			for name, qty in pairs(self.item.items) do
				local i_qty = player.backpack.items[name].quantity
				if (i_qty < qty) return false
			end
		
			return true
		end,

		trade = function(self)
			if (not self:tradeable()) return

			for name, qty in pairs(self.item.junk) do
				local j = junk[name]
				player.backpack:rm(j, qty)
			end

			for name, qty in pairs(self.item.fish) do
				local f = fish[name]
				player.backpack:rm(f, qty)
			end

			for name, qty in pairs(self.item.items) do
				local i = items[name]
				player.backpack:rm(i, qty)
			end

			player.backpack:add(self.item, 1)
		end,

		draw = function(self)
			-- draw base ui
			local bg = self.bg
			local bp = self.bp
			local ilist = self.ilist

			-- background
			rectfill(bg[1], bg[2], bg[3], bg[4], 5)

			-- backpack overlay
			rectfill(bp[1], bp[2], bp[3], bp[4], 15)
			
			-- title
			local title = "trade"
			print(title, bp[1] + 2, bp[2] + 2, 0)

			local r = self.ilist
			rectfill(r[1], r[2], r[3], r[4], 6)
			rect(r[1], r[2], r[3], r[4], 3)

			
			local x_mid = flr(r[1] + (r[3]-r[1])/2)
			local cx = r[1] + 4
			local cy = r[2] + 4

			local name = self.item.disp_name or self.item.name
			local p_qty = player.backpack.items[self.item.name].quantity
			draw_item(self.item, cx, cy)
			print(name .. " X " .. self.qty, cx + 20, cy + 2, 0)

			if (self.qty == 0) return

			cy += 12

			palt(0, true)
			spr(57, x_mid - 4, cy, 1, 1, false, true)
			palt(0, false)

			cy += 12

			for name, qty in pairs(self.item.junk) do
				local p_qty = player.backpack.junk[name].quantity
				local j = junk[name]
				draw_junk(j, cx, cy)
				print(j.name .. " X " .. p_qty .. "/" .. qty, cx + 20, cy + 2, 0)
				cy += 14
			end

			for name, qty in pairs(self.item.fish) do
				local p_qty = player.backpack.fish[name].quantity
				local f = fish[name]
				draw_fish(f, cx, cy)
				print(f.name .. " X " .. p_qty .. "/" .. qty, cx + 20, cy + 4, 0)
				cy += 18
			end

			for name, qty in pairs(self.item.items) do
				local p_qty = player.backpack.items[name].quantity
				local i = items[name]
				draw_item(i, cx, cy)
				print(i.name .. " X " .. p_qty .. "/" .. qty, cx + 20, cy + 4, 0)
				cy += 18
			end

			local tradeable = self:tradeable()

			local c = "trade"
			local e = "exit"

			if (tradeable) print(c, x_mid - 3*#c - 6, r[4] - 6, 3)
			print(e, x_mid + 3*#e, r[4] - 6, 5)

			palt(0, true)
			if (self.selected == 1) and tradeable then
				spr(59, x_mid - 4*#c - 6, r[4] - 8)
			else
				spr(59, x_mid + 4*#e - 9, r[4] - 8)
			end
			palt(0, false)
		end
	}

	return t
end

function create_craft_ui()
	local w = 14 * 8
	local h = 15 * 8
	local bg = {2*8, 2*8, w, h}
	local bp = {bg[1] + 4, bg[2] + 4, bg[3] - 4, bg[4] - 4}
	local ilist = {bp[1] + 2, bp[2] + 8, bp[3] - 2, bp[4] - 2}

	local craft = {
		x = 0,
		y = 16 * 8,
		w = w,
		h = h,
		bg = bg, -- background rect
		bp = bp, -- backpack overlay rect
		ilist = ilist, -- item list rect
		hitbox = {x = 0, y = -4, w = 20, h = 20},

		selected = 1,
		items = {
			items.sm_box,
			items.lg_box,
			items.music_box,
			items.boombox,
			items.super_rod
		},
		submenu = {
			selected = 1,
			ilist = ilist,
			item = nil,

			set_item = function(self, item)
				self.item = item
			end,

			on_left = function(self)
				if (self.selected == 2) self.selected = 1	
			end,

			on_right = function(self)
				if (self.selected == 1) self.selected = 2
			end,

			on_up = function(self)

			end,

			on_down = function(self)

			end,

			on_O = function(self)
				if self.selected == 1 then
					self:craft()
				else
					-- exit
					menu_state = "trader"
				end
			end,

			update = function(self)
			end,

			craftable = function(self)
				if (not self.item) return

				for name, qty in pairs(self.item.junk) do
					local p_qty = player.backpack.junk[name].quantity
					if (p_qty < qty) return false
				end

				for name, qty in pairs(self.item.fish) do
					local f_qty = player.backpack.fish[name].quantity
					if (f_qty < qty) return false
				end

				for name, qty in pairs(self.item.items) do
					local i_qty = player.backpack.items[name].quantity
					if (i_qty < qty) return false
				end
			
				return true
			end,

			craft = function(self)
				if (not self:craftable()) return

				for name, qty in pairs(self.item.junk) do
					local j = junk[name]
					player.backpack:rm(j, qty)
				end

				for name, qty in pairs(self.item.fish) do
					local f = fish[name]
					player.backpack:rm(f, qty)
				end

				for name, qty in pairs(self.item.items) do
					local i = items[name]
					player.backpack:rm(i, qty)
				end

				player.backpack:add(self.item, 1)
			end,

			draw = function(self)
				-- draw base ui
				trader_ui:draw()

				local r = self.ilist
				rectfill(r[1], r[2], r[3], r[4], 6)
				rect(r[1], r[2], r[3], r[4], 3)

				local x_mid = flr(r[1] + (r[3]-r[1])/2)
				local cx = r[1] + 4
				local cy = r[2] + 4

				local name = self.item.disp_name or self.item.name
				local p_qty = player.backpack.items[self.item.name].quantity
				draw_item(self.item, cx, cy-2)
				print(name .. " X " .. 1, cx + 20, cy + 2, 0)

				cy += 12

				palt(0, true)
				spr(57, x_mid - 4, cy, 1, 1, false, true)
				palt(0, false)

				cy += 12

				for name, qty in pairs(self.item.junk) do
					local p_qty = player.backpack.junk[name].quantity
					local j = junk[name]
					draw_junk(j, cx, cy)
					print((j.disp_name or j.name) .. " X " .. p_qty .. "/" .. qty, cx + 22, cy + 2, 0)
					cy += 14
				end

				for name, qty in pairs(self.item.fish) do
					local p_qty = player.backpack.fish[name].quantity
					local f = fish[name]
					draw_fish(f, cx, cy)
					print((f.disp_name or f.name) .. " X " .. p_qty .. "/" .. qty, cx + 22, cy + 4, 0)
					cy += 16
				end

				for name, qty in pairs(self.item.items) do
					local p_qty = player.backpack.items[name].quantity
					local i = items[name]
					draw_item(i, cx, cy)
					print((i.disp_name or i.name) .. " X " .. p_qty .. "/" .. qty, cx + 22, cy + 4, 0)
					cy += 18
				end

				local craftable = self:craftable()

				local c = "craft"
				local e = "exit"

				if (craftable) print(c, x_mid - 3*#c - 6, r[4] - 6, 3)
				print(e, x_mid + 3*#e, r[4] - 6, 5)

				palt(0, true)
				if (self.selected == 1) and craftable then
					spr(59, x_mid - 4*#c - 6, r[4] - 8)
				else
					spr(59, x_mid + 4*#e - 9, r[4] - 8)
				end
				palt(0, false)
			end
		},

		on_O = function(self)
			self.submenu:set_item(self.item)
			menu_state = "trader_submenu"
		end,

		on_left = function(self)

		end,

		on_right = function(self)

		end,

		on_up = function(self)
			if self.selected > 1 then
				self.selected -= 1
			end
		end,

		on_down = function(self)
			if self.selected < #self.items then
				self.selected += 1
			end
		end,

		update = function(self)
			self.item = self.items[self.selected]
		end,

		draw = function(self)
			local bg = self.bg
			local bp = self.bp
			local ilist = self.ilist

			-- background
			rectfill(bg[1], bg[2], bg[3], bg[4], 5)

			-- backpack overlay
			rectfill(bp[1], bp[2], bp[3], bp[4], 15)
			
			-- title
			local title = "craft"
			print(title, bp[1] + 2, bp[2] + 2, 0)

			-- draw items
			rect(ilist[1], ilist[2], ilist[3], ilist[4], 3)

			local cx_init = ilist[1] + 3
			local cy_init = ilist[2] + 3
			local cx = cx_init
			local cy = cy_init

			local i = 1
			for item in all(self.items) do

				if i == self.selected then
					palt(0, true)
					spr(59, cx, cy + 3)
					palt(0, false)
				end

				draw_item(item, cx + 4, cy)

				print((item.disp_name or item.name), cx + 22, cy + 4, 0)

				cy += 16
				i += 1
			end
		end
	}	

	return craft
end

function create_backpack_ui()
	local w = 14 * 8
	local h = 15 * 8
	local bg = {2*8, 2*8, w, h}
	local bp = {bg[1] + 4, bg[2] + 4, bg[3] - 4, bg[4] - 4}
	local ilist = {bp[1] + 2, bp[2] + 8, bp[3] - 2, bp[4] - 2}

	backpack_ui = {
		w = w,
		h = h,
		bg = bg, -- background rect
		bp = bp, -- backpack overlay rect
		ilist = ilist, -- item list rect
		curr_page = 1,
		pages = {},

		on_O = function(self)

		end,

		on_left = function(self)
			if (self.curr_page > 1) self.curr_page -= 1
		end,

		on_right = function(self)
			if (self.curr_page < #self.pages) self.curr_page += 1
		end,

		on_up = function(self)

		end,

		on_down = function(self)

		end,

		update = function(self)
			local pages = {}			

			local n_items = 0
			local page = {}

			local bp = {player.backpack.fish, player.backpack.junk, player.backpack.items}
			local types = {fish, junk, items}
			local i = 1

			for bp_i in all(bp) do
				for name, info in pairs(bp_i) do
					local item = types[i][name]
					local qty = info.quantity

					if qty > 0 then
						if n_items == 4 then
							n_items = 0
							add(pages, page)
							page = {}
						end

						add(page, {item, qty})
						n_items += 1
					end
				end
				i += 1
			end

			if #page > 0 then
				add(pages, page)				
			end

			self.pages = pages
		end,

		-- draw based on camera view
		draw = function(self)
			local bg = self.bg
			local bp = self.bp
			local ilist = self.ilist

			-- background
			rectfill(bg[1], bg[2], bg[3], bg[4], 4)

			-- backpack overlay
			rectfill(bp[1], bp[2], bp[3], bp[4], 15)
			
			-- title
			local title = "backpack"
			print(title, bp[1] + 2, bp[2] + 2, 0)

			-- draw fish
			rect(ilist[1], ilist[2], ilist[3], ilist[4], 3)

			local cx_init = ilist[1] + 2
			local cy_init = ilist[2] + 2
			local cx = cx_init
			local cy = cy_init

			local page = self.pages[self.curr_page]

			for res in all(page) do
				local item = res[1]
				local qty = res[2]

				if (item.type == item_types.fish) then
					print((item.disp_name or item.name) .. " X " .. qty, cx + 20, cy + 4, 0)
					draw_fish(item, cx, cy)
					cy += 20
				elseif item.type == item_types.item then
					print((item.disp_name or item.name) .. " X " .. qty, cx + 18, cy + 4, 0)
					draw_item(item, cx, cy)
					cy += 18
				elseif item.type == item_types.junk then
					print((item.disp_name or item.name) .. " X " .. qty, cx + 18, cy + 2, 0)
					draw_junk(item, cx, cy)
					cy += 16
				end
			end

			local w = ilist[3] - ilist[1]

			-- left/right page buttons
			self.page_l = {
				x=ilist[1] + flr(w/2) - 24,
				y = ilist[4] - 8,
				enabled=self.curr_page > 1
			}
			self.page_r = {
				x=ilist[1] + flr(w/2) + 16,
				y = ilist[4] - 8, 
				enabled=self.curr_page < #self.pages
			}
			self.page_l.k = self.page_l.enabled and 59 or 58
			self.page_r.k = self.page_r.enabled and 59 or 58

			palt(0, true)
			spr(self.page_l.k, self.page_l.x, self.page_l.y, 1, 1, true, false)
			spr(self.page_r.k, self.page_r.x, self.page_r.y)
			palt(0, false)

			-- page number
			local pn = (#self.pages > 0) and #self.pages or 1
			print("" .. self.curr_page .. " / " .. pn, self.page_l.x + 14, self.page_l.y + 1, 5)
		end,
	}

	return backpack_ui
end

-- GAME LOOP

function load_map()
    for x=1,128 do
        for y=1,64 do
            local tile = mget(x, y)
			local land_flag = fget(tile, 1)
			local land_flag_corner = fget(tile, 2)
            if contains(k_rocks, tile) then
                add(objects, create_rock(x*8, y*8, tile))
			elseif tile == k_ice_block then
				add(objects, create_ice_block(x*8, y*8))
			elseif land_flag then
				add(objects, create_land(x*8, y*8, tile))
			elseif land_flag_corner then
				add(objects, create_land_corner(x*8, y*8, tile))
			end
        end
    end

    -- debug=#objects
end

function _init()
	start_screen = create_start_screen()
	states:update_state(states.start)
	load_map()
	-- music(0)
end

function start_game()
	states:update_state(states.game)
	cam = {x=0, y=0}
	trader = create_trader()
	trader_ui = create_craft_ui()
	backpack_ui = create_backpack_ui()
	octopus = create_octopus()
	octopus_ui = create_octopus_ui()
	crabs = create_crabs()
	crabs_ui = create_crabs_ui()
	seal = create_seal()
	seal_ui = create_seal_ui()
	player = create_player(2*8, 2*8)
	-- player = create_player(54*8, 8*8)
	create_map_bounds()
	menu_state = nil
	menu_states = {
		trader = trader_ui,
		trader_submenu = trader_ui.submenu,
		octopus = octopus_ui,
		crabs = crabs_ui,
		seal = seal_ui,
		backpack = backpack_ui
	}

	-- for _, f in pairs(fish) do 
	-- 	player.backpack:add(f, 10) 
	-- end
	-- for _, j in pairs(junk) do 
	-- 	player.backpack:add(j, 10) 
	-- end
	-- for _, i in pairs(items) do
	-- 	player.backpack:add(i, 10)
	-- end

	-- add legendary fishing spots
	add(fishing_spots, create_fishing_spot(4*8, 62*8, false, true))
	add(fishing_spots, create_fishing_spot(54*8, 4*8, false, true))
end

function create_start_screen()
	local bubbles = {}

	for i=1,100 do
		local b = {
			x = rnd(128),
			y = 128+8,
			vy = .8 * gauss_rng(),
			r = 0,
			col = sample({12, 5, 13, 14, 10}),
			r_max = rnd(4),
			t = 0,
			dr = .05 * gauss_rng(),

			update = function(self)
				self.t += .01
				self.x += .35 * cos(3.2*self.t)
				self.y -= self.vy
				self.r = min(self.r + self.dr, self.r_max)

				if self.y < 0 then
					self.y = 128+8
					self.r = 0
					self.t = 0
				end
			end,

			draw = function(self)
				circ(self.x, self.y, self.r, self.col)
			end
		}
		add(bubbles, b)
	end

	local s = {
		update = function(self)
			for b in all(self.bubbles) do
				b:update()
			end
		end,

		draw = function(self)
			cls(1)

			for b in all(start_screen.bubbles) do
				b:draw()
			end

			print("nori", flr((128-3*4)/2), 5*8, 6)
				
			local msg = "start: ❎"
			print(debug, 10, 50)
			print(msg, (128-#msg*4)/2, 12*8, 6)
		end,

		bubbles = bubbles
	}

	return s
end

states = {
	state = nil,
	start = {
		_update = function()
			if (btnp(k_X)) then
				start_game()
			else
				start_screen:update()
			end
		end,
		_draw = function()
			start_screen:draw()	
		end
	},
	game = {
		_update = function()
			debug = ""

			local traders = {
				{trader_ui, "trader"}, 
				{octopus.enter_zone, "octopus"}, 
				{crabs.enter_zone, "crabs"}, 
				{seal.enter_zone, "seal"}
			}

			if not menu_state then
				if btnp(k_X) then 
					menu_state = "backpack"
					return
				elseif btnp(k_O) then
					for t in all(traders) do
						if player:collide(t[1], 0, 0) then
							menu_state = t[2]
							return
						end
					end
				end
			end

			if menu_state then
				menu_states[menu_state]:update()

				if btnp(k_O) then
					menu_states[menu_state]:on_O()
				elseif btnp(k_X) then
					if menu_state == "trader_submenu" then
						menu_state = "trader"
					else
						menu_state = nil
					end
				elseif btnp(k_up) then
					menu_states[menu_state]:on_up()
				elseif btnp(k_down) then
					menu_states[menu_state]:on_down()
				elseif btnp(k_left) then
					menu_states[menu_state]:on_left()
				elseif btnp(k_right) then
					menu_states[menu_state]:on_right()
				end

				return
			end

			-- debug = "" .. #boat_particles
			player:update()

			if btnp(k_O) then
				if player.casting then
					player:retrieve()
				else
					player:cast()
				end
			end

			-- update camera based on player loc
			cam = {
				x = mid(0, player.x - 64 + 6, 128*8-128),
				y = mid(0, player.y - 64 + 6, 64*8-128)
			}

			for wave in all(waves) do
				wave:update()
			end

			for spot in all(fishing_spots) do
				spot:update()
			end

			for part in all(boat_particles) do
				part:update()
			end

			if (#waves < n_waves_max) create_waves()
			if (#fishing_spots < n_fishing_spots) create_fishing_spots()
			local spd = magnitude(player.spd.x, player.spd.y)
			if (spd > 0) create_boat_particles(spd)
		end,
		_draw = function()
			cls()
			-- palt(0, true)
			camera(cam.x, cam.y)
			map()

			for wave in all(waves) do
				wave:draw()
			end

			-- draw boat particles
			for part in all(boat_particles) do
				part:draw()
			end

			for spot in all(fishing_spots) do
				spot:draw()
			end

			for obj in all(objects) do
				obj:draw()
			end

			player:draw()

			octopus:draw()

			camera(0, 0)
			if menu_state then
				menu_states[menu_state]:draw()
			end

			print(debug, 10, 10)

			camera(cam.x, cam.y)


			-- debug = "missed: " .. missed
			-- debug = "" .. get_region(player.x, player.y).id
			-- debug = "trader: " .. (trader.enabled and "yes" or "no")
			-- debug = "backpack: " .. (backpack_ui.enabled and "yes" or "no")
		end
	},
	update_state = function(self, s)
		self.state = s
		_update = s._update
		_draw = s._draw
	end
}


__gfx__
00000000ccccccccffffffff11111111bbbbbbbbbbbbbbbbbbbbbbbb445f445444540000f4444f44444ff44488000000bbbbbbbbbb1111bbccccccfcfcfccccc
00000000ccccccccffffffff11111111bb0000bbbb0000bbbb006bbb4f5f44544f540000ff4f444f4f4444f488000000bbbbbbbb11dc6dbbcccc9222222c7ccc
00700700ccccccccffffffff11111111bb6006bbbb0000bbbb0009bb4454f454f45f0000555555555555555577000000bbbbbbb11da06ddbcc9222949ff227cc
00077000ccccccccffffffff11111111bb0990bbbb0000bbbb000bbbf454f454f45f0000ff4444ff444444ff00000000bbbb1111dc6a6cdbc9224999949f72cc
00077000ccccccccffffffff11111111b000000bb000000bbb007bbbf454445444540000f444ff444f44ff4400000000bbb1cd1dc6666c1bcc299440999044cc
00700700ccccccccffffffff11111111bb0770bbbb0000bbbb007bbb4454445444540000ff4444444444444400000000bbbb1d1c667661bbc22494f99999f42c
00000000ccccccccffffffff11111111bb0770bbbb0000bbbb007bbb4f54f454f45f0000555555555555555500000000bbbbb1166776c1bb249994499009442c
00000000ccccccccffffffff11111111bb9779bbbb9009bbbb009bbb44544454f45f0000ff4444444444444400000000bbbbb1d677661bbbc24949994999972c
00000000cccccccccccccccccccccccc3cccc3cc55500000000000004f5f44544f540000f444ff44ff44ff4400000000bbbb1d677661bbbb249999999999472c
00000000cccccccccccccccccccccccccbccbccc5950000000000000445f44544f540000ff4444ff444444f400000000bbbb1c666c11bbbbc24994999949972c
00000000ccc6c6ccccccccccccc67cccc3ccc3cc5950000000000000f454f454f45f0000555555555555555500011000bbb1d67c11c1bbbb249999949999f72c
00000000cc6c6cccccccccccccd766ccccbcccbc59500000000000004454f454f4540000f4444f44ff44ff4400111100b11d6611bb1bbbbbc2294999994ff2cc
00000000cccccccccc6cc6cccc5d776cccc3c39c55500000000000004f5444544454000000000000000000000011110016cdd1bbbbbbbbbbcc22999999ff22cc
00000000ccccccccc6c66cccc575d67cccbc9ccc59500000000000004454445444540000000000000000000000011000b1dc1bbbbbbbbbbbccc229494ff22ccc
00000000ccccccccccccccccc555dd66ccc3cccc55500000000000004f5f4f5f4f540000000000000000000000000000bb161bbbbbbbbbbbcccc24242422cccc
00000000cccccccccccccccc55555dddccc9cccc0000000000000000ff5fff5fff5f0000000000000000000000000000bbb1bbbbbbbbbbbbccccc2c2c2cccccc
00000000000000000090090080900908ccccccccd500000045000000b3000000555555555555500005aa900055555555ccccccccc44dddccccccccc3333333cc
00000000000000008080080880800808cbcccccc6d500000f4500000fb30000054464445564650005aaaa9005d7777d5cccccccc44b66dccccccc3355555b03c
00000000000000008088880888888888cc3ccc3c06d500000f4500000fb3000054444645544450005aaaa900d1dccd1dcccccccc4a0b6dcccccc35564bbbbb33
0000000000000000088ee880008ee800cccbcccb006d500000f4500000fb3000564646455464500005aa90005deeeed5cccccc34bbabb3cccccc356b443333cc
00000000000000008088880808888880cc3ccc3c0006d500000f4500000fb30056464445555550000000000055555555cccc634bbbbbd3cccccc356b3ccccccc
00000000000000000800008080800808bc9c9bcc00006d500000f4500000fb3056464645000000000000000000000000cc63b64b3bbd3ccccccc3566b33ccccc
00000000000000000000000000000000c3c3cccc000006d500000f4500000fb356444445000000000000000000000000cc3634b3b36d3cccccccc3556bb3cccc
00000000000000000000000000000000ccc9cccc0000006d000000f4000000fb55555555000000000000000000000000ccc364b336d3cccccccccc3356bb3ccc
0000000011111111111111111111111111111111111311111111111111111111babbbbab009999000000000000000000cccc4bbb66d3ccccccccccc3356b3ccc
0000000011111111111111111111111111111111111111d11111171113111711bb1111bb009999005000000090000000cccc4bb66d3ccccccccc3335556b3ccc
000000001111111111167111111d1d11111111111d1111111511111111111111bb5116bb009999005500000099000000ccc4bb6dd3ccccccccc3555666bb3ccc
000000001767677111d7661111d1d11111111111111111111111e1111111e111bb1991bb999999995550000099900000cc46b6d33ccccccccc35666bbbb3cccc
0000000077667767115d77611111111111d11d11111111111111115111111111b111111b0999999055500000999000003dd3dd3b3ccccccccc35b333333ccccc
00000000767776771575d671111111111d1dd11111111d111111111111111111bb1771bb009999005500000099000000db3d3cc3cccccccc44353ccccccccccc
00000000c767677c1555dd66111111111111111111111111171111711711111ebb1771bb000990005000000090000000c3bdcccccccccccc45553ccccccccccc
000000001cccccc155555ddd1111111111111111131111111111111111111111bb9779bb000000000000000000000000ccd3cccccccccccc4444cccccccccccc
ccccccccccccccccddddddddddddddddccccccccccccccccddddddddddddddddddddddddddddd5dd000000000000000000000000000000000000000000000000
ccccccccccc44cccdddddd88888dddddccccccccccccccccddddddddddddddddddddddddddd5d5dd000000000000000000000000000000000000000000000000
ccccccccc44974ccddddd88ee8e8ddddcccc11111111ccccddddddddddd6d6ddddddddddddd565dd000000000000000000000000000000000000000000000000
ccccccc94970a4ccddddd2eeeee8ddddcc111cccccc111ccdddddddddd6d6ddddddddddddd27566d000000000000000000000000000000000000000000000000
cccccc94979aa4ccddddd0e8eee0ddddcc1cccccccccc1ccdddddddddddddddddd6dd6dddd52776d000000000000000000000000000000000000000000000000
cccccc4979aa4cccddddd2eeeee8ddddcd555565865555dcddddddddddddddddd6d66dddd5752676000000000000000000000000000000000000000000000000
cccccc499aa4ccccdddddd2e8eedddddc55555555555555cddddddddddddddddddddddddd5552266000000000000000000000000000000000000000000000000
ccccc4979a49ccccdddddd2eee8dddddc55dd577775dd55cdddddddddddddddddddddddd55555222000000000000000000000000000000000000000000000000
ccccc479a4ccccccdddd22eeeeeeddddc5d11d5555d11d5cf9fff4ff2dddd2dddddddddd00000000000000000000000000000000000000000000000000000000
cccc499a4cccccccdd22e8eee8eeedddc5d11d5665d11d5cffbfffffdeddeddddedddddd00000000000000000000000000000000000000000000000000000000
cc4479a4ccccccccd2ee8eeeee8e8eedc55dd5eeee5dd55cffbffbffd2ddd2dddd2ddd2d00000000000000000000000000000000000000000000000000000000
c4999a4ccccccccc2e88ee8e8e8ee8edc55555555555555cff3bfbf9ddedddeddddeddde00000000000000000000000000000000000000000000000000000000
cc44a4cccccccccce8d2e82edee8edeec66666666666666c9ff3bbffddd2d29ddd2ddd2d00000000000000000000000000000000000000000000000000000000
ccc4a4ccccccccccde2ee2dededd8ed8ccccccccccccccccf4ff3f4fdded9ddded9d9edd00000000000000000000000000000000000000000000000000000000
cccc4cccccccccccdede8dedd8edd8edccccccccccccccccffff3fffddd2ddddd2d2dddd00000000000000000000000000000000000000000000000000000000
cccccccccccccccc8dde8dedddedddedccccccccccccccccffffff9fddd9ddddddd9dddd00000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccccccccccf9fff4ffff4fff9f000000000000000000000000000000000000000000000000000000000000000000000000
cccccccccc555cccccccccccc55555cccc6666ccffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccc5d675cccccccccc5566666cc400004cfffffffffffffffc000000000000000000000000000000000000000000000000000000000000000000000000
ccccccc65d6075cccccccccc5606606ccf4aa4fcff4ffff99ffff4fc000d90000000000000000000000000000000000000000000000000000000000000000000
cccccc65d66675ccccccccc56666666cc449944c9fffffffffffffcc00d039000000000000000000000000000000000000000000000000000000000000000000
cccccc5d66d75ccccccccc446000600cc444444cf4ff9f4ff4f9ffcc00d003900000000000000000000000000000000000000000000000000000000000000000
ccccc5d66675ccccccccc444666666cccffffffcffffffffffffcccc000d00390000000000000000000000000000000000000000000000000000000000000000
ccccc5d6d765cccccccc5446666567ccccccccccffffff9fffcccccc0000d0039000000000000000000000000000000000000000000000000000000000000000
cccc5d66755ccccccccc556666566cccfcccccccff9fff4fcccccccf0000d0039000000000000000000000000000000000000000000000000000000000000000
cccc56675cccccccccc5566656675cccfffccccccfffffffcccccfff000d00003900000000000000000000000000000000000000000000000000000000000000
cc55d675cccccccccc4466666765cccc4f9ffcccccffffffcccff9f4000d00003900000000000000000000000000000000000000000000000000000000000000
c5d6675cccccccccc4446666765cccccfffffcccccf4ffffcccfffff00d000000390000000000000000000000000000000000000000000000000000000000000
cc5575ccccccccccc446667555ccccccffff4fcccccfffffccf4ffff008000000390000000000000000000000000000000000000000000000000000000000000
ccc575ccccccccccc555555cccccccccffffffcccccff9f4ccffffff007000000039000000000000000000000000000000000000000000000000000000000000
cccc5cccccccccccccccccccccccccccfffffffccccccfffcfffffff000000000039000000000000000000000000000000000000000000000000000000000000
ccccccccccccccccccccccccccccccccf4fff9ffcccccccfff9fff4f000000000039000000000000000000000000000000000000000000000000000000000000
30303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030
64646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464647564
30305330303030303030303030303030303030303030303030303030303030303030303030303030303030303030301330303030303030303013303030303030
64647564646464649464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464
30303030303030303030303030301330303073303030133030303063303030303030303030303030303030303030303030533030303030303030305330233030
64646464646464646464647564646464646464646464646464646464649464646464646464646464646464646464646464646464646464646464646464646464
30233030303030303030303030303030307330303030303030307330303030303030301330303053303030303063303030303030303030303030303030303030
64646464646464646464646464646464646485646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464
30303030303013303030733030303030303030303030303030303030303030303030303030303030233030306330303030303023303030303030303030303030
64646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646485646464
30303030633030303030303030535330303030533030303030303030303030533030303030303030303030303030303030303030306330303030303030303030
64646464646464646464646464646464646464646464646464646464646464646475646464646464646464646464646464648564646464646464646464946464
30303063533030305373303030306330303030303030233030533030133030306330303030303030303030303030305330303030303030303030303013303030
64646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464
30133030303030303030303030303030303030303030303030303030303063303030303030303030303030303030303030303030303030533030303030303030
64646475646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464
30303030303030301330303030303030301330633030303030303030303030303030306330303030303013303030303030133030303063303030306330305330
64646464646464648564646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464
30303030303030303030306330303030303030303030633030303030303030303030303030303030303030303030303030303030303030303030303030303030
64646494646464646464646464646464646464756464646464648564646464646494646464646464646464646494646464646464646464646464646464646464
30533030633030303030303030303030633030303030303030303030133030303030303030303030303030303030303030303030303030303030303030303030
64646464646464646464646464646464646464646494646464646464646464646464646464646464646464646464646464646464646464646464646464649464
30303030233030303030303030303030303030303030303030633030303030303063633030133030303030303030303030303030533030303030303030533030
64646464646464646464646464646464646464646464646464646464646464646464646464856464646464646464646464646464646464648564646464646464
30306330303030533030733030533030303030303063303030303030303030303030303030303030533030303030303030303030303030303063303030303030
64646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464
30303030303030303030303030303030306330303013303030303030233030303023303030303073303030303030305363303030133030305330303030303030
64946464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464647564
30303030303030303030303030133030303030303053535330303030303030303030303030303030533030303030303030303030303030303030302330303030
64646464646464646464646464646464649464646464646464646464646464646464646464946464646464646464646464646464646464646464646464646464
30303030133030303030306330303030303053303030303063303030303030303030533030303030303030633030303030303030305330303030303030303030
64646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464
30303030303030303030303030303030303030303030303030303030305330303030303023303030303013303030303030303030306330303030303030303030
64646464646464646475646464646464646464646464646464646464646464646464646464646464646464646464646475646464646464646464646464646464
30307373303030305330303030303030533030303013303053533063533013133030303030303030303030303030303030303030303030303030306330303030
64646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464
30303030303030633030303030302330303030303030133053303030303030303030303030303053303030303030533030303030303030303030133030303030
64646464648564646464646464646464646464646464646464646464649464756464646464646464646464646464646464646464646464649464646464646464
30233030303030303030303063303030303030303030303053303030303030303030633030303030633030303073303013307330303030306330303053303030
64646464646464646464646464646464648564646464646464646464646464646464646464646464646464646464646464646485646464646464646464646464
30303053303030303030303030303030303030303030303030303030306330303030303030303030133030303030303030303030303030303030303030303030
64646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464
30303030303030303030633030303030303030303030303030303030303030303030303030303030303030303030303030303053303030303030303030303030
64646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464
30303030303073303030303030303013303030533030633030133030533023533030305330303030303030303030303030303030303030233030735330303030
64646464646464646464646464646464646464646464646464646464646464646464646485646464646464646464649464646464646464646464646464646464
30303063303030301330303030303030303030303030303030303030303030303030305353303030303030303053303030303030303030303030303030303030
64646464646464646494646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464648564
30133030303030303030303030303030303030133030303030306330303030303053303030303030301330303030303030303063303030303073301330303030
64646464646464646464646464646464646464646464646464646464646464646464646464646464946464646464646464646464646464646464646464646464
30303030303030303030303023303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030
64646475646464646464646464646464646464646464646485646464646464646464646464646464646464646464646464646464646464646464646464646464
30303030303030303073303030303030306330303030533030303030303030306330303030303030303030303013733030302330303030303030303030303030
64646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464
30303030303030303030733030533030303030302330303030303030533030303030303030303030305330303030733030303030305330303030303030303030
64646464646464646464646464646464646464646464646464646464646464646464649464646464646464646464756464646464646464646464646464646464
30303013133030303030303030303030303030303030303030303030303030301330303023303030303030303030303030303030303030301330535330303030
64646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464856464646464646464
30301330301330303030303030303030307330303030303063303030303030303030303030303030303030303030303030303030303030303030303030303030
64646464646464646485646464646464646464646464648564646464646464646464646464646464646464646464646464646464646464646464646464646464
30301330301330303030303023303030303030733030303030303030233030303030633030303030301330303030535330303013303030733030303030307330
64646494646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464649464
30303013133030303030303030303030303030303030303030303030303030303030303030303030303030303030303030533030303030303030303030303030
64646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464646464
__gff__
0000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000020400000000000000000000000000040404000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101656565656565
0101010101010101011301010101010101010101010101010113010101010101010101010101010101010101130101010101010101131313010101010101010101010101010101010101010101010101010101010101010101010176657401130101010101010101010101010101010101010101010101010101656565566565
0101010113010114010101010101010101240101010101010101010101010101010101011401010101010101010101010101010113010114130101010101010101010101011301010101010101010101010101010101010101010165566501010101010101010101010101010101010101010101010101010101656565656565
0101010101010101010101010101010101010101010101010101010114010101130101010101010101010101010101010101011301010101011301010101010101010101010101010101010101010101010101010101010101010175656601010101010101010101010101130101010101010101010101010101656566756565
0124010101010101010101011301010101010101010101010101010101010101010101010101012401010101010101010101010113010101130101010101010101010101010101010176656556740101010101010101010101010101010101010101010101010101010101010101010176740101010101010101656574766565
0101010101010101012401010101010101010101011301010101010101010101010101010101010101010114010101010101010101131313010101010101010101010101010101766565656565650101010114010101010101010101010101010124010101010101010101010101010175660101010101010101566565656565
0101010101011301010101010101140101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101140101010176655665655665660101010101010101010101010101010101010101010101010101010101010101010101010101010101010101656565656565
0101010101010101010101010101010101010101010101010101010124010101010101010101010101010101010101010101010101010101010101010101010101010101010175656565656566010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101756565655665
0113010101010101010101010101010101010101010101010101010101010101010114010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101012401010101010101017565656565
0101010101010101010101011301010101010101010101010101010101010101010101010101010101010101010101130113010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101017665740101010101010101010114010101012401010165656565
0114010101010101010101010101010124010101010101010101010101010101010101010101010101010101010101011301010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101011401010101766565657401010101010101010101010101010101010175656565
0101010101010101010101010101010101010101010101011401010101130101010101010101011301010101010101010101010114010101010101010101010101010101010101010101130101010101010101010101010101010101010101010101010101655665656501010101010101010101010101010101010101010101
0101010113010101140101010101010101010101130101010101010101010101010101010101010101011401010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101756565655601010101010101140101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101017565656601010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010114010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101130101010101010101010101010101010101010101010101010101010101010101010101
0124010101010101140101010113010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101011401010101010113010101010101130101010101010101010101010101010101010101010101010101010101010101010101010101010101010101140101010101012401010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101011301010101010101010101010101010101240101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010176657401010101010101
0101011301010101010101010101010101010101010101010101010101010101010101010101010101010113010101010101010113010113010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101140101010101010101010101010175656601010101010101
0101010101010101010101010101010101010101010101010101010114010101010101010101010101010101010101010101010101010101010101010101010101010113010101010101010101010101010101010101010101010101017674010101010101010101010101010101010101010124010101010101010101010101
0101010101010101010101011301010101010101011301010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101766565740101010101010101010101010101017566010101010101010101010101011401130101010101010101010101010101010101
0114010101010101010101010101010101010101010101010101011301010101010101012401010101010101010101010101010101010101010101010101010101010101010101010101656556650101010101010101010101010101010101010101010101010101010101010101010101010101010101010101130101010101
0101010101010101010101010101010114010101010101010101010101010101010113010101010101011401010101010101010101010101010101010101010101010101010101010101566565650101010101010101010101010101010101010101010101010101010101010101010101010101010101140101010101010101
0101010101010101240101010101010101010101010101010101011401010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101756565660101011301010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101012401010101010101010101010101010101010101010101010101010124010101010101010114010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010124010101010101010101010101010101010101
0101130101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101011301010101010101010101240101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010176656565657401010101010101010101
0101010101010101010101010101130101010101010101010101010101010101140101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101017665656565566501010124010101010101
0101010124010101010101010101010101010101010101010101010101240101010101010101130101010101010101130101010101010101010101010101010101010101010101010113010101010101010101010101011401010101010101011301010101010101010101010101016565667565656574010101010101010101
0101010101010101010101010101010101010101010101130101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101017674010101010101010101016565747665656565010101010101010101
0101010101010101130101140101010101010124010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101240101010101010101010101010101010101016565010101010101010101017556656565566566010101010101010101
0101010101010101010101010101010101010101010101010101011301010101010101010101010101240101010101010101010124010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101017566010101010101010101010175655665656601010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
__sfx__
0012000000053000030000300053246153a6050005300003000530005300003000532461500003000530005300053000530000300053246150005300003000530005300053000030005324615000030005300053
011200000004500025000150001510045100351003510025100251002510015100150000500005150451501500045000250001500025100451003510035100251002510015100151001500005000050000500005
711200000000500005000150002500015000251001510025100151002510015100251001510025000050000515015150250001500025000150002510015100251001510025100151002510015100250000500000
49010000057550a7550c7550f7551375516755187551d7551f70500705267052e7053570500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
490300001044514445184251d42521425134051140510405104050d4050c405004050040500405004050040500405004050040500405004050040500405004050040500405004050040500405004050040500405
4b0400002d61032610386103b6103e6102160021600216003c6003c6003c6003c6003c6003b600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00020000090210a0210d0210f02111021140211802100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
4a0200000161003610066100d610166101d61023610296102f61033610376102f6003460036600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
__music__
03 00010244

