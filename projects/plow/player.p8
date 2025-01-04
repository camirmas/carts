function init_player()
    local player = {}

    player.x = 2 * 8
    player.y = 3 * 8
    player.vel = { x = 0, y = 0 }
    player.accel = .1
    player.friction = 0.9
    player.spr = 1
    player.max_speed = 3

    return player
end

function update_player(player)
    local new_speed = { x = player.vel.x, y = player.vel.y }

    if btn(0) then
        new_speed.x -= player.accel
    end
    if btn(1) then
        new_speed.x += player.accel
    end
    if btn(2) then
        new_speed.y -= player.accel
    end
    if btn(3) then
        new_speed.y += player.accel
    end

    if not btn(0) and not btn(1) and not btn(2) and not btn(3) then
        new_speed.x *= player.friction
        new_speed.y *= player.friction
    end

    if abs(new_speed.x) > player.max_speed then
        new_speed.x = sgn(new_speed.x) * player.max_speed
    end
    if abs(new_speed.y) > player.max_speed then
        new_speed.y = sgn(new_speed.y) * player.max_speed
    end

    player.vel = new_speed

    player.x += new_speed.x
    player.y += new_speed.y
end

function draw_player(player)
    spr(player.spr, player.x, player.y)
end