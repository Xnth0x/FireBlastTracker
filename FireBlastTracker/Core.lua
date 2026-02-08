-- Configuration
local FIRE_BLAST_ID = 108853
local _, playerClass = UnitClass("player")

-- Only initialize for Mages
if playerClass ~= "MAGE" then return end

local frame = CreateFrame("Frame", "FireBlastTrackerFrame", UIParent)
frame:SetSize(110, 20)
frame:SetPoint("CENTER", 0, -100)

local bars = {}

-- Create 3 status bars
for i = 1, 3 do
    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetSize(34, 12)
    
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(true)
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
    
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(1, 0.5, 0)
    
    if i == 1 then
        bar:SetPoint("LEFT", frame, "LEFT", 0, 0)
    else
        bar:SetPoint("LEFT", bars[i-1], "RIGHT", 4, 0)
    end
    
    bars[i] = bar
end

-- Update logic
local function UpdateFireBlast()
    -- Get current charges safely
    local current = C_Spell.GetSpellCastCount(FIRE_BLAST_ID)
    
    -- Get cooldown data safely
    local chargeInfo = C_Spell.GetSpellCharges(FIRE_BLAST_ID)
    
    -- GATEKEEPER: If any data is "secret" or nil, stop here to avoid crash
    if current == nil or chargeInfo == nil or type(chargeInfo.currentCharges) ~= "number" then 
        return 
    end

    local start = chargeInfo.cooldownStartTime or 0
    local duration = chargeInfo.cooldownDuration or 0

    for i = 1, 3 do
        bars[i]:SetScript("OnUpdate", nil) -- Reset existing animations

        if i <= current then
            -- Charge is ready
            bars[i]:SetMinMaxValues(0, 1)
            bars[i]:SetValue(1)
            bars[i]:SetAlpha(1)
            bars[i]:SetStatusBarColor(1, 0.5, 0)
        elseif i == current + 1 and duration > 0 then
            -- Charge is recharging
            bars[i]:SetAlpha(0.8)
            bars[i]:SetMinMaxValues(0, duration)
            bars[i]:SetStatusBarColor(1, 0.5, 0)
            bars[i]:SetScript("OnUpdate", function(self)
                local progress = GetTime() - start
                if progress > duration then progress = duration end
                self:SetValue(progress)
            end)
        else
            -- Charge is empty
            bars[i]:SetMinMaxValues(0, 1)
            bars[i]:SetValue(0)
            bars[i]:SetAlpha(0.3)
            bars[i]:SetStatusBarColor(1, 0, 0)
        end
    end
end

-- Events
frame:RegisterEvent("SPELL_UPDATE_CHARGES")
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", UpdateFireBlast)

-- Initial run with a 3-second delay to ensure spell data is ready
C_Timer.After(3, UpdateFireBlast)