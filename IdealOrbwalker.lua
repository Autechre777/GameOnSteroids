menu = MenuConfig("GSO", "GamSterOn IdealOrbwalker")
    menu:KeyBinding("combo", "Combo", 32)
    menu:Slider("win", "ExtraWindUp",50,0,100,10)

function Orb_GetTarget(range)
        local t = nil
        num = 10000
        for i, enemy in pairs(GetEnemyHeroes()) do
                if ValidTarget(enemy, range + enemy.boundingRadius) then
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

local lastmove = 0
local lastaa = 0
local aawind = 0
local aaanim = 0

--[[ TEST
local startaa = 0
local aaticks = 0]]

OnProcessSpellAttack(function(unit, aa)
        if unit.isMe then
                lastaa = GetTickCount()
                aawind = aa.windUpTime * 1000 - menu.win:Value()
                aaanim = aa.animationTime * 1000 - 125
                --[[ TEST
                if aaticks == 0 then startaa = GetTickCount() end
                aaticks = aaticks + 1
                if aaticks == 5 then
                        PrintChat("onspell: "..(GetTickCount()-startaa))
                        startaa = 0
                        aaticks = 0
                end]]
        end
end)

--[[ BLOCK SPELL IF ATTACK
OnSpellCast(function(spell)
        local s = spell.spellID
        if GetTickCount() < lastaa + 250 and (s == 0 or s == 1 or s == 2 or s == 3) then
                BlockCast()
        end
end)]]

OnTick(function(myHero)
        local pingT = GetLatency()
        local moveT = lastaa + aawind
        local attackT = lastaa + aaanim
        if menu.combo:Value() then
                local t = Orb_GetTarget(myHero.range + myHero.boundingRadius)
                if t == nil and GetTickCount() > moveT and GetTickCount() > lastmove + 175 then
                        lastmove = GetTickCount()
                        MoveToXYZ(GetMousePos())
                elseif t ~= nil and GetTickCount() > attackT then
                        AttackUnit(t)
                elseif GetTickCount() > moveT and GetTickCount() > lastmove + 175 then
                        lastmove = GetTickCount()
                        MoveToXYZ(GetMousePos())
                end
        end
end)
