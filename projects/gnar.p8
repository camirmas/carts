pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

gravity = .4
g = 1 -- Z gravity
pxi = 8*8
pyi = 1*8
player_load = 0

trail = {}
particles = {}

tile_types = {solid = 0, jib = 1}

debug = ""

function lerp(a, b, t)
    return a + (b - a) * t
end

function gauss_rng()
    local sum = 0
    for i=1,12 do
        sum = sum + rnd(1)
    end
    return sum - 6
end

function is_tile(type, x, y)
    return fget(mget(x, y), tile_types[type])
end

function make_particles(n)
    for i=1, n do
        local color = 6
        if p.grinding then
            color = rnd(15) + 1
        end

        local part = {
            x = p.x + 4 + gauss_rng(),
            y = p.y + 2 + gauss_rng(),
            vx = 0.05 * gauss_rng(),
            vy = 0.05 * gauss_rng(),
            t = 0, -- time alive
            lifetime = rnd(30 * 1.25), -- sec @ 30fps
            col = color -- color
        }
        add(trail, part)
    end
end

function make_explode(n)
    for i=1, n do
        local part = {
            x = p.x + 4 + gauss_rng(),
            y = p.y + 2 + gauss_rng(),
            vx = 0.1 * gauss_rng(),
            vy = 0.2 * gauss_rng(),
            t = 0, -- time alive
            lifetime = rnd(30 * 1.5), -- sec @ 30fps
            col = 6 -- color
        }
        add(particles, part)
    end
end

function update_particles()
    for part in all(trail) do
        part.t = part.t + 1

        if part.t >= part.lifetime then
            del(trail, part)
        else
            part.x = part.x + part.vx
            part.y = part.y + part.vy
        end
    end

    for part in all(particles) do
        part.t = part.t + 1

        if part.t >= part.lifetime then
            del(particles, part)
        else
            part.x = part.x + part.vx + gauss_rng()
            part.y = part.y + part.vy + .05
        end
    end

    if not p.jumping then
        make_particles(p.vy * 2 + abs(p.vx))
    end
end

function update_player()
    if player_load > 0 then
        player_load = player_load - 1
        return
    end

    local s = 7
    local down_speed = 0.0001 -- adjust to change how fast the player transitions to moving down

    -- Decrease horizontal speed and increase vertical speed over time when no button is pressed
    if not (btn(0) or btn(1) or btn(2) or btn(3)) then
        p.vx = max(0, p.vx - down_speed) -- Gradually decrease vx to 0
        p.vy = min(3, p.vy + down_speed * p.vy + .02) -- Accelerate vy, speed increases slowly initially and faster later
        p.target_dir = {0, 1} -- Gradually change target direction to moving down
    end

    if btn(0) then
        p.target_dir = {-1, 0} -- left
        p.vx = 2
        p.vy = max(.5, p.vy - .01 * p.vx)
        s = 9 
    end

    if btn(1) then
        p.target_dir = {1, 0} -- right
        p.vx = 2
        p.vy = max(.5, p.vy - .01 * p.vx)
        s = 8
    end
     
    if btn(2) then
        p.target_dir = {0, -1} -- up: slow down
        p.vy *= .9
        s = 10
    end

    if btn(3) then
        p.target_dir = {0, 1} -- down: speed up
        s = 7
    end

    if btn(4) and not p.jumping then
        debug = "jumping"
        p.jumping = true
        sfx(0)
        p.z = 15 -- jump frames
    end

    local turn_speed = 0.1 -- adjust this value to change how fast the player turns
    p.dir[1] = lerp(p.dir[1], p.target_dir[1], turn_speed)
    p.dir[2] = lerp(p.dir[2], p.target_dir[2], turn_speed)

    p.sprite = s

    if p.grinding then
        if collide(p, "jib") then
            p.sprite = 11
            p.vx = 0
        else
            p.grinding = false
        end
    end

    p.x = p.x + p.vx * p.dir[1]
    p.y = p.y + p.vy * p.dir[2]

    debug = "vx: " .. p.vx * p.dir[1] .. ", vy: " .. p.vy * p.dir[2]

    if p.jumping then
        local pz = p.z - g
        if pz >= 0 then
            p.z = pz

            if collide(p, "jib") then
                p.jumping = true
                p.grinding = true
            end
        else
            p.z = 0
            p.jumping = false
            sfx(1)
            -- debug = "end jump"
        end
    else
        if not p.grinding and collide(p, "solid") then
            -- debug="collide"
            make_explode(40)
            player_load = 30
            reset_player() 
            sfx(2)
        end
    end
end

function collide(o, tile_type)
    local off = 3 -- hardcoded player offset to 3 for now
    local x1 = (o.x + off) / 8
    local y1 = o.y / 8
    local x2 = (o.x + 7 - off) / 8
    local y2 = (o.y + 7) / 8

    local f = tile_types[tile_type]

    local a = fget(mget(x1, y1), f)
    local b = fget(mget(x1, y2), f)
    local c = fget(mget(x2, y2), f)
    local d = fget(mget(x2, y1), f)

    if a or b or c or d then
        return true
    else
        return false
    end
end

function reset_player()
    p.x = pxi
    p.y = pyi
    p.vx = 0
    p.vy = 0.1
end

function _init()
    p = {
        x = pxi,
        y = pyi,
        z = 0,
        vx = 0,
        vy = 0.1,
        jumping = false,
        grinding = false,
        sprite = 10,
        dir = {0, -1}, -- direction
        target_dir = {0, -1} -- target direction
    }
