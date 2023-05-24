--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    keyspawned=false        --flag that denotes if the key has been spawned or not
    keycollected=false      --flag that denotes if the key has been collected or not
    lockspawned = false     --flag that denotes if the lock has been spawned or not

    levelwidth= width       --stored the width of the level for upcoming reference

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if math.random(7) == 1  then  --change condition to math.random(7) > 0 to check consistency

            if x==1 or levelwidth-x<=4  then         --ensures that the first column the last few columns 
                for y = 7, height do                 --including the column with the goal will not be empty
                    table.insert(tiles[y],           
                        Tile(x, y, TILE_ID_GROUND, y == 7 and topper or nil, tileset, topperset))
                end
            else
                for y = 7, height do
                    table.insert(tiles[y],
                        Tile(x, y, tileID, nil, tileset, topperset))
                end
            end
            
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 and levelwidth-x>=4 then         --ensures the last few columns
                blockHeight = 2                                     --including the column with the goal won't have a pillar
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end
            
            -- chance to spawn a block
            if math.random(10) == 1 and levelwidth-x>=4 then --ensures blocks would not overlap the goalpost
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                

                            elseif math.random(5) >= 3 and keyspawned==false then   

                                 keycolor=math.random(#KEYS)          --assigned random key color to a variable to use it in lock 
                                  
                                         -- maintain reference so we can set it to nil
                                    local key = GameObject {
                                        texture = 'keys-and-locks',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = keycolor,
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- key has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score=player.score+50
                                            keycollected=true
                                        end
                                    }
                                    
                                    -- make the key move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [key] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()
                                    
                                    table.insert(objects, key)
                                    keyspawned=true --makes sure we don't get more than 1 key per level by checking in the elseif above
                                   
                                end

                                if keyspawned and not lockspawned then

                                    -- maintain reference so we can set it to nil
                                    local lock = GameObject {
                                        texture = 'keys-and-locks',
                                        x = (levelwidth-math.random(3)-2) * TILE_SIZE, --makes the lock near the end of the level
                                        y = (blockHeight-1) * TILE_SIZE - 10,
                                        width = 16,
                                        height = 16,
                                        frame = keycolor+4, --lock blocks are in the second row of the image file
                                        collidable = true,
                                        consumable = false,
                                        solid = true,

                                        
                                        onCollide = function(player, object)
                                            if keycollected then   --the lock won't get unlocked unless you have the key
                                            gSounds['pickup']:play()
                                            table.remove(objects, object)

                                            local pole = GameObject {
                                        texture = 'flags',
                                        x = (levelwidth-2) * TILE_SIZE,
                                        y = (3) * TILE_SIZE,
                                        width = 16,
                                        height = 64,
                                        frame = math.random(#POLES),
                                        collidable = false,
                                        consumable = true,
                                        solid = false,

                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            --if the player touches the goalpost reset the level but make it bigger and keep the score
                                            gStateMachine:change('play',{['score'] = player.score,['width']=levelwidth+10})
                                        end
                                    }
                                    
                                    local flag = GameObject {
                                        texture = 'flags',
                                        x = (levelwidth-1.5) * TILE_SIZE+1,
                                        y = (3.4) * TILE_SIZE,
                                        width = 16,
                                        height = 16,
                                        frame = 7 + (3 * math.random(0, 3)),
                                        collidable = false,
                                        consumable = true,
                                        solid = false,
                                        --set the animation of the flag
                                        animation = Animation {
                                            frames = {0, 1},
                                            interval = 0.15
                                        },

                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            --if the player touches the goalpost reset the level but make it bigger and keep the score
                                            gStateMachine:change('play',{['score'] = player.score,['width']=levelwidth+10})
                                        end
                                    }
                                    
                                    
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, pole)
                                    table.insert(objects, flag)
                                            else
                                                gSounds['empty-block']:play()
                                            end
                                        end
                                    }
                                    
                                    
                                    table.insert(objects, lock)
                                    lockspawned=true
                                end



                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end