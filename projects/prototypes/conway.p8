pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
t = 0
debug = ""

function get_neighbors(x, y)
    local neighbors = {}

    for i=-1,1 do
        for j=-1,1 do
            if not (i == 0 and j == 0) then
                if x > 0 and x < ngrid and y > 0 and y < ngrid then
                    local c = grid[x+i][y+j]
                    add(neighbors, c)
                end
            end
        end
    end

    return neighbors
end

function update_cell(c, neighbors)
    local alive = 0      

    for n in all(neighbors) do
        if n == 1 then
            alive += 1
        end
    end

    if c == 1 and (alive == 2 or alive == 3) then
        c = 1
    elseif c == 0 and (alive == 3) then
        c = 1
    else
        c = 0
    end

    return c
end

function create_grid()
    ngrid = 127
    local g = {}

    for x=0, ngrid do
        g[x] = {}
        for y=0, ngrid do
            g[x][y] = 0
        end
    end

    return g
end

function _init()
    grid = create_grid()

    for i=1,2000 do
        local x = flr(rnd(ngrid))
        local y = flr(rnd(ngrid))

        grid[x][y] = 1
    end
end

function _update()
    local updates = {}

    for x=1,ngrid do
        for y=1,ngrid do
            -- update cell
            local c = grid[x][y]

            local n = get_neighbors(x, y)
            local new_c = update_cell(c, n)
            updates[{x, y}] = new_c
        end
    end

    for u, v in pairs(updates) do
        grid[u[1]][u[2]] = v
    end

    t += 1
end

function _draw()
    cls()

    map(0, 0, 0, 0, 16, 16)

    local alive = 0
    for x=1,ngrid do
        for y=1,ngrid do
            local c = grid[x][y]
            if c == 1 then
                alive += 1
                circfill(x, y, 0, 7)
            end
        end
    end

    rectfill(0, 0, 50, 18, 5)
    print("alive: " .. alive, 1, 3, 7)
    print("time: " .. t, 1, 11, 7)
    -- print(debug, 0, 16, 7)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
