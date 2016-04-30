-- U P D A T E
local ver = "1.5"
function AutoUpdate(data)
    if tonumber(data) > tonumber(ver) then
        PrintChat("New version found! " .. data)
        PrintChat("Downloading update, please wait...")
        DownloadFileAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/Blitzcrank.lua", SCRIPT_PATH .. "Blitzcrank.lua", function() PrintChat("Update Complete, please 2x F6!") return end)
    else
        PrintChat(string.format("<font color='#b756c5'>GamSterOn </font>").."updated ! Version: "..ver)
    end
end
GetWebResultAsync("https://raw.githubusercontent.com/gamsteron/GameOnSteroids/master/Blitzcrank.version", AutoUpdate)

-- V A R I A B L E S
local UtilsManager = {}
local ImmobileBuffs  = {}
local WaypointManager = {}
local ObjectManager={Minions={Enemies ={},Allies = {},Jungle = {}},Heroes={Enemies={},Allies={}},Turrets={Enemies={},Allies={}}}
local AllyTeam = GetTeam(myHero)
local attack_animation, move_issue, attack_windup, attack_issue = 0, 0, 0, 0
local focus_target = nil

-- M E N U
Config = MenuConfig("GSO", "GamSterOn All in one")
Config:Menu("orbwalker", "GamSterOn Orbwalker")
Config.orbwalker:Boolean("a", "active", true)
Config.orbwalker:Menu("hk", "Hotkeys")
Config.orbwalker.hk:KeyBinding("c", "Combo", 32)
Config.orbwalker:Menu("mm", "Melee movement")
Config.orbwalker.mm:Boolean("a", "active", false)
Config:Menu("ts", "GamSterOn Target Selector")
Config.ts:Menu("fl", "Focus List")
Config.ts:Menu("mts", "Manual target selection")
Config.ts.mts:Boolean("a", "active", true)
Config.ts.mts:Menu("msr", "Minimum selection range")
Config.ts.mts.msr:Boolean("a", "active", true)
Config.ts.mts.msr:Slider("r", "range", 1500,0,3000,1)
Config.ts.mts:Menu("mtr", "Minimum target range")
Config.ts.mts.mtr:Boolean("a", "active", true)
Config.ts.mts.mtr:Slider("r", "range", 1500,0,3000,1)
Config:Menu("pred", "GamSterOn Prediction")
Config.pred:Slider("h", "Hitchance", 3,1,10,1)
Config:Menu("draw", "Drawings")
Config.draw:Menu("se", "Selected enemy")
Config.draw.se:Boolean("a", "active", true)
Config.draw.se:ColorPick("c", "Color", {255,255,0,0})

-- O N  O B J E C T  L O A D
OnObjectLoad(function(o)
        if GetObjectType(o) == Obj_AI_Hero then
                if GetTeam(o) == AllyTeam then
                        Insert(ObjectManager.Heroes.Allies, o)
                else
                        Insert(ObjectManager.Heroes.Enemies, o)
                end
        end
        if GetObjectType(o) == Obj_AI_Turret then
                if GetTeam(o) == AllyTeam then
                        table.insert(ObjectManager.Turrets.Allies, o)
                else
                        table.insert(ObjectManager.Turrets.Enemies, o)
                end
        end
end)

-- O N  C R E A T E  O B J E C T
OnCreateObj(function(o)
        local name = GetObjectBaseName(o)
        if AllyTeam == 100 then
                if name:find("Minion_T200") then
                        table.insert(ObjectManager.Minions.Enemies, o)
                end
        else
                if name:find("Minion_T100") then
                        table.insert(ObjectManager.Minions.Enemies, o)
                end
        end
end)

-- O N  D E L E T E  O B J E C T
OnDeleteObj(function(o)
        local count = #ObjectManager.Minions.Enemies
        for i = 1, count do
                local m = ObjectManager.Minions.Enemies[i]
                local on = GetObjectBaseName(o)
                local mn = GetObjectBaseName(m)
                if on == mn then
                        table.remove(ObjectManager.Minions.Enemies, i)
                        break
                end
        end
end)

