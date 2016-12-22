PrintChat("Waypoints Library by GamSterOn")

local WP = {}
local Heroes = {}

OnLoad(function()
        table.insert(Heroes, myHero)
        WP[GetNetworkID(myHero)] = { time = 0, path = {}, ismoving = false, lenght = 0 }
end)

OnObjectLoad(function(o)
        if GetObjectType(o) == Obj_AI_Hero then
                table.insert(Heroes, o)
                WP[GetNetworkID(o)] = { time = 0, path = {}, ismoving = false, lenght = 0 }
        end
end)

function WP_Moving(unit)
        if WP[GetNetworkID(unit)] then return WP[GetNetworkID(unit)].ismoving end
end

function WP_Time(unit)
        if WP[GetNetworkID(unit)] then return WP[GetNetworkID(unit)].time end
end

function WP_Path(unit)
        if WP[GetNetworkID(unit)] and #WP[GetNetworkID(unit)].path > 0 then return WP[GetNetworkID(unit)].path end
end

function WP_DistOnPath(unit)
        local id = GetNetworkID(unit)
        if WP[id] then return GetMoveSpeed(unit) * (GetTickCount() - WP[id].time) / 1000 end
end

function WP_TravelDist(unit)
        if WP[GetNetworkID(unit)] then return WP[GetNetworkID(unit)].lenght end
end

function WP_NormalizeVector(vec)
        local num = 1 / math.sqrt(vec.x^2 + vec.z^2)
        return { x = vec.x * num, z = vec.z * num }
end

function WP_ExtendedPosition(vec1, vec2, s)
        local normalized = WP_NormalizeVector({ x = vec1.x - vec2.x, z = vec1.z - vec2.z})
        if normalized and normalized.x then
                local px = vec2.x + (normalized.x * s)
                local pz = vec2.z + (normalized.z * s)
                return { x = px, y = 0, z = pz }
        end
end

function WP_InterceptionTime(source, startP, endP, unitspeed, spellspeed)
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
        return 0.0001
end

function WP_DistPointLineSegment(a, b, c)
        local ax = a.x
        local ay = a.z
        local bx = b.x
        local by = b.z
        local cx = c.x
        local cy = c.z
        local dx = bx - ax
        local dy = by - ay
        local t = ((cx - ax) * dx + (cy - ay) * dy) / (dx * dx + dy * dy)
        if t < 0 then
                dx = cx - ax
                dy = cy - ay
        elseif t > 1 then
                dx = cx - bx
                dy = cy - by
        else
                dx = cx - (ax + (t * dx))
                dy = cy - (ay + (t * dy))
        end
        return math.sqrt( dx^2 + dy^2 )
end

function WP_GetPredPointOnPath(source, unit, speed, width, delay)
        local id = GetNetworkID(unit)
        if WP[id] then
                local path = WP[id].path
                local pos = GetOrigin(unit)
                if not WP[id].ismoving then
                        return pos
                end
                local ms = GetMoveSpeed(unit)
                local spos = GetOrigin(source)
                local d = 0
                for i = 1, #path - 1, 1 do
                        local pi = path[i]
                        local pi1 = path[i+1]
                        d = d + math.sqrt( (pi.x-pi1.x)^2 + (pi.z-pi1.z)^2 )
                        local dop = WP_DistOnPath(unit)
                        if d > dop then
                                local dd = math.sqrt( (pos.x-pi1.x)^2 + (pos.z-pi1.z)^2 )
                                local t = WP_InterceptionTime(spos, pos, pi1, ms, speed) + delay
                                local s = (ms * t) - (width/2)
                                if dd >= s then
                                        local pos = WP_ExtendedPosition(pi1, pos, s)
                                        if pos and pos.x then
                                                return pos
                                        end
                                end
                                if i + 1 == #path then
                                        local pos = WP_ExtendedPosition(pi1, pos, dd)
                                        if pos and pos.x then
                                                return pos
                                        end
                                end
                                for j = i + 1, #path - 1, 1 do
                                        local pj = path[j]
                                        local pj1 = path[j + 1]
                                        t = WP_InterceptionTime(spos, pj, pj1, ms, speed) - (dd / ms) + delay
                                        s = (ms * t) - (width/2)
                                        dd = math.sqrt( (pj.x-pj1.x)^2 + (pj.z-pj1.z)^2 )
                                        if dd >= s then
                                                local pos = WP_ExtendedPosition(pj1, pj, s)
                                                if pos and pos.x then
                                                        return pos
                                                end
                                        end
                                        if j + 1 == #path then
                                                local pos = WP_ExtendedPosition(pj1, pj, dd)
                                                if pos and pos.x then
                                                        return pos
                                                end
                                        end
                                end
                        end
                end
        end
end

