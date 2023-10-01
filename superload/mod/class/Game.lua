local _M = loadPrevious(...)

local base_setupCommands = _M.setupCommands

function _M:setupCommands()
    base_setupCommands(self)
    self.key:addBinds {
        AUTO_FIGHT = function()
            local function autoFight()
                -- Skip if not suitable situation
                if not self.level or not self.zone then return end
                if self.player.resting or self.player.running or game:hasDialogUp(1) then return end

                -- Disable auto attack when health below 50%
                -- TODO Configurable threshold
                local hpFactor = 0.5
                local hpThreshold = self.player.max_life * hpFactor

                if self.player.life < hpThreshold then
                    self.log("#RED#You are too injured to fight recklessly!")
                    return
                end

                -- Player coordinates
                local px, py = self.player.x, self.player.y

                -- Seen enemy array
                local seen = {}
                core.fov.calc_circle(
                    px, 
                    py, 
                    self.level.map.w, 
                    self.level.map.h, 
                    self.player.sight or 10,
                    function(_, x, y) return self.level.map:opaque(x, y) end,
                    function(_, x, y)
                        local actor = self.level.map(x, y, self.level.map.ACTOR)
                        if actor and 
                        actor ~= self.player and 
                        self.player:reactionToward(actor) < 0 and
                        self.player:canSee(actor) and 
                        self.level.map.seens(x, y) then 
                            seen[#seen + 1] = {x=x, y=y, actor=actor} 
                        end
                    end, 
                    nil
                )

                -- Auto Explore if no visible enemies
                -- TODO Configurable auto explore
                if #seen == 0 then
                    self.key:triggerVirtual("RUN_AUTO")
                    return
                end

                -- Target the nearest enemy and attack
                local target = seen[1]
                
                if target then
                    -- Preferred method of attack
                    if self.player.hotkey[11] ~= nil and self.player.hotkey[11][2] ~= nil then
                        self.player:useTalent(self.player.hotkey[11][2], nil, nil, false, target)
                    else
                        self.log("#RED#Your preferred method of attack is empty. Please put a skill in the 11th slot.")
                        return
                    end

                    -- Switch to the closest target
                    local target = seen[1]
                    for i = 2, #seen do
                        if (seen[i].x - px) ^ 2 + (seen[i].y - py) ^ 2 < (target.x - px) ^ 2 + (target.y - py) ^ 2 then
                            target = seen[i]
                        end
                    end

                    -- Pathfind to target
                    local a = engine.Astar.new(self.level.map, self.player)
                    local result = a:calc(px, py, target.x, target.y)

                    -- Pathfinding failed
                    if not result or not result[1] then 
                        self.log("#RED#No path to enemy. Waiting 1 turn.")
                        self.key:triggerVirtual("MOVE_STAY")
                        return
                    end

                    -- Check for actual movement
                    local moved = self.player:move(result[1].x, result[1].y)
                    if not moved then self.key:triggerVirtual("MOVE_STAY") end
                else
                    self.log("#LIGHT_RED#No enemies in sight.")
                end
            end

            autoFight()
        end
    } 
end

return _M

