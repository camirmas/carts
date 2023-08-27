pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

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
k_rocks = {k_rock_start, k_rock_ice}
k_ice_block = 49
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

item_types = {
	fish = 1,
	junk = 2,
	item = 3,
}


fish = {
	bass = {
		name = "bass",
		k = 44,
		t_col = 12, -- transparency color
		rarity = "common",
		type = item_types.fish,
		dim = 2 -- 2x2
	},
	salmon = {
		name = "salmon",
		k = 12,
		t_col = 11, -- transparency color
		rarity = "rare",
		type = item_types.fish,
		dim = 2 -- 2x2
	}
}

junk = {
	metal = {
		name = "metal",
		k = 37,
		type = item_types.junk,
		dim = 1 -- 1x1
	},
	wood = {
		name = "wood",
		k = 38,
		type = item_types.junk,
		dim = 1 -- 1x1
	},
	bamboo = {
		name = "bamboo",
		k = 39,
		type = item_types.junk,
		dim = 1
	}
}

function draw_fish(fish, x, y)
	palt(0, false)
	palt(fish.t_col, true)
	spr(fish.k, x, y, fish.dim, fish.dim)
	palt(0, true)
	palt(fish.t_col, false)
end

function draw_item(item, x, y)
	spr(item.k, x + item.off.x, y + item.off.y)
end

items = {
	cassette = {
		name = "cassette",
		k = 43,
		type = item_types.item,
		dim = 1,
		off = {x = 0, y = 0},
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
		off = {x = 2, y = 2},
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
			salmon = 4
		},
		off = {x = 0, y = 0},
	},
	shiny_coin = {
		name = "shiny_coin",
		disp_name = "shiny coin",
		k = 42,
		type = item_types.item,
		dim = 1,
		off = {x = 0, y = 0},
	}
}

-- map regions
regions = {
	start = {
		id = 1,
		fish = {fish.bass, fish.salmon},
		junk = {junk.metal, junk.wood}
	},
	island = {
		id = 2
	},
	ice = {
		id = 3,
		fish = {fish.salmon},
		junk = {junk.metal}
	},
	junk = {
		id = 4
	}
}

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

function add_arr(arr1, arr2)
    local result = {}
    for i = 1, #arr1 do
        result[i] = arr1[i] + arr2[i]
    end
    return result
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

