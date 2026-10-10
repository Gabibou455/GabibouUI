-- Native vector icon registry. Injected into ui.luau's shared lexical scope.
-- Builders receive a 24-unit design canvas; geometry scales with the root Frame.

Library._icons = Library._icons or {}

local function iconFrame(parent, name, properties)
    properties = properties or {}
    properties.Name = name
    properties.BackgroundTransparency = properties.BackgroundTransparency or 0
    properties.BorderSizePixel = 0
    properties.AutoLocalize = false
    local frame=create("Frame", properties, parent)
    frame:SetAttribute("GabibouIconPrimitive",true)
    return frame
end

local function iconBuilder(window, root, color, token, thickness, variant)
    local strokeWidth = variant == "Soft" and math.min(4, thickness * 1.2) or thickness
    local function paint(instance, property)
        if color then instance[property] = color
        elseif window then window:BindColor(instance, property, token)
        else instance[property] = Color3.fromRGB(157, 162, 173) end
    end

    local function line(x1, y1, x2, y2, radius)
        local dx, dy = x2 - x1, y2 - y1
        local length = math.sqrt(dx * dx + dy * dy)
        local shape = iconFrame(root, "Vector", {
            AnchorPoint = Vector2.new(.5, .5),
            Position = UDim2.new((x1 + x2) / 48, 0, (y1 + y2) / 48, 0),
            -- Rounded caps shorten the visible ends of each segment. Extend the
            -- native width by one stroke so joined path segments overlap cleanly.
            Size = UDim2.new(length / 24, strokeWidth, 0, strokeWidth),
            Rotation = math.deg(math.atan2(dy, dx)),
        })
        if radius ~= false then corner(shape, variant == "Soft" and strokeWidth * 1.5 or strokeWidth) end
        paint(shape, "BackgroundColor3")
        if variant == "Duotone" then
            local canvasWidth = root.Size.X.Offset
            local extension = canvasWidth > 0 and strokeWidth * 24 / canvasWidth or 0
            local halfExtension = extension / 2
            local unitX, unitY = dx / length, dy / length
            local function fieldColor(x, y)
                local field = math.clamp((x + y) / 48, 0, 1)
                local value = 1 - (1 - 150 / 255) * field
                return Color3.new(value, value, value)
            end
            local startColor = fieldColor(x1 - unitX * halfExtension, y1 - unitY * halfExtension)
            local endColor = fieldColor(x2 + unitX * halfExtension, y2 + unitY * halfExtension)
            create("UIGradient", {
                Color = ColorSequence.new(startColor, endColor),
                Rotation = 0,
            }, shape)
        end
        return shape
    end

    local function rect(x, y, width, height, outline, radius)
        local shape = iconFrame(root, outline and "Outline" or "Vector", {
            BackgroundTransparency = outline and 1 or 0,
            Position = UDim2.new(x / 24, 0, y / 24, 0),
            Size = UDim2.new(width / 24, 0, height / 24, 0),
        })
        if radius then corner(shape, radius) end
        if outline then
            if variant == "Duotone" then
                local depth = create("UIStroke", {Thickness = strokeWidth + 1, Transparency = .62, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, shape)
                paint(depth, "Color")
            end
            local stroke = create("UIStroke", {Thickness = strokeWidth, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Transparency = 0}, shape)
            paint(stroke, "Color")
        else
            paint(shape, "BackgroundColor3")
            if variant == "Duotone" then
                create("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(150,150,150)), Rotation = 45}, shape)
            end
        end
        return shape
    end

    local function circle(cx, cy, diameter, outline)
        local shape = rect(cx - diameter / 2, cy - diameter / 2, diameter, diameter, outline, 0)
        local rounding = shape:FindFirstChildOfClass("UICorner")
        if rounding then rounding:Destroy() end
        corner(shape, 100)
        return shape
    end

    local function path(points)
        for index = 1, #points - 1 do
            local a, b = points[index], points[index + 1]
            line(a[1], a[2], b[1], b[2])
        end
    end

    return {line = line, rect = rect, circle = circle, path = path}
end

local function drawIcon(root, color, thickness, window, token, name, variant)
    local p = iconBuilder(window, root, color, token, thickness, variant)
    local line, rect, circle, path = p.line, p.rect, p.circle, p.path
    local function cubic(startPoint, controlA, controlB, endPoint, segments)
        local points = {}
        for index = 0, segments do
            local t = index / segments
            local u = 1 - t
            local x = u*u*u*startPoint[1] + 3*u*u*t*controlA[1] + 3*u*t*t*controlB[1] + t*t*t*endPoint[1]
            local y = u*u*u*startPoint[2] + 3*u*u*t*controlA[2] + 3*u*t*t*controlB[2] + t*t*t*endPoint[2]
            points[#points + 1] = {x, y}
        end
        path(points)
        return points
    end
    local function ellipse(cx, cy, radiusX, radiusY, segments, rotation)
        local points = {}
        local angleOffset = math.rad(rotation or 0)
        for index = 0, segments do
            local angle = math.pi * 2 * index / segments
            local x, y = math.cos(angle) * radiusX, math.sin(angle) * radiusY
            points[#points + 1] = {
                cx + x * math.cos(angleOffset) - y * math.sin(angleOffset),
                cy + x * math.sin(angleOffset) + y * math.cos(angleOffset),
            }
        end
        path(points)
        return points
    end
    local function arc(cx, cy, radiusX, radiusY, startAngle, endAngle, segments)
        local points = {}
        for index = 0, segments do
            local angle = math.rad(startAngle + (endAngle - startAngle) * index / segments)
            points[#points + 1] = {cx + math.cos(angle) * radiusX, cy + math.sin(angle) * radiusY}
        end
        path(points)
        return points
    end

    if name == "home" then
        path({{3,11},{12,4},{21,11}});rect(5,10,14,10,true,2)
        -- Separate the small openings so they remain distinct at toolbar sizes.
        rect(7,13,2.5,3,false,1);rect(14.5,13,2.5,3,false,1);rect(10.5,15,3,5,false,1)
    elseif name == "sliders" then
        line(3,6,5.5,6);line(10.5,6,21,6)
        line(3,12,13.5,12);line(18.5,12,21,12)
        line(3,18,7.5,18);line(12.5,18,21,18)
        circle(8,6,5,true);circle(15,12,5,true);circle(10,18,5,true)
    elseif name == "palette" then
        cubic({10,3.5},{6,3.5},{3.5,7},{3.5,11},5)
        cubic({3.5,11},{3.5,16},{7.5,20.5},{12,20.5},6)
        cubic({12,20.5},{15,20.5},{17,18.5},{17,16.5},4)
        cubic({17,16.5},{17,14.5},{15,13.5},{14.2,12.2},4)
        cubic({14.2,12.2},{13.2,10.6},{15,9.4},{17,9.4},4)
        cubic({17,9.4},{19,9.4},{20.5,8.5},{20.5,7.2},3)
        cubic({20.5,7.2},{20.5,5.1},{17,3.5},{13,3.5},5)
        path({{13,3.5},{10,3.5}})
        circle(8,8,2.2,false);circle(13,6.8,2.2,false);circle(17,8,2.2,false);circle(8,13,2.2,false)
    elseif name == "save" then
        path({{4,3},{17,3},{21,7},{21,21},{3,21},{3,4},{4,3}})
        line(7,4,7,9);line(7,9,16,9);rect(8,13,8,6,true,1);line(11,4,11,8)
    elseif name == "code" then
        path({{8,6},{3,12},{8,18}}); path({{16,6},{21,12},{16,18}}); line(14,4,10,20)
    elseif name == "search" then
        circle(9.5,9.5,11,true); line(13.5,13.5,20.5,20.5)
    elseif name == "close" then
        line(4.5,4.5,19.5,19.5); line(19.5,4.5,4.5,19.5)
    elseif name == "check" then
        path({{4,12},{10,18},{20,6}})
    elseif name == "chevron-down" then
        path({{5,9},{12,16},{19,9}})
    elseif name == "chevron-right" then
        path({{9,5},{16,12},{9,19}})
    elseif name == "settings" then
        local teeth = {}
        for index = 0, 23 do
            local angle = -math.pi / 2 + index * math.pi * 2 / 24
            local toothPhase = index % 4
            local radius = (toothPhase == 1 or toothPhase == 2) and 9 or 7.5
            teeth[#teeth + 1] = {12 + math.cos(angle) * radius, 12 + math.sin(angle) * radius}
        end
        teeth[#teeth + 1] = teeth[1]
        path(teeth)
        circle(12,12,8,true);circle(12,12,2.4,false)
    elseif name == "user" then
        circle(12,7.75,7,true)
        cubic({4,20},{4,15},{7,13.5},{12,13.5},6)
        cubic({12,13.5},{17,13.5},{20,15},{20,20},6)
        line(4,20,20,20)
    elseif name == "folder" then
        path({{3,8},{9,8},{11,10},{21,10},{20,19},{4,19},{3,8}})
        cubic({4,8},{4,6},{5,5},{7,5},3);line(7,5,10,5);line(10,5,12,8)
    elseif name == "download" then
        line(12,3,12,15); path({{7,11},{12,16},{17,11}}); line(4,20,20,20)
    elseif name == "upload" then
        line(12,21,12,9); path({{7,13},{12,8},{17,13}}); line(4,4,20,4)
    elseif name == "refresh" then
        local function arc(cx, cy, radius, startAngle, endAngle, segments)
            local points = {}
            for index = 0, segments do
                local angle = math.rad(startAngle + (endAngle - startAngle) * index / segments)
                points[#points + 1] = {cx + math.cos(angle) * radius, cy + math.sin(angle) * radius}
            end
            path(points)
            return points[#points]
        end
        local function arrowHead(tip, tangentAngle)
            local angle = math.rad(tangentAngle)
            local directionX, directionY = -math.sin(angle), math.cos(angle)
            local normalX, normalY = -directionY, directionX
            local baseX, baseY = tip[1] - directionX * 2.6, tip[2] - directionY * 2.6
            path({
                {baseX + normalX * 1.55, baseY + normalY * 1.55},
                {tip[1], tip[2]},
                {baseX - normalX * 1.55, baseY - normalY * 1.55},
            })
        end
        arrowHead(arc(12, 12, 7.5, 190, 350, 14), 350)
        arrowHead(arc(12, 12, 7.5, 10, 170, 14), 170)
    elseif name == "bell" then
        cubic({5,17},{7,15},{7,11},{7,9},5);cubic({7,9},{7,5},{10,4},{12,4},5)
        cubic({12,4},{15,4},{17,6},{17,9},5);cubic({17,9},{17,12},{17,15},{19,17},5)
        path({{19,17},{5,17}});cubic({10,19},{10,21},{14,21},{14,19},4)
    elseif name == "info" then
        circle(12,12,18,true); circle(12,7,2,false); line(12,11,12,17)
    elseif name == "plus" then
        line(12,4,12,20); line(4,12,20,12)
    elseif name == "minus" then
        line(4,12,20,12)
    elseif name == "farm" then
        path({{4,10},{12,4},{20,10}})
        rect(5,9,14,11,true,1)
        path({{8,20},{8,14},{12,11},{16,14},{16,20}})
        line(12,13,12,20);line(3,21,21,21)
    elseif name == "panel" then
        rect(3,4,18,16,true,2);line(3,9,21,9);line(12,9,12,20);circle(6,6.5,1,false);circle(9,6.5,1,false)
    elseif name == "inventory" then
        path({{4,8},{7,5},{17,5},{20,8},{20,19},{4,19},{4,8}})
        line(4,9,20,9);path({{9,9},{9,12},{15,12},{15,9}});line(8,15,8,17);line(16,15,16,17)
    elseif name == "harvest" then
        path({{5,13},{19,13},{17,20},{7,20},{5,13}});line(6,16,18,16);line(7,18,17,18)
        line(12,13,12,5);cubic({12,9},{9,5},{7,6},{7,9},5);cubic({12,8},{15,4},{18,5},{18,8},5)
        path({{9,10},{12,7},{15,9}})
    elseif name == "seed" then
        ellipse(12,12,5.7,8,16,-27)
        cubic({8,16},{10,13},{13,9},{16,7},7)
    elseif name == "sprout" then
        line(12,20,12,11)
        cubic({12,15},{9,15},{6,12},{6,9},6);cubic({6,9},{10,8},{13,10},{13,14},6)
        cubic({12,12},{13,8},{16,5},{20,5},6);cubic({20,5},{20,10},{17,14},{12,14},6)
        line(5,20,19,20)
    elseif name == "watering-can" then
        path({{5,11},{16,11},{15,19},{7,19},{5,11}})
        cubic({7,11},{6,7},{8,5},{11,5},5);cubic({11,5},{14,5},{15,7},{15,11},5)
        path({{16,12},{19,10},{21,11},{17,15}})
        line(19,11,20,9);line(20,9,21,9);circle(20,16,1.6,false);circle(18,19,1.6,false)
    elseif name == "shovel" then
        line(12,4,12,15);path({{8,15},{16,15},{18,18},{12,21},{6,18},{8,15}})
        line(9,5,15,5);line(10,4,14,4)
    elseif name == "tools" then
        -- Open jaw wrench with a round handle; the shaft stays clear of both ends.
        path({{4,4},{6,3},{10,7},{8,9},{7,8},{6,9},{8,11},{10,9},{12,11}})
        line(10,9,16,15);line(12,11,18,17);circle(18,18,5,true)
    elseif name == "tractor" then
        circle(7,18,8,true);circle(18,18,6,true);circle(7,18,1.5,false)
        rect(7,5,7,8,true,1)
        path({{14,10},{18,10},{21,12},{21,14},{14,14}})
    elseif name == "map" then
        path({{3,6},{9,4},{15,6},{21,4},{21,18},{15,20},{9,18},{3,20},{3,6}})
        line(9,4,9,18);line(15,6,15,20)
    elseif name == "menu" then
        line(4,6,20,6);line(4,12,20,12);line(4,18,20,18)
    elseif name == "arrow-left" then
        path({{14,5},{7,12},{14,19}});line(7,12,21,12)
    elseif name == "arrow-right" then
        path({{10,5},{17,12},{10,19}});line(3,12,17,12)
    elseif name == "minimize" then
        line(4.5,17.5,19.5,17.5)
    elseif name == "maximize" then
        rect(4.5,4.5,15,15,true,1.5)
    elseif name == "restore" then
        path({{8,8},{8,4},{20,4},{20,16},{16,16}});rect(4,8,12,12,true,1)
    elseif name == "resize" then
        path({{5,19},{19,5}});path({{12,5},{19,5},{19,12}});path({{5,12},{5,19},{12,19}})
    elseif name == "window" then
        rect(3,4,18,16,true,2);line(3,9,21,9);circle(6,6.5,1,false);circle(9,6.5,1,false)
    elseif name == "automation" then
        circle(9,13,11,true);circle(9,13,3,false);circle(18,7,5,true);line(9,3,9,5);line(9,20,9,21);line(3,13,5,13);line(14,13,16,13)
    elseif name == "play" then
        path({{7,4},{19,12},{7,20},{7,4}})
    elseif name == "pause" then
        rect(6,4,4,16,false,1);rect(14,4,4,16,false,1)
    elseif name == "stop" then
        rect(5,5,14,14,false,2)
    elseif name == "bolt" then
        path({{14,3},{7,12},{11,12},{9,21},{17,11},{13,11},{14,3}})
    elseif name == "shield" then
        path({{12,3},{20,6},{19,12}})
        cubic({19,12},{18,16},{15,19},{12,21},7)
        cubic({12,21},{9,19},{6,16},{5,12},7)
        path({{5,12},{4,6},{12,3}})
    elseif name == "key" then
        circle(8,9,9,true);line(11,12,20,21);line(16,17,18,15);line(18,19,20,17)
    elseif name == "lock" then
        rect(4,10,16,11,true,2);path({{7,10},{7,7},{8,4},{10,3},{14,3},{16,5},{17,8},{17,10}});circle(12,15,2,false);line(12,16,12,18)
    elseif name == "unlock" then
        rect(4,10,16,11,true,2);path({{7,10},{7,7},{8,4},{10,3},{14,3},{16,5},{16,7}});circle(12,15,2,false);line(12,16,12,18)
    elseif name == "coins" then
        circle(8,8,9,true);circle(16,16,9,true);circle(8,8,2,false);circle(16,16,2,false)
    elseif name == "gift" then
        rect(4,10,16,11,true,2);line(12,10,12,21);line(3,10,21,10);rect(3,7,18,4,true,1);path({{12,7},{8,7},{6,5},{7,3},{9,3},{12,7},{15,3},{17,3},{18,5},{16,7},{12,7}})
    elseif name == "teleport" then
        ellipse(12,12,5.5,8.5,16,0);line(3,12,17,12);path({{17,8},{21,12},{17,16}})
    elseif name == "target" then
        circle(12,12,18,true);circle(12,12,10,true);circle(12,12,2,false);line(12,3,12,5);line(19,12,21,12);line(12,19,12,21);line(3,12,5,12)
    elseif name == "chart" then
        line(4,4,4,20);line(4,20,21,20);path({{6,16},{10,12},{13,14},{19,7}});path({{15,7},{19,7},{19,11}})
    elseif name == "chart-bar" then
        line(4,4,4,20);line(4,20,21,20);rect(7,13,3,7,false,1);rect(12,9,3,11,false,1);rect(17,5,3,15,false,1)
    elseif name == "clock" then
        circle(12,12,18,true);line(12,6,12,12);line(12,12,17,15)
    elseif name == "timer" then
        circle(12,13,16,true);line(12,7,12,13);line(12,13,16,15);line(9,3,15,3);line(12,3,12,5);line(18,6,20,4)
    elseif name == "compass" then
        circle(12,12,19,true);path({{15,7},{13,13},{7,17},{9,11},{15,7}});circle(12,12,2,false)
    elseif name == "heart" then
        cubic({12,20},{9,17},{3,13},{3,9},7)
        cubic({3,9},{3,4},{9,4},{12,9},7)
        cubic({12,9},{15,4},{21,4},{21,9},7)
        cubic({21,9},{21,13},{15,17},{12,20},7)
    elseif name == "star" then
        path({{12,3},{14.2,9},{20.8,9.5},{15.7,13.5},{17.5,20},{12,16.4},{6.5,20},{8.3,13.5},{3.2,9.5},{9.8,9},{12,3}})
    elseif name == "eye" then
        cubic({3,12},{7,4.5},{17,4.5},{21,12},10);cubic({21,12},{17,19.5},{7,19.5},{3,12},10)
        circle(12,12,6.5,true);circle(12,12,2.4,false)
    elseif name == "eye-off" then
        cubic({3,12},{7,4.5},{17,4.5},{21,12},10);cubic({21,12},{17,19.5},{7,19.5},{3,12},10)
        line(5,5,19,19)
    elseif name == "filter" then
        path({{3,4},{21,4},{14,12},{14,19},{10,21},{10,12},{3,4}})
    elseif name == "sort" then
        path({{7,4},{7,20},{4,17}});path({{7,20},{10,17}});path({{17,20},{17,4},{14,7}});path({{17,4},{20,7}})
    elseif name == "check-circle" then
        circle(12,12,18,true);path({{7,12},{10,15},{17,8}})
    elseif name == "alert" then
        path({{12,4},{21,20},{3,20},{12,4}});line(12,9,12,14);circle(12,17,1.8,false)
    elseif name == "help" then
        cubic({8,8},{8,4.5},{16,3.5},{16,7.5},8)
        cubic({16,7.5},{16,10},{12,10.5},{12,13},5);circle(12,18,2,false)
    elseif name == "copy" then
        rect(8,4,12,15,true,2);path({{6,8},{4,8},{4,20},{15,20},{15,19}})
    elseif name == "clipboard" then
        rect(5,5,14,17,true,2);rect(9,3,6,4,false,1);line(8,11,16,11);line(8,15,16,15);line(8,18,13,18)
    elseif name == "trash" then
        path({{6,7},{7,20},{17,20},{18,7}});line(4,6,20,6);line(9,4,15,4);line(10,10,10,17);line(14,10,14,17)
    elseif name == "edit" then
        path({{4,17},{15,6},{19,10},{8,20},{4,21},{4,17}});path({{13,8},{17,12}});line(14,6,17,3);line(19,5,21,7)
    elseif name == "wand" then
        line(5,19,18,6);path({{17,3},{18,5},{21,6},{18,7},{17,9},{16,7},{14,6},{16,5},{17,3}});line(5,5,5,9);line(3,7,7,7);line(20,15,20,19);line(18,17,21,17)
    elseif name == "wifi" then
        arc(12,20,3,3,-135,-45,4);arc(12,20,6,6,-135,-45,6);arc(12,20,9,9,-135,-45,8);circle(12,19,2.2,false)
    elseif name == "globe" then
        ellipse(12,12,9,9,16,0);ellipse(12,12,4,9,16,0);line(3,12,21,12)
    elseif name == "link" then
        arc(7,12,4,7,45,315,12);arc(17,12,4,7,225,495,12);line(10,12,14,12)
    elseif name == "mail" then
        rect(3,6,18,12,true,2);path({{4,7},{12,13},{20,7}})
    elseif name == "message" then
        cubic({5,5},{4,5},{4,6},{4,7},3);line(4,7,4,15)
        cubic({4,15},{4,16},{5,17},{6,17},3);line(6,17,8,17);line(8,17,8,20);line(8,20,12,17)
        line(12,17,18,17);cubic({18,17},{19,17},{20,16},{20,15},3);line(20,15,20,7)
        cubic({20,7},{20,6},{19,5},{18,5},3);line(18,5,5,5);line(8,10,16,10);line(8,13,14,13)
    elseif name == "terminal" then
        rect(3,4,18,16,true,2);path({{7,9},{10,12},{7,15}});line(13,15,17,15)
    elseif name == "bug" then
        circle(12,13,10,true);circle(12,6,5,true);line(12,3,12,2);line(8,11,5,9);line(16,11,19,9)
        line(7,14,4,14);line(17,14,20,14);line(8,17,6,19);line(16,17,18,19)
    elseif name == "cpu" then
        rect(6,6,12,12,true,2);rect(9,9,6,6,true,1)
        for _, offset in ipairs({8,12,16}) do
            line(offset,3,offset,6);line(offset,18,offset,21)
            line(3,offset,6,offset);line(18,offset,21,offset)
        end
    elseif name == "server" then
        rect(4,4,16,7,true,2);rect(4,13,16,7,true,2)
        circle(7,7.5,2,false);circle(7,16.5,2,false);line(11,7.5,17,7.5);line(11,16.5,17,16.5)
    elseif name == "database" then
        ellipse(12,6,8,3,12,0);line(4,6,4,18);line(20,6,20,18)
        ellipse(12,18,8,3,12,0);arc(12,11,8,3,0,180,8)
    elseif name == "cloud" then
        cubic({6,18},{3,18},{3,15},{4,13},5);cubic({4,13},{4,10},{7,9},{9,10},5)
        cubic({9,10},{10,5},{15,4},{18,8},6);cubic({18,8},{21,8},{22,11},{20,14},5)
        cubic({20,14},{22,18},{19,19},{17,19},5);line(17,19,6,19);line(6,19,6,18)
    elseif name == "cloud-download" then
        cubic({6,12},{3,12},{3,9},{4,7},5);cubic({4,7},{4,4},{7,3},{9,4},5)
        cubic({9,4},{10,2.5},{15,2.5},{17,5},6);cubic({17,5},{21,5},{22,8},{20,11},5)
        cubic({20,11},{22,14},{19,15},{17,15},5);line(17,15,6,15);line(6,15,6,12)
        line(12,9,12,18);path({{8,15},{12,19},{16,15}})
    elseif name == "camera" then
        rect(3,7,18,13,true,2);path({{7,7},{9,4},{15,4},{17,7}})
        circle(13,13,7,true);circle(13,13,2,false);circle(18,9,1.6,false)
    elseif name == "image" then
        rect(3,4,18,16,true,2);circle(8,9,2.4,false);path({{5,18},{10,12},{13,15},{16,11},{20,17}})
    elseif name == "music" then
        line(10,6,10,17);line(10,6,18,4);line(18,4,18,15);circle(7,18,5,true);circle(15,16,5,true)
    elseif name == "volume" then
        path({{4,10},{8,10},{13,6},{13,18},{8,14},{4,14},{4,10}})
        arc(12,12,6,7,-55,55,5);arc(12,12,9,10,-55,55,6)
    elseif name == "volume-off" then
        path({{4,10},{8,10},{13,6},{13,18},{8,14},{4,14},{4,10}});line(16,9,21,15);line(21,9,16,15)
    elseif name == "sun" then
        circle(12,12,8,true)
        for _, angle in ipairs({0,45,90,135,180,225,270,315}) do
            local radians=math.rad(angle)
            line(12+math.cos(radians)*6.5,12+math.sin(radians)*6.5,12+math.cos(radians)*9,12+math.sin(radians)*9)
        end
    elseif name == "moon" then
        cubic({15,4},{7,4},{4,9},{5,14},8);cubic({5,14},{6,20},{13,21},{18,17},8)
        cubic({18,17},{13,17},{9,13},{9,9},7);cubic({9,9},{9,7},{11,5},{15,4},7)
    elseif name == "gamepad" then
        cubic({7,8},{4,8},{3,11},{3,15},5);cubic({3,15},{3,19},{6,20},{8,17},5)
        line(8,17,16,17);cubic({16,17},{18,20},{21,19},{21,15},5)
        cubic({21,15},{21,11},{20,8},{17,8},5);line(17,8,7,8)
        line(7,11,7,15);line(5,13,9,13);circle(16,12,2,false);circle(18,15,2,false)
    elseif name == "trophy" then
        path({{7,4},{17,4},{17,9},{16,14},{13,16},{11,16},{8,14},{7,9},{7,4}})
        cubic({7,6},{3,5},{3,12},{8,13},5);cubic({17,6},{21,5},{21,12},{16,13},5)
        line(12,16,12,19);line(8,20,16,20);line(9,18,15,18)
    elseif name == "rocket" then
        path({{12,3},{16,6},{18,11},{17,16},{12,19},{7,16},{6,11},{8,6},{12,3}})
        circle(12,9,4,true);path({{7,14},{4,17},{4,20},{9,17}});path({{17,14},{20,17},{20,20},{15,17}})
        path({{10,19},{12,21},{14,19}})
    elseif name == "backpack" then
        cubic({9,6},{9,2},{15,2},{15,6},8)
        rect(5,6,14,15,true,4)
        path({{5,9},{3,10},{3,18},{5,19}});path({{19,9},{21,10},{21,18},{19,19}})
        rect(8,13,8,5,true,1)
    elseif name == "sword" then
        path({{15,4},{19,8},{11,16},{8,13},{15,4}});line(8,13,5,16);line(5,15,9,19);line(8,20,12,16)
        line(12,10,16,14);line(13,9,17,13)
    elseif name == "flag" then
        line(5,3,5,20);path({{6,5},{20,7},{16,11},{20,15},{6,13},{6,5}})
    end
end

local builtinNames = {
    "home", "sliders", "palette", "save", "code", "search", "close", "check",
    "chevron-down", "chevron-right", "settings", "user", "folder", "download",
    "upload", "refresh", "bell", "info", "plus", "minus",
    "farm", "panel", "inventory", "harvest", "seed", "sprout", "watering-can",
    "shovel", "tools", "tractor", "map", "menu", "arrow-left", "arrow-right",
    "minimize", "maximize", "restore", "resize", "window",
    "automation", "play", "pause", "stop", "bolt", "shield", "key", "lock",
    "unlock", "coins", "gift", "teleport", "target", "chart", "chart-bar",
    "clock", "timer", "compass", "heart", "star", "eye", "eye-off", "filter",
    "sort", "check-circle", "alert", "help", "copy", "clipboard", "trash", "edit", "wand",
    "wifi", "globe", "link", "mail", "message", "terminal", "bug", "cpu", "server", "database",
    "cloud", "cloud-download", "camera", "image", "music", "volume", "volume-off", "sun", "moon",
    "gamepad", "trophy", "rocket", "backpack", "sword", "flag",
}
local iconVariants={"Outline","Soft","Duotone"}
Library._iconIds=Library._iconIds or {}
Library._iconNamesById=Library._iconNamesById or {}
Library._nextCustomIconId=math.max(Library._nextCustomIconId or 1000,1000)

local function bindIconId(name,id)
    local oldId=Library._iconIds[name]
    if oldId and Library._iconNamesById[oldId]==name then Library._iconNamesById[oldId]=nil end
    local oldName=Library._iconNamesById[id]
    if oldName and oldName~=name then Library._iconIds[oldName]=nil end
    Library._iconIds[name]=id
    Library._iconNamesById[id]=name
end

local builtinSet={}
for id,iconName in ipairs(builtinNames)do
    builtinSet[iconName]=true
    bindIconId(iconName,id)
end

for _, iconName in ipairs(builtinNames) do
    local registeredName = iconName
    Library._icons[registeredName] = function(root, color, thickness, window, token, variant)
        drawIcon(root, color, thickness, window, token, registeredName, variant)
    end
end

local unassignedCustomNames={}
local highestCustomId=999
for name,builder in pairs(Library._icons)do
    if not builtinSet[name] then
        local id=Library._iconIds[name]
        if type(id)=="number" and id%1==0 and id>=1000 and Library._iconNamesById[id]==name then
            highestCustomId=math.max(highestCustomId,id)
        else
            unassignedCustomNames[#unassignedCustomNames+1]=name
        end
    end
end
table.sort(unassignedCustomNames)
Library._nextCustomIconId=math.max(Library._nextCustomIconId,highestCustomId+1)
for _,name in ipairs(unassignedCustomNames)do
    bindIconId(name,Library._nextCustomIconId)
    Library._nextCustomIconId+=1
end

local function validIconName(name)
    return type(name) == "string"
        and #name > 0
        and #name <= 48
        and name:match("^[a-z][a-z0-9%-]*$") ~= nil
        and not name:find("--", 1, true)
        and name:sub(-1) ~= "-"
end

function Library:GetIconNames()
    local names = {}
    for name in pairs(self._icons) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function Library:GetIconId(name)
    if type(name)~="string" or type(self._icons[name])~="function" then return nil end
    local id=self._iconIds and self._iconIds[name]
    if type(id)=="number" and id%1==0 and self._iconNamesById[id]==name then return id end
    return nil
end

function Library:GetIconName(idOrName)
    if type(idOrName)=="string" then
        return type(self._icons[idOrName])=="function" and idOrName or nil
    end
    if type(idOrName)~="number" or idOrName~=idOrName or math.abs(idOrName)==math.huge or idOrName%1~=0 then return nil end
    local name=self._iconNamesById and self._iconNamesById[idOrName]
    if name and type(self._icons[name])=="function" and self._iconIds[name]==idOrName then return name end
    return nil
end

function Library:GetIconCatalogue()
    local catalogue={}
    for name,builder in pairs(self._icons)do
        local id=self:GetIconId(name)
        if type(builder)=="function" and id then catalogue[#catalogue+1]={Id=id,Name=name} end
    end
    table.sort(catalogue,function(a,b)return a.Id<b.Id end)
    return catalogue
end

function Library:GetIconVariants()
    return table.clone(iconVariants)
end

function Library:RegisterIcon(name, drawFunction)
    assert(validIconName(name), "Icon name must be lowercase kebab-case")
    assert(type(drawFunction) == "function", "Icon builder must be a function")
    assert(self._icons[name] == nil, "Icon name is already registered: " .. name)
    self._icons[name] = drawFunction
    bindIconId(name,self._nextCustomIconId)
    self._nextCustomIconId+=1
    return self
end

function Library:UnregisterIcon(name, expectedDraw)
    if not validIconName(name) then return false end
    local current = self._icons[name]
    if current == nil or (expectedDraw ~= nil and current ~= expectedDraw) then return false end
    self._icons[name] = nil
    local id=self._iconIds[name]
    self._iconIds[name]=nil
    if id and self._iconNamesById[id]==name then self._iconNamesById[id]=nil end
    return true
end

function Library:Icon(parent, name, options)
    assert(typeof(parent) == "Instance", "Icon parent must be an Instance")
    local iconName=self:GetIconName(name)
    assert(iconName,"Unknown icon ID or name: "..tostring(name))
    options = options or {}
    assert(type(options) == "table", "Icon options must be a table")
    local allowed = {Size=true, Color=true, Thickness=true, Name=true, Position=true, AnchorPoint=true, Window=true, Token=true, Variant=true, IconVariant=true}
    for key in pairs(options) do assert(allowed[key], "Unknown icon option: " .. tostring(key)) end
    assert(not (options.Variant~=nil and options.IconVariant~=nil),"Use Variant or IconVariant, not both")
    local builder = self._icons[iconName]
    local size = options.Size == nil and 20 or options.Size
    local thickness = options.Thickness == nil and 2 or options.Thickness
    local variant = options.IconVariant
    if variant == nil then variant = options.Variant end
    if variant == nil then variant = "Outline" end
    assert(type(size) == "number" and size == size and size >= 12 and size <= 64, "Icon Size must be 12..64")
    assert(type(thickness) == "number" and thickness == thickness and thickness >= 1 and thickness <= 4, "Icon Thickness must be 1..4")
    assert(variant == "Outline" or variant == "Soft" or variant == "Duotone", "Icon Variant must be Outline, Soft or Duotone")
    assert(options.Color == nil or typeof(options.Color) == "Color3", "Icon Color must be a Color3")
    assert(options.Name == nil or (type(options.Name) == "string" and #options.Name > 0), "Icon Name must be a non-empty string")
    assert(options.Position == nil or typeof(options.Position) == "UDim2", "Icon Position must be a UDim2")
    assert(options.AnchorPoint == nil or typeof(options.AnchorPoint) == "Vector2", "Icon AnchorPoint must be a Vector2")
    local window = options.Window
    if window ~= nil then
        assert(type(window) == "table" and window.BindColor and not window.Destroyed, "Icon Window must be a live Gabibou window")
        assert(parent:IsDescendantOf(window.Gui), "Icon parent must belong to Icon Window")
    end
    local token = options.Token or "Muted"
    if window and options.Color == nil then
        assert(type(token) == "string" and window.Theme[token] ~= nil and typeof(window.Theme[token]) == "Color3", "Unknown icon theme token: " .. tostring(token))
    else
        assert(options.Token == nil or (type(token) == "string" and #token > 0), "Icon Token must be a string")
    end
    local drawColor = options.Color or (window and window.Theme[token]) or Color3.fromRGB(157, 162, 173)

    local root = create("Frame", {
        Name = options.Name or (string.gsub(iconName, "%-", " ") .. "Icon"),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoLocalize = false,
        ClipsDescendants = false,
        Size = UDim2.fromOffset(size, size),
        Position = options.Position or UDim2.new(),
        AnchorPoint = options.AnchorPoint or Vector2.new(),
    }, parent)
    root:SetAttribute("GabibouIconVariant",variant)
    local ok, problem = pcall(builder, root, drawColor, thickness, window, token, variant)
    if ok and window and options.Color == nil then
        ok, problem = pcall(function()
            for _, instance in ipairs(root:GetDescendants()) do
                if instance:IsA("GuiObject") and instance.BackgroundTransparency < 1 then
                    window:BindColor(instance, "BackgroundColor3", token)
                elseif instance:IsA("UIStroke") then
                    window:BindColor(instance, "Color", token)
                end
            end
        end)
    end
    if not ok then
        if window and not window.Destroyed then window:_ForgetTree(root) end
        root:Destroy()
        error("Icon builder failed for '" .. iconName .. "': " .. tostring(problem), 2)
    end
    if window then
        local tracked = {root}
        for _, instance in ipairs(root:GetDescendants()) do tracked[#tracked + 1] = instance end
        local cleaned = false
        root.Destroying:Connect(function()
            if cleaned then return end
            cleaned = true
            for _, instance in ipairs(tracked) do
                window._themeTargets[instance] = nil
                window._styleTargets[instance] = nil
                window:_CancelAnimation(instance)
            end
            table.clear(tracked)
        end)
    end
    return root
end
