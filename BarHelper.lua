local mod = _G.HalionHelper

mod.modules.Bar = {
    texture = nil,
}

function mod.modules.Bar:Initialize()

    function self:Enable()
    end

    function self:Disable()
    end

--

    function self:DefineDefaultTexture()
        self.texture = "Interface\\Addons\\FlatStatusBar\\Textures\\statusbar\\Flat"

        local textureFrame = CreateFrame("Frame")
        textureFrame.texture = textureFrame:CreateTexture()

        if not textureFrame.texture:SetTexture("Interface\\Addons\\FlatStatusBar\\Textures\\statusbar\\Flat") then
            self.texture = "Interface\\TargetingFrame\\UI-StatusBar"
        end
    end
    -- Run it !
    self:DefineDefaultTexture()

    function self:NewBar(name, parent)

        local frame = CreateFrame("Frame", name, parent or UIParent)

        -- moves
--        frame:SetMovable(true)
--        frame:EnableMouse(true)
--        frame:RegisterForDrag("LeftButton")
--        frame:SetScript("OnDragStart", frame.StartMoving)
--        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

        -- todo get position from db
        frame:SetPoint("CENTER")
        frame:SetSize(200, 50)

        frame.StatusBar = CreateFrame("StatusBar", nil, frame)
        frame.StatusBar:SetHeight(20)
        frame.StatusBar:SetWidth(200)
        frame.StatusBar:SetPoint("LEFT")
        frame.StatusBar:SetStatusBarTexture(self.texture)
        frame.StatusBar:GetStatusBarTexture():SetHorizTile(false)
        frame.StatusBar:GetStatusBarTexture():SetVertTile(false)
        frame.StatusBar:SetMinMaxValues(0, 1)

        frame.StatusBar.Background = frame.StatusBar:CreateTexture(nil, "BACKGROUND")
        frame.StatusBar.Background:SetTexture(self.texture)
        frame.StatusBar.Background:SetAllPoints()
        frame.StatusBar.Background:SetVertexColor(0, 0, 0, 0.33)

        frame.StatusBar.timeText = frame.StatusBar:CreateFontString(nil, "OVERLAY")
        frame.StatusBar.timeText:SetPoint("CENTER")
        frame.StatusBar.timeText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        frame.StatusBar.timeText:SetTextColor(1, 1, 1)

        frame:Hide()

        frame:SetScript("OnEvent",
            function(self, event, ...) if self[event] then return self[event](self, ...) end end)

        return frame
    end

end