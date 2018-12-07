-- Grid Module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This module devides the world in a grid, with a connecting piece inbetween.

global.grid = global.grid or {}
global.grid.seed = 1
global.grid.size = 64
global.grid.x_border_width = 5
global.grid.y_border_width = 5
global.grid.x_bridge_width = 3 -- width * 1.5 ??
global.grid.y_bridge_width = 3

-- Grid Ore Module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This module is an extention to the grid module and is able to place ores / oil in certain "Grid chunks"
global.grid_ore = global.grid_ore or {}
global.grid_ore.resource_chance = 40
global.grid_ore.ore_start_amount = 225
global.grid_ore.ore_random_addition_amount = 450
global.grid_ore.oil_start_amount = 100000
global.grid_ore.oil_random_addition_amount = 200000
global.grid_ore.oil_spout_chance = 1


function grid_ore_place_ore_in_grid_chunck(location, ore)
    xoffset = (math.floor(location.x/global.grid.size))*global.grid.size
    yoffset = (math.floor(location.y/global.grid.size))*global.grid.size
    local distance_factor = math.log(math.max(math.abs(location.x/global.grid.size), math.abs(location.y/global.grid.size), 1.1))^2
    local random_factor = distance_factor / 10
    local ore_amount = 0
    for y=global.grid.y_border_width,global.grid.size-1 do
        for x=global.grid.x_border_width,global.grid.size-1 do
            ore_amount = math.ceil((global.grid_ore.ore_start_amount * distance_factor) + (math.random(global.grid_ore.ore_random_addition_amount)*random_factor))
            game.surfaces["nauvis"].create_entity({name=ore, amount=ore_amount, position={x+xoffset, y+yoffset}})
        end
    end
end

function grid_ore_place_oil_in_grid_chunck(location)
    xoffset = (math.floor(location.x/global.grid.size))*global.grid.size
    yoffset = (math.floor(location.y/global.grid.size))*global.grid.size
    local distance_factor = math.log(math.max(math.abs(location.x/global.grid.size), math.abs(location.y/global.grid.size), 1.1))^2
    local random_factor = distance_factor / 10
    local oil_amount = 0
    for y=global.grid.y_border_width,global.grid.size-1 do
        for x=global.grid.x_border_width,global.grid.size-1 do
            if math.random(200) <= global.grid_ore.oil_spout_chance then
                oil_amount = math.ceil((global.grid_ore.oil_start_amount * distance_factor) + (math.random(global.grid_ore.oil_random_addition_amount)*random_factor))
                game.surfaces["nauvis"].create_entity({name="crude-oil", amount=oil_amount, position={x+xoffset, y+yoffset}})
            end
        end
    end
end

function grid_ore_generate_resources(location)
    if(math.random(global.grid_ore.resource_chance ) == 1) then
        rndm = math.random(13)-1
        if(rndm <= 1) then
            grid_ore_place_ore_in_grid_chunck(location, "stone")
        elseif (rndm >= 2 and rndm <= 4) then
            grid_ore_place_ore_in_grid_chunck(location, "iron-ore")
        elseif (rndm >= 5 and rndm <= 7) then
            grid_ore_place_ore_in_grid_chunck(location, "copper-ore")
        elseif (rndm >= 8 and rndm <= 10) then
            grid_ore_place_ore_in_grid_chunck(location, "coal")
        elseif (rndm == 11) then
            grid_ore_place_oil_in_grid_chunck(location)
        elseif (rndm == 12) then
            grid_ore_place_ore_in_grid_chunck(location, "uranium-ore")
        end
    end
end

function grid_replace_tiles_in_chunk(area)
    local topleftx = area.left_top.x
    local toplefty = area.left_top.y
    local bottomrightx = area.right_bottom.x
    local bottomrighty = area.right_bottom.y
    local tileTable = {}
    for i=toplefty,bottomrighty do
        for j=topleftx,bottomrightx do
            for k=0,global.grid.x_border_width-1 do
                if(j % global.grid.size == k and
                        (((i+global.grid.size/2) % global.grid.size)-(math.floor(global.grid.x_bridge_width/2))) >= global.grid.x_bridge_width) then
                    table.insert(tileTable,{ name = "out-of-map", position = {j, i}})
                end
            end
            for k=0,global.grid.y_border_width-1 do
                if(i % global.grid.size == k and
                        (((j+global.grid.size/2) % global.grid.size)-(math.floor(global.grid.y_bridge_width/2))) >= global.grid.y_bridge_width) then
                    table.insert(tileTable,{ name = "out-of-map", position = {j, i}})
                end
            end
        end
    end
    game.surfaces["nauvis"].set_tiles(tileTable)
    --Suppress normal resource generation.  Doesn't work because the grid ore is spawned in one big pass.
    -- for _, ore in pairs(game.surfaces[1].find_entities_filtered{type="resource", area=area}) do
    -- 	ore.destroy()
    -- end
    grid_ore_generate_resources({x = topleftx, y=toplefty})
end

Event.register(defines.events.on_chunk_generated, function(event)
    grid_replace_tiles_in_chunk(event.area)
end)

Event.register(defines.events.on_player_created, function(event)
    local p = game.players[event.player_index]
    local surface = game.surfaces["nauvis"]
    p.teleport(surface.find_non_colliding_position("player", {x = math.floor(global.grid.size/2), y = math.floor(global.grid.size/2)}, 3, 1))
end)
