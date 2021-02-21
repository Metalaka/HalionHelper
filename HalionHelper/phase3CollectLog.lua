local mod = _G.HalionHelper

mod.modules.phase3CollectLog = {
    enable = false,
    enableCollect = false,
    amount = {
        [mod.NPC_ID_HALION_PHYSICAL] = 0,
        [mod.NPC_ID_HALION_TWILIGHT] = 0,
    },
    isFirstCorporeality = true,
    shoudGoTwilight = nil,
    side = {
        npcId = nil,
        corporeality = nil,
    },
    --
    corporealityAuras = {
        [74836] = { dealt = -70, taken = -100, }, --  70% less dealt, 100% less taken
        [74835] = { dealt = -50, taken = -80, }, --  50% less dealt,  80% less taken
        [74834] = { dealt = -30, taken = -50, }, --  30% less dealt,  50% less taken
        [74833] = { dealt = -20, taken = -30, }, --  20% less dealt,  30% less taken
        [74832] = { dealt = -10, taken = -15, }, --  10% less dealt,  15% less taken
        [mod.CORPOREALITY_AURA] = { dealt = 1, taken = 1, }, --  normal
        [74827] = { dealt = 15, taken = 20, }, --  15% more dealt,  20% more taken
        [74828] = { dealt = 30, taken = 50, }, --  30% more dealt,  50% more taken
        [74829] = { dealt = 60, taken = 100, }, --  60% more dealt, 100% more taken
        [74830] = { dealt = 100, taken = 200, }, -- 100% more dealt, 200% more taken
        [74831] = { dealt = 200, taken = 400, }, -- 200% more dealt, 400% more taken
    },
    minDiff = 0.05,
    iconsSets = {
        ["REALM"] = {
            --            Twilight = 75486, -- Dusk Shroud
            twilight = 74807, -- Twilight Realm
            physical = 75949, -- Meteor Strike
        },
        ["SPELL"] = {
            twilight = 77846, -- Twilight Cutter
            physical = 75887, -- Blazing Aura
        },
    },
}