end

function _update()
    update_player()
    update_particles()
end

function _draw()
    cls()
    if player_load == 0 then
        camera(p.x - 63 + 4, p.y - 63 + 4)
    end
    map()

    for part in all(trail) do
        circfill(part.x, part.y, 0, part.col)
    end

    for part in all(particles) do
        circfill(part.x, part.y, 0, part.col)
    end

    print(debug, p.x - 63 + 8, p.y - 63 + 8)

    -- draw shadow
    if p.jumping then
        spr(27, p.x, p.y + p.z / 4) -- Draw shadow sprite, assuming shadow sprite is 11
    end

    -- draw player
    if player_load == 0 then
        spr(p.sprite, p.x, p.y - p.z) -- Adjust player's y position based on jump height
    end
end

__gfx__
00000000777777777777777777777777776777677777777779999997000000000000000000000000000000000000000000000000000000000000000077777776
000000007777777777777777777b3777777777777777777779900997000220000022000000002200000220000002200000000000000000000000000077777776
007007007777777777755777777b3777767777777767777779900997000aa00000fa00000000af00000aa000000aa00000000000000000000000000077777776
000770007777777777dd557777bbb377777677677776777779900997000ff00000ff00000000ff00000ff000000ff00000000000000000000000000077777776
0007700077777777766dd57777bbb377777777777777777779999997000550000555500000055550005555000055550000000000000000000000000077777776
007007007777777776666d577bbb3337777777777777776779900997000950009055900000905590009559000905509000000000000000000000000077777776
00000000777777777777777777744777767776777777767779999997000cc00000c0c000000c0c00000cc00000c00c0000000000000000000000000077777776
00000000777777777777777777544777777777777777777777755777000880000888888008888880088888800888888000000000000000000000000077777776
7777766666666666666666666677777777777777777777777777777777777777777777777777777777777777000000007777777777777775dddddddd67676767
7777655555555555555555555567777777777777777557777777777777677777777777777777777755777777000550007777777777777775dddddddd66666666
777653c1c3c143c11c341c3c1c567777777777777755557777777777766766777777777777777775555777770055550077777775777777756666666676767676
77651c141c1c1c14c1c1c1c141c56777777777777555555777755777777777777777777777777755555777770555555077777775777777756666666667676767
76513111311131111113111311135677777777777555555777755777776767676777777677777577555777770555555077777775777777756667666776767676
765111c111c111c11c111c111c115677777777777755557777777777777777775677776577775575575577770055550077777775777777757676767667676767
65111111111111111111111111111567777777777775577777777777676767767566665777755555557577770005500077777775777777756767676776777677
6511c111c1111c11111c111c111c1567777777777777777777777777777777777777777777555555755757770000000077777775777777557676767667776777
6511c111cc11c111c111c111c111c567764444777444447777767777777767777777777777d57557555557770000000077777777777777777777777777777777
65111111111111111111111111111567774444777644447777676777777676777777777777dd5755555557770000000077777777777777777777777777777777
65c111c111c111c111c111c111c11567764444477744447776767777777767677777777777ddd555557555770000000077777777c77777777777777c77777777
6511311131113111311131113111356777444474764444446767777777777676c777777c766ddddd555755770000000077777777c77777777777777c77777777
65141c1c1c141c1c1c1c1c141c14567774444477744444777677777777777767cccccccc7666dd7dd55555770000000067676767c76767676767676c77777777
7651c3c143c1c34143c143c1c3c56777764ff47746444477677777777777777666666666766666dddd5575770000000076767676c67676767676767c67676767
7765555555555555555555555556777777ffff77774444477777777777777777666666666666666dddd555670000000066666666c66666666666666c76767676
7776666666666666666666666667777776ffff7776444477777777777777777777777777666666666dddddd700000000cccccccccccccccccccccccc66666666
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
10101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010
__gff__
0000010100000000000000000000000001010101000000000001010000000000010101010303000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010301010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101020101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0102010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010401010106010101010301050101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0501030101010101011801050103010301010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010301010103012501010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0103010101010101012501010103010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0102010301040101012401020101010301010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0103010101010103011701010103010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101050101010101010101010101010401010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010314141401030104010103010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101030101010101010101010101030101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101030101010102010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
040103012d2c2e01010101010101010301010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
010101051e1e1e05030101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010504040405010101010103010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101030105010501010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010501050105010118010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010f05050501010125010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
010101051f1f1f05010125010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010504040405010125010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010125010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010125010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010125010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010125010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010125010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010124010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010117010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
0101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101010101
__sfx__
480500000063005630136300f60010600086000160000600006002060024600286002a60000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
490500000060000640006300062000600006002760027600276002860015600166001760018600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
9b01000011330113301133011330103300e3300d3300c3300b3300833008330073300533003330003300033000330003000030000300053000430001300013000030000300043000630005300053000530005300
9110002000350003500000000000003500035014300123000f3000c30004350043500430002300003000030002350023500030000300023500235000300003000000000000043500435000000000000000000000
4d1000003662500600006003662500000000003662500600366250060000600006003662536625006000060036625006000060000600006000060036625006003662500600006000060036625366250060000000
011000002d050000002b0500000000000000002d050000002b0500000000000230502305000000240500000028050000000000000000000000000000000000002105000000000001f0501f050000002105000000
__music__
02 03040544

