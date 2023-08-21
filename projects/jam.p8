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
k_rock = 19
k_hook = 11 -- soon to have more
k_alert = 21

g = 1 -- gravity

n_waves = 10
n_waves_max = 30
n_fishing_spots = 5

t_bite_max = 5 * 30 -- max sec to wait before a bite

fishing_spots = {}
waves = {}
objects = {}
boat_particles = {}

-- map regions
regions = {
	start = 0,
	island = 1,
	ice = 2,
	junk = 3
}

-- fish
fish = {
	sardine = {
		k = 32,
		rarity = "common",
		regions = {regions.start},
	}
}

function draw_hitbox(obj)
	if debug_hitbox then
		rect(obj.x + obj.hitbox.x, obj.y + obj.hitbox.y, obj.x + obj.hitbox.x + obj.hitbox.w, obj.y + obj.hitbox.y + obj.hitbox.h, 11)
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
				self.t = self.t + 1

				if self.t >= self.lifetime then
					del(boat_particles, self)
					return
				end

				if self.x ~= 0 then
					self.x = self.x + self.vx
					self.y = self.y + self.vy * cos(self.t)
				elseif self.y ~= 0 then
					self.x = self.x + self.vx * cos(self.t)
					self.y = self.y + self.vy
				end
			end,

			draw = function(self)
				pset(self.x, self.y, 6)
			end
		}
		
		add(boat_particles, particle)
	end
end

function create_fishing_spots()
	for i=1,n_fishing_spots do
		x = flr(rnd(128))
		y = flr(rnd(128))
		local lifetime = rnd(30 * 20)

		local spot = {
			x = x,
			y = y,
			hitbox = {x=-8, y=-8, w=16, h=16},
			t = lifetime, -- time remaining
			t_bite = 0,
			bite = false,
			bubbles = {},

			set_hook = function(self, hook)
				self.bite = false
				self.hook = hook
				self.t_bite = min(rnd(t_bite_max), self.t)
			end,

			update = function(self)
				self.t = self.t - 1

				if self.hook ~= nil then
					if self.t_bite > 0 then
						self.t_bite = self.t_bite - 1
					elseif not (self.hook.bite or self.hook.caught) then
						sfx(3)
						self.hook.bite = true
						self.hook.bite_start = time()
					end
				end

				if (self.t <= 0) then
					self.hook = nil
					del(fishing_spots, self)
				end

				for bubble in all(self.bubbles) do
					bubble:update()
				end
			end,

			draw = function(self)
				for bubble in all(self.bubbles) do
					bubble:draw()
				end

				draw_hitbox(self)
			end
		}
		local n_bubbles = max(3, flr(rnd(6)))
		for i=1,n_bubbles do
			local bubble = {
				x = spot.x + 2 * gauss_rng(),
				y = spot.y + 2 * gauss_rng(),
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
					circ(self.x, self.y, self.r, 1)
				end
			}
			add(spot.bubbles, bubble)
		end

		add(fishing_spots, spot)
	end
end

function create_waves()
	for i=1,n_waves do
		local k = rnd() > .5 and 17 or 18
		local wave = {
			x = flr(rnd(128)),
			y = flr(rnd(128)),
			k = k,
			lifetime = rnd(30 * 2), -- sec @ 30fps
			t = 0, -- time alive

			update = function(self)
				self.t = self.t + 1

				if (self.t >= self.lifetime) del(waves, self)
			end,

			draw = function(self)
				spr(self.k, self.x, self.y)
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
				self.wait_time = self.wait_time - 1	
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
		bite_start = nil,
		bite = false,
		caught = nil,

		retrieve = function(self)
			if self.bite then
				-- check fish catch
				local dt = time() - self.bite_start

				if dt < .34 then
					-- extra roll for rare
					if rnd() > .5 then
						-- rare
						self.caught = fish.sardine
					else
						-- common
						self.caught = fish.sardine
					end
				elseif dt < .68 then
					-- common
					self.caught = fish.sardine
				else
					self.bite = false
					self.spot:set_hook(self)
				end

				self.bite = false
			end

			self.spot = nil
		end,

		update = function(self)
			local z = self.z - g

			if z >= 0 then
				-- apply physics

				self.z = z
				self.x = self.x + 1.5 * self.dir.x
				self.y = self.y + 1.5 * self.dir.y

				-- apply user control for rod

				local dx = 0
				local dy = 0

				if (btn(k_left)) dx = -1
				if (btn(k_right)) dx = 1
				if (btn(k_down)) dy = 1
				if (btn(k_up)) dy = -1

				if (self.dir.x ~= dx) self.x = self.x + dx
				if (self.dir.y ~= dy) self.y = self.y + dy
			else
				if self.splash == nil then
					sfx(6)	
					self.splash = create_splash(self.x, self.y)
				else
					self.splash:update()
				end

				-- check if within a fishing spot
				local spot_found
				for spot in all(fishing_spots) do
					if self:collide(spot, 0, 0) then
						spot_found = spot
					end
				end

				if spot_found ~= nil then
					if self.spot == nil then
						self.spot = spot_found
						self.spot:set_hook(self)
					end
				end

				if self.bite then
					local dt = time() - self.bite_start
					-- debug = "dt: " .. dt

					if dt > 0.68 then
						debug = "Missed!"
						self.bite = false
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
		backpack = {},
		info_timer = 0,
		info_spr = nil,

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
			local collided = false
			for obj in all(objects) do
				if self:collide(obj, dx, dy) then
					collided = true
					dx = 0
					dy = 0
				end
			end

			self.x = self.x + dx
			self.y = self.y + dy
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
			self.info_spr = self.hook.caught.k
			self.info_timer = 2.5 * 30 -- 2.5s @ 30fps
		end,

		retrieve = function(self)
			self.hook:retrieve()
			-- check fishing
			if self.hook.caught then
				self:set_info_timer()
				self.hook.caught = false
				add(self.backpack, self.hook.caught)
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
				self.info_timer = self.info_timer - 1
			end
		end,

        draw = function(self)
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
			if self.hook ~= nil and self.hook.spot ~= nil and self.hook.bite then
				spr(k_alert, p.x + 2, p.y - 6)
			end

			-- draw info spr
			if self.info_spr ~= nil and self.info_timer > 0 then
				spr(self.info_spr, p.x + 2, p.y - 6)
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
            self.x = self.x + dx
            self.y = self.y + dy
        end,
        draw = function(self)
            spr(self.k, self.x, self.y)

			-- draw hitbox (debug)
			draw_hitbox(self)
        end
    }
