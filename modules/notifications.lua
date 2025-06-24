local Notifications = {}

Notifications.active = {}

function Notifications:ShowNotification(sender, msg)
  local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  frame:SetSize(240, 60)
  frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", -300, 550 + (#self.active * 68))
  frame:SetFrameStrata("DIALOG")
  frame:SetMovable(true)
  frame:EnableMouse(true)

  -- Background
  frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  frame:SetBackdropColor(0.1, 0.1, 0.1, 0.85)
  frame:SetBackdropBorderColor(1, 0.2, 0.7, 0.7) -- Static pink border

  -- Static pink glow
  local glow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
  glow:SetBlendMode("ADD")
  glow:SetVertexColor(1, 0.2, 0.8, 0.35)
  glow:SetPoint("CENTER", frame, "CENTER", 0, -2)
  glow:SetSize(frame:GetWidth() + 60, frame:GetHeight() + 30)

  -- Slide in animation
  frame:SetAlpha(0)
  frame:Show()
  C_Timer.After(0, function()
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 30, 550 + (#self.active * 68))
    UIFrameFadeIn(frame, 0.3, 0, 1)
  end)

  -- Portrait
  local portrait = frame:CreateTexture(nil, "ARTWORK")
  portrait:SetSize(32, 32)
  portrait:SetPoint("TOPLEFT", 8, -8)
  portrait:SetTexture("Interface\\ICONS\\Achievement_Character_Dwarf_Male") -- Dynamically set this to the sender's icon
  portrait:SetTexCoord(0.07, 0.93, 0.07, 0.93)

  -- Sender name
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 8, -1)
  title:SetPoint("RIGHT", -10, 0)
  title:SetJustifyH("LEFT")
  title:SetText(sender)

  -- Snippet
  local snippet = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  snippet:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
  snippet:SetPoint("RIGHT", -10, 0)
  snippet:SetJustifyH("LEFT")
  snippet:SetText(string.sub(msg, 1, 60) .. "...")

  -- Click to open or dismiss
  frame:SetScript("OnMouseDown", function(_, btn)
    if btn == "RightButton" then
      -- Right-click to close
      frame:Hide()
      self:Remove(frame)
    elseif btn == "LeftButton" then
      if Whispr.modules.Whispers and Whispr.modules.Whispers.SetTarget then
        Whispr.modules.Whispers:SetTarget(sender)
      end
      frame:Hide()
      self:Remove(frame)
    end
  end)

  PlaySoundFile(2113870, "Master") -- Notification sound

  table.insert(self.active, frame)

  -- Auto-remove
  C_Timer.After(6, function()
    if frame and frame:IsShown() then
      frame:Hide()
      self:Remove(frame)
    end
  end)
end

function Notifications:Remove(target)
  for i, frame in ipairs(self.active) do
    if frame == target then
      table.remove(self.active, i)
      break
    end
  end

  -- Re-stack
  for i, frame in ipairs(self.active) do
    frame:ClearAllPoints()
    frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 30, 550 + ((i - 1) * 68))
  end
end

Whispr:RegisterModule("Notifications", Notifications)