function create_trader()
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

		enter_zone = {
			x = 0,
			y = 16*8,
			hitbox = {x = 0, y = -4, w = 20, h = 20}
		},
		hitbox = {x = 0, y = 0, w = 16, h = 12},
		enabled = false,
		selected = 1,
		items = {
			items.sm_box,
			items.lg_box
		},
		submenu = {
			selected = 1,
			ilist = ilist,
			enabled = false,
			item = nil,

			open = function(self, item)
				self.enabled = true
				self.item = item
			end,

			close = function(self)
				self.enabled = false
				self.item = nil
			end,

			select = function(self)
				if self.selected == 1 and self:craftable() then
					-- craft
				else
					-- exit
					self:close()
				end
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
			
				return true
			end,

			update = function(self)
				if btn(k_right) and self.selected == 1 then
					self.selected = 2
				elseif btn(k_left) and self.selected == 2 then
					self.selected = 1	
				end
			end,

			draw = function(self)
				-- apply camera offsets
				local r = add_arr({cam.x, cam.y, cam.x, cam.y}, self.ilist)
				rectfill(r[1], r[2], r[3], r[4], 6)
				rect(r[1], r[2], r[3], r[4], 3)

				
				local x_mid = flr(r[1] + (r[3]-r[1])/2)
				local cx = r[1] + 4
				local cy = r[2] + 4

				local name = self.item.disp_name or self.item.name
				draw_item(self.item, cx, cy)
				print(name .. " X " .. 1, cx + 20, cy + 2, 0)

				cy += 12

				spr(57, x_mid - 4, cy, 1, 1, false, true)

				cy += 12

				for name, qty in pairs(self.item.junk) do
					local p_qty = player.backpack.junk[name].quantity
					local j = junk[name]
					spr(j.k, cx, cy)
					print(j.name .. " X " .. p_qty .. "/" .. qty, cx + 20, cy + 2, 0)
					cy += 14
				end

				for name, qty in pairs(self.item.fish) do
					local p_qty = player.backpack.fish[name].quantity
					local f = fish[name]
					draw_fish(f, cx, cy)
					print(f.name .. " X " .. p_qty .. "/" .. qty, cx + 20, cy + 4, 0)
					cy += 16
				end

				local craftable = self:craftable()

				local c = "craft"
				local e = "exit"

				if (craftable) print(c, x_mid - 3*#c - 6, r[4] - 6, 3)
				print(e, x_mid + 3*#e, r[4] - 6, 5)

				if (self.selected == 1) and craftable then
					spr(59, x_mid - 4*#c - 6, r[4] - 8)
				else
					spr(59, x_mid + 4*#e - 9, r[4] - 8)
				end
			end
		},

		toggle = function(self)
			if self.submenu.enabled then
				self.submenu:close()
			else
				self.enabled = not self.enabled
			end
		end,

		update = function(self)
			if btnp(k_O) then
				if self.submenu.enabled then
					self.submenu:select()
				else
					self.submenu:open(self.items[self.selected])
				end
			end

			if self.submenu.enabled and btnp(k_X) then
				self.submenu:close()
			end

			if self.submenu.enabled then
				self.submenu:update()
				return
			end

			if btnp(k_down) and self.selected < #self.items then
				self.selected += 1
			elseif btnp(k_up) and self.selected > 1 then
				self.selected -= 1
			end

		end,

		draw = function(self)
			spr(9, self.x, self.y, 2, 2)

			palt(0, false)
			palt(11, true)

			spr(56, self.x + 2, self.y + 1)

			palt(0, true)
			palt(11, false)

			draw_hitbox(self)

			if self.enabled then
				-- apply camera offsets
				local c = {cam.x, cam.y, cam.x, cam.y}
				local bg = add_arr(c, self.bg)
				local bp = add_arr(c, self.bp)
				local ilist = add_arr(c, self.ilist)

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
						spr(59, cx, cy + 2)
					end

					draw_item(item, cx + 4, cy + 2)

					print((item.disp_name or item.name), cx + 20, cy + 4, 0)

					cy += 16
					i += 1
				end

				if (self.submenu.enabled) self.submenu:draw()
			end
		end
	}	
	add(objects, t)

	return t
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

		local k
		if (r == regions.start) then
			k = rnd() > .5 and 17 or 18
		elseif (r == regions.ice) then
			k =  rnd() > .5 and 51 or 52
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
				palt(12, true)
				spr(self.k, self.x, self.y)
				palt(12, false)
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


function create_fishing_spot(x, y, is_junk)
	x = (x or cam.x) + flr(rnd(128))
	y = (y or cam.y) + flr(rnd(128))
	local r = get_region(x, y)
	local lifetime = rnd(30 * 20)

	local spot = {
		x = x,
		y = y,
		region = r,
		hitbox = {x=-8, y=-8, w=16, h=16},
		t = lifetime, -- time remaining
		time_to_bite = 0, -- time until bite
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

			if self.is_junk then
				-- check junk catch
				local j
				if 	dt < .68 then
					j = sample(self.region.junk)
				else
					self.hook:missed()
				end

				self.to_delete = true

				return j
			end

			-- check fish catch
			local f
			if dt < .34 then
				-- extra roll for rare
				if rnd() > .5 then
					-- rare
					f = sample(self.region.fish)
				else
					-- common
					f = sample(self.region.fish)
				end
			elseif dt < .68 then
				-- common
				f = sample(self.region.fish)
			else
				-- missed
				self.hook:missed()
			end

			return f
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
			if (self.t <= 0 or 
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
					self.to_delete = true
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
				if self.regions == regions.start then
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
		create_fishing_spot()	
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

				if fish ~= nil then
					self.caught = f
				end
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
            if other.x+other.hitbox.x+other.hitbox.w > self.x+self.hitbox.x+dx and 
                other.y+other.hitbox.y+other.hitbox.h > self.y+self.hitbox.y+dy and
                other.x+other.hitbox.x < self.x+self.hitbox.x+self.hitbox.w+dx and 
                other.y+other.hitbox.y < self.y+self.hitbox.y+self.hitbox.h+dy then
                return other
            end
            return nil
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
		qty_fish = 0,
		qty_junk = 0,
		qty_items = 0,
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

		add_junk = function(self, j, qty)
			if self.junk[j] then
				self.junk[j].quantity = self.junk[j].quantity + qty
				self.qty_junk += qty
			end
		end,

		rm_junk = function(self, j, qty)
			if self.junk[j] and self.junk[j].quantity - qty >= 0 then
				self.junk[j].quantity = self.junk[j].quantity - qty
				self.qty_junk -= qty
			end
		end,

		add_fish = function(self, f, qty)
			if self.fish[f] then
				self.fish[f].quantity = self.fish[f].quantity + qty
				self.qty_fish += qty
			end
		end,

		rm_fish = function(self, f, qty)
			if self.fish[f] and self.fish[f].quantity - qty >= 0 then
				self.fish[f].quantity = self.fish[f].quantity - qty
				self.qty_fish -= qty
			end
		end,

		add_item = function(self, i, qty)
			if self.items[i] then
				self.items[i].quantity = self.items[i].quantity + qty
				self.qty_items += qty
			end
		end,

		rm_item = function(self, i, qty)
			if self.items[i] and self.items[i].quantity - qty >= 0 then
				self.items[i].quantity = self.items[i].quantity - qty
				self.qty_items -= qty
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

			if not (btn(0) or btn(1) or btn(2) or btn(3)) then
				self.spd.x = self.spd.x * .85
				self.spd.y = self.spd.y * .85
			end

			if btn(k_left) then
				self.spd.x = .5
				self.dir.x = -1
				self.cast_dir = {x=-1, y=0}
				self.k_raft = 9
				self.k_player = 6
				self.flip = {x=true, y=false}
			end

			if btn(k_right) then
				self.spd.x = .5
				self.dir.x = 1
				self.cast_dir = {x=1, y=0}
				self.k_raft = 9
				self.k_player = 6
				self.flip = {x = false, y = false}
			end

			if btn(k_up) then
				self.spd.y = .5
				self.dir.y = -1
				self.cast_dir = {x=0, y=-1}
				self.k_raft = 7
				self.k_player = 5
				self.flip = {x = false, y = false}
			end

			if btn(k_down) then
				self.spd.y = .5
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
				palt(0, false)
				palt(self.info_caught.t_col, true)
				local dim = self.info_caught.dim
				spr(self.info_caught.k, p.x + 2, p.y - 6, dim, dim)
				palt(0, true)
				palt(self.info_caught.t_col, false)
			end

			-- draw hitbox (debug)
			draw_hitbox(self)
        end,

        collide = function(self, other, dx, dy)
            if other.x+other.hitbox.x+other.hitbox.w > self.x+self.hitbox.x+dx and 
                other.y+other.hitbox.y+other.hitbox.h > self.y+self.hitbox.y+dy and
                other.x+other.hitbox.x < self.x+self.hitbox.x+self.hitbox.w+dx and 
                other.y+other.hitbox.y < self.y+self.hitbox.y+self.hitbox.h+dy then
                return other
            end
            return nil
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

function create_rock(x, y)
	local r = get_region(x, y)

	local k
	if (r == regions.start) then
		k = k_rock_start
	elseif (r == regions.ice) then
		k = k_rock_ice
	end
    local rock = create_obs(x, y, k)
    rock.hitbox = {x=1, y=3, w=7, h=5}

    return rock
end

function create_ice_block(x, y)
    local r = create_obs(x, y, k_ice_block)
    r.hitbox = {x=0, y=3, w=7, h=4}

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

function start_game()
	states:update_state(states.game)
	player = create_player(2*8, 56 * 8)
	cam = {x=0, y=0}
	trader = create_trader()
	backpack_ui = create_backpack_ui()
	create_map_bounds()

	for _, f in pairs(fish) do 
		player.backpack:add(f, 10) 
	end
	for _, j in pairs(junk) do 
		player.backpack:add(j, 10) 
	end
	for _, i in pairs(items) do
		player.backpack:add(i, 10)
	end
end

function create_backpack_ui()
	local w = 14 * 8
	local h = 14 * 8
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
		enabled = false,

		toggle = function(self)
			self.enabled = not self.enabled
		end,

		update = function(self)
			local pages = {}			

			local n_items = 0
			local page = {}

			for name, info in pairs(player.backpack.fish) do
				local f = fish[name]
				local qty = info.quantity

				if qty > 0 then
					if n_items == 4 then
						n_items = 0
						add(pages, page)
						page = {}
					end

					add(page, {f, qty})
					n_items += 1
				end
			end

			for name, info in pairs(player.backpack.junk) do
				local j = junk[name]
				local qty = info.quantity

				if qty > 0 then
					if n_items == 4 then
						n_items = 0
						add(pages, page)
						page = {}
					end

					add(page, {j, qty})
					n_items += 1
				end
			end

			for name, info in pairs(player.backpack.items) do
				local i = items[name]
				local qty = info.quantity

				if qty > 0 then
					if n_items == 4 then
						n_items = 0
						add(pages, page)
						page = {}
					end

					add(page, {i, qty})
					n_items += 1
				end
			end

			if #page > 0 then
				add(pages, page)				
			end

			self.pages = pages

			if btnp(k_left) then
				if (self.curr_page > 1) self.curr_page -= 1
			elseif btnp(k_right) then
				if (self.curr_page < #self.pages) self.curr_page += 1
			end
		end,

		-- draw based on camera view
		draw = function(self)
			local page = {}

			-- apply offsets
			local c = {cam.x, cam.y, cam.x, cam.y}
			local bg = add_arr(c, self.bg)
			local bp = add_arr(c, self.bp)
			local ilist = add_arr(c, self.ilist)

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

				print((item.disp_name or item.name) .. " X " .. qty, cx + 20, cy + 4, 0)

				if (item.type ~= item_types.fish) then
					spr(item.k, cx + 4, cy + 3, item.dim, item.dim)
					cy += 16
				else
					draw_fish(item, cx, cy)
					cy += 18
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

			spr(self.page_l.k, self.page_l.x, self.page_l.y, 1, 1, true, false)
			spr(self.page_r.k, self.page_r.x, self.page_r.y)

			-- page number
			local pn = #self.pages or 1
			print("" .. self.curr_page .. " / " .. pn, self.page_l.x + 14, self.page_l.y + 1, 5)
		end,
	}

	return backpack_ui
end

states = {
	state = nil,
	start = {
		_update = function()
			if (btn(k_X)) start_game()
		end,
		_draw = function()
			cls(1)
			local msg = "press ❎ to start"
			print(debug, 10, 50)
			print(msg, (128-#msg*4)/2, 12*8)
		end
	},
	game = {
		_update = function()
			debug = ""

			if btnp(k_X) then
				if player:collide(trader.enter_zone, 0, 0) then
					trader:toggle()
				else
					backpack_ui:toggle()
				end
			end

			if trader.enabled then
				trader:update()
				return
			end

			if backpack_ui.enabled then
				backpack_ui:update()
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
			map()

			camera(cam.x, cam.y)

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

			trader:draw()

			if (backpack_ui.enabled) backpack_ui:draw()

			-- debug = "missed: " .. missed
			-- debug = "" .. get_region(player.x, player.y).id
			-- debug = "trader: " .. (trader.enabled and "yes" or "no")
			-- debug = "backpack: " .. (backpack_ui.enabled and "yes" or "no")

			print(debug, cam.x + 10, cam.y + 10)
		end
	},
	update_state = function(self, s)
		self.state = s
		_update = s._update
		_draw = s._draw
	end
}

function contains(table, element)
	for _, value in pairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

function load_map()
    for x=1,128 do
        for y=1,64 do
            local tile = mget(x, y)
            if contains(k_rocks, tile) then
                add(objects, create_rock(x*8, y*8))
			elseif tile == k_ice_block then
				add(objects, create_ice_block(x*8, y*8))
			end
        end
    end

    -- debug=#objects
end

function _init()
	states:update_state(states.start)
	load_map()
	-- music(0)
end

__gfx__
00000000ccccccccffffffff11111111bbbbbbbbbbbbbbbbbbbbbbbb445f445444540000f4444f44444ff44488000000bbbbbbbbbb1111bb0000000000000000
00000000ccccccccffffffff11111111bb0000bbbb0000bbbb006bbb4f5f44544f540000ff4f444f4f4444f488000000bbbbbbbb11dc6dbb0000000000000000
00700700ccccccccffffffff11111111bb6006bbbb0000bbbb0009bb4454f454f45f0000555555555555555577000000bbbbbbb11da06ddb0000000000000000
00077000ccccccccffffffff11111111bb0990bbbb0000bbbb000bbbf454f454f45f0000ff4444ff444444ff00000000bbbb1111dc6a6cdb0000000000000000
00077000ccccccccffffffff11111111b000000bb000000bbb007bbbf454445444540000f444ff444f44ff4400000000bbb1cd1dc6666c1b0000000000000000
00700700ccccccccffffffff11111111bb0770bbbb0000bbbb007bbb4454445444540000ff4444444444444400000000bbbb1d1c667661bb0000000000000000
00000000ccccccccffffffff11111111bb0770bbbb0000bbbb007bbb4f54f454f45f0000555555555555555500000000bbbbb1166776c1bb0000000000000000
00000000ccccccccffffffff11111111bb9779bbbb9009bbbb009bbb44544454f45f0000ff4444444444444400000000bbbbb1d677661bbb0000000000000000
00000000cccccccccccccccccccccccc3cccc3cc55500000000000004f5f44544f540000f444ff44ff44ff4400000000bbbb1d677661bbbb0000000000000000
00000000cccccccccccccccccccccccccbccbccc5950000000000000445f44544f540000ff4444ff444444f400000000bbbb1c666c11bbbb0000000000000000
00000000ccc6c6ccccccccccccc67cccc3ccc3cc5950000000000000f454f454f45f0000555555555555555500011000bbb1d67c11c1bbbb0000000000000000
00000000cc6c6cccccccccccccd766ccccbcccbc59500000000000004454f454f4540000f4444f44ff44ff4400111100b11d6611bb1bbbbb0000000000000000
00000000cccccccccc6cc6cccc5d776cccc3c39c55500000000000004f5444544454000000000000000000000011110016cdd1bbbbbbbbbb0000000000000000
00000000ccccccccc6c66cccc575d67cccbc9ccc59500000000000004454445444540000000000000000000000011000b1dc1bbbbbbbbbbb0000000000000000
00000000ccccccccccccccccc555dd66ccc3cccc55500000000000004f5f4f5f4f540000000000000000000000000000bb161bbbbbbbbbbb0000000000000000
00000000cccccccccccccccc55555dddccc9cccc0000000000000000ff5fff5fff5f0000000000000000000000000000bbb1bbbbbbbbbbbb0000000000000000
c11c1cc1000000000090090080900908ccccccccd500000045000000b3000000555555555555500005aa900055555555ccccccccc44dddcc0000000000000000
1cc1c11c000000008080080880800808cbcccccc6d500000f4500000fb30000054464445564650005aaaa9005d7777d5cccccccc44b66dcc0000000000000000
c11111c1000000008088880888888888cc3ccc3c06d500000f4500000fb3000054444645544450005aaaa900d1dccd1dcccccccc4a0b6dcc0000000000000000
c1cc1c1c00000000088ee880008ee800cccbcccb006d500000f4500000fb3000564646455464500005aa90005deeeed5cccccc34bbabb3cc0000000000000000
1c1111c1000000008088880808888880cc3ccc3c0006d500000f4500000fb30056464445555550000000000055555555cccc634bbbbbd3cc0000000000000000
1cccc1c1000000000800008080800808bc9c9bcc00006d500000f4500000fb3056464645000000000000000000000000cc63b64b3bbd3ccc0000000000000000
c1111111000000000000000000000000c3c3cccc000006d500000f4500000fb356444445000000000000000000000000cc3634b3b36d3ccc0000000000000000
1c11cc1c000000000000000000000000ccc9cccc0000006d000000f4000000fb55555555000000000000000000000000ccc364b336d3cccc0000000000000000
1cc11ccc11111111111111111111111111111111111311111111111111111111babbbbab009999000000000000000000cccc4bbb66d3cccc0000000000000000
ccccc1c111111111111111111111111111111111111111d11111171113111711bb1111bb009999005000000090000000cccc4bb66d3ccccc0000000000000000
c1ccccc11111111111167111111d1d11111111111d1111111511111111111111bb5116bb009999005500000099000000ccc4bb6dd3cccccc0000000000000000
ccc1cc1c1767677111d7661111d1d11111111111111111111111e1111111e111bb1991bb999999995550000099900000cc46b6d33ccccccc0000000000000000
11cc11c177667767115d77611111111111d11d11111111111111115111111111b111111b0999999055500000999000003dd3dd3b3ccccccc0000000000000000
cc1c1ccc767776771575d671111111111d1dd11111111d111111111111111111bb1771bb009999005500000099000000db3d3cc3cccccccc0000000000000000
c1c1cc11c767677c1555dd66111111111111111111111111171111711711111ebb1771bb000990005000000090000000c3bdcccccccccccc0000000000000000
1ccc1ccc1cccccc155555ddd1111111111111111131111111111111111111111bb9779bb000000000000000000000000ccd3cccccccccccc0000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
30303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30305330303030303030303030303030303030303030303030303030303030303030303030303030303030303030301330303030303030303013303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030303030303030303030301330303073303030133030303063303030303030303030303030303030303030303030533030303030303030305330233030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30233030303030303030303030303030307330303030303030307330303030303030301330303053303030303063303030303030303030303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030303013303030733030303030303030303030303030303030303030303030303030303030233030306330303030303023303030303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030633030303030303030535330303030533030303030303030303030533030303030303030303030303030303030303030306330303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303063533030305373303030306330303030303030233030533030133030306330303030303030303030303030305330303030303030303030303013303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30133030303030303030303030303030303030303030303030303030303063303030303030303030303030303030303030303030303030533030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030303030301330303030303030301330633030303030303030303030303030306330303030303013303030303030133030303063303030306330305330
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030303030303030306330303030303030303030633030303030303030303030303030303030303030303030303030303030303030303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30533030633030303030303030303030633030303030303030303030133030303030303030303030303030303030303030303030303030303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030233030303030303030303030303030303030303030633030303030303063633030133030303030303030303030303030533030303030303030533030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30306330303030533030733030533030303030303063303030303030303030303030303030303030533030303030303030303030303030303063303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030303030303030303030303030306330303013303030303030233030303023303030303073303030303030305363303030133030305330303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030303030303030303030133030303030303053535330303030303030303030303030303030533030303030303030303030303030303030302330303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030133030303030306330303030303053303030303063303030303030303030533030303030303030633030303030303030305330303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030303030303030303030303030303030303030303030303030305330303030303023303030303013303030303030303030306330303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30307373303030305330303030303030533030303013303053533063533013133030303030303030303030303030303030303030303030303030306330303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030303030633030303030302330303030303030133053303030303030303030303030303053303030303030533030303030303030303030133030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30233030303030303030303063303030303030303030303053303030303030303030633030303030633030303073303013307330303030306330303053303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303053303030303030303030303030303030303030303030303030306330303030303030303030133030303030303030303030303030303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030303030303030633030303030303030303030303030303030303030303030303030303030303030303030303030303053303030303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030303073303030303030303013303030533030633030133030533023533030305330303030303030303030303030303030303030233030735330303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303063303030301330303030303030303030303030303030303030303030303030305353303030303030303053303030303030303030303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30133030303030303030303030303030303030133030303030306330303030303053303030303030301330303030303030303063303030303073301330303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030303030303030303023303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030303030303073303030303030306330303030533030303030303030306330303030303030303030303013733030302330303030303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303030303030303030733030533030303030302330303030303030533030303030303030303030305330303030733030303030305330303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303013133030303030303030303030303030303030303030303030303030301330303023303030303030303030303030303030303030301330535330303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30301330301330303030303030303030307330303030303063303030303030303030303030303030303030303030303030303030303030303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30301330301330303030303023303030303030733030303030303030233030303030633030303030301330303030535330303013303030733030303030307330
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
30303013133030303030303030303030303030303030303030303030303030303030303030303030303030303030303030533030303030303030303030303030
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
__gff__
0000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101011301010101010101010101010101010113010101010101010101010101010101010101130101010101010101131313010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010113010114010101010101010101240101010101010101010101010101010101011401010101010101010101010101010113010114130101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010114010101130101010101010101010101010101010101011301010101011301010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0124010101010101010101011301010101010101010101010101010101010101010101010101012401010101010101010101010113010101130101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101012401010101010101010101011301010101010101010101010101010101010101010114010101010101010101131313010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101011301010101010101140101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010124010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0113010101010101010101010101010101010101010101010101010101010101010114010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101011301010101010101010101010101010101010101010101010101010101010101010101130113010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0114010101010101010101010101010124010101010101010101010101010101010101010101010101010101010101011301010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101011401010101130101010101010101011301010101010101010101010114010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010113010101140101010101010101010101130101010101010101010101010101010101010101011401010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010114010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0124010101010101140101010113010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101011401010101010113010101010101130101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101011301010101010101010101010101010101240101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101011301010101010101010101010101010101010101010101010101010101010101010101010101010113010101010101010113010113010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010114010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101011301010101010101011301010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0114010101010101010101010101010101010101010101010101011301010101010101012401010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010114010101010101010101010101010101010113010101010101011401010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101240101010101010101010101010101010101011401010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101012401010101010101010101010101010101010101010101010101010124010101010101010114010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101130101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101011301010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101130101010101010101010101010101010101140101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010124010101010101010101010101010101010101010101010101240101010101010101130101010101010101130101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101130101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101130101140101010101010124010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101011301010101010101010101010101240101010101010101010124010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
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