-- O N  L O A D
OnLoad(function()
        for a, enemy in ipairs(ObjectManager.Heroes.Enemies) do
                local name = GetObjectName(enemy)
                Config.ts.fl:Boolean(name, name, true)
        end
        ImmobileBuffs = { [GetBuffTypeList().Stun] = true, [GetBuffTypeList().Taunt] = true, [GetBuffTypeList().Snare] = true, [GetBuffTypeList().Fear] = true, [GetBuffTypeList().Charm] = true, [GetBuffTypeList().Suppression] = true, [GetBuffTypeList().Flee] = true, [GetBuffTypeList().Knockup] = true, [GetBuffTypeList().Knockback] = true }
end)

-- O N  D R A W
OnDraw(function(myHero)
        if Config.ts.mts.a:Value() then
                if Config.draw.se.a:Value() then
                        if focus_target ~= nil then
                                if Config.ts.mts.msr.a:Value() then
                                        local dist = ComputeDistance(myHero.pos.x-focus_target.pos.x, myHero.pos.z-focus_target.pos.z)
                                        if dist < Config.ts.mts.msr.r:Value() then
                                                DrawCircle(focus_target.pos, 75, 3, 3, Config.draw.se.c:Value())
                                        end
                                else
                                        DrawCircle(focus_target.pos, 75, 3, 3, Config.draw.se.c:Value())
                                end
                        end
                end
        end
end)

-- O N  P R O C E S S  W A Y P  O I N T
OnProcessWaypoint(function(unit,waypoint)
        local id = GetNetworkID(unit)
        local ms = GetMoveSpeed(unit)
        if WaypointManager[id] then
                if waypoint.index == 2 then
                        WaypointManager[id].third = WaypointManager[id].second
                        WaypointManager[id].second = WaypointManager[id].last
                        WaypointManager[id].last.from = waypoint.position
                        WaypointManager[id].last.time = GetTickCount()
                end
                if waypoint.index == 1 then
                        if GetTickCount() < WaypointManager[id].last.time + 25 then
                                UtilsManager[id].CanMove = true
                                local t = waypoint.position
                                WaypointManager[id].last.to = t
                                local f = WaypointManager[id].last.from
                                local a = t.x - f.x
                                local b = t.z - f.z
                                local c = ComputeDistance(a, b)
                                WaypointManager[id].last.dist = c
                                WaypointManager[id].last.dir = { x = a/c, z = b/c }
                                UtilsManager[id].IsMoving = true
                        else
                                UtilsManager[id].CanMove = false
                                UtilsManager[id].LastStopMoveTime = GetTickCount()
                                UtilsManager[id].IsMoving = false
                        end
                end
        end
end)

-- O N  P R O C E S S  S P E L L  A T T A C K
OnProcessSpellAttack(function(unit, aa)
        if unit == myHero then
                local attack_spell = GetTickCount()
                attack_windup = attack_windup + ( attack_spell - attack_issue )
                attack_animation = attack_animation + ( attack_spell - attack_issue )
        end
        local id = GetNetworkID(unit)
        if UtilsManager[id] then
                UtilsManager[id].AACastDelay = aa.windUpTime
                UtilsManager[id].AALast = GetTickCount()
                UtilsManager[id].IsAttacking = true
        end
end)

-- O N  U P D A T E  B U F F
OnUpdateBuff(function(unit, buff)
        if unit == myHero then
                local name = buff.Name
                if name == "PowerFist" then
                        attack_animation = 0
                end
        end
        local id = GetNetworkID(unit)
        if WaypointManager[id] then
                local type = buff.Type
                if ImmobileBuffs[type] then
                        table.insert(UtilsManager[id].Immobile, { StartTime = GetTickCount(), EndTime = buff.ExpireTime } )
                        UtilsManager[id].IsImmobile = true
                end
        end
end)

-- O N  R E M O V E  B U F F
OnRemoveBuff(function(unit, buff)
        local id = GetNetworkID(unit)
        local et = buff.ExpireTime
        if UtilsManager[id] then
                for i, b in ipairs(UtilsManager[id].Immobile) do
                        if b.EndTime == et then
                                table.remove(UtilsManager[id].Immobile, i)
                                break
                        end
                end
        end
end)

-- O N  I S S U E  O R D E R
OnIssueOrder(function(order)
        if order.flag == 3 then
                attack_issue = GetTickCount()
                local speed = GetAttackSpeed(myHero) * GetBaseAttackSpeed(myHero)
                attack_windup = attack_issue + ( 270 / speed )
                attack_animation = attack_issue + ( 1000 / speed )
        end
        if order.flag == 2 then
                move_issue = GetTickCount() + 175
        end
end)

