if myHero.charName ~= "Orianna" then return end

local ver = "0.02"
function AutoUpdate(data)
    if tonumber(data) > tonumber(ver) then
        DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/GamsteronOrianna.lua", SCRIPT_PATH .. "GamsteronOrianna.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    else
        PrintChat(string.format("<font color='#b756c5'>GamSterOn Orianna </font>").."updated ! Version: "..ver)
    end
end
GetWebResultAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/GamsteronOrianna.version", AutoUpdate)

require "OpenPredict"

local lastq = 0
local lastw = 0
local laste = 0
local lastr = 0
local lastaa = 0
local aawind = 0
local aaanim = 0
local lastmove = 0
local qball = myHero
local DelayedActionQ = 0
local DelayedActionE = nil
local Q = { range = 1250, speed = 1800, width = 175, delay = 0 }
local W = { width = 250 }
local E = { range = 1100 }
local R = { width = 325, delay = 0.75 }

menu = MenuConfig("GSO", "GamSterOn Orianna 0.01")
    menu:KeyBinding("combo", "Combo", 32)
    menu:Slider("win", "Extra Wind Up Time",20,0,50,10)
    menu:Slider("predQ", "Q Hitchance",50,0,100,5)

OnProcessSpell(function(unit, spell)
        if unit.isMe and spell.name == "OrianaRedactCommand" then
                local t = spell.target
                local d = math.sqrt( (t.x-qball.x)^2 + (t.z-qball.z)^2) / 1850
                qball = nil
                DelayedActionE = { execute = function() qball = t end, time = GetTickCount(), delay = d*1000 }
        end
        if unit.isMe and spell.name == "OrianaIzunaCommand" then
                local epos = spell.endPos
                DelayedActionQ = GetTickCount() + ( 1000 * math.sqrt( (epos.x-qball.x)^2 + (epos.z-qball.z)^2) / 1400 )
                qball = nil
        end
end)

OnCreateObj(function(Object)
        local name = GetObjectBaseName(Object)
        if name == "Orianna_Base_Q_yomu_ring_green.troy" then qball = Object end
        if name == "Orianna_Base_Z_Ball_Flash_Reverse.troy" then qball = myHero end
end)

OnObjectLoad(function(Object)
        if GetObjectBaseName(Object) == "Orianna_Base_Q_yomu_ring_green.troy" then qball = Object end
end)

OnUpdateBuff(function(unit,buff)
        if unit.isMe and buff.Name == "orianaghostself" then qball = myHero end
end)

OnDraw(function(myHero)
        if qball ~= nil then
                local pos = { x = qball.x, y = qball.y, z = qball.z }
                DrawCircle(pos,300,3,100,0xff0B212A)
        end
end)

OnProcessSpellAttack(function(unit, aa)
        if unit.isMe then
                lastaa = GetTickCount()
                aawind = aa.windUpTime * 1000 - menu.win:Value()
                aaanim = aa.animationTime * 1000 - 125
        end
end)

function Ori_GetTarget(range)
        local t = nil
        num = 10000
        for i, enemy in pairs(GetEnemyHeroes()) do
                if ValidTarget(enemy, range) then
                        local mr = GetMagicResist(enemy)
                        local hp = enemy.health * (mr/(mr+100))
                        if hp - ((GetBonusDmg(enemy)+GetBonusAP(enemy))*2) < num then
                                num = hp
                                t = enemy
                        end
                end
        end
        return t
end

function Ori_CastQ()

        if not IsReady(_Q) or qball == nil then return false end
        
        if Ori_CastQFunc(300) == true then return true
        elseif Ori_CastQFunc(200) == true then return true
        elseif Ori_CastQFunc(100) == true then return true
        elseif Ori_CastQFunc(0) == true then return true end
        
        return false
        
end

function Ori_CastQFunc(range)
        
        local t = Ori_GetTarget(825 + range)
        if t == nil or qball == nil then return false end
        
        local pI = GetPrediction(t, Q, qball)
        if pI and (pI.hitChance > menu.predQ:Value() / 100 or math.sqrt( (pI.castPos.x-qball.x)^2 + (pI.castPos.z-qball.z)^2) >= 825) and math.sqrt( (pI.castPos.x-myHero.x)^2 + (pI.castPos.z-myHero.z)^2) < 825 then
                CastSkillShot(_Q, pI.castPos)
                return true
        end
        
        return false
        
end

function Ori_CastE()

        if not IsReady(_E) or qball == nil then return false end
        
        if math.sqrt( (qball.x-myHero.x)^2 + (qball.z-myHero.z)^2 ) > 825 or GetCurrentHP(myHero)/GetMaxHP(myHero)*100 < 75 then
                CastTargetSpell(myHero, _E)
                return true
        end
        
        return false
        
end

function Ori_CastSpell(spell, spellT)

        if not IsReady(spell) or qball == nil then return false end
        
        --local count = 0
        for i, enemy in pairs(GetEnemyHeroes()) do
                if ValidTarget(enemy, 1200) and math.sqrt( (qball.x-enemy.x)^2 + (qball.z-enemy.z)^2 ) < spellT.width / 1.5 then
                        --[[if spellT == R then
                                count = count + 1
                        else]]
                                CastSpell(spell)
                                return true
                        --end
                end
        end
        --[[
        if count >= 2 then
                CastSpell(spell)
                return true
        end]]
        
        return false
        
end

OnTick(function(myHero)
        if DelayedActionE ~= nil and GetTickCount() - DelayedActionE.time > DelayedActionE.delay then
                DelayedActionE.execute()
                DelayedActionE = nil
        end
        if GotBuff(myHero, "orianaghostself") == 1 and GetTickCount() > DelayedActionQ then qball = myHero end
        if menu.combo:Value() then
        
                local moveT = lastaa + aawind
                local attackT = lastaa + aaanim
                local t = Ori_GetTarget(myHero.range + myHero.boundingRadius)
                if t == nil and GetTickCount() > moveT and GetTickCount() > lastmove + 175 then
                        lastmove = GetTickCount()
                        MoveToXYZ(GetMousePos())
                elseif t ~= nil and GetTickCount() > attackT then
                        AttackUnit(t)
                elseif GetTickCount() > moveT and GetTickCount() > lastmove + 175 then
                        lastmove = GetTickCount()
                        MoveToXYZ(GetMousePos())
                end
                
                if Ori_CastE() == true then laste = GetTickCount() end
                if Ori_CastQ() == true then lastq = GetTickCount() end
                if Ori_CastSpell(_W, W) == true then lastw = GetTickCount() end
                if Ori_CastSpell(_R, R) == true then lastr = GetTickCount() end
                
        end
        
end)
