--[[
▒█░░░ ▒█▀▀▀█ ▒█▀▀█ ░█▀▀█ ▒█░░░ ▒█▀▀▀█ 
▒█░░░ ▒█░░▒█ ▒█░░░ ▒█▄▄█ ▒█░░░ ░▀▀▀▄▄ 
▒█▄▄█ ▒█▄▄▄█ ▒█▄▄█ ▒█░▒█ ▒█▄▄█ ▒█▄▄▄█ 
]]
local gsoSDK = {
      ChampTick = function() end,
      ChampDraw = function() end,
      ChampWndMsg = function(msg, wParam) end,
      Menu = nil,
      Spell = nil,
      Utilities = nil,
      Cursor = nil,
      AntiGapcloser = nil,
      Interrupter = nil,
      ObjectManager = nil,
      Farm = nil,
      TS = nil,
      Orbwalker = nil
}
local debugMode = false
local myHero = myHero
local GetTickCount = GetTickCount
local MathSqrt = math.sqrt
local DrawText = Draw.Text
local GameTimer = Game.Timer
local DrawColor = Draw.Color
local DrawCircle = Draw.Circle
local ControlKeyUp = Control.KeyUp
local ControlKeyDown = Control.KeyDown
local ControlIsKeyDown = Control.IsKeyDown
local ControlMouseEvent = Control.mouse_event
local ControlSetCursorPos = Control.SetCursorPos
local GameCanUseSpell = Game.CanUseSpell
local GameHeroCount = Game.HeroCount
local GameHero = Game.Hero
local GameMinionCount = Game.MinionCount
local GameMinion = Game.Minion
local GameTurretCount = Game.TurretCount
local GameTurret = Game.Turret
local GameIsChatOpen = Game.IsChatOpen
local GameLatency = Game.Latency
local damageSwitch = true
-- 1 = Q, 2 = W, 3 = R
local currentStance = 0
local QCount = 0
local WCount = 0
local RCount = 0
local function GetFastDistance(p1, p2)
      local x = p1.x - p2.x
      local z = p1.z - p2.z
      return x * x + z * z
end
local function GetInterceptionTime(source, startP, endP, unitspeed, spellspeed)
        local sx = source.x
        local sy = source.z
        local ux = startP.x
        local uy = startP.z
        local dx = endP.x - ux
        local dy = endP.z - uy
        local magnitude = math.sqrt(dx * dx + dy * dy)
        dx = (dx / magnitude) * unitspeed
        dy = (dy / magnitude) * unitspeed
        local a = (dx * dx) + (dy * dy) - (spellspeed * spellspeed)
        local b = 2 * ((ux * dx) + (uy * dy) - (sx * dx) - (sy * dy))
        local c = (ux * ux) + (uy * uy) + (sx * sx) + (sy * sy) - (2 * sx * ux) - (2 * sy * uy)
        local d = (b * b) - (4 * a * c)
        if d > 0 then
                local t1 = (-b + math.sqrt(d)) / (2 * a)
                local t2 = (-b - math.sqrt(d)) / (2 * a)
                return math.max(t1, t2)
        end
        if d >= 0 and d < 0.00001 then
                return -b / (2 * a)
        end
        return 0.00001
end
  local function CheckWall(from, to, distance)
      local pos1 = to + (to-from):Normalized() * 50
      local pos2 = pos1 + (to-from):Normalized() * (distance - 50)
      local point1 = Point(pos1.x, pos1.z)
      local point2 = Point(pos2.x, pos2.z)
      if (MapPosition:inWall(point1) and MapPosition:inWall(point2)) or MapPosition:intersectsWall(LineSegment(point1, point2)) then
            return true
      end
      return false
  end
--[[
▒█▀▀█ █░░█ █▀▀█ █▀▀ █▀▀█ █▀▀█ 
▒█░░░ █░░█ █▄▄▀ ▀▀█ █░░█ █▄▄▀ 
▒█▄▄█ ░▀▀▀ ▀░▀▀ ▀▀▀ ▀▀▀▀ ▀░▀▀ 
]]
class "__gsoCursor"
      function __gsoCursor:__init()
            self.CursorReady = true
            self.ExtraSetCursor = nil
            self.SetCursorPos = nil
      end
      function __gsoCursor:IsCursorReady()
            if self.CursorReady and not self.SetCursorPos and not self.ExtraSetCursor then
                  return true
            end
            return false
      end
      function __gsoCursor:CreateDrawMenu(menu)
            gsoSDK.Menu.gsodraw:MenuElement({name = "Cursor Pos",  id = "cursor", type = MENU})
                  gsoSDK.Menu.gsodraw.cursor:MenuElement({name = "Enabled",  id = "enabled", value = true})
                  gsoSDK.Menu.gsodraw.cursor:MenuElement({name = "Color",  id = "color", color = DrawColor(255, 153, 0, 76)})
                  gsoSDK.Menu.gsodraw.cursor:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
                  gsoSDK.Menu.gsodraw.cursor:MenuElement({name = "Radius",  id = "radius", value = 150, min = 1, max = 300})
      end
      function __gsoCursor:SetCursor(cPos, castPos, delay)
            self.ExtraSetCursor = castPos
            self.CursorReady = false
            self.SetCursorPos = { EndTime = GameTimer() + delay, Action = function() ControlSetCursorPos(cPos.x, cPos.y) end, Active = true }
      end
      function __gsoCursor:Tick()
            if self.SetCursorPos then
                  if self.SetCursorPos.Active and GameTimer() > self.SetCursorPos.EndTime then
                        self.SetCursorPos.Action()
                        self.SetCursorPos.Active = false
                        self.ExtraSetCursor = nil
                  elseif not self.SetCursorPos.Active and GameTimer() > self.SetCursorPos.EndTime + 0.025 then
                        self.CursorReady = true
                        self.SetCursorPos = nil
                  end
            end
            if self.ExtraSetCursor then
                  ControlSetCursorPos(self.ExtraSetCursor)
            end
      end
      function __gsoCursor:Draw()
            if gsoSDK.Menu.gsodraw.cursor.enabled:Value() then
                  DrawCircle(mousePos, gsoSDK.Menu.gsodraw.cursor.radius:Value(), gsoSDK.Menu.gsodraw.cursor.width:Value(), gsoSDK.Menu.gsodraw.cursor.color:Value())
            end
      end
--[[
▒█▀▀▀ █▀▀█ █▀▀█ █▀▄▀█ 
▒█▀▀▀ █▄▄█ █▄▄▀ █░▀░█ 
▒█░░░ ▀░░▀ ▀░▀▀ ▀░░░▀ 
]]
class "__gsoFarm"
      function __gsoFarm:__init()
            self.ActiveAttacks = {}
            self.ShouldWait = false
            self.ShouldWaitTime = 0
            self.IsLastHitable = false
      end
      function __gsoFarm:PredPos(speed, pPos, unit)
            if unit.pathing.hasMovePath then
                  local uPos = unit.pos
                  local ePos = unit.pathing.endPos
                  local distUP = pPos:DistanceTo(uPos)
                  local distEP = pPos:DistanceTo(ePos)
                  local unitMS = unit.ms
                  if distEP > distUP then
                        return uPos:Extended(ePos, 25+(unitMS*(distUP / (speed - unitMS))))
                  else
                        return uPos:Extended(ePos, 25+(unitMS*(distUP / (speed + unitMS))))
                  end
            end
            return unit.pos
      end
      function __gsoFarm:UpdateActiveAttacks()
            for k1, v1 in pairs(self.ActiveAttacks) do
                  local count = 0
                  for k2, v2 in pairs(self.ActiveAttacks[k1]) do
                        count = count + 1
                        if v2.Speed == 0 and (not v2.Ally or v2.Ally.dead) then
                              self.ActiveAttacks[k1] = nil
                              break
                        end
                        if not v2.Canceled then
                              local ranged = v2.Speed > 0
                              if ranged then
                                    self.ActiveAttacks[k1][k2].FlyTime = v2.Ally.pos:DistanceTo(self:PredPos(v2.Speed, v2.Pos, v2.Enemy)) / v2.Speed
                              end
                              local projectileOnEnemy = 0.025 + gsoSDK.Utilities:GetMaxLatency()
                              if GameTimer() > v2.StartTime + self.ActiveAttacks[k1][k2].FlyTime - projectileOnEnemy or not v2.Enemy or v2.Enemy.dead then
                                    self.ActiveAttacks[k1][k2] = nil
                              elseif ranged then
                                    self.ActiveAttacks[k1][k2].Pos = v2.Ally.pos:Extended(v2.Enemy.pos, ( GameTimer() - v2.StartTime ) * v2.Speed)
                              end
                        end
                  end
                  if count == 0 then
                        self.ActiveAttacks[k1] = nil
                  end
            end
      end
      function __gsoFarm:SetLastHitable(enemyMinion, time, damage, mode, allyMinions)
            if mode == "fast" then
                  local hpPred = self:MinionHpPredFast(enemyMinion, allyMinions, time)
                  local lastHitable = hpPred - damage < 0
                  if lastHitable then self.IsLastHitable = true end
                  local almostLastHitable = lastHitable and false or self:MinionHpPredFast(enemyMinion, allyMinions, myHero.attackData.animationTime * 3) - damage < 0
                  if almostLastHitable then
                        self.ShouldWait = true
                        self.ShouldWaitTime = GameTimer()
                  end
                  return { LastHitable =  lastHitable, Unkillable = hpPred < 0, AlmostLastHitable = almostLastHitable, PredictedHP = hpPred, Minion = enemyMinion }
            elseif mode == "accuracy" then
                  local hpPred = self:MinionHpPredAccuracy(enemyMinion, time)
                  local lastHitable = hpPred - damage < 0
                  if lastHitable then self.IsLastHitable = true end
                  local almostLastHitable = lastHitable and false or self:MinionHpPredFast(enemyMinion, allyMinions, myHero.attackData.animationTime * 3) - damage < 0
                  if almostLastHitable then
                        self.ShouldWait = true
                        self.ShouldWaitTime = GameTimer()
                  end
                  return { LastHitable =  lastHitable, Unkillable = hpPred < 0, AlmostLastHitable = almostLastHitable, PredictedHP = hpPred, Minion = enemyMinion }
            end
      end
      function __gsoFarm:CanLastHit()
            return self.IsLastHitable
      end
      function __gsoFarm:CanLaneClear()
            return not self.ShouldWait
      end
      function __gsoFarm:CanLaneClearTime()
            local shouldWait = gsoSDK.Menu.ts.shouldwaittime:Value() * 0.001
            return GameTimer() > self.ShouldWaitTime + shouldWait
      end
      function __gsoFarm:MinionHpPredFast(unit, allyMinions, time)
            local unitHandle, unitPos, unitHealth = unit.handle, unit.pos, unit.health
            for i = 1, #allyMinions do
                  local allyMinion = allyMinions[i]
                  if allyMinion.attackData.target == unitHandle then
                        local minionDmg = (allyMinion.totalDamage*(1+allyMinion.bonusDamagePercent))-unit.flatDamageReduction
                        local flyTime = allyMinion.attackData.projectileSpeed > 0 and allyMinion.pos:DistanceTo(unitPos) / allyMinion.attackData.projectileSpeed or 0
                        local endTime = (allyMinion.attackData.endTime - allyMinion.attackData.animationTime) + flyTime + allyMinion.attackData.windUpTime
                        endTime = endTime > GameTimer() and endTime or endTime + allyMinion.attackData.animationTime + flyTime
                        while endTime - GameTimer() < time do
                              unitHealth = unitHealth - minionDmg
                              endTime = endTime + allyMinion.attackData.animationTime + flyTime
                        end
                  end
            end
            return unitHealth
      end
      function __gsoFarm:MinionHpPredAccuracy(unit, time)
            local unitHealth, unitHandle = unit.health, unit.handle
            for allyID, allyActiveAttacks in pairs(self.ActiveAttacks) do
                  for activeAttackID, activeAttack in pairs(self.ActiveAttacks[allyID]) do
                        if not activeAttack.Canceled and unitHandle == activeAttack.Enemy.handle then
                              local endTime = activeAttack.StartTime + activeAttack.FlyTime
                              if endTime > GameTimer() and endTime - GameTimer() < time then
                                    unitHealth = unitHealth - activeAttack.Dmg
                              end
                        end
                  end
            end
            return unitHealth
      end
      function __gsoFarm:Tick(allyMinions, enemyMinions)
            for i = 1, #allyMinions do
                  local allyMinion = allyMinions[i]
                  if allyMinion.attackData.endTime > GameTimer() then
                        for j = 1, #enemyMinions do
                              local enemyMinion = enemyMinions[j]
                              if enemyMinion.handle == allyMinion.attackData.target then
                                    local flyTime = allyMinion.attackData.projectileSpeed > 0 and allyMinion.pos:DistanceTo(enemyMinion.pos) / allyMinion.attackData.projectileSpeed or 0
                                    if not self.ActiveAttacks[allyMinion.handle] then
                                          self.ActiveAttacks[allyMinion.handle] = {}
                                    end
                                    if GameTimer() < (allyMinion.attackData.endTime - allyMinion.attackData.windDownTime) + flyTime then
                                          if allyMinion.attackData.projectileSpeed > 0 then
                                                if GameTimer() > allyMinion.attackData.endTime - allyMinion.attackData.windDownTime then
                                                      if not self.ActiveAttacks[allyMinion.handle][allyMinion.attackData.endTime] then
                                                            self.ActiveAttacks[allyMinion.handle][allyMinion.attackData.endTime] = {
                                                                  Canceled = false,
                                                                  Speed = allyMinion.attackData.projectileSpeed,
                                                                  StartTime = allyMinion.attackData.endTime - allyMinion.attackData.windDownTime,
                                                                  FlyTime = flyTime,
                                                                  Pos = allyMinion.pos:Extended(enemyMinion.pos, allyMinion.attackData.projectileSpeed * ( GameTimer() - ( allyMinion.attackData.endTime - allyMinion.attackData.windDownTime ) ) ),
                                                                  Ally = allyMinion,
                                                                  Enemy = enemyMinion,
                                                                  Dmg = (allyMinion.totalDamage*(1+allyMinion.bonusDamagePercent))-enemyMinion.flatDamageReduction
                                                            }
                                                      end
                                                elseif allyMinion.pathing.hasMovePath then
                                                      self.ActiveAttacks[allyMinion.handle][allyMinion.attackData.endTime] = {
                                                            Canceled = true,
                                                            Ally = allyMinion
                                                      }
                                                end
                                          elseif not self.ActiveAttacks[allyMinion.handle][allyMinion.attackData.endTime] then
                                                self.ActiveAttacks[allyMinion.handle][allyMinion.attackData.endTime] = {
                                                      Canceled = false,
                                                      Speed = allyMinion.attackData.projectileSpeed,
                                                      StartTime = (allyMinion.attackData.endTime - allyMinion.attackData.windDownTime) - allyMinion.attackData.windUpTime,
                                                      FlyTime = allyMinion.attackData.windUpTime,
                                                      Pos = allyMinion.pos,
                                                      Ally = allyMinion,
                                                      Enemy = enemyMinion,
                                                      Dmg = (allyMinion.totalDamage*(1+allyMinion.bonusDamagePercent))-enemyMinion.flatDamageReduction
                                                }
                                          end
                                    end
                                    break
                              end
                        end
                  end
            end
            self:UpdateActiveAttacks()
            self.IsLastHitable = false
            self.ShouldWait = false
      end
