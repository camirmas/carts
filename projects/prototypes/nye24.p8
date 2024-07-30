pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

debug = {}

G = 1
N_PARTICLES = 1000
SNOW_COLORS = {1, 5, 6, 7, 13}
FIREWORK_COLORS = {
	{8, 9},
	{12, 14},
	{7, 12},
}
STAR_COLORS = {
	{7, 12},
	{12, 14},
	{8, 9, 10},
}

particles = {}
stars = {}
fireworks = {}

function random_sign()
	if rnd() < 0.5 then	
		return -1
	else
		return 1
	end
end

function create_firework(n)
	local x0 = 128/2
	local y0 = 128
	local m_i = flr(rnd(#FIREWORK_COLORS)) + 1
	local m_c = FIREWORK_COLORS[m_i]

	local firework = {
		id = n,
		color = flr(rnd(FIREWORK_COLORS[m_i])),

		t = 0,
		dt = 1,

		x = x0,
		y = y0,
		-- vx = random_sign() * rnd(),
		a = {x = random_sign() * .02, y = 0},
		v = {x = 0, y = -2},
		tail = {},
		explosion = {},
		exploded = false,
		lifetime = 45,

		update = function(self)
			if self.y < 50 or self.x < 30 or self.x > 100 or self.t > self.lifetime then
				self:explode()
			else
				self.v.x += self.a.x * self.dt
				self.v.y += self.a.y * self.dt

				self.x += self.v.x * self.dt
				self.y += self.v.y * self.dt
			end

			local len_tail = #self.tail

			if self.t + 10 > self.lifetime and len_tail > 0 then
				local p = self.tail[len_tail]
				del(self.tail, p)
			elseif len_tail >= 15 then
				local p = self.tail[len_tail]
				del(self.tail, p)
			else
				add(self.tail, {x=self.x, y=self.y}, 1)
			end

			for exp in all(self.explosion) do
				exp:update()
			end

			self.t += self.dt
		end,

		draw = function(self)
			if (not self.exploded) circfill(self.x, self.y, 1, self.color)

			local s_pairs = {}

			for i=1,#self.tail do
				if self.tail[i + 1] != nil then
					local c = m_c[flr(rnd(#m_c)) + 1]
					
					local p1 = self.tail[i]
					local p2 = self.tail[i + 1]

					line(p1.x, p1.y, p2.x, p2.y, c)
				end
			end

			for exp in all(self.explosion) do
				exp:draw()
			end
		end,

		explode = function(self)
			if self.exploded then return end
			self.exploded = true

			local dtheta = .05
			local theta = 0

			while theta < 1 do
				local exp = {
					x = self.x,
					y = self.y,
					a = {x = 0, y = .025},
					v = {x = 0, y = -1},
					theta = theta,
					color = self.color,
					t = 0,
					lifetime = 30 * 2,
					dt = 1,

					update = function(e)
						if e.x < 0 or e.x > 128 or e.y < 0 or e.y > 128 or e.t > e.lifetime then
							del(self.explosion, e)
						end

						e.v.x += e.a.x * e.dt
						e.v.y += e.a.y * e.dt

						e.x += e.v.x * e.dt + e.dt * 0.5 * cos(e.theta)
						e.y += e.v.y * e.dt + e.dt * 0.5 * sin(e.theta)

						e.t += e.dt
					end,

					draw = function(e)
						-- add(debug, "draw x: " .. e.x .. ", y: " .. e.y)
						pset(e.x, e.y, e.color)
					end
				}	

				theta += dtheta

				add(self.explosion, exp)
			end
		end,
	}

	add(fireworks, firework)
end

function create_particle(n)
	local particle = {
		color = SNOW_COLORS[flr(rnd(#SNOW_COLORS)) + 1],
		x0 = rnd(128),
		x = 0,
		y = 0,

		-- SHM: A * cos(wt + phi)
		A_x = 1,
		A_y = .01,
		omega_x = .05,
		omega_y = .05,
		t = 0,
		lifetime = 10 * 30, -- 10sec
		dt = .5,

		-- translational
		vx = .2 + random_sign() * rnd(),
		vy = random_sign() * rnd(G),

		update = function(self)
			self.x = self.vx * self.t + self.A_x * cos(self.omega_x * self.t) + self.x0
			self.y = self.vy * self.t + self.A_y * sin(self.omega_y * self.t)

			if self.y > 128 or self.x > 128 or self.x < 0 or self.t > self.lifetime then
				del(particles, self)	
			end

			-- change colors over lifetime?

			self.t += self.dt
		end,

		draw = function(self)
			pset(self.x, self.y, self.color)	
		end
	}

	add(particles, particle)
end

function create_particles(n)
	local particles = {}

	for i=1,n do
		create_particle(n)
	end
end

function update_particles()
	for p in all(particles) do
		p:update()
	end
end

function draw_particles()
	for p in all(particles) do
		p:draw()
	end
end

function update_fireworks()
	for m in all(fireworks) do
		m:update()
	end
end

function draw_fireworks()
	for m in all(fireworks) do
		m:draw()
	end
end

function create_stars()
	-- make constellations?
	for i=1,15 do
		local star = {
			id = i,
			x = rnd(128),
			y = rnd(128),
			color = STAR_COLORS[i % 2 + 1][flr(rnd(#STAR_COLORS)) + 1],

			update = function(self)
				local idx = rnd() < .5 and 1 or 2
				self.color = STAR_COLORS[(self.id % 2) + 1][flr(rnd(#STAR_COLORS)) + 1]
			end,

			draw = function(self)
				pset(self.x, self.y, self.color)
			end
		}		

		add(stars, star)
	end
end

function update_stars()
	for s in all(stars) do
		s:update()
	end
end

function draw_stars()
	for s in all(stars) do
		s:draw()
	end
end

function _init()
	create_stars()

	music()
end

t = 0
firework_id = 0

function _update()
	update_particles()	
	update_stars()
	update_fireworks()

	if t % (30 * 2) == 0 then
		create_firework(firework_id)		

		t = 0
		firework_id += 1
	end

	if #particles < N_PARTICLES then
		create_particles(5)
	end

	t += 1
end

function _draw()
	cls(0)

	map()
	
	draw_stars()
	draw_fireworks()
	draw_particles()

	local dx = 2
	local dy = 2

	for d in all(debug) do
		print(d, dx, dy)

		dy += 6
	end
end
__sfx__
911800000c053000030b0000c053336150c0030c000336150c0530c0000c0530c000336153f6000c0003f6000c053000030b0000c053336150c0030c000336150c0530c0000c0530c000336150c0530c00033615
491800003f3003f3003f3000c3053f3003f3003f3003f3003f3003f3153f3003f3153f3003f3003f300153053f3003f300153053f3003f3003f30015305153053f315153053f3001530515305153051530500000
4b1800003f6053f6153f6003f6053f6003f6153f6053f6053f6003f6153f6053f6153f6053f6153f6003f615006053f6153f600116053f6003f6151160511605116053f6153f6003f6153f6003f6003f6153f615
481800000274202722027420272202715027020274202722027150770202742027220271502702027420273206742067220674206722067150970206742067220671502702067420672206715027020674206722
4f180000267541e70423704187041a70423704217041e7041a70423704217040000000000007042f754217042f754217042d7542a7541e7042d75425754007040000000000000000000000000000000000000000
4f180000267541e70423704187041a70423704217041e7041a70423704217040000000000007042f754217042f754217042d7542a7541e7042d7542575400704000002d75400000000002a754000002875400000
4f180000267541e70423704187041a70423704217041e7041a70423704217040000000000007042f754217042f754217042d7542a7541e7042d754257540070400000000002d754000002a754000002875400000
__music__
01 00024144
00 00024144
00 00020344
00 00020344
01 00020304
00 00020306
00 00020304
02 00020305
02 00020305