-- O N  W N D  M S G
OnWndMsg(function(msg, key)
        if Config.ts.mts.a:Value() then
                if key == 1 then
                        local count = 0
                        local e = nil
                        for a, enemy in ipairs(ObjectManager.Heroes.Enemies) do
                                local dist1 = ComputeDistance(enemy.pos.x - GetMousePos().x, enemy.pos.z - GetMousePos().z)
                                if dist1 < 150 then
                                        if Config.ts.mts.msr.a:Value() then
                                                local dist2 = ComputeDistance(enemy.pos.x - myHero.pos.x, enemy.pos.z - myHero.pos.z)
                                                if dist2 < Config.ts.mts.msr.r:Value() then
                                                        count = count + 1
                                                        e = enemy
                                                end
                                        else
                                                count = count + 1
                                                e = enemy
                                        end
                                end
                        end
                        if count >= 1 then
                                focus_target = e
                        else
                                focus_target = nil
                        end
                end
        end
end)

-- O N  T I C K
OnTick(function (myHero)
        if Config.orbwalker.hk.c:Value() then
                if Ready(_Q) then
                        local t = SelectTarget(920, false, false)
                        if t ~= nil then
                                local pos = GetPos(myHero, t, 920, 1800, 0.25, 120)
                                if pos and pos.x ~= 0 then
                                        CastSkillShot(_Q, pos)
                                end
                        end
                elseif Ready(_R) then
                        local t = SelectTarget(550, false, false)
                        if t ~= nil then
                                CastSpell(_R) 
                        end
                end
                if Config.orbwalker.a:Value() then
                        Orb()
                end
                if Ready(_E) then
                        local t = SelectTarget(300, false, false)
                        if t ~= nil then
                                CastSpell(_E) 
                        end
                end
        end
end)

-- T A R G E T   S E L E C T O R
function ComputeTS(unit, AD)
        if AD then return GetCurrentHP(unit) * ( GetArmor(unit) / ( GetArmor(unit) + 100 ) ) - ( ( GetBaseDamage(unit) + GetBonusDmg(unit) ) * GetAttackSpeed(myHero) * GetBaseAttackSpeed(myHero) ) - GetBonusAP(unit) end
        return GetCurrentHP(unit) * ( GetMagicResist(unit) / ( GetMagicResist(unit) + 100 ) ) - ( ( GetBaseDamage(unit) + GetBonusDmg(unit) ) * GetAttackSpeed(myHero) * GetBaseAttackSpeed(myHero) ) - GetBonusAP(unit)
