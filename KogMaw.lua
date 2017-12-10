if myHero.charName ~= "KogMaw" then return end

local ver = "0.04"
function AutoUpdate(data)
    if tonumber(data) > tonumber(ver) then
        DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/KogMaw.lua", SCRIPT_PATH .. "KogMaw.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    else
        PrintChat(string.format("<font color='#b756c5'>GamSterOn KogMaw </font>").."updated ! Version: "..ver)
    end
end
GetWebResultAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/KogMaw.version", AutoUpdate)

require "OpenPredict"

local lastq = 0
local lastw = 0
local laste = 0
local lastr = 0
local lastaa = 0
local aawind = 0
local aaanim = 0
local lastmove = 0
local Q = { range = 1175, speed = 1700, width = 70, delay = 0.25 }
local E = { range = 1280, speed = 1350, width = 110, delay = 0.25 }
local R = { range = 0, speed = math.huge, width = 220, delay = 0.8 }

menu = MenuConfig("GSO", "GamSterOn KogMaw 0.04")
    menu:KeyBinding("combo", "Combo", 32)
    menu:Slider("win", "Extra Wind Up Time",50,0,100,10)
    menu:Slider("manaR", "Max R Mana Cost",160,40,400,40)
    menu:Slider("predQ", "Q Hitchance",25,0,100,1)
    menu:Slider("predE", "E Hitchance",25,0,100,1)
    menu:Slider("predR", "R Hitchance",25,0,100,1)

OnProcessSpellAttack(function(unit, aa)
        if unit.isMe then
                lastaa = GetTickCount()
                aawind = aa.windUpTime * 1000 - menu.win:Value()
                aaanim = aa.animationTime * 1000 - 125
        end
end)

OnSpellCast(function(spell)
        local s = spell.spellID
        if GetTickCount() < lastaa + aawind + 50 and (s == 0 or s == 1 or s == 2 or s == 3) then BlockCast() end
end)

function Orb_GetTarget(range)
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

function Kog_CastSpell(spell, spellT)

        if not IsReady(spell) or GetTickCount() < lastaa + aawind + 50 or GetTickCount() < lastq + 100 or GetTickCount() < laste + 100 or GetTickCount() < lastr + 100 then return false end
        
        if spell == _R then
                local mana = GetCurrentMana(myHero)
                local kogartillery = 40 + ( 40 * GotBuff(myHero, "kogmawlivingartillerycost") )
                if kogartillery > mana - 80 or kogartillery > menu.manaR:Value() then return false end
                spellT.range = 900 + ( 300 * GetCastLevel(myHero, spell) )
        end
        
        local t = Orb_GetTarget(spellT.range)
        if t == nil then return false end
        
        local dist = math.sqrt( (t.x-myHero.x)^2 + (t.z-myHero.z)^2)
        local herorange = myHero.range + myHero.boundingRadius + t.boundingRadius
        if dist < herorange and GetTickCount() > lastaa + ( 0.7 * aaanim ) then return false end
        if dist < herorange and (GetTickCount() < lastq + 500 or GetTickCount() < laste + 500 or GetTickCount() < lastr + 500) then return false end
        local pI = GetPrediction(t, spellT)
        if pI and math.sqrt( (pI.castPos.x-myHero.x)^2 + (pI.castPos.z-myHero.z)^2) < spellT.range then
                if spell == _Q and pI.hitChance < menu.predQ:Value() / 100 then return false end
                if spell == _E and pI.hitChance < menu.predE:Value() / 100 then return false end
                if spell == _R and pI.hitChance < menu.predR:Value() / 100 then return false end
                if spell == _Q and pI:mCollision(1) then return false end
                CastSkillShot(spell, pI.castPos)
                return true
        end
        
        return false
end

OnTick(function(myHero)

        if menu.combo:Value() then
        
                local aarange = myHero.range
                local kogbio = GotBuff(myHero, "KogMawBioArcaneBarrage")
                if kogbio == 1 or GetTickCount() < lastw + 500 or (IsReady(_W) and GetTickCount() > lastw + 500) then aarange = 610 + (20 * GetCastLevel(myHero, _W)) end
                local t = Orb_GetTarget(aarange + myHero.boundingRadius)
                if t ~= nil and IsReady(_W) and GetTickCount() > lastw + 500 then
                        CastSpell(_W)
                        lastw = GetTickCount()
                end
                
                local moveT = lastaa + aawind
                local attackT = lastaa + aaanim
                if t == nil and GetTickCount() > moveT and GetTickCount() > lastmove + 175 then
                        lastmove = GetTickCount()
                        MoveToXYZ(GetMousePos())
                elseif t ~= nil and GetTickCount() > attackT then
                        AttackUnit(t)
                elseif GetTickCount() > moveT and GetTickCount() > lastmove + 175 then
                        lastmove = GetTickCount()
                        MoveToXYZ(GetMousePos())
                end
                
                if Kog_CastSpell(_E, E) == true then laste = GetTickCount() end
                if Kog_CastSpell(_Q, Q) == true then lastq = GetTickCount() end
                if Kog_CastSpell(_R, R) == true then lastr = GetTickCount() end
                
        end
        
end)
