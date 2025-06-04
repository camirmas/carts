pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
	game = create_game()
end

function _update()
	update_game()
end

function _draw()
	draw_game()
end
-->8
-- game

debug = false

-- states
state_init = "init"
state_play = "play"

-- maximum room size
room_width = 16
room_height = 16

function create_game()
	local g = {
		state = state_play,
		player = create_player(10, 24),
		level = 1,
		moves = 0,
		objects = {}
	}
	
	for w=0,room_width-1 do
		for h=0,room_height-1 do
			local tile = mget(w, h)
			local f = fget(tile)
			
			if f == 1 then
				local obj = {
					x = w * 8, 
					y = h * 8, 
					w = 8,
					h = 8,
					ox = 0,
					oy = 0,
					kind="wall",
				}
				add(g.objects, obj)	
			end
		end
	end
	
	printh("objects: " .. #g.objects)
	
	return g
end

function update_game()
	if game.state == state_init then
	
	elseif game.state == state_play then
		update_player(game.player)	
	end
	
	-- camera will be set to level loc
	camera(0, 0)
end

function draw_game()
	cls()
	
	map()
	
	if debug then
		for obj in all(game.objects) do
			local x0 = obj.x + obj.ox
			local y0 = obj.y + obj.oy
			rect(x0, y0, x0 + obj.w - 1, y0 + obj.h - 1, 11) 
		end
	end
	
	draw_player(game.player)
	
	print("state: " .. game.player.state)
	print("charge: " .. game.player.charge)
	print("vx: " .. game.player.vx .. ", vy: " .. game.player.vy)
end
-->8
-- player

state_stopped = "stopped"
state_charge = "charging"
state_launch = "launching"
state_glide = "gliding"
state_respawn = "respawning"

function create_player(x, y)
	return {
		x = x,
		y = y,
		vx = 0,
		vy = 0,
		vx_max = 2,
		vy_max = 2,
		
		-- glide control
		acc = .05,
		glide_ctrl_time = 0,
		glide_ctrl_timer = 30,
		
		-- movement remainder
		rem_x = 0,
		rem_y = 0,
		
		charge = 0,
		charge_rate = 1/30,
		discharge_rate = 1/15,
		
		dec = .1, -- decel
		
		aim_x = 0,
		aim_y = 0,
		
		state = state_stopped,
		
		-- sprite
		k = {1, 2, 3},
		
		-- bounding box
		w = 8,
		h = 8,
		ox = 0,
		oy = 0,
	}
end

function update_player(player)
	local state = player.state
	
	local btn_⬅️ = btn(⬅️)
	local btn_➡️ = btn(➡️)
	local btn_⬆️ = btn(⬆️)
	local btn_⬇️ = btn(⬇️)
	local btn_🅾️ = btn(🅾️)
	local btn_❎ = btn(❎)
	
	if state == state_stopped then
		player.aim_x = 0
		player.aim_y = 0
		
		-- left
		if btn_⬅️ then
			player.aim_x = -1
		end
		
		-- right
		if btn_➡️ then
			player.aim_x = 1
		end
		
		-- up
		if btn_⬆️ then
			player.aim_y = -1
		end
		
		-- down
		if btn_⬇️ then
			player.aim_y = 1
		end
		
		local is_aiming = player.aim_x != 0 or player.aim_y != 0 
		
		-- button_o
		if btn_🅾️ and is_aiming then
			player.state = state_charge
		end
	elseif state == state_charge then	
		if btn_🅾️ then
			player.charge += player.charge_rate
			
			if (player.charge > 1) player.charge = 1
		else
			player.state = state_launch
		end
	elseif state == state_launch then
		local charge, vx_max, vy_max = player.charge, player.vx_max, player.vy_max
		player.vx += charge * player.aim_x
		player.vy += charge * player.aim_y
		player.charge -= player.discharge_rate
		
		local vx, vy = player.vx, player.vy
		
		player.vx = mid(vx, -vx_max, vx_max)
		player.vy = mid(vy, -vy_max, vy_max)
		
		move_x(player, player.vx)
		move_y(player, player.vy)
		
		if player.charge <= 0 then
			player.charge = 0
			player.state = state_glide
		end
	elseif state == state_glide then
		if player.glide_ctrl_time < player.glide_ctrl_timer then
			local acc = player.acc
			
			if btn_⬆️ then
				player.aim_y = -1
				player.vy -= acc
			end
			
			if btn_⬇️ then
				player.aim_y = 1
				player.vy += acc
			end
			
			if btn_⬅️ then
				player.aim_x = -1
				player.vx -= acc
			end
			
			if btn_➡️ then
				player.aim_x = 1
				player.vx += acc
			end
			
			player.glide_ctrl_time += 1
		end
		
		local dec = player.dec
		player.vx *= (1 - dec)
		player.vy *= (1 - dec)
		
		local vx, vy, vx_max, vy_max = player.vx, player.vy, player.vx_max, player.vy_max
		
		player.vx = mid(vx, -vx_max, vx_max)
		player.vy = mid(vy, -vy_max, vy_max)
		
		move_x(player, vx)
		move_y(player, vy)
		
		if abs(vx) < .05 and abs(vy) < .05 then
			player.vx = 0
			player.vy = 0
			player.state = state_stopped
			player.glide_ctrl_time = 0
			game.moves += 1
			printh("moves: " .. game.moves)
		end
	end
end

function draw_player(player)
	-- draw aim arrows
	local x, y, k, aim_x, aim_y = player.x, player.y, player.k, player.aim_x, player.aim_y
	
	-- left/right
	if aim_x != 0 and aim_y == 0 then
		spr(k[2], x, y, 1, 1, aim_x == -1, false)
	-- up/down
	elseif aim_x == 0 and aim_y != 0 then
		spr(k[1], x, y, 1, 1, false, aim_y == 1)
	-- diagonal
	elseif aim_x != 0 and aim_y != 0 then
		spr(k[3], x, y, 1, 1, aim_x == -1, aim_y == -1)
	else
		spr(k[1], x, y)
	end
end

function move_x(player, amt)
	player.rem_x += amt
	local move = flr(player.rem_x + .5)
	
	if move != 0 then
		player.rem_x -= move
		local s = sign(move)
		
		while move != 0 do
			local px = player.x
			player.x += s
			
			local collided = false
			for obj in all(game.objects) do
				if (collide(player, obj)) collided = true
			end
			
			if collided then
				player.x = px
				return
			else
				move -= s
			end
		end
	end
end

function move_y(player, amt)
	player.rem_y += amt
	local move = flr(player.rem_y + .5)
	
	if move != 0 then
		player.rem_y -= move
		local s = sign(move)
	
		while (move != 0) do
			local py = player.y -- keep prev
			player.y += s
			
			local collided = false
			for obj in all(game.objects) do
				if (collide(player, obj)) collided = true
			end
			
			if collided then
				player.y = py
				return
			else
				move -= s
			end
		end
	end
end
-->8
-- utils

function collide(a, b)
	local ax1 = a.x + a.ox
 local ay1 = a.y + a.oy
 local ax2 = ax1 + a.w
 local ay2 = ay1 + a.h

 local bx1 = b.x + b.ox
 local by1 = b.y + b.oy
 local bx2 = bx1 + b.w
 local by2 = by1 + b.h

 return not (ax2 <= bx1 or ax1 >= bx2 or ay2 <= by1 or ay1 >= by2)
end

function sign(x)
	if (x < 0) return -1
	if (x > 0) return 1
	return 0
end
__gfx__
000000000067760000006000007000000000000000000000dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
000000000677776070067660700700000000000000000000dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
007007000677776007677776070676600000000000000000dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
000770006777777670777777076777760000000000000000dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
000770000677776007777777707777760000000000000000dddd0000000000000000dddd0000dddddddd00000000000000000000000000000000000000000000
007007000067760007677776076777770000000000000000dddd0000000000000000dddd0000dddddddd00000000000000000000000000000000000000000000
000000000070770070067660006777760000000000000000dddd0000000000000000dddd0000dddddddd00000000000000000000000000000000000000000000
000000000707007000006000000667600000000000000000dddd0000000000000000dddd0000dddddddd00000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000dddd0000000000000000dddd0000dddddddd00000000000000000000000000000000000000000000
000000000000000000000000095a00000000000000000000dddd0000000000000000dddd0000dddddddd00000000000000000000000000000000000000000000
0000000000000000000000000999a0000000000000000000dddd0000000000000000dddd0000dddddddd00000000000000000000000000000000000000000000
00000000000000000000000006999a000000000000000000dddd0000000000000000dddd0000dddddddd00000000000000000000000000000000000000000000
000000000000000000000000006999000000000000000000dddd0000000000000000dddd00000000000000000000000000000000000000000000000000000000
000000000000000000000000000699960000000000000000dddd0000000000000000dddd00000000000000000000000000000000000000000000000000000000
000000000000000000000000000009600000000000000000dddd0000000000000000dddd00000000000000000000000000000000000000000000000000000000
000000000000000000000000000006000000000000000000dddd0000000000000000dddd00000000000000000000000000000000000000000000000000000000
00000000007777000000000000000000000000000dd00dd0dddd0000000000000000dddd00000000000000000000000000000000000000000000000000000000
00000000070000700000000000000000000000000d10001ddddd0000000000000000dddd00000000000000000000000000000000000000000000000000000000
00000000700700070000000e000000000000000000dd100ddddd0000000000000000dddd00000000000000000000000000000000000000000000000000000000
0000000070700007e08e0e0e000000000000000000d100dddddd0000000000000000dddd00000000000000000000000000000000000000000000000000000000
000000007000000708e000e00000000000000000d000001ddddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
00000000700000070e000e800000000000000000dd0dd001dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
000000000700007000e08e000000000000000000d100d100dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
0000000000777700000ee0000000000000000000000d1100dddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
__gff__
0000000000000101010101000000000000000000000001010101010000000000000002000001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2525252525252525252525250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000000000000000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000000000000000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000000000000000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000000000000000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2500000000000000000000250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2525252525252525252525250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