end
function SelectTarget(range, aa, ad)
        local dist = range
        if aa then
                dist = GetRange(myHero) + GetHitBox(myHero)
        end
        if Config.ts.mts.a:Value() then
                if focus_target ~= nil then
                        if aa then
                                dist = dist + GetHitBox(focus_target)
                        end
                        local dist2 = ComputeDistance(focus_target.pos.x - myHero.pos.x, focus_target.pos.z - myHero.pos.z)
                        if Config.ts.mts.mtr.a:Value() then
                                if dist2 < Config.ts.mts.mtr.r:Value() and dist2 > dist then
                                        return nil
                                elseif ValidTarget(focus_target, dist) then
                                        return focus_target
                                end
                        else
                                if ValidTarget(focus_target, dist) then
                                        return focus_target
                                else
                                        return nil
                                end
                        end
                        local hp = GetCurrentHP(focus_target)
                        if hp == 0 then
                                focus_target = nil
                        end
                end
        end
        local t1, t2, t3, t4, t5 = nil, nil, nil, nil, nil
        local count, c1, c2, c3, c4, c5 = 0, 0, 0, 0, 0, 0
        local tr1, tr2, tr3, tr4, tr5 = false, false, false, false, false
        for a, enemy in ipairs(ObjectManager.Heroes.Enemies) do
                if aa then
                        dist = dist + GetHitBox(enemy)
                end
                local name = GetObjectName(enemy)
                if Config.ts.fl[name]:Value() and ValidTarget(enemy, dist) then
                        count = count + 1
                        if a == 1 then
                                t1 = enemy
                                tr1 = true
                                if ad then
                                        c1 = ComputeTS(enemy, true)
                                else
                                        c1 = ComputeTS(enemy, false)
                                end
                        end
                        if a == 2 then
                                if not tr1 then
                                        t1 = enemy
                                        tr1 = true
                                        if ad then
                                                c1 = ComputeTS(enemy, true)
                                        else
                                                c1 = ComputeTS(enemy, false)
                                        end
                                else
                                        t2 = enemy
                                        tr2 = true
                                        if ad then
                                                c2 = ComputeTS(enemy, true)
                                        else
                                                c2 = ComputeTS(enemy, false)
                                        end
                                end
                        end
                        if a == 3 then
                                if not tr1 then
                                        t1 = enemy
                                        tr1 = true
                                        if ad then
                                                c1 = ComputeTS(enemy, true)
                                        else
                                                c1 = ComputeTS(enemy, false)
                                        end
                                elseif not tr2 then
                                        t2 = enemy
                                        tr2 = true
                                        if ad then
                                                c2 = ComputeTS(enemy, true)
                                        else
                                                c2 = ComputeTS(enemy, false)
                                        end
                                else
                                        t3 = enemy
                                        tr3 = true
                                        if ad then
                                                c3 = ComputeTS(enemy, true)
                                        else
                                                c3 = ComputeTS(enemy, false)
                                        end
                                end
                        end
                        if a == 4 then
                                if not tr1 then
                                        t1 = enemy
                                        tr1 = true
                                        if ad then
                                                c1 = ComputeTS(enemy, true)
                                        else
                                                c1 = ComputeTS(enemy, false)
                                        end
                                elseif not tr2 then
                                        t2 = enemy
                                        tr2 = true
                                        if ad then
                                                c2 = ComputeTS(enemy, true)
                                        else
                                                c2 = ComputeTS(enemy, false)
                                        end
                                elseif not tr3 then
                                        t3 = enemy
                                        tr3 = true
                                        if ad then
                                                c3 = ComputeTS(enemy, true)
                                        else
                                                c3 = ComputeTS(enemy, false)
                                        end
                                else
                                        t4 = enemy
                                        tr4 = true
                                        if ad then
                                                c4 = ComputeTS(enemy, true)
                                        else
                                                c4 = ComputeTS(enemy, false)
                                        end
                                end
                        end
                        if a == 5 then
                                if not tr1 then
                                        t1 = enemy
                                        tr1 = true
                                        if ad then
                                                c1 = ComputeTS(enemy, true)
                                        else
                                                c1 = ComputeTS(enemy, false)
                                        end
                                elseif not tr2 then
                                        t2 = enemy
                                        tr2 = true
                                        if ad then
                                                c2 = ComputeTS(enemy, true)
                                        else
                                                c2 = ComputeTS(enemy, false)
                                        end
                                elseif not tr3 then
                                        t3 = enemy
                                        tr3 = true
                                        if ad then
                                                c3 = ComputeTS(enemy, true)
                                        else
                                                c3 = ComputeTS(enemy, false)
                                        end
                                elseif not tr4 then
                                        t4 = enemy
                                        tr4 = true
                                        if ad then
                                                c4 = ComputeTS(enemy, true)
                                        else
                                                c4 = ComputeTS(enemy, false)
                                        end
                                else
                                        t5 = enemy
                                        tr5 = true
                                        if ad then
                                                c5 = ComputeTS(enemy, true)
                                        else
                                                c5 = ComputeTS(enemy, false)
                                        end
                                end
                        end
                end
        end
        if count == 1 then
                return t1
        end
        if count == 2 then
                if c1 < c2 then
                        return t1
                else
                        return t2
                end
        end
        if count == 3 then
                if c1 < c2 and c1 < c3 then
                        return t1
                elseif c2  < c1 and c2 < c3 then
                        return t2
                else
                        return t3
                end
        end
        if count == 4 then
                if c1 < c2 and c1 < c3 and c1 < c4 then
                        return t1
                elseif c2  < c1 and c2 < c3 and c2 < c4 then
                        return t2
                elseif c3  < c1 and c3 < c2 and c3 < c4 then
                        return t3
                else
                        return t4
                end
        end
        if count == 5 then
                if c1 < c2 and c1 < c3 and c1 < c4 and c1 < c5 then
                        return t1
                elseif c2  < c1 and c2 < c3 and c2 < c4 and c2 < c5 then
                        return t2
                elseif c3  < c1 and c3 < c2 and c3 < c4 and c3 < c5 then
                        return t3
                elseif c4  < c1 and c4 < c2 and c4 < c3 and c4 < c5 then
                        return t4
                else
                        return t5
                end
        end
        return nil
