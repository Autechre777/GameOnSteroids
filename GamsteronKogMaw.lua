if myHero.charName ~= "KogMaw" then return end

local ver = "0.09"
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
local lastmove = 0
local lastkillsteal = 0
local aarange = myHero.range + myHero.boundingRadius
local Q = { range = 1175, speed = 1700, width = 70, delay = 0.25 }
local E = { range = 1280, speed = 1350, width = 110, delay = 0.25 }
local R = { range = 0, speed = math.huge, width = 220, delay = 0.8 }

menu = MenuConfig("GSO", "GamSterOn KogMaw 0.08")
        menu:Key("reset", "Reset Menu Settings", string.byte("T"))
        menu:SubMenu("combo", "Combo")
                menu.combo:Key("ckey", "Combo Key", 32)
                menu.combo:Slider("ewin", "Higher Value = faster kite",60,-15,100,10)
                menu.combo:Slider("manaR", "Max R Mana Cost - combo",80,40,400,40)
                menu.combo:Slider("manaRk", "Max R Mana Cost - killsteal",200,40,400,40)
        menu:SubMenu("pred", "Prediction")
                menu.pred:Slider("predQ", "Q Hitchance",50,0,100,1)
                menu.pred:Slider("predE", "E Hitchance",50,0,100,1)
                menu.pred:Slider("predR", "R Hitchance",50,0,100,1)

local qHitchance =  menu.pred.predQ:Value() * 0.01
local eHitchance =  menu.pred.predE:Value() * 0.01
local rHitchance =  menu.pred.predR:Value() * 0.01

OnProcessSpellAttack(function(unit, aa)
        if unit.isMe then
                lastaa = GetTickCount()
                aawind = ( aa.windUpTime * 1000 ) - menu.combo.ewin:Value()
                aaanim = ( aa.animationTime * 1000 ) - 125
        end
end)

function Kog_GetTarget(range, addBB)
        local t = nil
        local num = 0
        for i, enemy in pairs(GetEnemyHeroes()) do
                local r = addBB and range + enemy.boundingRadius or range
                if ValidTarget(enemy, r) then
                        local hp = enemy.health * (100/(100+GetMagicResist(enemy)))
                        if hp > num then
                                num = hp
                                t = enemy
                        end
                end
        end
        return t
end