function mod.modules.phase3CollectLog:Initialize()

    function self:Enable()
        self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.frame:RegisterEvent("CHAT_MSG_ADDON")
        self.frame:RegisterEvent("RAID_ROSTER_UPDATE")
        self.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

        self:ManageCollectActivation()
    end

    function self:Disable()
        self.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self.frame:UnregisterEvent("CHAT_MSG_ADDON")
        self.frame:UnregisterEvent("RAID_ROSTER_UPDATE")
        self.frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

        self:ManageCollectActivation()
        self.frame:PLAYER_REGEN_ENABLED() -- Hide UI
    end

    -- functions

    local _self = self
    self.dc, self.ui = {}, {}

    local function SendData(frame, elapsed)

        if not _self.enable or not _self.side.npcId or _self.amount[_self.side.npcId] == 0 then
            return
        end

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed > mod.SLEEP_DELAY then
            frame.elapsed = 0

            local payload = _self.side.npcId .. ":" .. _self.amount[_self.side.npcId]
            SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P3_DATA, payload, "RAID")
        end
    end

    function self:ManageCollectActivation()
        if not self.enableCollect and mod:IsRemarkablePlayer() then
            self.enableCollect = true

            self.frame:SetScript("OnUpdate", SendData)
        elseif self.enableCollect and not mod:IsRemarkablePlayer() then
            self.enableCollect = false

            self.frame:SetScript("OnUpdate", nil)
        end
    end

    function self.side:IsPhysical()
        return self.npcId == mod.NPC_ID_HALION_PHYSICAL
    end

    function self.side:IsTwilight()
        return self.npcId == mod.NPC_ID_HALION_TWILIGHT
    end

    function self:ShoudGoTwilight()
        local c = self.side.corporeality

        -- by default go Twilight
        if self.side:IsTwilight() and c.dealt >= 1 then
            return true
        elseif self.side:IsPhysical() and c.dealt <= 1 then
            return true
        else
            return false
        end
    end

    function self.dc:InitializeDataCollect()
        function self:SwingDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
            self:AddDamageData(dstGUID, amount)
        end

        function self:SpellDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
            self:AddDamageData(dstGUID, amount)
        end

        function self:EnvironmentalDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, enviromentalType, amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing)
            self:AddDamageData(dstGUID, amount)
        end

        function self:SpellAura(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, spellId, spellName, spellSchool, auraType)

            local aura = _self.corporealityAuras[spellId]

            if aura then

                _self.side.npcId = mod:GetNpcId(dstGUID)
                _self.side.corporeality = aura

                if _self.isFirstCorporeality then
                    _self.isFirstCorporeality = false

                    _self.ui.timer:StartTimer(5) -- display 5sec wait timer
                    mod:ScheduleTimer(function()
                        _self.enable = true
                        _self:StartMonitor()
                    end, 5)

                    if _self.enableCollect then
                        -- send transition event to Physical Realm
                        SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_P3_TRANSITION, nil, "RAID")
                    end
                else
                    _self:StartMonitor()
                end
            end
        end

        function self:AddDamageData(dstGUID, amount)

            local npcId = mod:GetNpcId(dstGUID)

            _self.amount[npcId] = _self.amount[npcId] + amount
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
            ["SPELL_AURA_APPLIED"] = self.SpellAura,
        }

        local function IsBossCastAura(eventtype, srcGUID, dstGUID)
            return eventtype == "SPELL_AURA_APPLIED" and srcGUID == dstGUID
        end

        function self:CombatLogEvent(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, ...)

            if dstName ~= mod.BOSS_NAME then
                return
            end

            if not _self.enable and not IsBossCastAura(eventtype, srcGUID, dstGUID) then
                return
            end

            local parsefunc = EventParse[eventtype]

            if parsefunc then
                parsefunc(self, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, ...)
            end
        end

        function _self.frame:COMBAT_LOG_EVENT_UNFILTERED(...)
            _self.dc:CombatLogEvent(...)
        end
    end

    function self.ui:InitializeUI()

        function self:CalculatePercent()
            local total = _self.amount[mod.NPC_ID_HALION_TWILIGHT] + _self.amount[mod.NPC_ID_HALION_PHYSICAL]

            return _self.amount[mod.NPC_ID_HALION_PHYSICAL] / mod:max(total, 1)
        end

        local uiFrame = CreateFrame("Frame", "HalionHelper_phase3CollectLog_uiFrame", UIParent)
        self.uiFrame = uiFrame
        uiFrame:SetPoint(mod.db.profile.ui.point, mod.db.profile.ui.x, mod.db.profile.ui.y)
        --        uiFrame:SetPoint("CENTER")
        uiFrame:SetSize(170 + 60, 30)

        uiFrame.twilightIcon = CreateFrame("Button", nil, uiFrame)
        uiFrame.twilightIcon:SetHeight(30)
        uiFrame.twilightIcon:SetWidth(30)
        uiFrame.twilightIcon:SetPoint("LEFT")
        mod.modules.bar:SetIcon(uiFrame.twilightIcon, _self.iconsSets[mod.db.profile.iconsSet].twilight)
        uiFrame.twilightIcon:EnableMouse(false)

        uiFrame.physicalIcon = CreateFrame("Button", nil, uiFrame)
        uiFrame.physicalIcon:SetHeight(30)
        uiFrame.physicalIcon:SetWidth(30)
        uiFrame.physicalIcon:SetPoint("RIGHT")
        mod.modules.bar:SetIcon(uiFrame.physicalIcon, _self.iconsSets[mod.db.profile.iconsSet].physical)
        uiFrame.physicalIcon:EnableMouse(false)

        uiFrame:Hide()

        function self:InitializeCorporealityBar()

            self.corporealityBar = mod.modules.bar:NewBar("HalionHelper_phase3CollectLog_corporealityBar", self.uiFrame)
            self.corporealityBar:SetPoint("TOP")
            self.corporealityBar:SetHeight(25)
            self.corporealityBar:SetValue(1)

            self.corporealityBar.startDelay = 0

            self.corporealityBar:SetScript("OnUpdate", function(frame, elapsed)

                frame.elapsed = (frame.elapsed or 0) + elapsed
                if frame.elapsed > mod.SLEEP_DELAY and frame.elapsed > frame.startDelay then
                    frame.elapsed = 0
                    frame.startDelay = 0

                    _self.ui:UpdateCorporealityBar()
                end
            end)

            function self:UpdateCorporealityBar()

                local percent, text = self:CalculatePercent(), ""

                -- orange (1, 0.6, 0.05)
                if (_self.shoudGoTwilight and percent < (0.5 - _self.minDiff)) or (not _self.shoudGoTwilight and percent > (0.5 + _self.minDiff)) then
                    self.corporealityBar:SetStatusBarColor(0, 1, 0)
                    -- go
                elseif _self.shoudGoTwilight then
                    if _self.side:IsPhysical() then
                        self.corporealityBar:SetStatusBarColor(1, 0, 0)
                        -- stop
                    else
                        self.corporealityBar:SetStatusBarColor(1, 0.95, 0)
                        -- gogogo
                    end
                else
                    if _self.side:IsTwilight() then
                        self.corporealityBar:SetStatusBarColor(1, 0, 0)
                        -- stop
                    else
                        self.corporealityBar:SetStatusBarColor(1, 0.95, 0)
                        -- gogogo
                    end
                end

                local p, t = _self.amount[mod.NPC_ID_HALION_PHYSICAL], _self.amount[mod.NPC_ID_HALION_TWILIGHT]
                if _self.side:IsPhysical() then
                    text = math.floor((p - t) / 1000)
                else
                    text = math.floor((t - p) / 1000)
                end

                self.corporealityBar.timeText:SetText(text .. " K")
            end
        end

        function self:InitializeTimer()

            self.timer = mod.modules.bar:NewBar("HalionHelper_phase3CollectLog_Timer", self.uiFrame)
            self.timer:SetPoint("BOTTOM")
            self.timer:SetHeight(5)
            self.timer.expire = nil

            self.timer:SetScript("OnUpdate", function(self)
                local left = self.expire - GetTime()

                if (left < 0) then
                    self.expire = 0
                else
                    self:SetValue(left)
                end
            end)

            function self.timer:StartTimer(time)
                self.expire = GetTime() + time
                self:SetMinMaxValues(0, time)
                self:SetValue(time)

                if not _self.ui.uiFrame:IsShown() then
                    _self.ui.uiFrame:Show()
                end
            end

            function self.timer:StopTimer()
                self.expire = nil
                _self.ui.uiFrame:Hide()
            end
        end

        self:InitializeCorporealityBar()
        self:InitializeTimer()
    end

    function self:StartMonitor()
        self.amount[mod.NPC_ID_HALION_PHYSICAL] = 0
        self.amount[mod.NPC_ID_HALION_TWILIGHT] = 0
        self.ui.timer:StartTimer(15)
        self.ui.corporealityBar.startDelay = 0.5

        self.shoudGoTwilight = self:ShoudGoTwilight()
    end

    self.frame = CreateFrame("Frame", "HalionHelper_phase3CollectLog")
    self.frame:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, ...) end end)

    function self.frame:CHAT_MSG_ADDON(prefix, message)

        if _self.isFirstCorporeality and prefix == mod.ADDON_MESSAGE_PREFIX_P3_TRANSITION and not mod:IsInTwilightRealm() then
            -- Boss in Physical Realm start P3 without a Corporeality aura.
            -- This hack start the P3 from the Twilight event

            _self.isFirstCorporeality = false
            if mod:IsInTwilightRealm() then
                -- should never happen
                _self.side.npcId = mod.NPC_ID_HALION_TWILIGHT
            else
                _self.side.npcId = mod.NPC_ID_HALION_PHYSICAL
            end
            _self.side.corporeality = _self.corporealityAuras[mod.CORPOREALITY_AURA]

            _self.ui.timer:StartTimer(5) -- display 5sec wait timer
            mod:ScheduleTimer(function()
                _self.enable = true
                _self:StartMonitor()
            end, 5)

        elseif _self.enable and prefix == mod.ADDON_MESSAGE_PREFIX_P3_DATA then
            local npcId, amount = mod:cut(message, ":")
            npcId = tonumber(npcId)

            if _self.side.npcId == npcId then
                -- don't change our data
                return
            end

            _self.amount[npcId] = tonumber(amount)
        end
    end

    function self.frame:PLAYER_REGEN_ENABLED()

        _self.enable = false
        _self.isFirstCorporeality = true

        _self.ui.timer:StopTimer()
    end

    function self.frame:RAID_ROSTER_UPDATE()
        _self:ManageCollectActivation()
    end

    -- init

    self.dc:InitializeDataCollect()
    self.ui:InitializeUI()
end