end

-- D I S T A N C E
function ComputeDistance(a, b)
        return math.sqrt( a^2 + b^2 )
end

-- D I R E C T I O N
function ComputeDirection(a, b)
        local c = ComputeDistance(a, b)
        return { x = a/c, z = b/c }
end


-- O R B W A L K E R
function Orb()
        local aat = SelectTarget(0, true, true)
        if aat ~= nil then
                if GetTickCount() > attack_animation then
                        AttackUnit(aat)
                end
                if GetTickCount() > attack_windup then
                        local pos = MovePred(aat)
                        if pos then
                                if GetTickCount() > move_issue then
                                        MoveToXYZ(pos)
                                end
                        end
                end
        elseif GetTickCount() > attack_windup + 75 then
                if GetTickCount() > move_issue then
                        MoveToXYZ(GetMousePos())
                end
        end
end
function MovePred(unit)
        if not Config.orbwalker.mm.a:Value() then
                return GetMousePos()
        end
        local unit_x = unit.pos.x
        local unit_z = unit.pos.z
        local mouse_x = GetMousePos().x
        local mouse_z = GetMousePos().z
        local dir = ComputeDirection(mouse_x-unit_x,mouse_z-unit_z)
        local aarange = GetRange(myHero)
        local go_to_pos_x = unit_x + ( dir.x * ( aarange + 100 ) )
        local go_to_pos_z = unit_z + ( dir.z * ( aarange + 100 ) )
        local dist = ComputeDistance(go_to_pos_x-myHero.pos.x, go_to_pos_z-myHero.pos.z)
        return { x = go_to_pos_x, y = 0, z = go_to_pos_z }
end