--[[
▀█▀ ▒█▄░▒█ ▀▀█▀▀ ▒█▀▀▀ ▒█▀▀█ ▒█░▒█ ▒█▀▀█ ▀▀█▀▀ ▒█▀▀▀ ▒█▀▀█ 
▒█░ ▒█▒█▒█ ░▒█░░ ▒█▀▀▀ ▒█▄▄▀ ▒█░▒█ ▒█▄▄█ ░▒█░░ ▒█▀▀▀ ▒█▄▄▀ 
▄█▄ ▒█░░▀█ ░▒█░░ ▒█▄▄▄ ▒█░▒█ ░▀▄▄▀ ▒█░░░ ░▒█░░ ▒█▄▄▄ ▒█░▒█ 
]]
class "__gsoInterrupter"
      function __gsoInterrupter:__init()
            self.Loaded = true
            self.Callback = {}
            self.Spells = {
                  ["CaitlynAceintheHole"] = true,
                  ["Crowstorm"] = true,
                  ["DrainChannel"] = true,
                  ["GalioIdolOfDurand"] = true,
                  ["ReapTheWhirlwind"] = true,
                  ["KarthusFallenOne"] = true,
                  ["KatarinaR"] = true,
                  ["LucianR"] = true,
                  ["AlZaharNetherGrasp"] = true,
                  ["Meditate"] = true,
                  ["MissFortuneBulletTime"] = true,
                  ["AbsoluteZero"] = true,
                  ["PantheonRJump"] = true,
                  ["PantheonRFall"] = true,
                  ["ShenStandUnited"] = true,
                  ["Destiny"] = true,
                  ["UrgotSwap2"] = true,
                  ["VelkozR"] = true,
                  ["InfiniteDuress"] = true,
                  ["XerathLocusOfPower2"] = true
            }
      end
      function __gsoInterrupter:Tick()
            local enemyList = gsoSDK.ObjectManager:GetEnemyHeroes(1500, false, "spell")
            for i =1, #enemyList do
                  local enemy = enemyList[i]
                  local activeSpell = enemy.activeSpell
                  if activeSpell and activeSpell.valid and self.Spells[activeSpell.name] and activeSpell.isChanneling and activeSpell.castEndTime - GameTimer() > 0.33 then
                        for j = 1, #self.Callback do
                              self.Callback[j](enemy, activeSpell)
                        end
                  end
            end
      end
--[[
░█▀▀█ ▒█▄░▒█ ▀▀█▀▀ ▀█▀ ▒█▀▀█ ░█▀▀█ ▒█▀▀█ ▒█▀▀█ ▒█░░░ ▒█▀▀▀█ ▒█▀▀▀█ ▒█▀▀▀ ▒█▀▀█ 
▒█▄▄█ ▒█▒█▒█ ░▒█░░ ▒█░ ▒█░▄▄ ▒█▄▄█ ▒█▄▄█ ▒█░░░ ▒█░░░ ▒█░░▒█ ░▀▀▀▄▄ ▒█▀▀▀ ▒█▄▄▀ 
▒█░▒█ ▒█░░▀█ ░▒█░░ ▄█▄ ▒█▄▄█ ▒█░▒█ ▒█░░░ ▒█▄▄█ ▒█▄▄█ ▒█▄▄▄█ ▒█▄▄▄█ ▒█▄▄▄ ▒█░▒█ 
]]
class "__gsoAntiGapcloser"
      function __gsoAntiGapcloser:__init()
            self.Loaded = true
            self.Callback = {}
      end
      function __gsoAntiGapcloser:Tick()
            local mePos = myHero.pos
            local enemyList = gsoSDK.ObjectManager:GetEnemyHeroes(500, false, "spell")
            for i =1, #enemyList do
                  local enemy = enemyList[i]
                  for j = 1, #self.Callback do
                        self.Callback[j](enemy)
                  end
            end
      end
