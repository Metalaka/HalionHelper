local mod = _G.HalionHelper

mod.modules.election = {
    inscriptions = {},
    elected = false,
}

function mod.modules.election:Initialize()

    function self:Enable()

        self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        self.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        self.frame:RegisterEvent("CHAT_MSG_ADDON")
    end

    function self:Disable()

        self.frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
        self.frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self.frame:UnregisterEvent("CHAT_MSG_ADDON")

        self.frame:SetScript("OnUpdate", nil)
    end

    -- functions

    local _self = self
    local separator = ":"

    local function IsInInscriptions(guid)

        for _, inscription in ipairs(_self.inscriptions) do
            if guid == inscription.Guid then
                return true
            end
        end

        return false
    end

    local function GetProfile()

        local weight = UnitHealthMax("player")

        return mod.MINOR_VERSION
                .. separator .. tostring(mod:IsInTwilightRealm())
                .. separator .. weight
                .. separator .. UnitGUID("player")
    end

    local function DoElection()

        local isInTwilightRealm = mod:IsInTwilightRealm()
        local winner = nil

        for _, inscription in ipairs(_self.inscriptions) do
            if isInTwilightRealm == inscription.IsInTwilightRealm then
                if winner == nil then
                    winner = inscription
                elseif winner.Weight < inscription.Weight then
                    winner = inscription
                elseif winner.Weight == inscription.Weight and winner.Guid < inscription.Guid then
                    winner = inscription
                end
            end
        end

        _self.elected = (winner or false) and winner.Guid == UnitGUID("player")

        --mod:Print('elected: ' .. tostring(_self.elected))
    end

    local function OnUpdate(frame, elapsed)

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed < mod.ELECTION_DELAY then
            return
        end

        frame.elapsed = 0

        if frame.electionPhase then
            DoElection()
            _self.inscriptions = {}
        else
            SendAddonMessage(mod.ADDON_MESSAGE_PREFIX_ELECTION, GetProfile(), "RAID")
        end

        frame.electionPhase = not (frame.electionPhase or false)
    end

    local function OnInscription(message)

        local version, tmp = mod:cut(message, separator)

        version = tonumber(version)
        if mod.versionMax < version then
            mod:OnClientHello(version)
            -- Disable addon
            return
        end

        if mod.versionMax > version then
            return
        end

        local isInTwilightRealm, tmp2 = mod:cut(tmp, separator)
        local weight, guid = mod:cut(tmp2, separator)

        if IsInInscriptions(guid) == true then
            return
        end

        table.insert(_self.inscriptions, {
            IsInTwilightRealm = isInTwilightRealm == "true",
            Weight = tonumber(weight),
            Guid = guid,
        })
    end

    -- frame

    self.frame = CreateFrame("Frame")
    self.frame:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            return self[event](self, ...)
        end
    end)

    -- event

    function self.frame:PLAYER_REGEN_DISABLED()
        self:SetScript("OnUpdate", OnUpdate)
    end

    function self.frame:PLAYER_REGEN_ENABLED()
        self:SetScript("OnUpdate", nil)
    end

    function self.frame:CHAT_MSG_ADDON(prefix, message)
        if prefix == mod.ADDON_MESSAGE_PREFIX_ELECTION then
            OnInscription(message)
        end
    end
end
