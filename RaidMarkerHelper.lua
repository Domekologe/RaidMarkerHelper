local addonName = ...
RaidMarkerHelperDB = RaidMarkerHelperDB or {}

-- Save frame position
local function SavePosition(frame)
    local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
    RaidMarkerHelperDB.pos = { point = point, relativePoint = relativePoint, x = xOfs, y = yOfs }
end

-- Restore frame position
local function RestorePosition(frame)
    local pos = RaidMarkerHelperDB.pos
    if pos then
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        frame:SetPoint("CENTER")
    end
end

-- Main frame
local markerFrame = CreateFrame("Frame", "RaidMarkerHelperFrame", UIParent, "BackdropTemplate")
markerFrame:SetSize(240, 64)
markerFrame:SetMovable(true)
markerFrame:EnableMouse(false) -- Only header is mouse-enabled
markerFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
markerFrame:SetBackdropColor(0, 0, 0, 0.6)
markerFrame:Hide()

-- Blizzard-style 3-part header
local headerLeft = markerFrame:CreateTexture(nil, "ARTWORK")
headerLeft:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header-Left")
headerLeft:SetSize(32, 32)
headerLeft:SetPoint("TOP", markerFrame, "TOP", -106, 7) -- angepasst

local headerCenter = markerFrame:CreateTexture(nil, "ARTWORK")
headerCenter:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
headerCenter:SetSize(180, 32)
headerCenter:SetPoint("LEFT", headerLeft, "RIGHT")

local headerRight = markerFrame:CreateTexture(nil, "ARTWORK")
headerRight:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header-Right")
headerRight:SetSize(32, 32)
headerRight:SetPoint("LEFT", headerCenter, "RIGHT")

-- Title text
local headerText = markerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
headerText:SetPoint("TOP", markerFrame, "TOP", 0, 2)
headerText:SetText("Marker")

-- Enable dragging via header
local function EnableDrag(target)
    target:EnableMouse(true)
    target:RegisterForDrag("LeftButton")
    target:SetScript("OnDragStart", function()
        markerFrame:StartMoving()
    end)
    target:SetScript("OnDragStop", function()
        markerFrame:StopMovingOrSizing()
        SavePosition(markerFrame)
    end)
end

-- Invisible drag frame on top of header
local dragHeader = CreateFrame("Frame", nil, markerFrame)
dragHeader:SetSize(244, 32)
dragHeader:SetPoint("TOP", markerFrame, "TOP", 0, 8)
dragHeader:EnableMouse(true)
dragHeader:RegisterForDrag("LeftButton")
dragHeader:SetScript("OnDragStart", function()
    markerFrame:StartMoving()
end)
dragHeader:SetScript("OnDragStop", function()
    markerFrame:StopMovingOrSizing()
    SavePosition(markerFrame)
end)


-- Marker icons
local markerIcons = {
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
    "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
}

for i = 1, 8 do
    local button = CreateFrame("Button", nil, markerFrame)
    button:SetSize(24, 24)
    button:SetPoint("TOPLEFT", (i - 1) * 28 + 10, -26)

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local texture = button:CreateTexture(nil, "BACKGROUND")
    texture:SetAllPoints()
    texture:SetTexture(markerIcons[i])

    button:SetScript("OnClick", function(self, mouseButton)
        if not UnitExists("target") then
            print("No target selected.")
            return
        end

        if mouseButton == "LeftButton" then
            SetRaidTarget("target", i)
        elseif mouseButton == "RightButton" then
            SetRaidTarget("target", 0)
        end
    end)
end


-- Show/hide frame depending on group status
local function UpdateFrameVisibility()
    if IsInGroup() or IsInRaid() then
        markerFrame:Show()
    else
        markerFrame:Hide()
    end
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        C_Timer.After(0.1, function()
            RestorePosition(markerFrame)
            UpdateFrameVisibility()
        end)
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        UpdateFrameVisibility()
    end
end)

-- Slash command: /rmh
SLASH_RMH1 = "/rmh"
SlashCmdList["RMH"] = function(msg)
    msg = msg:lower()
    if msg == "show" then
        markerFrame:Show()
        print("|cffffcc00[RaidMarkerHelper]|r Frame is now shown.")
    elseif msg == "hide" then
        markerFrame:Hide()
        print("|cffffcc00[RaidMarkerHelper]|r Frame is now hidden.")
    else
        print("|cffffcc00RaidMarkerHelper Commands:|r")
        print("/rmh show - Show the frame for repositioning")
        print("/rmh hide - Hide the frame again")
    end
end

-- === Minimap Icon ===
local LDB = LibStub("LibDataBroker-1.1"):NewDataObject("RaidMarkerHelper", {
    type = "launcher",
    icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
    OnClick = function(_, button)
        if button == "RightButton" then
            markerFrame:Hide()
            print("|cffffcc00[RaidMarkerHelper]|r Frame hidden.")
        else
            if markerFrame:IsShown() then
                markerFrame:Hide()
                print("|cffffcc00[RaidMarkerHelper]|r Frame hidden.")
            else
                markerFrame:Show()
                print("|cffffcc00[RaidMarkerHelper]|r Frame shown.")
            end
        end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("RaidMarkerHelper")
        tooltip:AddLine("Left-Click: Toggle Marker Frame", 1, 1, 1)
        tooltip:AddLine("Right-Click: Hide Marker Frame", 1, 1, 1)
    end,
})

local icon = LibStub("LibDBIcon-1.0")
icon:Register("RaidMarkerHelper", LDB, RaidMarkerHelperDB.minimap or {})