--[[
▒█▀▀▀█ █▀▀▄ ░░▀ █▀▀ █▀▀ ▀▀█▀▀ 　 ▒█▀▄▀█ █▀▀█ █▀▀▄ █▀▀█ █▀▀▀ █▀▀ █▀▀█ 
▒█░░▒█ █▀▀▄ ░░█ █▀▀ █░░ ░░█░░ 　 ▒█▒█▒█ █▄▄█ █░░█ █▄▄█ █░▀█ █▀▀ █▄▄▀ 
▒█▄▄▄█ ▀▀▀░ █▄█ ▀▀▀ ▀▀▀ ░░▀░░ 　 ▒█░░▒█ ▀░░▀ ▀░░▀ ▀░░▀ ▀▀▀▀ ▀▀▀ ▀░▀▀ 
]]
class "__gsoOB"
      function __gsoOB:__init()
            self.LastFound = -99999
            self.LoadedChamps = false
            self.AllyHeroes = {}
            self.EnemyHeroes = {}
            self.AllyHeroLoad = {}
            self.EnemyHeroLoad = {}
            self.Units = { EnemyMinions = {} }
            self.UndyingBuffs = { ["zhonyasringshield"] = true }
      end
      function __gsoOB:OnAllyHeroLoad(func)
            self.AllyHeroLoad[#self.AllyHeroLoad+1] = func
      end
      function __gsoOB:OnEnemyHeroLoad(func)
            self.EnemyHeroLoad[#self.EnemyHeroLoad+1] = func
      end
      function __gsoOB:IsUnitValid(unit, range, bb)
            local extraRange = bb and unit.boundingRadius or 0
            if  unit.pos:DistanceTo(myHero.pos) < range + extraRange and not unit.dead and unit.isTargetable and unit.valid and unit.visible then
                  return true
            end
            return false
      end
      function __gsoOB:IsUnitValid_invisible(unit, range, bb)
            local extraRange = bb and unit.boundingRadius or 0
            if  unit.pos:DistanceTo(myHero.pos) < range + extraRange and not unit.dead and unit.isTargetable and unit.valid then
                  return true
            end
            return false
      end
      function __gsoOB:IsHeroImmortal(unit, jaxE)
            local hp = 100 * ( unit.health / unit.maxHealth )
            if self.UndyingBuffs["JaxCounterStrike"] ~= nil then self.UndyingBuffs["JaxCounterStrike"] = jaxE end
            if self.UndyingBuffs["kindredrnodeathbuff"] ~= nil then self.UndyingBuffs["kindredrnodeathbuff"] = hp < 10 end
            if self.UndyingBuffs["UndyingRage"] ~= nil then self.UndyingBuffs["UndyingRage"] = hp < 15 end
            if self.UndyingBuffs["ChronoShift"] ~= nil then self.UndyingBuffs["ChronoShift"] = hp < 15; self.UndyingBuffs["chronorevive"] = hp < 15 end
            for i = 0, unit.buffCount do
                  local buff = unit:GetBuff(i)
                  if buff and buff.count > 0 and self.UndyingBuffs[buff.name] then
                        return true
                  end
            end
            return false
      end
      function __gsoOB:GetAllyHeroes(range, bb)
            local result = {}
            for i = 1, GameHeroCount() do
                  local hero = GameHero(i)
                  if hero and hero.team == myHero.team and self:IsUnitValid(hero, range, bb) then
                        result[#result+1] = hero
                  end
            end
            return result
      end
      function __gsoOB:GetEnemyHeroes(range, bb, state)
            local result = {}
            if state == "spell" then
                  for i = 1, GameHeroCount() do
                        local hero = GameHero(i)
                        if hero and hero.team ~= myHero.team and self:IsUnitValid(hero, range, bb) and not self:IsHeroImmortal(hero, false) then
                              result[#result+1] = hero
                        end
                  end
            elseif state == "attack" then
                  for i = 1, GameHeroCount() do
                        local hero = GameHero(i)
                        if hero and hero.team ~= myHero.team and self:IsUnitValid(hero, range, bb) and not self:IsHeroImmortal(hero, true) then
                              result[#result+1] = hero
                        end
                  end
            elseif state == "immortal" then
                  for i = 1, GameHeroCount() do
                        local hero = GameHero(i)
                        if hero and hero.team ~= myHero.team and self:IsUnitValid(hero, range, bb) then
                              result[#result+1] = hero
                        end
                  end
            elseif state == "spell_invisible" then
                  for i = 1, GameHeroCount() do
                        local hero = GameHero(i)
                        if hero and hero.team ~= myHero.team and self:IsUnitValid_invisible(hero, range, bb) then
                              result[#result+1] = hero
                        end
                  end
            end
            return result
      end
      function __gsoOB:GetAllyTurrets(range, bb)
            local result = {}
            for i = 1, GameTurretCount() do
                  local turret = GameTurret(i)
                  if turret and turret.team == myHero.team and self:IsUnitValid(turret, range, bb)  then
                        result[#result+1] = turret
                  end
            end
            return result
      end
      function __gsoOB:GetEnemyTurrets(range, bb)
            local result = {}
            for i = 1, GameTurretCount() do
                  local turret = GameTurret(i)
                  if turret and turret.team ~= myHero.team and self:IsUnitValid(turret, range, bb) and not turret.isImmortal then
                        result[#result+1] = turret
                  end
            end
            return result
      end
      function __gsoOB:GetAllyMinions(range, bb)
            local result = {}
            for i = 1, GameMinionCount() do
                  local minion = GameMinion(i)
                  if minion and minion.team == myHero.team and self:IsUnitValid(minion, range, bb) then
                        result[#result+1] = minion
                  end
            end
            return result
      end
      function __gsoOB:GetEnemyMinions(range, bb)
            local result = {}
            for i = 1, GameMinionCount() do
                  local minion = GameMinion(i)
                  if minion and minion.team ~= myHero.team and self:IsUnitValid(minion, range, bb) and not minion.isImmortal then
                        result[#result+1] = minion
                  end
            end
            return result
      end
      function __gsoOB:Tick()
            for i = 1, GameHeroCount() do end
            for i = 1, GameTurretCount() do end
            for i = 1, GameMinionCount() do end
            self.Units.EnemyMinions = self:GetEnemyMinions(2000, false)
            if self.LoadedChamps then return end
            for i = 1, GameHeroCount() do
                  local hero = GameHero(i)
                  local eName = hero.charName
                  if eName and #eName > 0 then
                        local isNewHero = true
                        if hero.team ~= myHero.team then
                              for j = 1, #self.EnemyHeroes do
                                    if hero == self.EnemyHeroes[j] then
                                          isNewHero = false
                                          break
                                    end
                              end
                              if isNewHero then
                                    self.EnemyHeroes[#self.EnemyHeroes+1] = hero
                                    self.LastFound = GameTimer()
                                    if eName == "Kayle" then self.UndyingBuffs["JudicatorIntervention"] = true
                                    elseif eName == "Taric" then self.UndyingBuffs["TaricR"] = true
                                    elseif eName == "Kindred" then self.UndyingBuffs["kindredrnodeathbuff"] = true
                                    elseif eName == "Zilean" then self.UndyingBuffs["ChronoShift"] = true; self.UndyingBuffs["chronorevive"] = true
                                    elseif eName == "Tryndamere" then self.UndyingBuffs["UndyingRage"] = true
                                    elseif eName == "Jax" then self.UndyingBuffs["JaxCounterStrike"] = true; gsoIsJax = true
                                    elseif eName == "Fiora" then self.UndyingBuffs["FioraW"] = true
                                    elseif eName == "Aatrox" then self.UndyingBuffs["aatroxpassivedeath"] = true
                                    elseif eName == "Vladimir" then self.UndyingBuffs["VladimirSanguinePool"] = true
                                    elseif eName == "KogMaw" then self.UndyingBuffs["KogMawIcathianSurprise"] = true
                                    elseif eName == "Karthus" then self.UndyingBuffs["KarthusDeathDefiedBuff"] = true
                                    end
                              end
                        else
                              for j = 1, #self.AllyHeroes do
                                    if hero == self.AllyHeroes[j] then
                                          isNewHero = false
                                          break
                                    end
                              end
                              if isNewHero then
                                    self.AllyHeroes[#self.EnemyHeroes+1] = hero
                              end
                        end
                  end
            end
            if GameTimer() > self.LastFound + 2.5 and GameTimer() < self.LastFound + 5 then
                  self.LoadedChamps = true
                  for i = 1, #self.AllyHeroes do
                        for j = 1, #self.AllyHeroLoad do
                              self.AllyHeroLoad[j](self.AllyHeroes[i])
                        end
                  end
                  for i = 1, #self.EnemyHeroes do
                        for j = 1, #self.EnemyHeroLoad do
                              self.EnemyHeroLoad[j](self.EnemyHeroes[i])
                        end
                  end
            end
      end
--[[
▒█▀▀▀█ █▀▀█ █▀▀▄ █░░░█ █▀▀█ █░░ █░█ █▀▀ █▀▀█ 
▒█░░▒█ █▄▄▀ █▀▀▄ █▄█▄█ █▄▄█ █░░ █▀▄ █▀▀ █▄▄▀ 
▒█▄▄▄█ ▀░▀▀ ▀▀▀░ ░▀░▀░ ▀░░▀ ▀▀▀ ▀░▀ ▀▀▀ ▀░▀▀ 
]]
class "__gsoOrbwalker"
      function __gsoOrbwalker:__init()
            -- attack
            self.AttackStartTime = 0
            self.AttackEndTime = 0
            self.AttackCastEndTime = 0
            self.AttackServerStart = 0
            self.AttackLocalStart = 0
            -- move
            self.LastMoveLocal = 0
            self.LastMoveTime = 0
            self.LastMovePos = myHero.pos
            -- mouse
            self.LastMouseDown = 0
            -- callbacks
            self.OnPreAttackC = {}
            self.OnPostAttackC = {function () StanceCounter() end}
            self.OnAttackC = {}
            self.OnPreMoveC = {}
            -- debug
            self.TestCount = 0
            self.TestStartTime = 0
            -- other
            self.LoadTime = GameTimer()
            self.PostAttackBool = false
            self.AttackEnabled = true
            self.MovementEnabled = true
            self.Loaded = false
            self.IsTeemo = false
            self.IsBlindedByTeemo = false
            self.ResetAttack = false
            self.SpellMoveDelays = { q = 0, w = 0, e = 0, r = 0 }
            self.SpellAttackDelays = { q = 0, w = 0, e = 0, r = 0 }
            gsoSDK.ObjectManager:OnEnemyHeroLoad(function(hero) if hero.charName == "Teemo" then self.IsTeemo = true end end)
            self.CanAttackC = function() return true end
            self.CanMoveC = function() return true end
      end
      function __gsoOrbwalker:CreateMenu()
            gsoSDK.Menu:MenuElement({name = "Orbwalker", id = "orb", type = MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/orb.png" })
                  gsoSDK.Menu.orb:MenuElement({name = "Keys", id = "keys", type = MENU})
                  gsoSDK.Menu.orb.keys:MenuElement({name = "Combo Key", id = "combo", key = string.byte(" ")})
                  --gsoSDK.Menu.orb.keys:MenuElement({name = "Harass Key", id = "harass", key = string.byte("C")})
                  --gsoSDK.Menu.orb.keys:MenuElement({name = "LastHit Key", id = "lasthit", key = string.byte("X")})
                  gsoSDK.Menu.orb.keys:MenuElement({name = "JungleClear Key", id = "laneclear", key = string.byte("V")})
                  --gsoSDK.Menu.orb.keys:MenuElement({name = "Flee Key", id = "flee", key = string.byte("A")})
                  gsoSDK.Menu.orb:MenuElement({name = "Extra WindUp Delay", tooltip = "Less Value = Better KITE", id = "windupdelay", value = 0, min = 0, max = 50, step = 5 })
                  gsoSDK.Menu.orb:MenuElement({name = "Extra Anim Delay", tooltip = "Less Value = Better DPS [ for me 80 is ideal ] - lower value than 80 cause slow KITE ! Maybe for your PC ideal value is 0 ? You need test it in debug mode.", id = "animdelay", value = 80, min = 0, max = 150, step = 10 })
                  gsoSDK.Menu.orb:MenuElement({name = "Extra LastHit Delay", tooltip = "Less Value = Faster Last Hit Reaction", id = "lhDelay", value = 0, min = 0, max = 50, step = 1 })
                  gsoSDK.Menu.orb:MenuElement({name = "Extra Server Timeout", tooltip = "Less Value = Faster reaction after bad response from server", id = "timeout", value = 100, min = 0, max = 200, step = 10 })
                  gsoSDK.Menu.orb:MenuElement({name = "Debug Mode", tooltip = "Will Print Some Data", id = "enabled", value = false})
      end
      function __gsoOrbwalker:CreateDrawMenu(menu)
            gsoSDK.Menu.gsodraw:MenuElement({name = "MyHero Attack Range", id = "me", type = MENU})
                  gsoSDK.Menu.gsodraw.me:MenuElement({name = "Enabled",  id = "enabled", value = true})
                  gsoSDK.Menu.gsodraw.me:MenuElement({name = "Color",  id = "color", color = DrawColor(150, 49, 210, 0)})
                  gsoSDK.Menu.gsodraw.me:MenuElement({name = "Width",  id = "width", value = 1, min = 1, max = 10})
            gsoSDK.Menu.gsodraw:MenuElement({name = "Enemy Attack Range", id = "he", type = MENU})
                  gsoSDK.Menu.gsodraw.he:MenuElement({name = "Enabled",  id = "enabled", value = true})
                  gsoSDK.Menu.gsodraw.he:MenuElement({name = "Color",  id = "color", color = DrawColor(150, 255, 0, 0)})
                  gsoSDK.Menu.gsodraw.he:MenuElement({name = "Width",  id = "width", value = 1, min = 1, max = 10})
      end
      function __gsoOrbwalker:CheckTeemoBlind()
            for i = 0, myHero.buffCount do
                  local buff = myHero:GetBuff(i)
                  if buff and buff.count > 0 and buff.name:lower() == "blindingdart" and buff.duration > 0 then
                        return true
                  end
            end
            return false
      end
      function __gsoOrbwalker:IsBeforeAttack(multipier)
            if GameTimer() > self.AttackLocalStart + multipier * myHero.attackData.animationTime then
                  return true
            else
                  return false
            end
      end
      function __gsoOrbwalker:SetSpellMoveDelays(delays)
            self.SpellMoveDelays = delays
      end
      function __gsoOrbwalker:SetSpellAttackDelays(delays)
            self.SpellAttackDelays = delays
      end
      function __gsoOrbwalker:OnPreAttack(func)
            self.OnPreAttackC[#self.OnPreAttackC+1] = func
      end
      function __gsoOrbwalker:OnPostAttack(func)
            self.OnPostAttackC[#self.OnPostAttackC+1] = func
      end
      function __gsoOrbwalker:OnAttack(func)
            self.OnAttackC[#self.OnAttackC+1] = func
      end
      function __gsoOrbwalker:OnPreMovement(func)
            self.OnPreMoveC[#self.OnPreMoveC+1] = func
      end
      function __gsoOrbwalker:GetMode()
            if gsoSDK.Menu.orb.keys.combo:Value() then
                  return "Combo"
            elseif gsoSDK.Menu.orb.keys.laneclear:Value() then
                  return "Clear"
            else
                  return "None"
            end
      end
      function __gsoOrbwalker:Draw()
            if gsoSDK.Menu.gsodraw.me.enabled:Value() and myHero.pos:ToScreen().onScreen then
                  DrawCircle(myHero.pos, myHero.range + myHero.boundingRadius + 35, gsoSDK.Menu.gsodraw.me.width:Value(), gsoSDK.Menu.gsodraw.me.color:Value())
            end
            if gsoSDK.Menu.gsodraw.he.enabled:Value() then
                  local enemyHeroes = gsoSDK.ObjectManager:GetEnemyHeroes(99999999, false, "immortal")
                  for i = 1, #enemyHeroes do
                        local enemy = enemyHeroes[i]
                        if enemy.pos:ToScreen().onScreen then
                              DrawCircle(enemy.pos, enemy.range + enemy.boundingRadius + 35, gsoSDK.Menu.gsodraw.he.width:Value(), gsoSDK.Menu.gsodraw.he.color:Value())
                        end
                  end
            end
      end
      function __gsoOrbwalker:CanAttackEvent(func)
            self.CanAttackC = func
      end
      function __gsoOrbwalker:CanMoveEvent(func)
            self.CanMoveC = func
      end
      function __gsoOrbwalker:Attack(unit)
            self.ResetAttack = false
            gsoSDK.Cursor:SetCursor(cursorPos, unit.pos, 0.06)
            ControlSetCursorPos(unit.pos)
            ControlKeyDown(HK_TCO)
            ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
            ControlMouseEvent(MOUSEEVENTF_RIGHTUP)
            ControlKeyUp(HK_TCO)
            self.LastMoveLocal = 0
            self.AttackLocalStart = GameTimer()
      end
      function __gsoOrbwalker:Move()
            if ControlIsKeyDown(2) then self.LastMouseDown = GameTimer() end
            self.LastMovePos = mousePos
            ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
            ControlMouseEvent(MOUSEEVENTF_RIGHTUP)
            self.LastMoveLocal = GameTimer() + 200 * 0.001
            self.LastMoveTime = GameTimer()
      end
      function __gsoOrbwalker:MoveToPos(pos)
            if ControlIsKeyDown(2) then self.LastMouseDown = GameTimer() end
            gsoSDK.Cursor:SetCursor(cursorPos, pos, 0.06)
            ControlSetCursorPos(pos)
            ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
            ControlMouseEvent(MOUSEEVENTF_RIGHTUP)
            self.LastMoveLocal = GameTimer() + 200 * 0.001
            self.LastMoveTime = GameTimer()
      end
      
      -- CAN ATTACK
      function __gsoOrbwalker:CanAttack()
            
            -- get can attack from function
            if not self.CanAttackC() then return false end
            
            -- spell windups
            if not gsoSDK.Spell:CheckSpellDelays(self.SpellAttackDelays) then return false end
            
            -- check teemo blind
            if self.IsBlindedByTeemo then
                  return false
            end
            
            -- waiting for response from server
            if self.AttackServerStart < self.AttackLocalStart then
                  -- timeout
                  local menuTimeout = gsoSDK.Menu.orb.timeout:Value() * 0.001
                  if GameTimer() > self.AttackLocalStart + 0.12 + menuTimeout + gsoSDK.Utilities:GetMaxLatency() then
                        return true
                  end
                  return false
            end
            
            -- reset attack
            if self.ResetAttack then
                  return true
            end
            
            -- server timers
            local menuAnim = gsoSDK.Menu.orb.animdelay:Value() * 0.001
            if GameTimer() < self.AttackStartTime + myHero.attackData.animationTime + menuAnim - 0.15 - gsoSDK.Utilities:GetMaxLatency() then
                  return false
            end
            
            -- success
            return true
      end
      
      -- CAN MOVE
      function __gsoOrbwalker:CanMove()
            
            -- get can move from function
            if not self.CanMoveC() then return false end
            
            -- spell windups
            if not gsoSDK.Spell:CheckSpellDelays(self.SpellMoveDelays) then return false end
            
            -- waiting for response from server
            if self.AttackServerStart < self.AttackLocalStart then
                  -- timeout
                  local menuTimeout = gsoSDK.Menu.orb.timeout:Value() * 0.001
                  if GameTimer() > self.AttackLocalStart + 0.12 + menuTimeout + gsoSDK.Utilities:GetMaxLatency() then
                        return true
                  end
                  return false
            end
            
            -- server timers
            local menuWindUp = gsoSDK.Menu.orb.windupdelay:Value() * 0.001
            local userLatency = gsoSDK.Utilities:GetUserLatency()
            if GameTimer() < self.AttackCastEndTime + menuWindUp - userLatency then
                  return false
            end
            
            -- success
            return true
      end
      
      -- ATTACK MOVE
      function __gsoOrbwalker:AttackMove(unit)
            if self.AttackEnabled and unit and unit.pos:ToScreen().onScreen and self:CanAttack() then
                  local args = { Target = unit, Process = true }
                  for i = 1, #self.OnPreAttackC do
                        self.OnPreAttackC[i](args)
                  end
                  if args.Process and args.Target and not args.Target.dead and args.Target.isTargetable and args.Target.valid then
                        self:Attack(args.Target)
                        self.PostAttackBool = true
                  end
            elseif self.MovementEnabled and self:CanMove() then
                  if self.PostAttackBool then
                        for i = 1, #self.OnPostAttackC do
                              self.OnPostAttackC[i]()
                        end
                        self.PostAttackBool = false
                  end
                  if GameTimer() > self.LastMoveLocal then
                        local args = { Target = nil, Process = true }
                        for i = 1, #self.OnPreMoveC do
                              self.OnPreMoveC[i](args)
                        end
                        if args.Process then
                              if not args.Target then
                                    self:Move()
                              elseif args.Target.x then
                                    self:MoveToPos(args.Target)
                              elseif args.Target.pos then
                                    self:MoveToPos(args.Target.pos)
                              else
                                    assert(false, "Gamsteron OnPreMovement Event: expected Vector !")
                              end
                        end
                  end
            end
      end
      
      -- ON TICK
      function __gsoOrbwalker:Tick()
            
            -- check if loaded
            if not self.Loaded and GameTimer() > self.LoadTime + 2.5 then
                  self.Loaded = true
            end
            if not self.Loaded then return end
            
            -- unload other orbwalkers
            if _G.Orbwalker.Enabled:Value() then _G.Orbwalker.Enabled:Value(false) end
            if _G.SDK and _G.SDK.Orbwalker and _G.SDK.Orbwalker.Loaded and _G.SDK.Orbwalker.Menu.Enabled:Value() then _G.SDK.Orbwalker.Menu.Enabled:Value(false) end
            if self.IsTeemo then self.IsBlindedByTeemo = self:CheckTeemoBlind() end
            
            -- server attack timers
            local meAAData = myHero.attackData
            if meAAData.endTime > self.AttackEndTime then
                  
                  -- on attack
                  for i = 1, #self.OnAttackC do
                        self.OnAttackC[i]()
                  end
                  
                  -- set attack timers
                  self.AttackStartTime = meAAData.endTime - meAAData.animationTime
                  self.AttackServerStart = GameTimer()
                  self.AttackEndTime = meAAData.endTime
                  self.AttackCastEndTime = meAAData.endTime - meAAData.windDownTime
                  
                  -- debug
                  if gsoSDK.Menu.orb.enabled:Value() then
                        if self.TestCount == 0 then
                              self.TestStartTime = GameTimer()
                        end
                        self.TestCount = self.TestCount + 1
                        if self.TestCount == 5 then
                              print("5 attacks in time: " .. tostring(GameTimer() - self.TestStartTime) .. "[sec]")
                              self.TestCount = 0
                              self.TestStartTime = 0
                        end
                  end
            end
            
            -- cursor not ready, chat open, is evading
            local isEvading = ExtLibEvade and ExtLibEvade.Evading
            if not gsoSDK.Cursor:IsCursorReady() or GameIsChatOpen() or isEvading then
                  return
            end
            -- ORBWALKER MODE
            if gsoSDK.Menu.orb.keys.combo:Value() then
                  self:AttackMove(gsoSDK.TS:GetComboTarget())
            elseif gsoSDK.Menu.orb.keys.laneclear:Value() then
                  if gsoSDK.Farm:CanLastHit() then
                        self:AttackMove(gsoSDK.TS:GetLastHitTarget())
                  elseif gsoSDK.Farm:CanLaneClear() then
                        self:AttackMove(gsoSDK.TS:GetLaneClearTarget())
                  else
                        self:AttackMove()
                  end
            elseif GameTimer() < self.LastMouseDown + 1 then
                  ControlMouseEvent(MOUSEEVENTF_RIGHTDOWN)
                  self.LastMouseDown = 0
            end
      end
--[[
▒█▀▀▀█ █▀▀█ █▀▀ █░░ █░░ 
░▀▀▀▄▄ █░░█ █▀▀ █░░ █░░ 
▒█▄▄▄█ █▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ 
]]
class "__gsoSpell"
      function __gsoSpell:__init()
            --[[ test dashSpell:
                  local cc= 0
                  if myHero.activeSpell and myHero.activeSpell.valid then cc = cc + 1; print('ok '..cc); print(myHero.activeSpell.name) end
                  if myHero.pathing.isDashing then print(cc.. " dash") end
            ]]
            self.dashSpell = {
                  ["sionr"] = true,
                  ["warwickr"] = true,
                  ["vir"] = true,
                  ["tristanaw"] = true,
                  ["shyvanatransformleap"] = true,
                  ["powerball"] = true,
                  ["leonazenithblade"] = true,
                  ["galioe"] = true,
                  ["galior"] = true,
                  ["blindmonkqone"] = true,
                  ["alphastrike"] = true,
                  ["nautilusanchordragmissile"] = true,
                  ["caitlynentrapment"] = true,
                  ["bandagetoss"] = true,
                  ["ekkoeattack"] = true,
                  ["ekkor"] = true,
                  ["evelynne"] = true,
                  ["evelynne2"] = true,
                  ["evelynnr"] = true,
                  ["ezrealarcaneshift"] = true,
                  ["crowstorm"] = true,
                  ["tahmkenchnewr"] = true,
                  ["shenr"] = true,
                  ["graveschargeshot"] = true,
                  ["jarvanivdragonstrike"] = true,
                  ["hecarimrampattack"] = true,
                  ["illaoiwattack"] = true,
                  ["riftwalk"] = true,
                  ["katarinae"] = true,
                  ["pantheonrjump"] = true
                  -- taliyahr
                  -- reksair
                  -- kled ?
                  -- rakanq, rakanr
                  -- sejuaniq ?
                  -- zace
                  -- zoe ?
                  -- kalistaq
                  -- eliseq ?
                  -- aurelionsol ?
            }
            self.Waypoints = {}
            self.LastQ = 0
            self.LastQk = 0
            self.LastW = 0
            self.LastWk = 0
            self.LastE = 0
            self.LastEk = 0
            self.LastR = 0
            self.LastRk = 0
            self.DelayedSpell = {}
            self.spellDraw = { q = false, w = false, e = false, r = false }
            if myHero.charName == "Aatrox" then
                  self.spellDraw = { q = true, qr = 650, e = true, er = 1000, r = true, rr = 550 }
            elseif myHero.charName == "Ahri" then
                  self.spellDraw = { q = true, qr = 880, w = true, wr = 700, e = true, er = 975, r = true, rr = 450 }
            elseif myHero.charName == "Akali" then
                  self.spellDraw = { q = true, qr = 600 + 120, w = true, wr = 475, e = true, er = 300, r = true, rr = 700 + 120 }
            elseif myHero.charName == "Alistar" then
                  self.spellDraw = { q = true, qr = 365, w = true, wr = 650 + 120, e = true, er = 350 }
            elseif myHero.charName == "Amumu" then
                  self.spellDraw = { q = true, qr = 1100, w = true, wr = 300, e = true, er = 350, r = true, rr = 550 }
            elseif myHero.charName == "Anivia" then
                  self.spellDraw = { q = true, qr = 1075, w = true, wr = 1000, e = true, er = 650 + 120, r = true, rr = 750 }
            elseif myHero.charName == "Annie" then
                  self.spellDraw = { q = true, qr = 625 + 120, w = true, wr = 625, r = true, rr = 600 }
            elseif myHero.charName == "Ashe" then
                  self.spellDraw = { w = true, wr = 1200 }
            elseif myHero.charName == "AurelionSol" then
                  self.spellDraw = { q = true, qr = 1075, w = true, wr = 600, e = true, ef = function() local eLvl = myHero:GetSpellData(_E).level; if eLvl == 0 then return 3000 else return 2000 + 1000 * eLvl end end, r = true, rr = 1500 }
            elseif myHero.charName == "Azir" then
                  self.spellDraw = { q = true, qr = 740, w = true, wr = 500, e = true, er = 1100, r = true, rr = 250 }
            elseif myHero.charName == "Bard" then
                  self.spellDraw = { q = true, qr = 950, w = true, wr = 800, e = true, er = 900, r = true, rr = 3400 }
            elseif myHero.charName == "Blitzcrank" then
                  self.spellDraw = { q = true, qr = 925, e = true, er = 300, r = true, rr = 600 }
            elseif myHero.charName == "Brand" then
                  self.spellDraw = { q = true, qr = 1050, w = true, wr = 900, e = true, er = 625 + 120, r = true, rr = 750 + 120 }
            elseif myHero.charName == "Braum" then
                  self.spellDraw = { q = true, qr = 1000, w = true, wr = 650 + 120, r = true, rr = 1250 }
            elseif myHero.charName == "Caitlyn" then
                  self.spellDraw = { q = true, qr = 1250, w = true, wr = 800, e = true, er = 750, r = true, rf = function() local rLvl = myHero:GetSpellData(_R).level; if rLvl == 0 then return 2000 else return 1500 + 500 * rLvl end end }
            elseif myHero.charName == "Camille" then
                  self.spellDraw = { q = true, qr = 325, w = true, wr = 610, e = true, er = 800, r = true, rr = 475 }
            elseif myHero.charName == "Cassiopeia" then
                  self.spellDraw = { q = true, qr = 850, w = true, wr = 800, e = true, er = 700, r = true, rr = 825 }
            elseif myHero.charName == "Chogath" then
                  self.spellDraw = { q = true, qr = 950, w = true, wr = 650, e = true, er = 500, r = true, rr = 175 + 120 }
            elseif myHero.charName == "Corki" then
                  self.spellDraw = { q = true, qr = 825, w = true, wr = 600, r = true, rr = 1225 }
            elseif myHero.charName == "Darius" then
                  self.spellDraw = { q = true, qr = 425, w = true, wr = 300, e = true, er = 535, r = true, rr = 460 + 120 }
            elseif myHero.charName == "Diana" then
                  self.spellDraw = { q = true, qr = 900, w = true, wr = 200, e = true, er = 450, r = true, rr = 825 }
            elseif myHero.charName == "DrMundo" then
                  self.spellDraw = { q = true, qr = 975, w = true, wr = 325 }
            elseif myHero.charName == "Draven" then
                  self.spellDraw = { e = true, er = 1050 }
            elseif myHero.charName == "Ekko" then
                  self.spellDraw = { q = true, qr = 1075, w = true, wr = 1600, e = true, er = 325 }
            elseif myHero.charName == "Elise" then
                  -- self.spellDraw = { need check form buff qHuman = 625, qSpider = 475, wHuman = 950, wSpider = math.huge(none), eHuman = 1075, eSpider = 750 }
            elseif myHero.charName == "Evelynn" then
                  self.spellDraw = { q = true, qr = 800, w = true, wf = function() local wLvl = myHero:GetSpellData(_W).level; if wLvl == 0 then return 1200 else return 1100 + 100 * wLvl end end, e = true, er = 210, r = true, rr = 450 }
            elseif myHero.charName == "Ezreal" then
                  self.spellDraw = { q = true, qr = 1150, w = true, wr = 1000, e = true, er = 475 }
            elseif myHero.charName == "Fiddlesticks" then
                  self.spellDraw = { q = true, qr = 575 + 120, w = true, wr = 650, e = true, er = 750 + 120, r = true, rr = 800 }
            elseif myHero.charName == "Fiora" then
                  self.spellDraw = { q = true, qr = 400, w = true, wr = 750, r = true, rr = 500 + 120 }
            elseif myHero.charName == "Fizz" then
                  self.spellDraw = { q = true, qr = 550 + 120, e = true, er = 400, r = true, rr = 1300 }
            elseif myHero.charName == "Galio" then
                  self.spellDraw = { q = true, qr = 825, w = true, wr = 350, e = true, er = 650, r = true, rf = function() local rLvl = myHero:GetSpellData(_R).level; if rLvl == 0 then return 4000 else return 3250 + 750 * rLvl end end }
            elseif myHero.charName == "Gangplank" then
                  self.spellDraw = { q = true, qr = 625 + 120, w = true, wr = 650, e = true, er = 1000 }
            elseif myHero.charName == "Garen" then
                  self.spellDraw = { e = true, er = 325, r = true, rr = 400 + 120 }
            elseif myHero.charName == "Gnar" then
                  self.spellDraw = { q = true, qr = 1100, r = true, rr = 475, w = false, e = false } -- wr (mega gnar) = 550, er (mini gnar) = 475, er (mega gnar) = 600
            elseif myHero.charName == "Gragas" then
                  self.spellDraw = { q = true, qr = 850, e = true, er = 600, r = true, rr = 1000 }
            elseif myHero.charName == "Graves" then
                  self.spellDraw = { q = true, qr = 925, w = true, wr = 950, e = true, er = 475, r = true, rr = 1000 }
            elseif myHero.charName == "Hecarim" then
                  self.spellDraw = { q = true, qr = 350, w = true, wr = 575 + 120, r = true, rr = 1000 }
            elseif myHero.charName == "Heimerdinger" then
                  self.spellDraw = { q = false, w = true, wr = 1325, e = true, er = 970 } --  qr (noR) = 350, wr (R) = 450
            elseif myHero.charName == "Illaoi" then
                  self.spellDraw = { q = true, qr = 850, w = true, wr = 350 + 120, e = true, er = 900, r = true, rr = 450 }
            elseif myHero.charName == "Irelia" then
                  self.spellDraw = { q = true, qr = 625 + 120, w = true, wr = 825, e = true, er = 900, r = true, rr = 1000 }
            elseif myHero.charName == "Ivern" then
                  self.spellDraw = { q = true, qr = 1075, w = true, wr = 1000, e = true, er = 750 + 120 }
            elseif myHero.charName == "Janna" then
                  self.spellDraw = { q = true, qf = function() local qt = GameTimer() - self.LastQk;if qt > 3 then return 1000 end local qrange = qt * 250;if qrange > 1750 then return 1750 end return qrange end, w = true, wr = 550 + 120, e = true, er = 800 + 120, r = true, rr = 725 }
            elseif myHero.charName == "JarvanIV" then
                  self.spellDraw = { q = true, qr = 770, w = true, wr = 625, e = true, er = 860, r = true, rr = 650 + 120 }
            elseif myHero.charName == "Jax" then
                  self.spellDraw = { q = true, qr = 700 + 120, e = true, er = 300 }
            elseif myHero.charName == "Jayce" then
                  --self.spellDraw = { q = true, qr = 700 + 120, e = true, er = 300, r = true }  (Mercury Hammer: q=600+120, w=285, e=240+120; Mercury Cannon: q=1050/1470, w=active, e=650
            elseif myHero.charName == "Jhin" then
                  self.spellDraw = { q = true, qr = 550 + 120, w = true, wr = 3000, e = true, er = 750, r = true, rr = 3500 }
            elseif myHero.charName == "Jinx" then
                  self.spellDraw = { q = true, qf = function() if self:HasBuff(myHero, "jinxq") then return 525 + myHero.boundingRadius + 35 else local qExtra = 25 * myHero:GetSpellData(_Q).level; return 575 + qExtra + myHero.boundingRadius + 35 end end, w = true, wr = 1450, e = true, er = 900 }
            elseif myHero.charName == "KogMaw" then
                  self.spellDraw = { q = true, qr = 1175, e = true, er = 1280, r = true, rf = function() local rlvl = myHero:GetSpellData(_R).level; if rlvl == 0 then return 1200 else return 900 + 300 * rlvl end end }
            elseif myHero.charName == "Lucian" then
                  self.spellDraw = { q = true, qr = 500+120, w = true, wr = 900+350, e = true, er = 425, r = true, rr = 1200 }
            elseif myHero.charName == "Nami" then
                  self.spellDraw = { q = true, qr = 875, w = true, wr = 725, e = true, er = 800, r = true, rr = 2750 }
            elseif myHero.charName == "Sivir" then
                  self.spellDraw = { q = true, qr = 1250, r = true, rr = 1000 }
            elseif myHero.charName == "Teemo" then
                  self.spellDraw = { q = true, qr = 680, r = true, rf = function() local rLvl = myHero:GetSpellData(_R).level; if rLvl == 0 then rLvl = 1 end return 150 + ( 250 * rLvl ) end }
            elseif myHero.charName == "Twitch" then
                  self.spellDraw = { w = true, wr = 950, e = true, er = 1200, r = true, rf = function() return myHero.range + 300 + ( myHero.boundingRadius * 2 ) end }
            elseif myHero.charName == "Tristana" then
                  self.spellDraw = { w = true, wr = 900 }
            elseif myHero.charName == "Varus" then
                  self.spellDraw = { q = true, qr = 1650, e = true, er = 950, r = true, rr = 1075 }
            elseif myHero.charName == "Vayne" then
                  self.spellDraw = { q = true, qr = 300, e = true, er = 550 }
            elseif myHero.charName == "Viktor" then
                  self.spellDraw = { q = true, qr = 600 + 2 * myHero.boundingRadius, w = true, wr = 700, e = true, er = 550 }
            elseif myHero.charName == "Xayah" then
                  self.spellDraw = { q = true, qr = 1100 }
            end
      end
      -- reduced damage by Marty
      function __gsoSpell:ReducedDmg(unit, dmg, isAP)
            if isAP then
                  local targetBaseMagicResist = unit.magicResist - unit.bonusMagicResist
                  local targetBonusMagicResist = unit.bonusMagicResist
                  local sourceMagicPen = myHero.magicPen
                  local sourceMagicPenPercent = myHero.magicPenPercent
                  local magicResistLeft = 0
                  magicResistLeft = targetBaseMagicResist + targetBonusMagicResist
                  if magicResistLeft < 0 then 
                        dmg = dmg * (2 - (100 / (100 - magicResistLeft)))
                  elseif magicResistLeft >= 0 then
                        if sourceMagicPenPercent > 0 then --  make sure it dont will calculate magicResist = 0 (tested ingame and myHero.magicPenPercent was always 0, should be 1)
                              targetBaseMagicResist = targetBaseMagicResist * sourceMagicPenPercent
                              targetBonusMagicResist = targetBonusMagicResist * sourceMagicPenPercent
                        end
                        magicResistLeft = targetBaseMagicResist + targetBonusMagicResist - sourceMagicPen
                        if magicResistLeft < 0 then
                              dmg = dmg
                        elseif magicResistLeft >= 0 then
                              dmg = dmg * (100 / (100 + magicResistLeft))
                        end
                  end	
            else
                  local targetBaseArmor = unit.armor - unit.bonusArmor
                  local targetBonusArmor = unit.bonusArmor
                  local sourceArmorPen = myHero.armorPen
                  local sourceArmorPenPercent = myHero.armorPenPercent
                  local sourceBonusArmorPenPercent = myHero.bonusArmorPenPercent
                  local myHerolevel = myHero.levelData.lvl
                  local armorLeft = 0
                  armorLeft = targetBaseArmor + targetBonusArmor
                  if armorLeft < 0 then
                        dmg = dmg * (2 - (100 / (100 - armorLeft)))
                  elseif armorLeft >= 0 then
                        if sourceArmorPenPercent > 0 then -- make sure it dont will calculate armor = 0 
                              targetBaseArmor = targetBaseArmor * sourceArmorPenPercent
                              targetBonusArmor = targetBonusArmor * sourceArmorPenPercent
                        end
                        if sourceBonusArmorPenPercent > 0 then --  make sure it dont will calculate armor = 0 
                              targetBonusArmor = targetBonusArmor * sourceBonusArmorPenPercent
                        end
                        armorLeft = targetBaseArmor + targetBonusArmor - (sourceArmorPen * (0.6 + (0.4 * myHerolevel * 0.0555555)))-- * 0.055555 entspricht /18, Formel für FlatDmgPen von Lethality
                        if armorLeft < 0 then
                              dmg = dmg
                        elseif armorLeft >= 0 then
                              dmg = dmg * (100 / (100 + armorLeft))
                        end
                  end
            end
            return dmg
      end
      function __gsoSpell:CalculateDmg(unit, spellData)
            local dmgType = spellData.dmgType and spellData.dmgType or ""
            if not unit then assert(false, "[234] CalculateDmg: unit is nil !") end
            if dmgType == "ad" and spellData.dmgAD then
                  local dmgAD = spellData.dmgAD - unit.shieldAD
                  return dmgAD < 0 and 0 or self:ReducedDmg(unit, dmgAD, false) 
            elseif dmgType == "ap" and spellData.dmgAP then
                  local dmgAP = spellData.dmgAP - unit.shieldAD - unit.shieldAP
                  return dmgAP < 0 and 0 or self:ReducedDmg(unit, dmgAP, true) 
            elseif dmgType == "true" and spellData.dmgTrue then
                  return spellData.dmgTrue - unit.shieldAD
            elseif dmgType == "mixed" and spellData.dmgAD and spellData.dmgAP then
                  local dmgAD = spellData.dmgAD - unit.shieldAD
                  local shieldAD = dmgAD < 0 and (-1) * dmgAD or 0
                  dmgAD = dmgAD < 0 and 0 or self:ReducedDmg(unit, dmgAD, false)
                  local dmgAP = spellData.dmgAP - shieldAD - unit.shieldAP
                  dmgAP = dmgAP < 0 and 0 or self:ReducedDmg(unit, dmgAP, true)
                  return dmgAD + dmgAP
            end
            assert(false, "[234] CalculateDmg: spellData - expected array { dmgType = string(ap or ad or mixed or true), dmgAP = number or dmgAD = number or ( dmgAP = number and dmgAD = number ) or dmgTrue = number } !")
      end
      function __gsoSpell:GetLastSpellTimers()
            return self.LastQ, self.LastQk, self.LastW, self.LastWk, self.LastE, self.LastEk, self.LastR, self.LastRk
      end
      function __gsoSpell:HasBuff(unit, bName)
            bName = bName:lower()
            for i = 0, unit.buffCount do
                  local buff = unit:GetBuff(i)
                  if buff and buff.count > 0 and buff.name:lower() == bName then
                        return true
                  end
            end
            return false
      end
      function __gsoSpell:GetBuffDuration(unit, bName)
            bName = bName:lower()
            for i = 0, unit.buffCount do
                  local buff = unit:GetBuff(i)
                  if buff and buff.count > 0 and buff.name:lower() == bName then
                        return buff.duration
                  end
            end
            return 0
      end
      function __gsoSpell:GetBuffCount(unit, bName)
            bName = bName:lower()
            for i = 0, unit.buffCount do
                  local buff = unit:GetBuff(i)
                  if buff and buff.count > 0 and buff.name:lower() == bName then
                        return buff.count
                  end
            end
            return 0
      end
      function __gsoSpell:GetDamage(unit, spellData)
            return self:CalculateDmg(unit, spellData)
      end
      function __gsoSpell:CheckSpellDelays(delays)
            if GameTimer() < self.LastQ + delays.q or GameTimer() < self.LastQk + delays.q then return false end
            if GameTimer() < self.LastW + delays.w or GameTimer() < self.LastWk + delays.w then return false end
            if GameTimer() < self.LastE + delays.e or GameTimer() < self.LastEk + delays.e then return false end
            if GameTimer() < self.LastR + delays.r or GameTimer() < self.LastRk + delays.r then return false end
            return true
      end
      function __gsoSpell:CustomIsReady(spell, cd)
            local passT
            if spell == _Q then
                  passT = GameTimer() - self.LastQk
            elseif spell == _W then
                  passT = GameTimer() - self.LastWk
            elseif spell == _E then
                  passT = GameTimer() - self.LastEk
            elseif spell == _R then
                  passT = GameTimer() - self.LastRk
            end
            local cdr = 1 - myHero.cdr
            cd = cd * cdr
            if passT - gsoSDK.Utilities:GetMaxLatency() - 0.15 > cd then
                  return true
            end
            return false
      end
      function __gsoSpell:IsReady(spell, delays)
            return gsoSDK.Cursor:IsCursorReady() and self:CheckSpellDelays(delays) and GameCanUseSpell(spell) == 0
      end
      function __gsoSpell:GetWaypoints(unit)
            local path = unit.pathing
            return { IsMoving = path.hasMovePath, Path = path.endPos, Tick = GameTimer() }
      end
      function __gsoSpell:SaveWaypointsSingle(unit)
            local unitID = unit.networkID
            -- create waypoints key
            if not self.Waypoints[unitID] then
                  self.Waypoints[unitID] = self:GetWaypoints(unit)
                  return
            end
            -- get new waypoints
            local currentWaypoints = self:GetWaypoints(unit)
            local currentWaypointsT = self.Waypoints[unitID]
            -- isMoving is not equal -> save new waypoint
            if currentWaypoints.IsMoving ~= currentWaypointsT.IsMoving then
                  self.Waypoints[unitID] = currentWaypoints
                  --if debugMode then print("[saveWaypoints] -> isMoving not equal") end
                  return
            end
            -- check if paths are equal
            if currentWaypoints.IsMoving then
                  -- last
                  local xx = currentWaypoints.Path.x
                  local zz = currentWaypoints.Path.z
                  local xxT = currentWaypointsT.Path.x
                  local zzT = currentWaypointsT.Path.z
                  -- vectors are not equal
                  if xx ~= xxT or zz ~= zzT then
                        --if debugMode then print("[saveWaypoints] -> paths vectors are not equal") end
                        self.Waypoints[unitID] = currentWaypoints
                  end
            end
      end
      function __gsoSpell:SaveWaypoints(enemyList)
            for i = 1, #enemyList do
                  local unit = enemyList[i]
                  self:SaveWaypointsSingle(unit)
            end
      end
      --[[ http://leagueoflegends.wikia.com/wiki/Types_of_Crowd_Control
      ok
            STUN = 5
            SNARE = 11
            SUPRESS = 24
            KNOCKUP = 29
      good
            FEAR = 21 -> fiddle Q, ...
            CHARM = 22 -> ahri E, ...
      not good
            TAUNT = 8 -> rammus E, ... can move too fast + anyway will detect attack
            SLOW = 10 -> can move too fast -> nasus W, zilean E are ok. Rylai item, ... not good
            KNOCKBACK = 30 -> alistar W, lee sin R, ... - no no
      ]]
      function __gsoSpell:IsImmobile(unit, delay)
            for i = 0, unit.buffCount do
                  local buff = unit:GetBuff(i)
                  if buff and buff.count > 0 and buff.duration > delay then
                        local bType = buff.type
                        if bType == 5 or bType == 11 or bType == 21 or bType == 22 or bType == 24 or bType == 29 or buff.name == "recall" then
                              return true
                        end
                  end
            end
            return false
      end
      function __gsoSpell:ImmobileTime(unit)
            local iT = 0
            for i = 0, unit.buffCount do
                  local buff = unit:GetBuff(i)
                  if buff and buff.count > 0 then
                        local bType = buff.type
                        if bType == 5 or bType == 11 or bType == 21 or bType == 22 or bType == 24 or bType == 29 or buff.name == "recall" then
                              local bDuration = buff.duration
                              if bDuration > iT then
                                    iT = bDuration
                              end
                        end
                  end
            end
            return iT
      end
      function __gsoSpell:IsSlowed(unit, delay)
            for i = 0, unit.buffCount do
                  local buff = unit:GetBuff(i)
                  if from and buff.count > 0 and buff.type == 10 and buff.duration >= delay then
                        return true
                  end
            end
            return false
      end
      function __gsoSpell:ClosestPointOnLineSegment(p, p1, p2)
            --local px,pz,py = p.x, p.z, p.y
            --local ax,az,ay = p1.x, p1.z, p1.y
            --local bx,bz,by = p2.x, p2.z, p2.y
            local px,pz = p.x, p.z
            local ax,az = p1.x, p1.z
            local bx,bz = p2.x, p2.z
            local bxax = bx - ax
            local bzaz = bz - az
            --local byay = by - by
            --local t = ((px - ax) * bxax + (pz - az) * bzaz + (py - ay) * byay) / (bxax * bxax + bzaz * bzaz + byay * byay)
            local t = ((px - ax) * bxax + (pz - az) * bzaz) / (bxax * bxax + bzaz * bzaz)
            if t < 0 then
                  return p1, false
            elseif t > 1 then
                  return p2, false
            else
                  return { x = ax + t * bxax, z = az + t * bzaz }, true
                  --return Vector({ x = ax + t * bxax, z = az + t * bzaz, y = ay + t * byay }), true
            end
      end
      function __gsoSpell:IsMinionCollision(unit, spellData, prediction)
            local width = spellData.radius * 0.77
            local enemyMinions = gsoSDK.ObjectManager.Units.EnemyMinions
            local mePos = myHero.pos
            for i = 1, #enemyMinions do
                  local minion = enemyMinions[i]
                  if minion ~= unit then
                        -- get prediction width
                        local bbox = minion.boundingRadius
                        local predWidth = width + bbox + 20
                        -- get middle point of not moving minion
                        local minionPos = minion.pos
                        local point,onLineSegment = self:ClosestPointOnLineSegment(minionPos, prediction and unit:GetPrediction(spellData.speed,spellData.delay) or unit.pos, myHero.pos)
                        local x = minionPos.x - point.x
                        local z = minionPos.z - point.z
                        if onLineSegment and x * x + z * z < predWidth * predWidth then
                              return true
                        end
                        -- get middle point of moving minion
                        local mPathing = minion.pathing
                        if mPathing.hasMovePath then
                              local minionPosPred = minionPos:Extended(mPathing.endPos, spellData.delay + (mePos:DistanceTo(minionPos) / spellData.speed))
                              point,onLineSegment = self:ClosestPointOnLineSegment(minionPosPred, prediction and unit:GetPrediction(spellData.speed,spellData.delay) or unit.pos, myHero.pos)
                              local xx = minionPosPred.x - point.x
                              local zz = minionPosPred.z - point.z
                              if onLineSegment and xx * xx + zz * zz < predWidth * predWidth then
                                    return true
                              end
                        end
                  end
            end
            return false
      end
      
      -- Prediction: IsCollision
      function __gsoSpell:IsCollision(unit, spellData)
            if unit:GetCollision(spellData.radius, spellData.speed, spellData.delay) > 0 or gsoSDK.Spell:IsMinionCollision(unit, spellData) or gsoSDK.Spell:IsMinionCollision(unit, spellData, true) then
                  return true
            end
            return false
      end
      
      function __gsoSpell:CastSpell(spell, unit, from, spellData, HitChance)
            local result = false
            if not unit then
                  ControlKeyDown(spell)
                  ControlKeyUp(spell)
                  result = true
            else
                  if GameTimer() < gsoSDK.Orbwalker.LastMoveTime + 0.05 then
                        return false
                  end
                  local CastPos
                  local unitPos = unit.pos
                  if from and spellData and HitChance then
                        local unitID = unit.networkID
                        local radius = spellData.radius
                        local speed = spellData.speed
                        local sType = spellData.sType
                        local collision = spellData.collision
                        local range = spellData.range - 35
                        if sType == "line" then
                              range = range - radius * 0.5
                        end
                        local interceptionTime = speed < 10000 and GetInterceptionTime(from, unitPos, unit.pathing.endPos, unit.ms, speed) or 0
                        local latency = GameLatency() * 0.001 + gsoSDK.Utilities:GetMaxLatency()
                        latency = latency / 2
                        local delay = spellData.delay + interceptionTime
                        -- check collision
                        if collision and self:IsCollision(unit, spellData) then
                              return false
                        end
                        -- declare hitchance
                        local hitChance = 1
                        -- stop if dashing (galio E etc.)
                        if unit.pathing.isDashing then
                              --if debugMode then print("PREDICTION FALSE: IS DASHING") end
                              return false
                        end
                        -- stop if has predash, dash, tp, speed spells
                        local isCastingSpell = unit.activeSpell and unit.activeSpell.valid
                        if isCastingSpell and self.dashSpell[unit.activeSpell.name:lower()] then
                              --if debugMode then print("PREDICTION FALSE: DASH SPELL") end
                              return false
                        end
                        -- get prediction pos
                        local fromToUnit = from:DistanceTo(unitPos) / speed
                        -- immobile
                        local isImmobile = self:IsImmobile(unit, delay + fromToUnit)
                        -- enemy is immobile
                        if isImmobile or (isCastingSpell and unit.activeSpell.castEndTime - GameTimer() > delay + latency - 0.15) then
                              CastPos = unit.pos
                              hitChance = 2
                        elseif unit.pathing.hasMovePath then
                              -- get endPos
                              local endPos = unit.pathing.endPos
                              local UnitEnd = GetFastDistance(unitPos, endPos)
                              -- not moving or too short click
                              if UnitEnd < 1000 then -- 50*50
                                    if debugMode then print("PREDICTION FALSE: SHORT CLICK") end
                                    return false
                              end
                              -- get last waypoint
                              self:SaveWaypointsSingle(unit)
                              -- not moving
                              if not self.Waypoints[unitID].IsMoving then
                                    return false
                              end
                              -- hitchance high
                              if GameTimer() - self.Waypoints[unitID].Tick < 0.1 or UnitEnd > 4000000 or from:AngleBetween(unitPos, endPos) < 25 or self:IsSlowed(unit, delay + fromToUnit) then
                                    if debugMode then print("HITCHANCE HIGH") end
                                    hitChance = 2
                              end
                              -- get predict pos
                              CastPos = unit:GetPrediction(math.huge,delay):Extended(unitPos, radius * 0.5)
                              -- too short or too long distance between unit position and cast pos
                              local UnitCastPos = GetFastDistance(unitPos, CastPos)
                              if UnitCastPos < 1000 or UnitCastPos > 250000 then -- 50*50, 500*500
                                    return false
                              end
                        elseif not isCastingSpell and not self:IsImmobile(unit, 0) then
                              -- get last waypoint
                              self:SaveWaypointsSingle(unit)
                              -- isMoving
                              if self.Waypoints[unitID].IsMoving then
                                    return false
                              end
                              if GameTimer() - self.Waypoints[unitID].Tick > 0.25 then
                                    CastPos = unit.pos
                              end
                              if GameTimer() - self.Waypoints[unitID].Tick > 1 then
                                    hitChance = 2
                              end
                        end
                        if not CastPos or not CastPos:ToScreen().onScreen then
                              --if debugMode then print("PREDICTION FALSE: NOT ON SCREEN") end
                              return false
                        end
                        if GetFastDistance(from, CastPos) > range * range then
                              --if debugMode then print("PREDICTION FALSE: OUT OF RANGE") end
                              return false
                        end
                        if hitChance >= HitChance then
                              gsoSDK.Cursor:SetCursor(cursorPos, CastPos, 0.06)
                              ControlSetCursorPos(CastPos)
                              ControlKeyDown(spell)
                              ControlKeyUp(spell)
                              gsoSDK.Orbwalker.LastMoveLocal = 0
                              result = true
                        end
                  else
                        CastPos = unit.pos
                        gsoSDK.Cursor:SetCursor(cursorPos, CastPos, 0.06)
                        ControlSetCursorPos(CastPos)
                        ControlKeyDown(spell)
                        ControlKeyUp(spell)
                        gsoSDK.Orbwalker.LastMoveLocal = 0
                        result = true
                  end
            end
            if result then
                  if spell == HK_Q then
                        self.LastQ = GameTimer()
                  elseif spell == HK_W then
                        self.LastW = GameTimer()
                  elseif spell == HK_E then
                        self.LastE = GameTimer()
                  elseif spell == HK_R then
                        self.LastR = GameTimer()
                  end
            end
            return result
      end
      function __gsoSpell:CastManualSpell(spell, delays)
            local kNum = 0
            if spell == _W then
                  kNum = 1
            elseif spell == _E then
                  kNum = 2
            elseif spell == _R then
                  kNum = 3
            end
            if GameCanUseSpell(spell) == 0 then
                  for k,v in pairs(self.DelayedSpell) do
                        if k == kNum then
                              if gsoSDK.Cursor:IsCursorReady() and self:CheckSpellDelays(delays) then
                                    v[1]()
                                    gsoSDK.Cursor:SetCursor(cursorPos, nil, 0.06)
                                    if k == 0 then
                                          self.LastQ = GameTimer()
                                    elseif k == 1 then
                                          self.LastW = GameTimer()
                                    elseif k == 2 then
                                          self.LastE = GameTimer()
                                    elseif k == 3 then
                                          self.LastR = GameTimer()
                                    end
                                    self.DelayedSpell[k] = nil
                                    break
                              end
                              if GameTimer() - v[2] > 0.125 then
                                    self.DelayedSpell[k] = nil
                              end
                              break
                        end
                  end
            end
      end
      function __gsoSpell:WndMsg(msg, wParam)
            local manualNum = -1
            if wParam == HK_Q and GameTimer() > self.LastQk + 1 and GameCanUseSpell(_Q) == 0 then
                  self.LastQk = GameTimer()
                  manualNum = 0
            elseif wParam == HK_W and GameTimer() > self.LastWk + 1 and GameCanUseSpell(_W) == 0 then
                  self.LastWk = GameTimer()
                  manualNum = 1
            elseif wParam == HK_E and GameTimer() > self.LastEk + 1 and GameCanUseSpell(_E) == 0 then
                  self.LastEk = GameTimer()
                  manualNum = 2
            elseif wParam == HK_R and GameTimer() > self.LastRk + 1 and GameCanUseSpell(_R) == 0 then
                  self.LastRk = GameTimer()
                  manualNum = 3
            end
            if manualNum > -1 and not self.DelayedSpell[manualNum] then
                  if gsoSDK.Menu.orb.keys.combo:Value() or gsoSDK.Menu.orb.keys.laneclear:Value() then
                        self.DelayedSpell[manualNum] = {
                              function()
                                    ControlKeyDown(wParam)
                                    ControlKeyUp(wParam)
                                    ControlKeyDown(wParam)
                                    ControlKeyUp(wParam)
                                    ControlKeyDown(wParam)
                                    ControlKeyUp(wParam)
                              end,
                              GameTimer()
                        }
                  end
            end
      end
      function __gsoSpell:CreateDrawMenu()
            gsoSDK.Menu.gsodraw:MenuElement({name = "Spell Ranges", id = "circle1", type = MENU,
                  onclick = function()
                        if self.spellDraw.q then
                              gsoSDK.Menu.gsodraw.circle1.qrange:Hide(true)
                              gsoSDK.Menu.gsodraw.circle1.qrangecolor:Hide(true)
                              gsoSDK.Menu.gsodraw.circle1.qrangewidth:Hide(true)
                        end
                        if self.spellDraw.w then
                              gsoSDK.Menu.gsodraw.circle1.wrange:Hide(true)
                              gsoSDK.Menu.gsodraw.circle1.wrangecolor:Hide(true)
                              gsoSDK.Menu.gsodraw.circle1.wrangewidth:Hide(true)
                        end
                        if self.spellDraw.e then
                              gsoSDK.Menu.gsodraw.circle1.erange:Hide(true)
                              gsoSDK.Menu.gsodraw.circle1.erangecolor:Hide(true)
                              gsoSDK.Menu.gsodraw.circle1.erangewidth:Hide(true)
                        end
                        if self.spellDraw.r then
                              gsoSDK.Menu.gsodraw.circle1.rrange:Hide(true)
                              gsoSDK.Menu.gsodraw.circle1.rrangecolor:Hide(true)
                              gsoSDK.Menu.gsodraw.circle1.rrangewidth:Hide(true)
                        end
                  end
            })
            if self.spellDraw.q then
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({name = "Q Range", id = "note5", icon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/arrow.png", type = SPACE,
                        onclick = function()
                              gsoSDK.Menu.gsodraw.circle1.qrange:Hide()
                              gsoSDK.Menu.gsodraw.circle1.qrangecolor:Hide()
                              gsoSDK.Menu.gsodraw.circle1.qrangewidth:Hide()
                        end
                  })
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "qrange", name = "        Enabled", value = true})
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "qrangecolor", name = "        Color", color = DrawColor(255, 66, 134, 244)})
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "qrangewidth", name = "        Width", value = 1, min = 1, max = 10})
            end
            if self.spellDraw.w then
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({name = "W Range", id = "note6", icon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/arrow.png", type = SPACE,
                        onclick = function()
                              gsoSDK.Menu.gsodraw.circle1.wrange:Hide()
                              gsoSDK.Menu.gsodraw.circle1.wrangecolor:Hide()
                              gsoSDK.Menu.gsodraw.circle1.wrangewidth:Hide()
                        end
                  })
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "wrange", name = "        Enabled", value = true})
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "wrangecolor", name = "        Color", color = DrawColor(255, 92, 66, 244)})
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "wrangewidth", name = "        Width", value = 1, min = 1, max = 10})
            end
            if self.spellDraw.e then
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({name = "E Range", id = "note7", icon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/arrow.png", type = SPACE,
                        onclick = function()
                              gsoSDK.Menu.gsodraw.circle1.erange:Hide()
                              gsoSDK.Menu.gsodraw.circle1.erangecolor:Hide()
                              gsoSDK.Menu.gsodraw.circle1.erangewidth:Hide()
                        end
                  })
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "erange", name = "        Enabled", value = true})
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "erangecolor", name = "        Color", color = DrawColor(255, 66, 244, 149)})
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "erangewidth", name = "        Width", value = 1, min = 1, max = 10})
            end
            if self.spellDraw.r then
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({name = "R Range", id = "note8", icon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/arrow.png", type = SPACE,
                        onclick = function()
                              gsoSDK.Menu.gsodraw.circle1.rrange:Hide()
                              gsoSDK.Menu.gsodraw.circle1.rrangecolor:Hide()
                              gsoSDK.Menu.gsodraw.circle1.rrangewidth:Hide()
                        end
                  })
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "rrange", name = "        Enabled", value = true})
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "rrangecolor", name = "        Color", color = DrawColor(255, 244, 182, 66)})
                  gsoSDK.Menu.gsodraw.circle1:MenuElement({id = "rrangewidth", name = "        Width", value = 1, min = 1, max = 10})
            end
      end
      function __gsoSpell:Draw()
            local drawMenu = gsoSDK.Menu.gsodraw.circle1
            if self.spellDraw.q and drawMenu.qrange:Value() then
                  local qrange = self.spellDraw.qf and self.spellDraw.qf() or self.spellDraw.qr
                  DrawCircle(myHero.pos, qrange, drawMenu.qrangewidth:Value(), drawMenu.qrangecolor:Value())
            end
            if self.spellDraw.w and drawMenu.wrange:Value() then
                  local wrange = self.spellDraw.wf and self.spellDraw.wf() or self.spellDraw.wr
                  DrawCircle(myHero.pos, wrange, drawMenu.wrangewidth:Value(), drawMenu.wrangecolor:Value())
            end
            if self.spellDraw.e and drawMenu.erange:Value() then
                  local erange = self.spellDraw.ef and self.spellDraw.ef() or self.spellDraw.er
                  DrawCircle(myHero.pos, erange, drawMenu.erangewidth:Value(), drawMenu.erangecolor:Value())
            end
            if self.spellDraw.r and drawMenu.rrange:Value() then
                  local rrange = self.spellDraw.rf and self.spellDraw.rf() or self.spellDraw.rr
                  DrawCircle(myHero.pos, rrange, drawMenu.rrangewidth:Value(), drawMenu.rrangecolor:Value())
            end
      end
