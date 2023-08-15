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

g = 1 -- gravity

n_waves = 10
n_waves_max = 30
n_fishing_spots = 5

fishing_spots = {}
waves = {}
objects = {}

function gauss_rng()
    local sum = 0
    for i=1,12 do
        sum = sum + rnd(1)
    end
    return sum - 6
end

function create_fishing_spots()
	for i=1,n_fishing_spots do
		local spot = {
			x = flr(rnd(128)),
			y = flr(rnd(128)),
			lifetime = rnd(30 * 20), -- sec @ 30fps
			t = 0, -- time alive
			bubbles = {},

			update = function(self)
				if (self.t >= self.lifetime) del(self.bubbles, self)

				for bubble in all(self.bubbles) do
					bubble:update()
				end
			end,

			draw = function(self)
				for bubble in all(self.bubbles) do
					bubble:draw()
				end
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

function create_hook(x, y, dir)
	local hook = {
		start = {x=x, y=y},
		x = x,
		y = y,		
		dir = dir,
		z = 15,
		k = k_hook,

		update = function(self)
			local z = self.z - g

			if z >= 0 then
				self.z = z
				self.x = self.x + 1.5 * self.dir.x
				self.y = self.y + 1.5 * self.dir.y
			else
				-- check fishing
			end
		end,

		draw = function(self)
			line(self.start.x, self.start.y, self.x, self.y, 10)

			local xo, yo
			if dir.x == 1 then
				xo = -3	
				yo = -2	
			elseif dir.x == -1 then
				xo = -4	
				yo = -2	
			else
				xo = -4	
				yo = -4	
			end
			spr(self.k, self.x + xo, self.y + yo, 1, 1, dir.x == 1, dir.y == -1)
		end
	}

	return hook
end

function create_player(x, y)
	return {
		x = x,
		y = y,
		spd = {x=0, y=0},
		acc = {x=0, y=0},
		dir = {x=0, y=0},
		cast_dir = {x=0, y=-1},
        hitbox = {x=0, y=0, w=12, h=16},
		k_player = 4,
		k_raft = 7,
		flip = {x=false, y=true}, -- initially facing down right
		max_spd = 1,
		hook = nil,
		casting = false,
		retrieving = false,

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
			local px = self.x + self.hitbox.w / 2 - 4
			local py = self.y + self.hitbox.h / 2 - 4
			self.hook = create_hook(px, py, self.cast_dir)
		end,

		retrieve = function(self)
			self.casting = false
			self.hook = nil

			-- check fishing
		end,

		update = function(self)
			if self.casting and self.hook ~= nil then			
				self.hook:update()
				self.spd = {x=0, y=0}
				return 
			end

			self:update_hitbox()

			if not (btn(0) or btn(1) or btn(2) or btn(3)) then
				self.spd.x = self.spd.x * .9
				self.spd.y = self.spd.y * .9
			end

			if btn(k_left) then
				self.facing = "left"
				self.spd.x = .5
				self.dir.x = -1
				self.cast_dir = {x=-1, y=0}
				self.k_raft = 9
				self.k_player = 6
				self.flip = {x=true, y=false}
			end

			if btn(k_right) then
				self.facing = "right"
				self.spd.x = .5
				self.dir.x = 1
				self.cast_dir = {x=1, y=0}
				self.k_raft = 9
				self.k_player = 6
				self.flip = {x = false, y = false}
			end

			if btn(k_up) then
				self.facing = "up"
				self.spd.y = .5
				self.dir.y = -1
				self.cast_dir = {x=0, y=-1}
				self.k_raft = 7
				self.k_player = 5
				self.flip = {x = false, y = false}
			end

			if btn(k_down) then
				self.facing = "down"
				self.spd.y = .5
				self.dir.y = 1
				self.cast_dir = {x=0, y=1}
				self.k_raft = 7
				self.k_player = 4
				self.flip = {x = false, y = true}
			end

			-- debug = "x: " .. self.dir.x .. ", y: " .. self.dir.y

			player:move(self.dir.x * self.spd.x, self.dir.y * self.spd.y)
		end,

        draw = function(self)
			-- draw raft
            spr(self.k_raft, self.x, self.y, 2, 2, self.flip.x, self.flip.y)

			palt(0, false)
			palt(11, true)

			-- draw player
			local px = self.x + self.hitbox.w / 2 - 4
			local py = self.y + self.hitbox.h / 2 - 4
            spr(self.k_player, px, py, 1, 1, self.flip.x, false)

			palt(0, true)
			palt(11, false)

			-- draw hook
			if self.casting then
				self.hook:draw()
			end

			-- draw hitbox (debug)
			if debug_hitbox then
				rect(self.x, self.y, self.x + self.hitbox.w, self.y + self.hitbox.h, 11)
			end
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

			if debug_hitbox then
				rect(self.x, self.y, self.x + self.hitbox.w, self.y + self.hitbox.h, 11)
			end
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

			if (#waves < n_waves_max) create_waves()
			if (#fishing_spots < n_fishing_spots) create_fishing_spots()
		end,
		_draw = function()
			cls()
			map()

			for wave in all(waves) do
				wave:draw()
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
00000000ccccccccffffffffccccccccbbbbbbbbbbbbbbbbbbbbbbbb445f445444540000f4444f44444ff4440000000000000000000000000000000000000000
00000000ccccccccffffffffccccccccbb0000bbbb0000bbbb006bbb4f5f44544f540000ff4f444f4f4444f40000000000000000000000000000000000000000
00700700ccccccccffffffffccccccccbb6006bbbb0000bbbb0009bb4454f454f45f000055555555555555550000d00000011000000000000000000000000000
00077000ccccccccffffffffccccccccbb0990bbbb0000bbbb000bbbf454f454f45f0000ff4444ff444444ff0000d00000111100000000000000000000000000
00077000ccccccccffffffffccccccccb000000bb000000bbb007bbbf454445444540000f444ff444f44ff4400d0d00000111100000000000000000000000000
00700700ccccccccffffffffccccccccbb0770bbbb0000bbbb007bbb4454445444540000ff44444444444444000d000000011000000000000000000000000000
00000000ccccccccffffffffccccccccbb0770bbbb0000bbbb007bbb4f54f454f45f000055555555555555550000000000000000000000000000000000000000
00000000ccccccccffffffffccccccccbb9779bbbb9009bbbb009bbb44544454f45f0000ff444444444444440000000000000000000000000000000000000000
00000000cccccccccccccccccccc11cc3cccc3cc00000000000000004f5f44544f540000f444ff44ff44ff440000000000000000000000000000000000000000
00000000cccccccccccccccccc11661ccbccbccc0000000000000000445f44544f540000ff4444ff444444f40000000000000000000000000000000000000000
00000000ccc6c6ccccccccccc166661cc3ccc3cc0000000000000000f454f454f45f000055555555555555550000000000000000000000000000000000000000
00000000cc6c6ccccccccccc1dd66661ccbcccbc00000000000000004454f454f4540000f4444f44ff44ff440000000000000000000000000000000000000000
00000000cccccccccc6cc6cc15dd6661ccc3c39c00000000000000004f5444544454000000000000000000000000000000000000000000000000000000000000
00000000ccccccccc6c66ccc155dddd1ccbc9ccc0000000000000000445444544454000000000000000000000000000000000000000000000000000000000000
00000000cccccccccccccccc15555551ccc3cccc00000000000000004f5f4f5f4f54000000000000000000000000000000000000000000000000000000000000
00000000ccccccccccccccccccccccccccc9cccc0000000000000000ff5fff5fff5f000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0112000000053000030000300053246153a6050005300003000530005300003000532461500003000530005300053000530000300053246150005300003000530005300053000030005324615000030005300053
011200000004500025000150001510045100351003510025100251002510015100150000500005150451501500045000250001500025100451003510035100251002510015100151001500005000050000500005
711200000000500005000150002500015000251001510025100151002510015100251001510025000050000515015150250001500025000150002510015100251001510025100151002510015100250000500000
__music__
03 00010244