function Kog_CastSpell(spell, spellT, kill)

        if not IsReady(spell) or GetTickCount() < lastaa + aawind then return false end
        if kill == true and GetTickCount() < lastkillsteal + 1000 then return false end
        
        local spelldmg = 0
        local manacost = 0
        if spellT == Q  then
                if GetTickCount() < lastq + 500 then return false end
                manacost = 40
                if kill == true then spelldmg = ( 0.5 * GetBonusAP(myHero) ) + 30 + ( GetCastLevel(myHero, spell) * 50 ) end
        elseif spellT == E then
                if GetTickCount() < laste + 500 then return false end
                manacost = 70 + ( GetCastLevel(myHero, spell) * 10 )
                if kill == true then spelldmg = ( 0.5 * GetBonusAP(myHero) ) + 15 + ( GetCastLevel(myHero, spell) * 45 ) end
        elseif spellT == R then
                if GetTickCount() < lastr + 500 then return false end
                manacost = 40 + ( 40 * GotBuff(myHero, "kogmawlivingartillerycost") )
                if ( kill == true and manacost > menu.combo.manaRk:Value() ) or ( kill == false and manacost > menu.combo.manaR:Value() ) then return false end
                if kill == true then spelldmg = ( ( 0.65 * GetBonusDmg(myHero) ) + ( 0.25 * GetBonusAP(myHero) ) + 60 + ( GetCastLevel(myHero, spell) * 40 ) ) * 2 end
                spellT.range = 900 + ( 300 * GetCastLevel(myHero, spell) )
        end
        
        local cdliveW = GetTickCount() - lastw
        local cdW = math.floor(17*1000*(1+GetCDR(myHero)))
        if cdliveW - cdW < 0 then
                if GetCurrentMana(myHero) + ( 0.001 * ( cdW - cdliveW ) * GetMPRegen(myHero) ) < 40 + manacost then return false end
        elseif GetCurrentMana(myHero) < 40 + manacost then return false end
        
        local t = Kog_GetTarget(spellT.range, false)
        if t == nil then return false end
        
        local inRange = math.sqrt( (t.x-myHero.x)^2 + (t.z-myHero.z)^2) < aarange + myHero.boundingRadius + t.boundingRadius
        if inRange and kill == false and GetTickCount() > lastaa + ( 0.7 * aaanim ) then return false end
        
        if kill == true then
                local tkill = nil
                for i, enemy in pairs(GetEnemyHeroes()) do
                        if ValidTarget(enemy, spellT.range) then
                                if math.sqrt( (enemy.x-myHero.x)^2 + (enemy.z-myHero.z)^2) > aarange + myHero.boundingRadius + enemy.boundingRadius then
                                        local tmr = GetMagicResist(enemy) - GetMagicPenFlat(myHero)
                                        tmr = tmr > 0 and GetMagicPenPercent(myHero) * tmr or tmr
                                        spelldmg = tmr > 0 and spelldmg * ( 100 / ( 100 + tmr ) ) or spelldmg * ( 2 - ( 100 / ( 100 - tmr ) ) )
                                        local thp = enemy.health + GetMagicShield(enemy) + (GetHPRegen(enemy)*2) - spelldmg
                                        if thp < 0 then
                                                tkill = enemy
                                                break
                                        end
                                end
                        end
                end
                if tkill ~= nil then
                        t = tkill
                else return false end
        end
        
        local pI = GetPrediction(t, spellT)
        if pI then
                if spell == _Q and pI.hitChance < qHitchance then return false end
                if spell == _E and pI.hitChance < eHitchance then return false end
                if spell == _R and pI.hitChance < rHitchance then return false end
                if spell == _Q and pI:mCollision(1) then return false end
                CastSkillShot(spell, pI.castPos)
                if kill == true then lastkillsteal = GetTickCount() end
                return true
        end
        
        return false
end

OnTick(function(myHero)

        qHitchance =  menu.pred.predQ:Value() * 0.01
        eHitchance =  menu.pred.predE:Value() * 0.01
        rHitchance =  menu.pred.predR:Value() * 0.01
        local baarange = GotBuff(myHero, "KogMawBioArcaneBarrage") == 1 or GetTickCount() < lastw + 500 or (IsReady(_W) and GetTickCount() > lastw + 500)
        aarange = baarange and myHero.boundingRadius + 610 + (20 * GetCastLevel(myHero, _W)) or myHero.range + myHero.boundingRadius
        
        if menu.reset:Value() then
                menu.combo.manaR:Value(80)
                menu.combo.manaRk:Value(200)
                menu.combo.ewin:Value(50)
                menu.pred.predQ:Value(50)
                menu.pred.predE:Value(50)
                menu.pred.predR:Value(50)
        end
        
        if menu.combo.ckey:Value() then
        
                BlockF7OrbWalk(true)
                
                local checkT = GetTickCount()
                local canMove = checkT > lastaa + aawind and checkT > lastmove + 125
                local canAttack = checkT > lastaa + aaanim
                
                local t = Kog_GetTarget(aarange, true)
                if t ~= nil and canAttack then
                        if IsReady(_W) and GetTickCount() > lastw + 500 then
                                CastSpell(_W)
                                lastw = GetTickCount()
                        end
                        AttackUnit(t)
                elseif canMove then
                        lastmove = GetTickCount()
                        MoveToXYZ(GetMousePos())
                end
                
                if Kog_CastSpell(_E, E, false) == true then laste = GetTickCount() end
                if Kog_CastSpell(_Q, Q, false) == true then lastq = GetTickCount() end
                if Kog_CastSpell(_R, R, false) == true then lastr = GetTickCount() end
                
        else
        
                BlockF7OrbWalk(false)
                
        end

        if Kog_CastSpell(_Q, Q, true) == true then lastq = GetTickCount() end
        if Kog_CastSpell(_R, R, true) == true then lastr = GetTickCount() end
        if Kog_CastSpell(_E, E, true) == true then laste = GetTickCount() end
        
end)