--[[
▀▀█▀▀ █▀▀█ █▀▀█ █▀▀▀ █▀▀ ▀▀█▀▀ 　 ▒█▀▀▀█ █▀▀ █░░ █▀▀ █▀▀ ▀▀█▀▀ █▀▀█ █▀▀█ 
░▒█░░ █▄▄█ █▄▄▀ █░▀█ █▀▀ ░░█░░ 　 ░▀▀▀▄▄ █▀▀ █░░ █▀▀ █░░ ░░█░░ █░░█ █▄▄▀ 
░▒█░░ ▀░░▀ ▀░▀▀ ▀▀▀▀ ▀▀▀ ░░▀░░ 　 ▒█▄▄▄█ ▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ░░▀░░ ▀▀▀▀ ▀░▀▀ 
]]
class "__gsoTS"
      function __gsoTS:__init()
            -- Last LastHit Minion
            self.LastHandle = 0
            -- Last LaneClear Minion
            self.LastLCHandle = 0
            self.SelectedTarget = nil
            self.LastSelTick = 0
            self.LastHeroTarget = nil
            self.FarmMinions = {}
            self.Priorities = {
                  ["Aatrox"] = 3, ["Ahri"] = 2, ["Akali"] = 2, ["Alistar"] = 5, ["Amumu"] = 5, ["Anivia"] = 2, ["Annie"] = 2, ["Ashe"] = 1, ["AurelionSol"] = 2, ["Azir"] = 2,
                  ["Bard"] = 3, ["Blitzcrank"] = 5, ["Brand"] = 2, ["Braum"] = 5, ["Caitlyn"] = 1, ["Camille"] = 3, ["Cassiopeia"] = 2, ["Chogath"] = 5, ["Corki"] = 1,
                  ["Darius"] = 4, ["Diana"] = 2, ["DrMundo"] = 5, ["Draven"] = 1, ["Ekko"] = 2, ["Elise"] = 3, ["Evelynn"] = 2, ["Ezreal"] = 1, ["Fiddlesticks"] = 3, ["Fiora"] = 3,
                  ["Fizz"] = 2, ["Galio"] = 5, ["Gangplank"] = 2, ["Garen"] = 5, ["Gnar"] = 5, ["Gragas"] = 4, ["Graves"] = 2, ["Hecarim"] = 4, ["Heimerdinger"] = 3, ["Illaoi"] =  3,
                  ["Irelia"] = 3, ["Ivern"] = 5, ["Janna"] = 4, ["JarvanIV"] = 3, ["Jax"] = 3, ["Jayce"] = 2, ["Jhin"] = 1, ["Jinx"] = 1, ["Kalista"] = 1, ["Karma"] = 2, ["Karthus"] = 2,
                  ["Kassadin"] = 2, ["Katarina"] = 2, ["Kayle"] = 2, ["Kayn"] = 2, ["Kennen"] = 2, ["Khazix"] = 2, ["Kindred"] = 2, ["Kled"] = 4, ["KogMaw"] = 1, ["Leblanc"] = 2,
                  ["LeeSin"] = 3, ["Leona"] = 5, ["Lissandra"] = 2, ["Lucian"] = 1, ["Lulu"] = 3, ["Lux"] = 2, ["Malphite"] = 5, ["Malzahar"] = 3, ["Maokai"] = 4, ["MasterYi"] = 1,
                  ["MissFortune"] = 1, ["MonkeyKing"] = 3, ["Mordekaiser"] = 2, ["Morgana"] = 3, ["Nami"] = 3, ["Nasus"] = 4, ["Nautilus"] = 5, ["Nidalee"] = 2, ["Nocturne"] = 2,
                  ["Nunu"] = 4, ["Olaf"] = 4, ["Orianna"] = 2, ["Ornn"] = 4, ["Pantheon"] = 3, ["Poppy"] = 4, ["Quinn"] = 1, ["Rakan"] = 3, ["Rammus"] = 5, ["RekSai"] = 4,
                  ["Renekton"] = 4, ["Rengar"] = 2, ["Riven"] = 2, ["Rumble"] = 2, ["Ryze"] = 2, ["Sejuani"] = 4, ["Shaco"] = 2, ["Shen"] = 5, ["Shyvana"] = 4, ["Singed"] = 5,
                  ["Sion"] = 5, ["Sivir"] = 1, ["Skarner"] = 4, ["Sona"] = 3, ["Soraka"] = 3, ["Swain"] = 3, ["Syndra"] = 2, ["TahmKench"] = 5, ["Taliyah"] = 2, ["Talon"] = 2,
                  ["Taric"] = 5, ["Teemo"] = 2, ["Thresh"] = 5, ["Tristana"] = 1, ["Trundle"] = 4, ["Tryndamere"] = 2, ["TwistedFate"] = 2, ["Twitch"] = 1, ["Udyr"] = 4, ["Urgot"] = 4,
                  ["Varus"] = 1, ["Vayne"] = 1, ["Veigar"] = 2, ["Velkoz"] = 2, ["Vi"] = 4, ["Viktor"] = 2, ["Vladimir"] = 3, ["Volibear"] = 4, ["Warwick"] = 4, ["Xayah"] = 1,
                  ["Xerath"] = 2, ["XinZhao"] = 3, ["Yasuo"] = 2, ["Yorick"] = 4, ["Zac"] = 5, ["Zed"] = 2, ["Ziggs"] = 2, ["Zilean"] = 3, ["Zoe"] = 2, ["Zyra"] = 2
            }
            self.PriorityMultiplier = {
                  [1] = 1,
                  [2] = 1.15,
                  [3] = 1.3,
                  [4] = 1.45,
                  [5] = 1.6,
                  [6] = 1.75
            }
      end
      function __gsoTS:GetSelectedTarget()
            return self.SelectedTarget
      end
      function __gsoTS:CreatePriorityMenu(charName)
            local priority = self.Priorities[charName] ~= nil and self.Priorities[charName] or 5
            gsoSDK.Menu.ts.priority:MenuElement({ id = charName, name = charName, value = priority, min = 1, max = 5, step = 1 })
      end
      function __gsoTS:CreateMenu(menu)
            gsoSDK.Menu:MenuElement({name = "Target Selector", id = "ts", type = MENU, leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/ts.png" })
                  gsoSDK.Menu.ts:MenuElement({ id = "Mode", name = "Mode", value = 1, drop = { "Auto", "Closest", "Least Health", "Least Priority" } })
                  gsoSDK.Menu.ts:MenuElement({ id = "priority", name = "Priorities", type = MENU })
                        gsoSDK.ObjectManager:OnEnemyHeroLoad(function(hero) self:CreatePriorityMenu(hero.charName) end)
                  gsoSDK.Menu.ts:MenuElement({ id = "selected", name = "Selected Target", type = MENU })
                        gsoSDK.Menu.ts.selected:MenuElement({ id = "enable", name = "Enable", value = true })
                  gsoSDK.Menu.ts:MenuElement({name = "LastHit Mode", id = "lasthitmode", value = 1, drop = { "Accuracy", "Fast" } })
                  gsoSDK.Menu.ts:MenuElement({name = "LaneClear Should Wait Time", id = "shouldwaittime", value = 200, min = 0, max = 1000, step = 50, tooltip = "Less Value = Faster LaneClear" })
                  gsoSDK.Menu.ts:MenuElement({name = "LaneClear Harass", id = "laneset", value = true })
      end
      function __gsoTS:CreateDrawMenu(menu)
            gsoSDK.Menu.gsodraw:MenuElement({name = "Selected Target",  id = "selected", type = MENU})
                  gsoSDK.Menu.gsodraw.selected:MenuElement({name = "Enabled",  id = "enabled", value = true})
                  gsoSDK.Menu.gsodraw.selected:MenuElement({name = "Color",  id = "color", color = DrawColor(255, 204, 0, 0)})
                  gsoSDK.Menu.gsodraw.selected:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
                  gsoSDK.Menu.gsodraw.selected:MenuElement({name = "Radius",  id = "radius", value = 150, min = 1, max = 300})
            gsoSDK.Menu.gsodraw:MenuElement({name = "LastHitable Minion",  id = "lasthit", type = MENU})
                  gsoSDK.Menu.gsodraw.lasthit:MenuElement({name = "Enabled",  id = "enabled", value = true})
                  gsoSDK.Menu.gsodraw.lasthit:MenuElement({name = "Color",  id = "color", color = DrawColor(150, 255, 255, 255)})
                  gsoSDK.Menu.gsodraw.lasthit:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
                  gsoSDK.Menu.gsodraw.lasthit:MenuElement({name = "Radius",  id = "radius", value = 50, min = 1, max = 100})
            gsoSDK.Menu.gsodraw:MenuElement({name = "Almost LastHitable Minion",  id = "almostlasthit", type = MENU})
                  gsoSDK.Menu.gsodraw.almostlasthit:MenuElement({name = "Enabled",  id = "enabled", value = true})
                  gsoSDK.Menu.gsodraw.almostlasthit:MenuElement({name = "Color",  id = "color", color = DrawColor(150, 239, 159, 55)})
                  gsoSDK.Menu.gsodraw.almostlasthit:MenuElement({name = "Width",  id = "width", value = 3, min = 1, max = 10})
                  gsoSDK.Menu.gsodraw.almostlasthit:MenuElement({name = "Radius",  id = "radius", value = 50, min = 1, max = 100})
      end
      function __gsoTS:GetTarget(enemyHeroes, dmgAP)
            local selectedID
            if gsoSDK.Menu.ts.selected.enable:Value() and self.SelectedTarget then
                  selectedID = self.SelectedTarget.networkID
            end
            local result = nil
            local num = 10000000
            local mode = gsoSDK.Menu.ts.Mode:Value()
            for i = 1, #enemyHeroes do
                  local x
                  local unit = enemyHeroes[i]
                  if selectedID and unit.networkID == selectedID then
                        return self.SelectedTarget
                  elseif mode == 1 then
                        local unitName = unit.charName
                        local multiplier = self.PriorityMultiplier[gsoSDK.Menu.ts.priority[unitName] and gsoSDK.Menu.ts.priority[unitName]:Value() or 6]
                        local def = dmgAP and multiplier * (unit.magicResist - myHero.magicPen) or multiplier * (unit.armor - myHero.armorPen)
                        if def > 0 then
                              def = dmgAP and myHero.magicPenPercent * def or myHero.bonusArmorPenPercent * def
                        end
                        x = ( ( unit.health * multiplier * ( ( 100 + def ) / 100 ) ) - ( unit.totalDamage * unit.attackSpeed * 2 ) ) - unit.ap
                  elseif mode == 2 then
                        x = unit.pos:DistanceTo(myHero.pos)
                  elseif mode == 3 then
                        x = unit.health
                  elseif mode == 4 then
                        local unitName = unit.charName
                        x = gsoSDK.Menu.ts.priority[unitName] and gsoSDK.Menu.ts.priority[unitName]:Value() or 6
                  end
                  if x < num then
                        num = x
                        result = unit
                  end
            end
            return result
      end
      function __gsoTS:GetLastHeroTarget()
            return self.LastHeroTarget
      end
      function __gsoTS:GetFarmMinions()
            return self.FarmMinions
      end
      function __gsoTS:GetComboTarget()
            local comboT = self:GetTarget(gsoSDK.ObjectManager:GetEnemyHeroes(myHero.range+myHero.boundingRadius - 35, true, "attack"), false)
            if comboT ~= nil then
                  self.LastHeroTarget = comboT
            end
            return comboT
      end
      function __gsoTS:GetLastHitTarget()
            local min = 10000000
            local result = nil
            for i = 1, #self.FarmMinions do
                  local enemyMinion = self.FarmMinions[i]
                  if enemyMinion.LastHitable and enemyMinion.PredictedHP < min then
                        min = enemyMinion.PredictedHP
                        result = enemyMinion.Minion
                  end
            end
            if result ~= nil then
                  self.LastHandle = result.handle
            end
            return result
      end
      function __gsoTS:GetLaneClearTarget()
            local enemyTurrets = gsoSDK.ObjectManager:GetEnemyTurrets(myHero.range+myHero.boundingRadius - 35, true)
            for i = 1, #enemyTurrets do
                  return enemyTurrets[i]
            end
            if gsoSDK.Menu.ts.laneset:Value() then
                  local result = self:GetComboTarget()
                  if result then return result end
            end
            local result = nil
            if gsoSDK.Farm:CanLaneClearTime() then
                  local min = 10000000
                  for i = 1, #self.FarmMinions do
                        local enemyMinion = self.FarmMinions[i]
                        if enemyMinion.PredictedHP < min then
                              min = enemyMinion.PredictedHP
                              result = enemyMinion.Minion
                        end
                  end
            end
            if result ~= nil then
                  self.LastLCHandle = result.handle
            end
            return result
      end
      function __gsoTS:GetClosestEnemy(enemyList, maxDistance)
            local result = nil
            for i = 1, #enemyList do
                  local hero = enemyList[i]
                  local distance = myHero.pos:DistanceTo(hero.pos)
                  if distance < maxDistance then
                        maxDistance = distance
                        result = hero
                  end
            end
            return result
      end
      function __gsoTS:GetImmobileEnemy(enemyList, maxDistance)
            local result = nil
            local num = 0
            for i = 1, #enemyList do
                  local hero = enemyList[i]
                  local distance = myHero.pos:DistanceTo(hero.pos)
                  local iT = gsoSDK.Spell:ImmobileTime(hero)
                  if distance < maxDistance and iT > num then
                        num = iT
                        result = hero
                  end
            end
            return result
      end
      function __gsoTS:Tick()
            local enemyMinions = gsoSDK.ObjectManager:GetEnemyMinions(myHero.range + myHero.boundingRadius - 35, true)
            local allyMinions = gsoSDK.ObjectManager:GetAllyMinions(1500, false)
            local lastHitMode = gsoSDK.Menu.ts.lasthitmode:Value() == 1 and "accuracy" or "fast"
            local cacheFarmMinions = {}
            for i = 1, #enemyMinions do
                  local enemyMinion = enemyMinions[i]
                  local FlyTime = myHero.attackData.windUpTime + ( myHero.pos:DistanceTo(enemyMinion.pos) / myHero.attackData.projectileSpeed )
                  cacheFarmMinions[#cacheFarmMinions+1] = gsoSDK.Farm:SetLastHitable(enemyMinion, FlyTime, myHero.totalDamage, lastHitMode, allyMinions)
            end
            self.FarmMinions = cacheFarmMinions
      end
      function __gsoTS:WndMsg(msg, wParam)
            if msg == WM_LBUTTONDOWN and gsoSDK.Menu.ts.selected.enable:Value() and GetTickCount() > self.LastSelTick + 100 then
                  self.SelectedTarget = nil
                  local num = 10000000
                  local enemyList = gsoSDK.ObjectManager:GetEnemyHeroes(99999999, false, "immortal")
                  for i = 1, #enemyList do
                        local unit = enemyList[i]
                        local distance = mousePos:DistanceTo(unit.pos)
                        if distance < 150 and distance < num then
                              self.SelectedTarget = unit
                              num = distance
                        end
                  end
                  self.LastSelTick = GetTickCount()
            end
      end
      function __gsoTS:Draw()
            if gsoSDK.Menu.gsodraw.selected.enabled:Value() then
                  if self.SelectedTarget and not self.SelectedTarget.dead and self.SelectedTarget.isTargetable and self.SelectedTarget.visible and self.SelectedTarget.valid then
                        DrawCircle(self.SelectedTarget.pos, gsoSDK.Menu.gsodraw.selected.radius:Value(), gsoSDK.Menu.gsodraw.selected.width:Value(), gsoSDK.Menu.gsodraw.selected.color:Value())
                  end
            end
            if gsoSDK.Menu.gsodraw.lasthit.enabled:Value() or gsoSDK.Menu.gsodraw.almostlasthit.enabled:Value() then
                  for i = 1, #self.FarmMinions do
                        local minion = self.FarmMinions[i]
                        if minion.LastHitable and gsoSDK.Menu.gsodraw.lasthit.enabled:Value() then
                              DrawCircle(minion.Minion.pos, gsoSDK.Menu.gsodraw.lasthit.radius:Value(), gsoSDK.Menu.gsodraw.lasthit.width:Value(), gsoSDK.Menu.gsodraw.lasthit.color:Value())
                        elseif minion.AlmostLastHitable and gsoSDK.Menu.gsodraw.almostlasthit.enabled:Value() then
                              DrawCircle(minion.Minion.pos, gsoSDK.Menu.gsodraw.almostlasthit.radius:Value(), gsoSDK.Menu.gsodraw.almostlasthit.width:Value(), gsoSDK.Menu.gsodraw.almostlasthit.color:Value())
                        end
                  end
            end
      end
--[[
▒█░▒█ ▀▀█▀▀ ▀█▀ ▒█░░░ ▀█▀ ▀▀█▀▀ ▀█▀ ▒█▀▀▀ ▒█▀▀▀█ 
▒█░▒█ ░▒█░░ ▒█░ ▒█░░░ ▒█░ ░▒█░░ ▒█░ ▒█▀▀▀ ░▀▀▀▄▄ 
░▀▄▄▀ ░▒█░░ ▄█▄ ▒█▄▄█ ▄█▄ ░▒█░░ ▄█▄ ▒█▄▄▄ ▒█▄▄▄█ 
]]
class "__gsoUtilities"
      function __gsoUtilities:__init()
            self.MinLatency = GameLatency() * 0.001
            self.MaxLatency = GameLatency() * 0.001
            self.Min = GameLatency() * 0.001
            self.LAT = {}
            self.DA = {}
      end
      function __gsoUtilities:DelayedActions()
            local cacheDA = {}
            for i = 1, #self.DA do
                  local t = self.DA[i]
                  if GameTimer() > t.StartTime + t.Delay then
                        t.Func()
                  else
                        cacheDA[#cacheDA+1] = t
                  end
            end
            self.DA = cacheDA
      end
      function __gsoUtilities:Latencies()
            local lat1 = 0
            local lat2 = 50
            local latency = GameLatency() * 0.001
            if latency < self.Min then
                  self.Min = latency
            end
            self.LAT[#self.LAT+1] = { endTime = GameTimer() + 2.5, Latency = latency }
            local cacheLatencies = {}
            for i = 1, #self.LAT do
                  local t = self.LAT[i]
                  if GameTimer() < t.endTime then
                        cacheLatencies[#cacheLatencies+1] = t
                        if t.Latency > lat1 then
                              lat1 = t.Latency
                              self.MaxLatency = lat1
                        end
                        if t.Latency < lat2 then
                              lat2 = t.Latency
                              self.MinLatency = lat2
                        end
                  end
            end
            self.LAT = cacheLatencies
      end
      function __gsoUtilities:Tick()
            self:DelayedActions()
            self:Latencies()
      end
      function __gsoUtilities:AddAction(func, delay)
            self.DA[#self.DA+1] = { StartTime = GameTimer(), Func = func, Delay = delay }
      end
      function __gsoUtilities:GetMaxLatency()
            return self.MaxLatency
      end
      function __gsoUtilities:GetMinLatency()
            return self.MinLatency
      end
      function __gsoUtilities:GetUserLatency()
            return self.Min
      end
--[[
▒█░░░ ▒█▀▀▀█ ░█▀▀█ ▒█▀▀▄ ▒█▀▀▀ ▒█▀▀█ 
▒█░░░ ▒█░░▒█ ▒█▄▄█ ▒█░▒█ ▒█▀▀▀ ▒█▄▄▀ 
▒█▄▄█ ▒█▄▄▄█ ▒█░▒█ ▒█▄▄▀ ▒█▄▄▄ ▒█░▒█ 
]]
class "__gsoLoader"
      function __gsoLoader:__init()
            -- LOAD LIBS
            gsoSDK.Spell = __gsoSpell()
            gsoSDK.Utilities = __gsoUtilities()
            gsoSDK.Cursor = __gsoCursor()
            gsoSDK.ObjectManager = __gsoOB()
            gsoSDK.Farm = __gsoFarm()
            gsoSDK.TS = __gsoTS()
            gsoSDK.Orbwalker = __gsoOrbwalker()
            -----------------------------------------------------------
            gsoSDK.TS:CreateMenu()
            gsoSDK.Orbwalker:CreateMenu()
            gsoSDK.Menu:MenuElement({name = "Drawings", id = "gsodraw", leftIcon = "https://raw.githubusercontent.com/gamsteron/GoSExt/master/Icons/circles.png", type = MENU })
            gsoSDK.Menu.gsodraw:MenuElement({name = "Enabled",  id = "enabled", value = true})
            gsoSDK.Spell:CreateDrawMenu()
            gsoSDK.TS:CreateDrawMenu()
            gsoSDK.Cursor:CreateDrawMenu()
            gsoSDK.Orbwalker:CreateDrawMenu()
            Callback.Add('Tick', function()
                  gsoSDK.ObjectManager:Tick()
                  gsoSDK.Spell:SaveWaypoints(gsoSDK.ObjectManager:GetEnemyHeroes(10000, false, "spell"))
                  gsoSDK.Utilities:Tick()
                  gsoSDK.Cursor:Tick()
                  local enemyMinions = gsoSDK.ObjectManager:GetEnemyMinions(1500, false)
                  local allyMinions = gsoSDK.ObjectManager:GetAllyMinions(1500, false)
                  gsoSDK.Farm:Tick(allyMinions, enemyMinions)
                  gsoSDK.TS:Tick()
                  gsoSDK.Orbwalker:Tick()
                  if gsoSDK.AntiGapcloser and gsoSDK.AntiGapcloser.Loaded then
                        gsoSDK.AntiGapcloser:Tick()
                  end
                  if gsoSDK.Interrupter and gsoSDK.Interrupter.Loaded then
                        gsoSDK.Interrupter:Tick()
                  end
                  gsoSDK.ChampTick()
            end)
            Callback.Add('WndMsg', function(msg, wParam)
                  gsoSDK.TS:WndMsg(msg, wParam)
                  gsoSDK.Spell:WndMsg(msg, wParam)
                  gsoSDK.ChampWndMsg(msg, wParam)
            end)
            Callback.Add('Draw', function()
                  if not gsoSDK.Menu.gsodraw.enabled:Value() then return end
                  gsoSDK.TS:Draw()
                  gsoSDK.Cursor:Draw()
                  gsoSDK.Spell:Draw()
                  gsoSDK.Orbwalker:Draw()
                  gsoSDK.ChampDraw()
            end)
      end

-- Udyr --
class "__gsoUdyr"

      function __gsoUdyr:__init()
            -- menu
            gsoSDK.Menu = MenuElement({name = "UberUdyr123 by farmer123", id = "gsoudyr", type = MENU, leftIcon = "https://raw.githubusercontent.com/thefarmer123/UberBrainIQRepo/master/Images/bigbrainudyr.png" })
            __gsoLoader()
            self.lastReset = 0
            gsoSDK.Orbwalker:SetSpellMoveDelays( { q = 0, w = 0, e = 0, r = 0 } )
            gsoSDK.Orbwalker:SetSpellAttackDelays( { q = 0, w = 0, e = 0, r = 0 } )
            self:CreateMenu()
            self:AddTickEvent()
      end
      
      function __gsoUdyr:CreateMenu()
	  
            gsoSDK.Menu:MenuElement({name = "High IQ Settings", id = "iqset", type = MENU })
                  gsoSDK.Menu.iqset:MenuElement({name = "Combo Settings", id = "combo", type = MENU })
					gsoSDK.Menu.iqset.combo:MenuElement({id = "combow", name = "% Health for W usage", value = 60, min = 0, max = 100, step = 1, tooltip = "If your Health drops lower than this number, W is being used Combo Mode" })
					gsoSDK.Menu.iqset.combo:MenuElement({id = "comboforcew", name = "% Health for W force", value = 35, min = 0, max = 100, step = 1, tooltip = "If your Health drops lower than this number, only W and E will be used Combo Mode" })
				  gsoSDK.Menu.iqset:MenuElement({name = "(Jungle) Clear Settings", id = "clear", type = MENU })
					gsoSDK.Menu.iqset.clear:MenuElement({id = "clearw", name = "% Health for W usage", value = 60, min = 0, max = 100, step = 1, tooltip = "If your Health drops lower than this number, W is being used Clear Mode" })
      end
      
      function __gsoUdyr:AddTickEvent()
    gsoSDK.ChampTick = function()
    -- Is Attacking
    if not gsoSDK.Orbwalker:CanMove() then
        return
    end
    -- Get Mode
    local mode = gsoSDK.Orbwalker:GetMode()
    -- Can Attack
    local AATarget = gsoSDK.TS:GetComboTarget()
    if AATarget and mode ~= "None" and gsoSDK.Orbwalker:CanAttack() then
        return
    end
	--E
	if mode == "Combo" then			  
		if gsoSDK.Spell:IsReady(_E, { q = 0, w = 0, e = 0, r = 0 } ) then
			local enemyList = gsoSDK.ObjectManager:GetEnemyHeroes(700 + myHero.boundingRadius - 35, true, "attack")
			if not gsoSDK.TS:GetComboTarget() or (gsoSDK.TS:GetComboTarget() and not gsoSDK.Spell:HasBuff(gsoSDK.TS:GetComboTarget(), "UdyrBearStunCheck")) then
				if #enemyList > 0 and not (gsoSDK.TS:GetComboTarget() and (QCount == 3 or WCount == 3)) and gsoSDK.Spell:CastSpell(HK_E) then
					currentStance = 0
					DamageSwitcher()
					return
				end
            end
		end
		--W
		if not damageSwitch and gsoSDK.Spell:IsReady(_W, { q = 0, w = 0, e = 0, r = 0 } ) then
			local enemyList = gsoSDK.ObjectManager:GetEnemyHeroes(700 + myHero.boundingRadius - 35, true, "attack")
			if (not gsoSDK.TS:GetComboTarget() and (myHero.maxHealth * 15 * 0.01) > myHero.health) or (gsoSDK.TS:GetComboTarget() and (gsoSDK.Spell:HasBuff(gsoSDK.TS:GetComboTarget(), "UdyrBearStunCheck")) or myHero:GetSpellData(_E).level == 0)then
				if #enemyList > 0 and gsoSDK.Spell:CastSpell(HK_W) then
					currentStance = 2
					WCount = 3
					DamageSwitcher()
					return
				end
			end
		end
		--Q
		if gsoSDK.Spell:IsReady(_Q, { q = 0, w = 0, e = 0, r = 0 } ) and damageSwitch then
			local enemyList = gsoSDK.ObjectManager:GetEnemyHeroes(myHero.range + myHero.boundingRadius + 35, true, "attack")
			if gsoSDK.TS:GetComboTarget() and (gsoSDK.Spell:HasBuff(gsoSDK.TS:GetComboTarget(), "UdyrBearStunCheck") or myHero:GetSpellData(_E).level == 0) then
				if #enemyList > 0 and gsoSDK.Spell:CastSpell(HK_Q) then
					currentStance = 1
					QCount = 3
					DamageSwitcher()
					return
				end
			end
		end
	end
	if mode == "Clear" then
		if gsoSDK.TS:GetLaneClearTarget() and gsoSDK.Spell:IsReady(_E, { q = 0, w = 0, e = 0, r = 0 } ) and not (QCount == 3 or WCount == 3) then
			if string.find(gsoSDK.TS:GetLaneClearTarget().name:lower(), "crab")then
				if gsoSDK.Spell:CastSpell(HK_E) then
					currentStance = 0
					return
				end
			end
		end
		if gsoSDK.Spell:IsReady(_W, { q = 0, w = 0, e = 0, r = 0 } ) and (myHero.maxHealth * gsoSDK.Menu.iqset.clear.clearw:Value() * 0.01) > myHero.health and not (QCount == 2 or QCount == 3) then
			if gsoSDK.TS:GetLaneClearTarget() or gsoSDK.TS:GetLastHitTarget() then
				if gsoSDK.Spell:CastSpell(HK_W) then
					currentStance = 2
					WCount = 3
					return
				end
			end
		end
		if gsoSDK.Spell:IsReady(_Q, { q = 0, w = 0, e = 0, r = 0 } ) then
			if gsoSDK.TS:GetLaneClearTarget() or gsoSDK.TS:GetLastHitTarget() and not (WCount == 2 or WCount == 3) then
				if gsoSDK.Spell:CastSpell(HK_Q) then
					currentStance = 1
					QCount = 3
					return
				end
			end
		end
	end
	end
end

function DamageSwitcher()
	if (myHero.maxHealth * gsoSDK.Menu.iqset.combo.combow:Value() * 0.01) < myHero.health then
		damageSwitch = true
	elseif (myHero.maxHealth * gsoSDK.Menu.iqset.combo.comboforcew:Value() * 0.01) > myHero.health then
		damageSwitch = false
	else 
		if damageSwitch then
			damageSwitch = false
		else
			damageSwitch = true
		end
	end
end

function StanceCounter()
	if currentStance == 1 then
		if QCount == 3 then
			QCount = 1
		elseif QCount == 2 then
			QCount = 3
		elseif QCount == 1 then
			QCount = 2
		end
	elseif currentStance == 2 then
	    if WCount == 3 then
			WCount = 1
		elseif WCount == 2 then
			WCount = 3
		elseif WCount == 1 then
			WCount = 2
		end
	elseif currentStance == 3 then
		if RCount == 3 then
			RCount = 1
		elseif RCount == 2 then
			RCount = 3
		elseif RCount == 1 then
			RCount = 2
		end
	end
end

--[[
▒█░░░ ▒█▀▀▀█ ░█▀▀█ ▒█▀▀▄ 　 ░█▀▀█ ▒█░░░ ▒█░░░ 
▒█░░░ ▒█░░▒█ ▒█▄▄█ ▒█░▒█ 　 ▒█▄▄█ ▒█░░░ ▒█░░░ 
▒█▄▄█ ▒█▄▄▄█ ▒█░▒█ ▒█▄▄▀ 　 ▒█░▒█ ▒█▄▄█ ▒█▄▄█ 
]]
if myHero.charName == "Udyr" then
      __gsoUdyr()
	  print("Congratulations on choosing the absolutly fantastic UberUdyr123!")
	  print("v420.0Beta by farmer123")
else
      gsoSDK.Menu = MenuElement({name = "Gamsteron Test", id = "gamsteron", type = MENU })
      __gsoLoader()
      print("this hero is not supported. You are only playing with a modified Version of the Gamsteron Orbwalker this Script is based on.")
end
