if myHero.charName ~= "KogMaw" then return end

local ver = "0.01"
function AutoUpdate(data)
    if tonumber(data) > tonumber(ver) then
        DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/KogMaw.lua", SCRIPT_PATH .. "KogMaw.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    else
        PrintChat(string.format("<font color='#b756c5'>GamSterOn KogMaw </font>").."updated ! Version: "..ver)
    end
end
GetWebResultAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/KogMaw.version", AutoUpdate)

require "OpenPredict"

local spelltime = 0
local aawind = 250
local lastq = 0
local laste = 0
local lastr = 0
local Q = { range = 1175, speed = 1700, width = 70, delay = 0.25 }
local E = { range = 1280, speed = 1350, width = 110, delay = 0.25 }
local R = { range = 0, speed = math.huge, width = 100, delay = 0.6 }

menu = MenuConfig("GSO", "GamSterOn KogMaw")
    menu:KeyBinding("combo", "Combo", 32)

OnProcessSpellAttack(function(unit,aa)
        if unit.isMe then
                aawind = aa.windUpTime * 1000
                spelltime = GetTickCount() + aawind + 60
        end
end)

OnProcessSpellComplete(function(unit, spell)
        if unit == myHero and spell.name:find("Attack") and IsReady(_W) and spell.target.type == "AIHeroClient" then CastSpell(_W) end
end)

OnIssueOrder(function(Order)
        if Order.flag == 3 then spelltime = GetTickCount() + aawind + 120 end
end)

function WP_GetTarget(range)
        local t = nil
        num = 10000
        for i, enemy in pairs(GetEnemyHeroes()) do
                if ValidTarget(enemy, range + 100) then
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

function WP_CastSpell(spell, spellT, col)
        if not IsReady(spell) or GetTickCount() < spelltime or GetTickCount() < lastq + 500 or GetTickCount() < laste + 500 or GetTickCount() < lastr + 500 then return false end
        if spell == _R then
                if GetCurrentMana(myHero) - 200 < GotBuff(myHero, "kogmawlivingartillerycost") * 40 and GotBuff(myHero, "kogmawlivingartillerycost") > 1 then return false end
                R.range = 900 + ( 300 * GetCastLevel(myHero, spell) )
        end
        local t = WP_GetTarget(spellT.range)
        if t == nil then return false end
        local pI = GetPrediction(t, spellT)
        if pI and pI.hitChance >= 0.25 and math.sqrt( (pI.castPos.x-myHero.x)^2 + (pI.castPos.z-myHero.z)^2) < spellT.range and (col == false or not pI:mCollision(1)) then
                CastSkillShot(spell, pI.castPos)
                return true
        end
        return false
end

OnTick(function(myHero)
        if menu.combo:Value() then
                if WP_CastSpell(_E, E, false) == true then laste = GetTickCount() end
                if WP_CastSpell(_Q, Q, true) == true then lastq = GetTickCount() end
                if WP_CastSpell(_R, R, false) == true then lastr = GetTickCount() end
        end
end)