-- P R E D I C T I O N
function GetPos(startpos, endpos, range, speed, delay, width)
        local hitchance = Config.pred.h:Value()
        local id = GetNetworkID(endpos)
        local way = WaypointManager[id]
        local util = UtilsManager[id]
        if WaypointManager[id] and WaypointManager[id].third.to then
                local ax = startpos.pos.x
                local az = startpos.pos.z
                local bx = endpos.pos.x
                local bz = endpos.pos.z
                for m, minion in ipairs(ObjectManager.Minions.Enemies) do
                        local hp = GetCurrentHP(minion)
                        if hp ~= 0 then
                                local cx = minion.pos.x
                                local cz = minion.pos.z
                                local cbb = GetHitBox(minion)
                                local a = bz-az
                                local b = bx-ax
                                local c = ax-cx
                                local d = cz-az
                                local ab = ComputeDistance(b,a)
                                local ac = ComputeDistance(c,az-cz)
                                local bc = ComputeDistance(bx-cx,bz-cz)
                                if ac < ab + 250 then
                                        if bc < ab + 250 then
                                                local dist_obj_line = math.abs(a * c + b * d) / ab
                                                local compute_max_obj_dist = width/2 + cbb/2
                                                if dist_obj_line < compute_max_obj_dist then
                                                        return { x = 0 }
                                                end
                                        end
                                end
                        end
                end
                local cx = WaypointManager[id].last.to.x
                local cz = WaypointManager[id].last.to.z
                local bc = WaypointManager[id].last.dist
                local vx = WaypointManager[id].last.dir.x
                local vz = WaypointManager[id].last.dir.z
                local bv = GetMoveSpeed(endpos)
                local array = #UtilsManager[id].Immobile
                if UtilsManager[id].IsImmobile then
                        local array = #UtilsManager[id].Immobile
                        if array ~= 0 then
                                local max = UtilsManager[id].Immobile[array].EndTime
                                local tick = UtilsManager[id].Immobile[array].StartTime
                                if array > 1 then
                                        for i = array-1, 1, - 1 do
                                                if UtilsManager[id].Immobile[i].EndTime>max then
                                                        max = UtilsManager[id].Immobile[i].EndTime
                                                        tick = UtilsManager[id].Immobile[i].StartTime
                                                end
                                        end
                                end
                                if max ~= 0 then
                                        if GetTickCount() < tick + max - max/10*hitchance then
                                                local dist = ComputeDistance(myHero.pos.x - bx, myHero.pos.z - bz)
                                                if dist < range then
                                                        WaypointManager[id].last.timeto = dist / bv * 1000
                                                        return endpos.pos
                                                end
                                        else
                                                UtilsManager[id].IsImmobile = false
                                        end
                                end
                        else
                                UtilsManager[id].IsImmobile = false
                        end
                end
                if UtilsManager[id].IsAttacking then
                        local lastaa = UtilsManager[id].AALast
                        local windup = UtilsManager[id].AACastDelay
                        local dist = ComputeDistance(myHero.pos.x - bx, myHero.pos.z - bz)
                        if GetTickCount() < lastaa + windup - windup/10*hitchance then
                                if dist < range then
                                        WaypointManager[id].last.timeto = dist / bv * 1000
                                        return endpos.pos
                                end
                        else
                                UtilsManager[id].IsAttacking = false
                        end
                end
                if UtilsManager[id].IsMoving and UtilsManager[id].CanMove then
                        if bx == cx and bz == cz then
                                UtilsManager[id].LastStopMoveTime = GetTickCount()
                                UtilsManager[id].IsMoving = false
                        end
                        local ab = ComputeDistance(ax - bx, az - bz)
                        local hx = bx + ( vx * bv * ( delay + ab / speed ) )
                        local hz = bz + ( vz * bv * ( delay + ab / speed ) )
                        local ah = ComputeDistance(ax - hx, az - hz)
                        local ix = bx + ( vx * bv * ( delay + ah / speed ) )
                        local iz = bz + ( vz * bv * ( delay + ah / speed ) )
                        local ai = ComputeDistance(ax - ix, az - iz)
                        local jx = bx + ( vx * bv * ( delay + ai / speed ) )
                        local jz = bz + ( vz * bv * ( delay + ai / speed ) )
                        local aj = ComputeDistance(ax - jx, az - jz)
                        local bj = ComputeDistance(bx - jx, bz - jz)
                        local at = delay + aj / speed
                        local bt = bj / bv
                        if at - bt > -0.05 and at - bt < 0.05 then
                                local px = jx - ( vx * ( width/2 ) )
                                local pz = jz - ( vz * ( width/2 ) )
                                local bp = ComputeDistance(bx - px, bz - pz)
                                if GetTickCount() < WaypointManager[id].last.time + 250/hitchance or GetTickCount() > WaypointManager[id].last.time + 1000 then
                                        if bp > bc then
                                                local dist = ComputeDistance(myHero.pos.x - cx, myHero.pos.z - cz)
                                                if dist< range then
                                                        WaypointManager[id].last.timeto = dist / bv * 1000
                                                        return way.last.to
                                                end
                                        else
                                                local dist = ComputeDistance(myHero.pos.x - px, myHero.pos.z - pz) 
                                                if dist < range then
                                                        WaypointManager[id].last.timeto = dist / bv * 1000
                                                        return { x = px, y = 0, z = pz }
                                                end
                                        end
                                end
                        end
                else
                        local dist = ComputeDistance(myHero.pos.x - bx, myHero.pos.z - bz)
                        if dist < range then
                                if GetTickCount() < UtilsManager[id].LastStopMoveTime + 250/hitchance then
                                        WaypointManager[id].last.timeto = dist / bv * 1000
                                        return endpos.pos
                                end
                        end
                end
        end
end

-- I N S E R T  T A B L E
function Insert(t, o)
        table.insert(t, o)
        WaypointManager[GetNetworkID(o)] =
        {
                last =
                {
                        dir = {},
                        time = 0,
                        from = {},
                        to = {},
                        dist = 0,
                        timeto = 0
                },
                second = {},
                third = {}
        }
        UtilsManager[GetNetworkID(o)] =
        {
                CanMove = true,
                IsMoving = false,
                LastStopMoveTime = 0,
                IsAttacking = false,
                AALast = 0,
                AACastDelay = 0,
                IsImmobile = false,
                Immobile = {}
        }
end
