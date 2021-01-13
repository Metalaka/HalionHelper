local mod = _G.HalionHelper

mod.modules.CollectLogPhase3 = {
    enable = false,
    amount = {
        [40142] = 0, -- shadow
        [39863] = 0, -- light
    },
    isFirstCorporeality = true,
    side = {
        npcId = nil,
        corporeality = nil,
    },
}

function mod.modules.CollectLogPhase3:Initialize()

    function self:Enable()

        self:CreateTimer()
        self:CreateCorporealityBar()

        self.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        --        self.frame:RegisterEvent("UPDATE_WORLD_STATES")
        self.frame:RegisterEvent("CHAT_MSG_ADDON")
    end

    function self:Disable()
    end

    --

    local _self = mod.modules.CollectLogPhase3



    local buffs = {
        [74836] = { done = 0, taken = 0, }, --  70% less dealt, 100% less taken
        [74835] = { done = 0, taken = 0, }, --  50% less dealt,  80% less taken
        [74834] = { done = 0, taken = 0, }, --  30% less dealt,  50% less taken
        [74833] = { done = 0, taken = 0, }, --  20% less dealt,  30% less taken
        [74832] = { done = 0, taken = 0, }, --  10% less dealt,  15% less taken
        [74826] = { done = 0, taken = 0, }, --  normal
        [74827] = { done = 0, taken = 0, }, --  15% more dealt,  20% more taken
        [74828] = { done = 0, taken = 0, }, --  30% more dealt,  50% more taken
        [74829] = { done = 0, taken = 0, }, --  60% more dealt, 100% more taken
        [74830] = { done = 0, taken = 0, }, -- 100% more dealt, 200% more taken
        [74831] = { done = 0, taken = 0, }, -- 200% more dealt, 400% more taken
    }

    function self:SwingDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
        self:AddDamageData(dstGUID, amount)
    end

    function self:SpellDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
        self:AddDamageData(dstGUID, amount)
    end

    function self:EnvironmentalDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, enviromentalType, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
        self:AddDamageData(dstGUID, amount)
    end

    function self:SpellAuraAppliedRemoved(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType)

        local buff = buffs[spellId]

        if buff then

            self.side.npcId = tonumber(dstGUID:sub(-12, -7), 16)
            self.side.corporeality = buff

            --            DEFAULT_CHAT_FRAME:AddMessage(eventtype .. ": " .. spellId)
            --            DEFAULT_CHAT_FRAME:AddMessage(srcGUID .. ": " .. dstGUID)

            if self.isFirstCorporeality then
                self.isFirstCorporeality = false
                self.enable = true
                self.timer:StartTimer(5) -- display 5sec wait timer
                mod:ScheduleTimer(function() _self:StartMonitor() end, 5)
            else
                self:StartMonitor()
            end
        end
    end

    function self:AddDamageData(dstGUID, amount)

        local npcId = tonumber(dstGUID:sub(-12, -7), 16)

        self.amount[npcId] = self.amount[npcId] + amount
    end

    local EventParse =
    {
        ["SWING_DAMAGE"] = self.SwingDamage,
        ["RANGE_DAMAGE"] = self.SpellDamage,
        ["SPELL_DAMAGE"] = self.SpellDamage,
        ["SPELL_PERIODIC_DAMAGE"] = self.SpellDamage,
        ["DAMAGE_SHIELD"] = self.SpellDamage,
        ["DAMAGE_SPLIT"] = self.SpellDamage,
        ["ENVIRONMENTAL_DAMAGE"] = self.EnvironmentalDamage,
        ["SPELL_AURA_APPLIED"] = self.SpellAuraAppliedRemoved,
    }
    function self:CombatLogEvent(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, ...)

        if dstName ~= mod.BOSS_NAME then
            return
        end
        if not self.enable and not (eventtype == "SPELL_AURA_APPLIED" and srcGUID == dstGUID) then
            return
        end

        local parsefunc = EventParse[eventtype]

        if parsefunc then
            parsefunc(self, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, ...)
        end
    end

    self.frame = CreateFrame("Frame", "HalionHelper_CollectLogPhase3")
    self.frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, ...) end end)

    -- init
    function self.frame:COMBAT_LOG_EVENT_UNFILTERED(...)
        _self:CombatLogEvent(...)
    end

    function self:StartMonitor()
        self.amount[self.side.npcId] = 0
        self.timer:StartTimer(15)
        self.CorporealityBar:Show()
    end

    self.frame:SetScript("OnUpdate", function(frame, elapsed)

        if not _self.enable or not _self.side.npcId then
            return
        end

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed > mod.SLEEP_DELAY then
            frame.elapsed = 0

            --                frame:SetScript("OnUpdate", nil)

            -- send addonmsg
            local payload = _self.side.npcId .. ":" .. _self.amount[_self.side.npcId]
            SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P3, payload, "RAID")
        end
    end)

    function self.frame:CHAT_MSG_ADDON(prefix, message)
        if not _self.enable or not _self.side.npcId then
            return
        end

        if (prefix == mod.ADDON_MESSAGE_PREFIX_P3) then
            local npcId, amount = cut(message, ":")
            npcId = tonumber(npcId)

            if _self.side.npcId == npcId then
                return
            end

            _self.amount[npcId] = tonumber(amount)
        end
    end


    --[[local CORPOREALITY = GetSpellInfo(74826)



    function self:GetCorporeality()

        if UnitExists("boss1") and UnitAura("boss1", CORPOREALITY) then
            return UnitAura("boss1", CORPOREALITY)
        end
        if UnitExists("boss2") and UnitAura("boss2", CORPOREALITY) then
            return UnitAura("boss2", CORPOREALITY)
        end

        return nil
    end]]


    function self:CreateTimer()

        self.timer = mod.modules.Bar:NewBar("HalionHelper_CollectLogPhase3_Timer")
        self.timer.expire = nil

        self.timer:SetScript("OnUpdate", function(self)
            local left = self.expire - GetTime()

            if (left < 0) then
                self:StopTimer()
            else
                self:SetValue(left)
            end
        end)

        function self.timer:StartTimer(time)
            self.expire = GetTime() + time
            self.StatusBar:SetMinMaxValues(0, time)
            self.StatusBar:SetValue(time)
            self:Show()
        end

        function self.timer:StopTimer()
            self.expire = nil
            self:Hide()
        end

        function self.timer:SetValue(left)
            self.StatusBar:SetValue(left)
            self.StatusBar.timeText:SetText(self:FormatTime(left) .. " sec")
        end

        function self.timer:FormatTime(left)
            if (not left or not type(left) == 'number' or left < 0) then left = 0 end
            if (left < 10) then
                return (string.format("%01.1f", left))
            elseif (left < 60) then
                return (string.format("%d", left))
            else
                return (string.format("%d:%02d", left / 60, left % 60))
            end
        end
    end

    function self:CreateCorporealityBar()

        function self:CalculPercent()
            local total = self.amount[40142] + self.amount[39863]

            return self.amount[39863] / max(total, 1)
        end

        -- shadow | light
        self.CorporealityBar = mod.modules.Bar:NewBar("HalionHelper_CollectLogPhase3_CorporealityBar")
        self.CorporealityBar.StatusBar:SetValue(0.5)

        self.CorporealityBar:SetScript("OnUpdate", function(frame, elapsed)

            frame.elapsed = (frame.elapsed or 0) + elapsed
            if frame.elapsed > mod.SLEEP_DELAY then
                frame.elapsed = 0

                _self.CorporealityBar:SetValue(_self:CalculPercent())
            end
        end)

        function self.CorporealityBar:SetValue(value)
            self.StatusBar:SetValue(value)
            self.StatusBar.timeText:SetText(string.format("%.1f", value * 100) .. " %")
        end
    end
end
