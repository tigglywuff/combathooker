
CombatHooker = {
    ["bars"] = {}
}
--[[
This object should contain all the actual bar groups, ex:
bars = {
    ["Interrupts"] = {
        -- This is a Frame object with some extra custom properties
        ["active_bars"] = { ... } -- An array of StatusBar Frames
    }
}
]]

-- These are the statusbar frames we can recycle
zombie_bars = {}

function CombatHooker:on_load()
    this:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    this:RegisterEvent("PLAYER_LOGIN")
end

function CombatHooker:on_event(timestamp, event, ...)
    if event == "PLAYER_LOGIN" then
        CombatHookerConfig = CombatHookerConfig or {}
        CombatHookerTimeTracker = CombatHookerTimeTracker or {}

        -- Create our empty BarGroups!
        local bar_groups = {"Interrupts", "Coolies"}
        for _,v in ipairs(bar_groups) do
            CombatHooker.bars[v] = create_bar_group(v).body
        end
        return
    end

    local eventType = select(2, ...) --timestamp, eventType, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags
    local sourceName = select(4, ...)
    local spellName = select(10, ...)

    local interrupts = {
        ["Counterspell"] = 24,
        ["Earth Shock"] = 6,
        ["Kick"] = 10,
        ["Pummel"] = 10,
        ["Shield Bash"] = 12,
    }

    local coolies = {
        ["Innervate"] = 360,
        ["Mana Tide Totem"] = 300,
        ["Fear Ward"] = 180,
    }

    -- if eventType=="SPELL_CAST_SUCCESS" and sourceName=="Lady Vashj" then
    --     DEFAULT_CHAT_FRAME:AddMessage(sourceName.." cast "..spellName)
    --     if spellName == "Persuasion" then
    --         CombatHooker:handle_spell_cast("Coolies", 30, sourceName, "Spell_Nature_UndyingStrength")
    --     end
    -- end

    if UnitInRaid(sourceName) or UnitInParty(sourceName) then
        if eventType=="SPELL_CAST_SUCCESS" then
            for spell,cd in pairs(interrupts) do
                if spellName == spell then
                    CombatHooker:handle_spell_cast("Interrupts", cd, sourceName, get_spell_icon(spell))
                end
            end

            for spell,cd in pairs(coolies) do
                if spellName == spell then
                    CombatHooker:handle_spell_cast("Coolies", cd, sourceName, get_spell_icon(spell))
                    if spellName == "Mana Tide Totem" then
                        PlaySoundFile("Interface\\AddOns\\CombatHooker\\sounds\\my-bubbles.mp3")
                    end
                end
            end
        end
    end

    if sourceName=="Ballgag" and eventType=="SWING_DAMAGE" then
        -- PlaySoundFile("Interface\\AddOns\\CombatHooker\\sounds\\coin.mp3")
    end
end

function CombatHooker:handle_spell_cast(category, cooldown, name, icon)
    local StatusBar = make_bar(self.bars[category], cooldown, name, icon, zombie_bars)
    local duration = cooldown
    StatusBar:SetScript("OnUpdate", function(self, elapsed)
        if self.active then
            duration = duration - elapsed
            if duration > 0 then
                -- Update the text displaying time remaining
                self:SetValue(duration)
                self.value:SetText(self.name.." "..math.ceil(duration))

                -- Update this bar's positioning within the group
                for i,statusbar in ipairs(self:GetParent().active_bars) do
                    if (statusbar.id == self.id) then
                        self:SetPoint("TOPLEFT", self:GetParent(),"TOPLEFT", 0, -30*(i-1))
                    end
                end
            else
                self.active = false
                self:Hide()
                table.insert(zombie_bars, self)
            end
        end
    end)
end

--[[
SLASH COMMAND STUFF
]]

local function ch_print(msg)
    msg = tostring(msg)
    DEFAULT_CHAT_FRAME:AddMessage('\124cFFEB9560[ch] '..'\124cFFFFFFFF'..msg)
end

function CombatHooker.show()
    for _,v in pairs(CombatHooker.bars) do
        v:GetParent():Show()
    end
end

function CombatHooker.hide()
    for _,v in pairs(CombatHooker.bars) do
        v:GetParent():Hide()
    end
end

function CombatHooker.reset()
    for _,v in pairs(CombatHooker.bars) do
        v:GetParent():SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

CombatHooker.commands = {
    hide = CombatHooker.hide,
    show = CombatHooker.show,
    reset = CombatHooker.reset,
}

SLASH_COMBATHOOKER1 = "/ch"
SLASH_COMBATHOOKER2 = "/combathooker"
SlashCmdList["COMBATHOOKER"] = function(msg)
    local _, _, cmd = string.find(msg, "%s?(%w+)%s?(.*)")
    if CombatHooker.commands[cmd] then
        CombatHooker.commands[cmd]()
    else
        ch_print("CombatHooker usage /ch hide | show")
    end
end