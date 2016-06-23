local ver = "0.05"
function AutoUpdate(data)
    if tonumber(data) > tonumber(ver) then
        DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/AutoLVL.lua", SCRIPT_PATH .. "AutoLVL.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    else
        PrintChat(string.format("<font color='#b756c5'>GamSterOn AutoLVL </font>").."updated ! Version: "..ver)
    end
end
GetWebResultAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/AutoLVL.version", AutoUpdate)

if not DirExists(COMMON_PATH.."GamSterOn\\") then
        repeat
                CreateDir(COMMON_PATH.."GamSterOn\\")
        until DirExists(COMMON_PATH.."GamSterOn\\")
end

if not DirExists(COMMON_PATH.."GamSterOn\\AutoLVL\\") then
        repeat
                CreateDir(COMMON_PATH.."GamSterOn\\AutoLVL\\")
        until DirExists(COMMON_PATH.."GamSterOn\\AutoLVL\\")
end

if not FileExist(COMMON_PATH.."GamSterOn\\AutoLVL\\AutoLVL.txt") then
        DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/AutoLVL.txt", COMMON_PATH.."GamSterOn\\AutoLVL\\AutoLVL.txt", function() PrintChat("AutoLVL.txt Download Completed, please 2x F6!") return end)
        return
end

local gsal_File = io.open(COMMON_PATH.."GamSterOn\\AutoLVL\\AutoLVL.txt", "r")
local gsal_FileContent = gsal_File:read("*all")
gsal_File:close()

local gsal_ChampionName = GetObjectName(myHero)
local gsal_SkillOrder = {}
local gsal_Timer = GetTickCount()
local gsal_ErrorTimer = 0
local gsal_IDNames = {}
local gsal_DelayedActions = {}

function gsal_GetIDName(file)
        for i = 1, #file do
                local str1 = file:sub(i, i)
                if str1 == "." then
                        for j = i+1, #file do
                                local str2 = file:sub(j, j)
                                if str2 == " " then
                                        return file:sub(i+1, j-1)
                                end
                        end
                elseif i == #file then
                        return nil
                end
        end
end

function gsal_GetChampionName(file)
        for i = 1, #file do
                local str = file:sub(i, i)
                if str == ' ' or str == '.' then
                        return file:sub(1, i-1)
                end
        end
end

function gsal_GetSkillOrder(file, id)
        for i = 1, #file do
                local str1 = file:sub(i, i)
                if str1 == " " then
                        for j = 1, 18 do
                                local str2 = file:sub(i+j, i+j)
                                if str2 == "1" or str2 == "q" or str2 == "Q" then
                                        gsal_SkillOrder[id][j] = _Q
                                elseif str2 == "2" or str2 == "w" or str2 == "W" then
                                        gsal_SkillOrder[id][j] = _W
                                elseif str2 == "3" or str2 == "e" or str2 == "E" then
                                        gsal_SkillOrder[id][j] = _E
                                elseif str2 == "4" or str2 == "r" or str2 == "R" then
                                        gsal_SkillOrder[id][j] = _R
                                end
                        end
                end
        end
end

function gsal_DoSkillSequenceStr(IDName)
        local str = " "
        for  i = 1, 18 do
                local skill = gsal_SkillOrder[IDName][i]
                if skill == 0 then
                        str = str.."q"
                elseif skill == 1 then
                        str = str.."w"
                elseif skill== 2 then
                        str = str.."e"
                elseif skill == 3 then
                        str = str.."r"
                end
        end
        return str
end

function gsal_ConnectTableString()
        local t = {}
        for i = 1, #gsal_IDNames do
                t[i] = gsal_IDNames[i].." "..gsal_DoSkillSequenceStr(gsal_IDNames[i])
        end
        return t
end

function gsal_AnalyseText()
        for s in string.gmatch(gsal_FileContent,'[^\r\n]+') do
                local NAME = gsal_GetChampionName(s)
                local str = s:sub(1, 1)
                if str ~= "-" then
                        if gsal_ChampionName:lower():find(NAME:lower()) then
                                local IDNAME = gsal_GetIDName(s)
                                if IDNAME ~= nil then
                                        table.insert(gsal_IDNames, IDNAME)
                                        gsal_SkillOrder[IDNAME] = {}
                                        gsal_GetSkillOrder(s, IDNAME)
                                else
                                        table.insert(gsal_IDNames, NAME)
                                        gsal_SkillOrder[NAME] = {}
                                        gsal_GetSkillOrder(s, NAME)
                                end
                        end
                end
        end
end

function ExecuteDelayedActions()
        if gsal_DelayedActions == nil then
                return
        end
        for i = 1, #gsal_DelayedActions do
                if GetTickCount() - gsal_DelayedActions[i].time >= gsal_DelayedActions[i].delay then
                        gsal_DelayedActions[i].execute()
                        table.remove(gsal_DelayedActions, i)
                        break
                end
        end
end

function DelayedAction(func, sec)
        if #gsal_DelayedActions == 0 then -- -> stop holding more than 1 action
                table.insert(gsal_DelayedActions, {execute = func, time = GetTickCount(), delay = sec*1000})
        end
end

function GenerateRandomFloat(lower, greater)
        return lower + math.random()  * (greater - lower)
end

gsal_AnalyseText()

gsal_MainMenu = MenuConfig("gsoalu", "GamSterOn Auto LVL UP")
gsal_MainMenu:Boolean("HUMANIZER", "Humanizer", false)
gsal_MainMenu:Boolean("SETVALUE", "Block LvlUP on Load", true)
gsal_MainMenu:Menu(GetObjectName(myHero), GetObjectName(myHero))
gsal_MainMenu[gsal_ChampionName]:DropDown("SWITCH", "Skill Order -> ", 0, gsal_ConnectTableString())
if gsal_MainMenu.SETVALUE:Value() then
        gsal_MainMenu[gsal_ChampionName].SWITCH:Value(0)
end

OnTick(function (myHero)
        ExecuteDelayedActions()
        if GetTickCount() > gsal_Timer + 1000 then
                local CASE = gsal_MainMenu[gsal_ChampionName].SWITCH:Value()
                if gsal_IDNames[CASE] == nil then
                        if GetTickCount() > gsal_ErrorTimer + 10000 then
                                PrintChat("[GamSterOn AUTOLVL] -> CHOOSE YOUR SEQUENCE FROM MENU")
                                gsal_ErrorTimer = GetTickCount()
                        end
                else
                        local HUMANIZER = gsal_MainMenu.HUMANIZER:Value()
                        local RANDOM = GenerateRandomFloat(0.5, 1)
                        local LEVEL = GetLevel(myHero)
                        local PLUS = GetCastLevel(myHero, _Q) + GetCastLevel(myHero, _W) + GetCastLevel(myHero, _E) + GetCastLevel(myHero, _R)
                        if gsal_SkillOrder[gsal_IDNames[CASE]] then
                                if LEVEL > PLUS then
                                        if HUMANIZER then
                                                DelayedAction(function() LevelSpell(gsal_SkillOrder[gsal_IDNames[CASE]][LEVEL]) end, RANDOM)
                                        else
                                                LevelSpell(gsal_SkillOrder[gsal_IDNames[CASE]][LEVEL])
                                        end
                                end
                        end
                        gsal_Timer = GetTickCount()
              end
      end
end)
