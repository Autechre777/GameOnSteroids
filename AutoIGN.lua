local ignite = nil

if GetCastName(myHero, SUMMONER_1):lower():find("summonerdot") then
        ignite = SUMMONER_1
end
if GetCastName(myHero, SUMMONER_2):lower():find("summonerdot") then
        ignite = SUMMONER_2
end

if ignite == nil then
        return
end

local ver = "0.01"
function AutoUpdate(data)
    if tonumber(data) > tonumber(ver) then
        DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/AutoIGN.lua", SCRIPT_PATH .. "AutoIGN.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    else
        PrintChat(string.format("<font color='#b756c5'>GamSterOn AutoIGNITE </font>").."updated ! Version: "..ver)
    end
end
GetWebResultAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/AutoIGN.version", AutoUpdate)

GSOAI = MenuConfig("gsoai", "GamSterOn Auto Ignite")
GSOAI:Slider("HEALTH", "Minimum Enemy HP + Player Lvl * 5", 50,25,200,25)
GSOAI:Boolean("SHIELD", "Calculate shields", false)

OnLoad(function()
        for i,o in pairs(GetEnemyHeroes()) do
                GSOAI:Boolean(GetObjectName(o), GetObjectName(o), true)
        end
end)

OnTick(function (myHero)
        local level = GetLevel(myHero)
        local health = GSOAI.HEALTH:Value() + ( level * 5 )
        if ignite ~= nil then
                if Ready(ignite) then
                        for i, enemy in pairs(GetEnemyHeroes()) do
                                if ValidTarget(enemy, 600) and GSOAI[GetObjectName(enemy)]:Value() then
                                        local hp = GetCurrentHP(enemy) + ( GetHPRegen(enemy) * 5 * 0.6 )
                                        if GSOAI.SHIELD:Value() then
                                                hp = hp + GetDmgShield(enemy)
                                        end
                                        if hp > health and hp <= 50 + (20 * level) then
                                                CastTargetSpell(enemy, ignite)
                                        end
                                end
                        end
                end
        end
end)
