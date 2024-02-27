local _, ns = ...

local AddOn = ns.AddOn
local module = {
    elected = false,
}
AddOn.modules.election = module

function module:Initialize()

    local SEPARATOR = ":"
    local inscriptions = {}

    -- functions

    local function IsInInscriptions(guid)

        for _, inscription in ipairs(inscriptions) do
            if guid == inscription.Guid then
                return true
            end
        end

        return false
    end

    local function GetProfile()

        local weight = UnitHealthMax("player")

        return AddOn.VERSION
                .. SEPARATOR .. weight
                .. SEPARATOR .. UnitGUID("player")
    end

    local function DoElection()

        local winner

        for _, inscription in ipairs(inscriptions) do
            if winner == nil then
                winner = inscription
            elseif winner.Weight < inscription.Weight then
                winner = inscription
            elseif winner.Weight == inscription.Weight and winner.Guid < inscription.Guid then
                winner = inscription
            end
        end

        module.elected = (winner or false) and winner.Guid == UnitGUID("player")

        --AddOn:Print('elected: ' .. tostring(module.elected))
    end

    local function OnUpdate(frame, elapsed)

        frame.elapsed = (frame.elapsed or 0) + elapsed
        if frame.elapsed < AddOn.ELECTION_DELAY then
            return
        end

        frame.elapsed = 0

        if frame.electionPhase then
            DoElection()
            inscriptions = {}
        else
            C_ChatInfo.SendAddonMessage(AddOn.ADDON_MESSAGE_PREFIX_ELECTION, GetProfile(), "RAID")
        end

        frame.electionPhase = not (frame.electionPhase or false)
    end

    local function OnInscription(message)

        local version, tmp = ns.cut(message, SEPARATOR)

        version = tonumber(version)
        AddOn:OnClientHello(version)

        if math.floor(AddOn.VERSION / 10000) > math.floor(version / 10000) then
            return
        end

        local weight, guid = ns.cut(tmp, SEPARATOR)

        if IsInInscriptions(guid) == true then
            return
        end

        table.insert(inscriptions, {
            Weight = tonumber(weight),
            Guid = guid,
        })
    end

    -- frame

    local frame = CreateFrame("Frame")
    frame:SetScript("OnEvent", function(self, event, ...)
        if self[event] then
            return self[event](self, ...)
        end
    end)

    -- event

    function frame:PLAYER_REGEN_DISABLED()
        -- election only in combat
        self:SetScript("OnUpdate", OnUpdate)
    end

    function frame:PLAYER_REGEN_ENABLED()
        self:SetScript("OnUpdate", nil)
        module.elected = false
    end

    function frame:CHAT_MSG_ADDON(prefix, message)
        if prefix == AddOn.ADDON_MESSAGE_PREFIX_ELECTION then
            OnInscription(message)
        end
    end

    --

    function self:Enable()

        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:RegisterEvent("CHAT_MSG_ADDON")
    end

    function self:Disable()

        frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
        frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        frame:UnregisterEvent("CHAT_MSG_ADDON")

        frame:SetScript("OnUpdate", nil)
    end
end