function WP_MCollision(source, castpos, range, speed, width, delay)
        local col = {}
        for m, minion in pairs(minionManager.objects) do
                if ValidTarget(minion, range + 500) then
                        local minionpos = WP_GetPredPointOnPath(source, minion, speed, width, delay)
                        if minionpos and minionpos.x then
                                local dist = WP_DistPointLineSegment(GetOrigin(source), castpos, minionpos)
                                if dist < width + GetHitBox(minion) + ((GetLatency() / 1000) * GetMoveSpeed(minion)) + 25 then
                                        table.insert(col, minion)
                                end
                        end
                end
        end
        return col
end

function WP_HCollision(source, castpos, range, speed, width, delay)
        local col = {}
        for t, target in pairs(GetEnemyHeroes()) do
                if ValidTarget(target, range + 500) then
                        local targetpos = WP_GetPredPointOnPath(source, target, speed, width, delay)
                        if targetpos and targetpos.x then
                                local dist = WP_DistPointLineSegment(GetOrigin(source), castpos, targetpos)
                                if dist < width + GetHitBox(target) + ((GetLatency() / 1000) * GetMoveSpeed(target)) + 25 then
                                        table.insert(col, target)
                                end
                        end
                end
        end
        return col
end

function WP_GetExtendedPointOnPath(unit, s)
        local id = GetNetworkID(unit)
        if WP[id] then
                local path = WP[id].path
                local pos = GetOrigin(unit)
                if not WP[id].ismoving then
                        return pos
                end
                local d = 0
                for i = 1, #path - 1, 1 do
                        local pi = path[i]
                        local pi1 = path[i+1]
                        d = d + math.sqrt( (pi.x-pi1.x)^2 + (pi.z-pi1.z)^2 )
                        local dop = WP_DistOnPath(unit)
                        if d > dop then
                                local dd = math.sqrt( (pos.x-pi1.x)^2 + (pos.z-pi1.z)^2 )
                                if dd >= s then
                                        local pos = WP_ExtendedPosition(pi1, pos, s)
                                        if pos and pos.x then
                                                return pos
                                        end
                                end
                                if i + 1 == #path then
                                        local pos = WP_ExtendedPosition(pi1, pos, dd)
                                        if pos and pos.x then
                                                return pos
                                        end
                                end
                                local ss = s
                                for j = i + 1, #path - 1, 1 do
                                        local pj = path[j]
                                        local pj1 = path[j + 1]
                                        ss = ss - dd
                                        dd = math.sqrt( (pj.x-pj1.x)^2 + (pj.z-pj1.z)^2 )
                                        if dd >= ss then
                                                local pos = WP_ExtendedPosition(pj1, pj, ss)
                                                if pos and pos.x then
                                                        return pos
                                                end
                                        end
                                        if j + 1 == #path then
                                                local pos = WP_ExtendedPosition(pj1, pj, dd)
                                                if pos and pos.x then
                                                        return pos
                                                end
                                        end
                                end
                        end
                end
        end
end

local function StopMoveLogic(id, speed)
        local count = #WP[id].path
        if count > 1 then
                if GetTickCount() > WP[id].time + 50 then
                        local d = 0
                        for i = 1, count-1, 1 do
                                local px = WP[id].path[i].x-WP[id].path[i+1].x
                                local py = WP[id].path[i].z-WP[id].path[i+1].z
                                d = d + math.sqrt( px^2 + py^2 )
                        end
                        WP[id].lenght = d
                        local s = speed * (GetTickCount() - WP[id].time) / 1000
                        if d > 0 and d - s < 15 then
                                WP[id].ismoving = false
                                WP[id].path = WP[id].path[count]
                                WP[id].time = GetTickCount()
                                --PrintChat("DEBUG STOPMOVE")
                        end
                end
        end
end

OnDeleteObj(function(object)
        local id = GetNetworkID(object)
        if WP[id] then
                WP[id] = nil
        end
end)

OnProcessWaypoint(function(unit,waypoint)
        local id = GetNetworkID(unit)
        if WP[id] then
                if waypoint.index == 2 then
                        --PrintChat("DEBUG OnProcessWaypoint: move")
                        WP[id].ismoving = true
                end
                if GetTickCount() > WP[id].time + 1 then
                        --PrintChat("DEBUG OnProcessWaypoint: new waypoint")
                        WP[id].time = GetTickCount()
                        WP[id].path = {}
                end
                if #WP[id].path == 0 and waypoint.index == 1 then
                        --PrintChat("DEBUG OnProcessWaypoint: not move")
                        WP[id].ismoving = false
                end
                table.insert(WP[id].path, waypoint.position)
        end
end)

OnTick(function(myHero)
        for m, minion in pairs(minionManager.objects) do
                local networkID = GetNetworkID(minion)
                if not WP[networkID] then
                        WP[networkID] = { time = 0, path = {}, ismoving = false, lenght = 0 }
                end
                StopMoveLogic(networkID, GetMoveSpeed(minion))
        end
        for u,unit in ipairs(Heroes) do
                StopMoveLogic(GetNetworkID(unit), GetMoveSpeed(unit))
        end
end)
