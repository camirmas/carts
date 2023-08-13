pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

debug = ""

k_left=0
k_right=1
k_up=2
k_down=3

objects = {}

function create_player(x, y)
	return {
		x = x,
		y = y,
		spd = {x=0, y=0},
		acc = {x=0, y=0},
		dir = {x=0, y=0},
		flip = {x=false, y=false}, -- initially facing right
		max_spd = 1,
		k_player = 4,
		k_raft = 7,
        hitbox = {x=0, y=0, w=12, h=16},

		update_hitbox = function(self)
			if self.k_raft == 9 then
				self.hitbox = {x=0, y=0, w=16, h=12}
			else
				self.hitbox = {x=0, y=0, w=12, h=16}
			end
		end,

		move = function(self, dx, dy)
			self.x = self.x + dx
			self.y = self.y + dy
		end,

		update = function(self)
			if not (btn(0) or btn(1) or btn(2) or btn(3)) then
				self.spd.x = self.spd.x * .9
				self.spd.y = self.spd.y * .9
			end

			if btn(k_left) then
				self.spd.x = .5
				self.dir.x = -1
				self.k_raft = 9
				self.k_player = 6
				self.flip.x = true
			end

			if btn(k_right) then
				self.spd.x = .5
				self.dir.x = 1
				self.k_raft = 9
				self.k_player = 6
				self.flip.x = false
			end

			if btn(k_up) then
				self.spd.y = .5
				self.dir.y = -1
				self.k_raft = 7
				self.k_player = 5
			end

			if btn(k_down) then
				self.spd.y = .5
				self.dir.y = 1
				self.k_raft = 7
				self.k_player = 4
			end

			self:update_hitbox()

			debug = "x: " .. self.dir.x .. ", y: " .. self.dir.y

			player:move(self.dir.x * self.spd.x, self.dir.y * self.spd.y)
		end,

        draw = function(self)
			palt(0, false)
			palt(11, true)
			-- draw raft
            spr(self.k_raft, self.x, self.y, 2, 2, self.flip.x, self.flip.y)

			-- draw player
			local px = self.x + self.hitbox.w / 2 - 4
			local py = self.y + self.hitbox.h / 2 - 4
            spr(self.k_player, px, py, 1, 1, self.flip.x, self.flip.y)

			palt(0, true)
			palt(11, false)
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

function start_game()
	states:update_state(states.game)
	player = create_player(20, 20)
end

states = {
	state = nil,
	start = {
		_update = function()
			if (btn(5)) start_game()
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
		end,
		_draw = function()
			cls()
			map()
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

function _init()
	states:update_state(states.start)
end

__gfx__
00000000ccccccccffffffffccccccccbbbbbbbbbbbbbbbbbbbbbbbb445f44544454bbbbf4444f44444ff4440000000000000000000000000000000000000000
00000000ccccccccffffffffccccccccbb0000bbbb0000bbbb006bbb4f5f44544f54bbbbff4f444f4f4444f40000000000000000000000000000000000000000
00700700ccccccccffffffffccccccccbb6006bbbb0000bbbb0009bb4454f454f45fbbbb55555555555555550000000000000000000000000000000000000000
00077000ccccccccffffffffccccccccbb0990bbbb0000bbbb000bbbf454f454f45fbbbbff4444ff444444ff0000000000000000000000000000000000000000
00077000ccccccccffffffffccccccccb000000bb000000bbb007bbbf45444544454bbbbf444ff444f44ff440000000000000000000000000000000000000000
00700700ccccccccffffffffccccccccbb0770bbbb0000bbbb007bbb445444544454bbbbff444444444444440000000000000000000000000000000000000000
00000000ccccccccffffffffccccccccbb0770bbbb0000bbbb007bbb4f54f454f45fbbbb55555555555555550000000000000000000000000000000000000000
00000000ccccccccffffffffccccccccbb9779bbbb9009bbbb009bbb44544454f45fbbbbff444444444444440000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000004f5f44544f54bbbbf444ff44ff44ff440000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000445f44544f54bbbbff4444ff444444f40000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000f454f454f45fbbbb55555555555555550000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000004454f454f454bbbbf4444f44ff44ff440000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000004f5444544454bbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000445444544454bbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000004f5f4f5f4f54bbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000ff5fff5fff5fbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000
__map__
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0303030303030303030303030303030300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
