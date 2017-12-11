if myHero.charName ~= "KogMaw" then return end

local ver = "0.06"
function AutoUpdate(data)
    if tonumber(data) > tonumber(ver) then
        DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/GamsteronKogMaw.lua", SCRIPT_PATH .. "GamsteronKogMaw.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    else
        PrintChat(string.format("<font color='#b756c5'>GamSterOn KogMaw </font>").."updated ! Version: "..ver)
    end
end
GetWebResultAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/GamsteronKogMaw.version", AutoUpdate)

require "OpenPredict"

local lastq = 0
local lastw = 0
local laste = 0
local lastr = 0
local lastaa = 0
local aawind = 0
local aaanim = 0
local aarange = 0
local lastmove = 0
local Q = { range = 1175, speed = 1700, width = 70, delay = 0.25 }
local E = { range = 1280, speed = 1350, width = 110, delay = 0.25 }
local R = { range = 0, speed = math.huge, width = 220, delay = 0.8 }

menu = MenuConfig("GSO", "GamSterOn KogMaw 0.06")
        menu:SubMenu("combo", "Combo")
                menu.combo:KeyBinding("ckey", "Combo Key", 32)
                menu.combo:Slider("ewin", "Extra Wind Up Time",30,0,60,10)
        menu:SubMenu("pred", "Prediction")
                menu.pred:Slider("predQ", "Q Hitchance",65,0,100,1)
                menu.pred:Slider("predE", "E Hitchance",65,0,100,1)
                menu.pred:Slider("predR", "R Hitchance",65,0,100,1)

OnProcessSpellAttack(function(unit, aa)
        if unit.isMe then
                lastaa = GetTickCount()
                aawind = aa.windUpTime * 1000 - menu.combo.ewin:Value()
                aaanim = aa.animationTime * 1000 - 125
        end
end)

function Orb_GetTarget(range)
        local t = nil
        num = 10000
        for i, enemy in pairs(GetEnemyHeroes()) do
                if ValidTarget(enemy, range + enemy.boundingRadius) then
                        local mr = GetMagicResist(enemy)
                        local hp = enemy.health * (mr/(mr+100))
                        if hp < num then
                                num = hp
                                t = enemy
                        end
                end
        end
        return t
end

function Spell_GetTarget(range)
        local t = nil
        num = 10000
        for i, enemy in pairs(GetEnemyHeroes()) do
                if ValidTarget(enemy, range) then
                        local mr = GetMagicResist(enemy)
                        local hp = enemy.health * (mr/(mr+100))
                        if hp < num then
                                num = hp
                                t = enemy
                        end
                end
        end
        return t
end

function Kog_CastSpell(spell, spellT)

        if not IsReady(spell) or GetTickCount() < lastaa + aawind + 50 then return false end
        
        local manacost = 0
        local mana = GetCurrentMana(myHero)
        local cdliveW = GetTickCount() - lastw
        local cdW = math.floor(17*1000*(1+GetCDR(myHero)))
        if spellT == Q  then
                if GetTickCount() < lastq + 500 or GetTickCount() < laste + 250 or GetTickCount() < lastr + 250 then return false end
                manacost = 40
        elseif spellT == E then
                if GetTickCount() < laste + 500 or GetTickCount() < lastq + 250 or GetTickCount() < lastr + 250 then return false end
                manacost = 70 + ( GetCastLevel(myHero, spell) * 10 )
        elseif spellT == R then
                spellT.range = 900 + ( 300 * GetCastLevel(myHero, spell) )
                manacost = 40 + ( 40 * GotBuff(myHero, "kogmawlivingartillerycost") )
                if manacost > 120 or GetTickCount() < lastr + 500 or GetTickCount() < lastq + 250 or GetTickCount() < laste + 250 then return false end
        end
        if cdliveW - cdW < 0 then
                if GetCurrentMana(myHero) + ( 0.001 * ( cdW - cdliveW ) * GetMPRegen(myHero) ) < 40 + manacost then return false end
        elseif mana < 40 + manacost then return false end
        
        local t = Spell_GetTarget(spellT.range)
        if t == nil then return false end
        
        local dist = math.sqrt( (t.x-myHero.x)^2 + (t.z-myHero.z)^2)
        local herorange = aarange + myHero.boundingRadius + t.boundingRadius
        if dist < herorange and GetTickCount() > lastaa + ( 0.7 * aaanim ) then return false end
        
        local pI = GetPrediction(t, spellT)
        if pI then
                if spell == _Q and pI.hitChance < menu.pred.predQ:Value() / 100 then return false end
                if spell == _E and pI.hitChance < menu.pred.predE:Value() / 100 then return false end
                if spell == _R and pI.hitChance < menu.pred.predR:Value() / 100 then return false end
                if spell == _Q and pI:mCollision(1) then return false end
                CastSkillShot(spell, pI.castPos)
                return true
        end
        
        return false
end

OnTick(function(myHero)

        if menu.combo.ckey:Value() then
                
                BlockF7OrbWalk(true)
                
                aarange = myHero.range
                if GotBuff(myHero, "KogMawBioArcaneBarrage") == 1 or GetTickCount() < lastw + 500 or (IsReady(_W) and GetTickCount() > lastw + 500) then aarange = 610 + (20 * GetCastLevel(myHero, _W)) end
                local t = Orb_GetTarget(aarange + myHero.boundingRadius)
                
                local moveT = lastaa + aawind
                local attackT = lastaa + aaanim
                if t == nil and GetTickCount() > moveT and GetTickCount() > lastmove + 175 then
                        lastmove = GetTickCount()
                        MoveToXYZ(GetMousePos())
                elseif t ~= nil and GetTickCount() > attackT then
                        if IsReady(_W) and GetTickCount() > lastw + 500 then
                                CastSpell(_W)
                                lastw = GetTickCount()
                        end
                        AttackUnit(t)
                elseif GetTickCount() > moveT and GetTickCount() > lastmove + 175 then
                        lastmove = GetTickCount()
                        MoveToXYZ(GetMousePos())
                end
                
                if Kog_CastSpell(_E, E) == true then laste = GetTickCount() end
                if Kog_CastSpell(_Q, Q) == true then lastq = GetTickCount() end
                if Kog_CastSpell(_R, R) == true then lastr = GetTickCount() end
                
        else
        
                BlockF7OrbWalk(false)
                
        end
        
end)
