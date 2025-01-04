function init_game(snow)
    return {
        player = init_player(),
        snow = init_snow(),
    }
end

function update_game(game)
    update_player(game.player)
    update_snow(game.snow)
end

function draw_game(game)
    cls()

    map()

    draw_player(game.player)
    draw_snow(game.snow)
end