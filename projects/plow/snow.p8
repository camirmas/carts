function init_snow()
    local snow = {}

    snow.flakes = {}
    for i = 1, 100 do
        add(
            snow.flakes, {
                x = rnd(128),
                y = rnd(128),
                speed = {x = rnd(0.5), y = rnd(0.5) + 0.5},
                period = rnd(60) + 30,
                t = 0
            }
        )
    end

    return snow
end

function update_snow(snow)
    for flake in all(snow.flakes) do
        flake.y += flake.speed.y
        flake.x += flake.speed.x * cos(1 / flake.period * flake.t)
        flake.t += 1

        if flake.y > 128 then
            flake.y = 0
        end
        if flake.x > 128 then
            flake.x = 0
        end
        if flake.x < 0 then
            flake.x = 128
        end
    end
end

function draw_snow(snow)
    for flake in all(snow.flakes) do
        pset(flake.x, flake.y, 7)
    end
end