end

function create_rock(x, y)
    local r = create_obs(x, y, k_rock)
    r.hitbox = {x=1, y=1, w=7, h=6}

    return r
end

function start_game()
	states:update_state(states.game)
	player = create_player(20, 20)
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

			-- debug = "" .. #boat_particles
			player:update()

			if btnp(k_O) then
				if player.casting then
					player:retrieve()
				else
					player:cast()
				end
			end

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

			print(debug, (128-#debug*4)/2, 12*8)
		end
	},
	update_state = function(self, s)
		self.state = s
		_update = s._update
		_draw = s._draw
	end
}

function load_room()
    -- TODO: load objects based on camera view
    for x=1,15 do
        for y=1,15 do
            local tile = mget(x, y)
            if tile == k_rock then
                add(objects, create_rock(x*8, y*8))
			end
        end
    end

    -- debug=#objects
end

function _init()
	states:update_state(states.start)
	load_room()
	-- music(0)
end

__gfx__
00000000ccccccccffffffffccccccccbbbbbbbbbbbbbbbbbbbbbbbb445f445444540000f4444f44444ff4448800000000000000000000000000000000000000
00000000ccccccccffffffffccccccccbb0000bbbb0000bbbb006bbb4f5f44544f540000ff4f444f4f4444f48800000000000000000000000000000000000000
00700700ccccccccffffffffccccccccbb6006bbbb0000bbbb0009bb4454f454f45f000055555555555555557700000000000000000000000000000000000000
00077000ccccccccffffffffccccccccbb0990bbbb0000bbbb000bbbf454f454f45f0000ff4444ff444444ff0000000000000000000000000000000000000000
00077000ccccccccffffffffccccccccb000000bb000000bbb007bbbf454445444540000f444ff444f44ff440000000000000000000000000000000000000000
00700700ccccccccffffffffccccccccbb0770bbbb0000bbbb007bbb4454445444540000ff444444444444440000000000000000000000000000000000000000
00000000ccccccccffffffffccccccccbb0770bbbb0000bbbb007bbb4f54f454f45f000055555555555555550000000000000000000000000000000000000000
00000000ccccccccffffffffccccccccbb9779bbbb9009bbbb009bbb44544454f45f0000ff444444444444440000000000000000000000000000000000000000
00000000cccccccccccccccccccc11cc3cccc3cc55500000000000004f5f44544f540000f444ff44ff44ff440000000000000000000000000000000000000000
00000000cccccccccccccccccc11661ccbccbccc5950000000000000445f44544f540000ff4444ff444444f40000000000000000000000000000000000000000
00000000ccc6c6ccccccccccc166661cc3ccc3cc5950000000000000f454f454f45f000055555555555555550001100000000000000000000000000000000000
00000000cc6c6ccccccccccc1dd66661ccbcccbc59500000000000004454f454f4540000f4444f44ff44ff440011110000000000000000000000000000000000
00000000cccccccccc6cc6cc15dd6661ccc3c39c55500000000000004f5444544454000000000000000000000011110000000000000000000000000000000000
00000000ccccccccc6c66ccc155dddd1ccbc9ccc5950000000000000445444544454000000000000000000000001100000000000000000000000000000000000
00000000cccccccccccccccc15555551ccc3cccc55500000000000004f5f4f5f4f54000000000000000000000000000000000000000000000000000000000000
00000000ccccccccccccccccccccccccccc9cccc0000000000000000ff5fff5fff5f000000000000000000000000000000000000000000000000000000000000
00000000000000000090090080900908000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008080080880800808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d01dd70000000008088880888888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01dddddd00000000088ee880008ee800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01dddddd000000008088880808888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d01ddd0000000000800008080800808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0303030303030303030303030301030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030101010101011301030101030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0301010113030314010301030101030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303010303010300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0314030303030301010303011303010300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303010103030301010101010303010300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030301011301030303030101140300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303010103030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0313030103030103030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303010103030303030303031303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0314010303030303030301010101010300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0301010101010101010101030303010300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0301030313010103140303030303010300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0012000000053000030000300053246153a6050005300003000530005300003000532461500003000530005300053000530000300053246150005300003000530005300053000030005324615000030005300053
011200000004500025000150001510045100351003510025100251002510015100150000500005150451501500045000250001500025100451003510035100251002510015100151001500005000050000500005
711200000000500005000150002500015000251001510025100151002510015100251001510025000050000515015150250001500025000150002510015100251001510025100151002510015100250000500000
49010000057550a7550c7550f7551375516755187551d7551f70500705267052e7053570500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
490300001044514445184251d42521425134051140510405104050d4050c405004050040500405004050040500405004050040500405004050040500405004050040500405004050040500405004050040500405
4a0400002d61032610386103b6103e6102160021600216003c6003c6003c6003c6003c6003b600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
00020000090210a0210d0210f02111021140211802100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
__music__
03 00010244

