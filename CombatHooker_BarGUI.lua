local function class_colors(class)
    rgb_map = {
        ["Druid"] =     {1,0.49,0.04},
        ["Mage"] =      {0.25,0.78,0.92},
        ["Rogue"] =     {1,0.96,0.41},
        ["Shaman"] =    {0,0.44,0.87},
        ["Warrior"] =   {0.78,0.61,0.43},
        ["Priest"] = {1,1,1,0.5},
    }
    return rgb_map[class][1], rgb_map[class][2], rgb_map[class][3]
end

local function get_point(group_name)
    -- Checks if this bar group has a saved location, else put it in the middle
    -- returns point, relative point, x, y

    if CombatHookerConfig[group_name] then
        return CombatHookerConfig[group_name]["point"],
               CombatHookerConfig[group_name]["relativePoint"],
               CombatHookerConfig[group_name]["x"],
               CombatHookerConfig[group_name]["y"]
    end
    return "CENTER", "CENTER", 0, 0
end

function create_bar_group(name)
    -- Creates a bar group with the specified name
    -- returns a frame

    -- title area, draggable
    frame = CreateFrame("Frame", nil, UIParent)
    frame:SetWidth(200)
    frame:SetHeight(15)
    local point, relativePoint, x, y = get_point(name)
    frame:SetPoint(point, UIParent, relativePoint, x, y)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self) 
        self:StopMovingOrSizing() 
        local point,_,relativePoint,x,y = self:GetPoint()
        CombatHookerConfig[name] = {
            ["point"]=point,
            ["relativePoint"]=relativePoint,
            ["x"]=x,
            ["y"]=y
        }       
    end)

    -- actual title text
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
    frame.title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    frame.title:SetTextColor(1, 1, 1)
    frame.title:SetText(name)

    -- body that will house the bars
    frame.body = CreateFrame("Frame", nil, frame)
    frame.body:SetWidth(200)
    frame.body:SetHeight(30)
    frame.body:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0)
    -- added a background to help troubleshoot
    -- frame.body:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 16})
    -- frame.body:SetBackdropColor(0,0,0,0.5)

    frame.body.active_bars = {}
    frame.body:SetScript("OnUpdate", function(self, elapsed)
        -- delete inactive bars
        for i,v in ipairs(self.active_bars) do
            if not v.active then
                table.remove(self.active_bars, i)
            end
        end

        -- todo: re-arrange the bars by duration here

        -- update the height accordingly
        self:SetHeight(30*#self.active_bars + 10)
    end)

    frame:Show()
    return frame
end

local next_bar_id = 1
function make_bar(parent, max, name, icon, zombies)
    --[[
    Recycles zombie bars if any, otherwise makes a new StatusBar frame for the given parent Frame.
    ]]
    local statusbar = nil
    zombies = zombies or {}
    if #zombies > 0 then
        statusbar = table.remove(zombies)
        statusbar:SetParent(parent)
    else
        statusbar = CreateFrame("StatusBar", nil, parent)
        statusbar.id = next_bar_id
        next_bar_id = next_bar_id + 1

        statusbar:SetWidth(200)
        statusbar:SetHeight(30)
        statusbar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")

        statusbar.bg = statusbar:CreateTexture(nil, "BACKGROUND")
        statusbar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
        statusbar.bg:SetAllPoints(true)

        statusbar.value = statusbar:CreateFontString(nil, "OVERLAY")
        statusbar.value:SetPoint("LEFT", statusbar, "LEFT", 4, 0)
        statusbar.value:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
        statusbar.value:SetJustifyH("LEFT")
        statusbar.value:SetShadowOffset(1, -1)
        statusbar.value:SetTextColor(1, 1, 1)

        statusbar.icon = CreateFrame("Frame", nil, statusbar)
        statusbar.icon:SetWidth(30)
        statusbar.icon:SetHeight(30)
        statusbar.icon:SetPoint("RIGHT", statusbar, "LEFT", -5, 0)
        statusbar.icon.texture = statusbar.icon:CreateTexture(nil, "BACKGROUND")
        statusbar.icon.texture:SetAllPoints(statusbar.icon)
    end
    update_bar(statusbar, max, name, icon)

    statusbar:Show()
    return statusbar
end

function update_bar(statusbar, max, name, icon)
    local parent = statusbar:GetParent()
    local r,g,b = class_colors(UnitClass(name))


    statusbar:SetPoint("TOPLEFT", nil,"TOPLEFT", 0, -30*#parent["active_bars"])
    statusbar:SetStatusBarColor(r, g, b)

    statusbar.name = name
    statusbar.active = true
    statusbar.bg:SetVertexColor(r/3, g/3, b/3)
    
    statusbar:SetMinMaxValues(0,max)
    statusbar:SetValue(max)

    statusbar.value:SetText(name.." "..max)

    statusbar.icon.texture:SetTexture(icon)

    table.insert(parent.active_bars, statusbar)
    parent:SetHeight(30*#parent.active_bars)
end