Whispr.Chat = {}

local frame, chatArea, inputBox

function Whispr.Chat:OnInit()
    -- Initialize when addon loads
end

function Whispr.Chat:CreateNewConversationPrompt()
    if Whispr.Chat.newConversationFrame then
        Whispr.Chat.newConversationFrame:Show()
        -- Register ESC key for this frame
        table.insert(UISpecialFrames, "WhisprNewConversationFrame")
        return
    end

    local prompt = CreateFrame("Frame", "WhisprNewConversationFrame", UIParent, "BackdropTemplate")
    prompt:SetSize(300, 100)
    prompt:SetPoint("CENTER", frame, "CENTER")
    prompt:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background" })
    prompt:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    prompt:SetFrameStrata("FULLSCREEN_DIALOG") -- Higher than main frame

    -- Make frame closable with ESC
    prompt:EnableKeyboard(true)
    prompt:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        end
    end)

    local title = prompt:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Start New Conversation")

    local nameBox = CreateFrame("EditBox", nil, prompt, "InputBoxTemplate")
    nameBox:SetSize(200, 20)
    nameBox:SetPoint("TOP", title, "BOTTOM", 0, -10)
    nameBox:SetAutoFocus(true)
    nameBox:SetMaxLetters(50)

    local confirm = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
    confirm:SetSize(80, 22)
    confirm:SetPoint("BOTTOMRIGHT", -10, 10)
    confirm:SetText("Start")

    local cancel = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
    cancel:SetSize(80, 22)
    cancel:SetPoint("BOTTOMLEFT", 10, 10)
    cancel:SetText("Cancel")

    confirm:SetScript("OnClick", function()
        local name = nameBox:GetText()
        if name and name ~= "" then
            if not Whispr.Messages.conversations[name] then
                Whispr.Messages.conversations[name] = {}
            end
            Whispr.Messages:SetTarget(name)
            Whispr.Contacts:UpdateSidebar()
        end
        prompt:Hide()
    end)

    cancel:SetScript("OnClick", function()
        prompt:Hide()
    end)

    -- Register ESC key handling for this frame
    table.insert(UISpecialFrames, "WhisprNewConversationFrame")

    Whispr.Chat.newConversationFrame = prompt
end

function Whispr.Chat:Create()
    frame = CreateFrame("Frame", "WhisprChatWindow", UIParent, "PortraitFrameTemplate")
    frame:SetSize(800, 500)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetTitle("Whispr Chat")

    -- Make main frame closable with ESC
    frame:EnableKeyboard(true)
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:Hide()
        elseif key == "TAB" then
            -- Focus the input box when TAB is pressed
            if inputBox then
                inputBox:SetFocus()
            end
        end
    end)

    -- Register ESC key handling for main frame
    table.insert(UISpecialFrames, "WhisprChatWindow")

    local sidebarFrame = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
    sidebarFrame:SetPoint("TOPLEFT", 4, -28)
    sidebarFrame:SetPoint("BOTTOMLEFT", 4, 4)
    sidebarFrame:SetWidth(200)

    -- New conversation button with PlusManz texture
    local newConversationButton = CreateFrame("Button", nil, sidebarFrame, "BackdropTemplate")
    newConversationButton:SetSize(24, 24)
    newConversationButton:SetPoint("TOPLEFT", 15, -10)

    -- Set the PlusManz texture
    local plusTexture = "Interface\\PlusManz\\PlusManz"
    local bg = newConversationButton:CreateTexture(nil, "ARTWORK")
    bg:SetAllPoints()
    bg:SetTexture(plusTexture)

    -- Make the button functional
    newConversationButton:SetScript("OnClick", function()
        Whispr.Chat:CreateNewConversationPrompt()
    end)

    -- Add hover effects
    newConversationButton:SetScript("OnEnter", function(self)
        if bg then
            bg:SetVertexColor(1.2, 1.2, 1.2, 1) -- Slightly brighter on hover
        end
        -- Optional: Add tooltip
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Start New Conversation", 1, 1, 1)
        GameTooltip:Show()
    end)

    newConversationButton:SetScript("OnLeave", function(self)
        if bg then
            bg:SetVertexColor(1, 1, 1, 1) -- Back to normal
        end
        GameTooltip:Hide()
    end)

    -- Add pressed effect
    newConversationButton:SetScript("OnMouseDown", function(self)
        if bg then
            bg:SetVertexColor(0.8, 0.8, 0.8, 1) -- Darker when pressed
        end
    end)

    newConversationButton:SetScript("OnMouseUp", function(self)
        if bg then
            bg:SetVertexColor(1, 1, 1, 1) -- Back to normal
        end
    end)

    local searchBox = CreateFrame("EditBox", nil, sidebarFrame, "InputBoxTemplate")
    searchBox:SetSize(160, 20)
    searchBox:SetPoint("TOPLEFT", 15, -40)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject("GameFontHighlightSmall")
    searchBox:SetTextInsets(6, 6, 0, 0)
    searchBox:SetText("Search...")
    searchBox:SetTextColor(0.5, 0.5, 0.5)
    Whispr.Chat.searchBox = searchBox

    -- Scrollable contact list frame
    local contactScroll = CreateFrame("ScrollFrame", nil, sidebarFrame)
    contactScroll:SetPoint("TOPLEFT", 4, -90)
    contactScroll:SetPoint("BOTTOMRIGHT", -28, 4)

    contactScroll.scrollBarTemplate = "MinimalScrollBar"
    contactScroll.scrollBarX = 12
    contactScroll.scrollBarTopY = 0
    contactScroll.scrollBarBottomY = 0
    ScrollFrame_OnLoad(contactScroll)

    local contactList = CreateFrame("Frame", nil, contactScroll)
    contactList:SetSize(1, 1)
    contactScroll:SetScrollChild(contactList)
    Whispr.Chat.contactList = contactList

    -- Chat area
    chatArea = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
    chatArea:SetPoint("TOPLEFT", sidebarFrame, "TOPRIGHT", 2, 0)
    chatArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 44)

    chatArea.titleBar = CreateFrame("Frame", nil, chatArea)
    chatArea.titleBar:SetPoint("TOPLEFT", 0, 0)
    chatArea.titleBar:SetPoint("TOPRIGHT", 0, 0)
    chatArea.titleBar:SetHeight(24)

    chatArea.titleText = chatArea.titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chatArea.titleText:SetPoint("LEFT", 10, 0)
    chatArea.titleText:SetText("No conversation selected")

    chatArea.scroll = CreateFrame("ScrollingMessageFrame", nil, chatArea)
    chatArea.scroll:SetPoint("TOPLEFT", 10, -30)
    chatArea.scroll:SetPoint("BOTTOMRIGHT", -30, 10)

    chatArea.scroll:SetFontObject(GameFontHighlightSmall)
    chatArea.scroll:SetFading(false)
    chatArea.scroll:SetMaxLines(500)
    chatArea.scroll:SetJustifyH("LEFT")
    chatArea.scroll:SetIndentedWordWrap(true)
    chatArea.scroll:SetHyperlinksEnabled(true)

    chatArea.scroll:SetScript("OnHyperlinkEnter", function(_, link)
        GameTooltip:SetOwner(chatArea.scroll, "ANCHOR_CURSOR")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)

    chatArea.scroll:SetScript("OnHyperlinkLeave", function()
        GameTooltip:Hide()
    end)

    chatArea.scroll:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)

    chatArea.scroll.scrollBarTemplate = "MinimalScrollBar"
    chatArea.scroll.scrollBarX = 12
    chatArea.scroll.scrollBarTopY = 0
    chatArea.scroll.scrollBarBottomY = 0

    chatArea.scroll:EnableMouseWheel(true)
    chatArea.scroll:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            self:ScrollUp()
        elseif delta < 0 then
            self:ScrollDown()
        end
    end)

    -- Input box
    inputBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    inputBox:SetAutoFocus(false)
    inputBox:SetSize(460, 24)
    inputBox:SetMaxLetters(255)
    inputBox:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 220, 10)

    local charCount = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    charCount:SetPoint("LEFT", inputBox, "RIGHT", 8, 0)
    charCount:SetText("0/255")

    inputBox:SetScript("OnTextChanged", function(self)
        local len = self:GetNumLetters()
        charCount:SetText(len .. "/255")
    end)

    inputBox:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        if Whispr.Messages.target and text ~= "" then
            SendChatMessage(text, "WHISPER", nil, Whispr.Messages.target)
            table.insert(Whispr.Messages.conversations[Whispr.Messages.target], {
                sender = UnitName("player"),
                text = text,
                fromPlayer = true,
                timestamp = date("%H:%M")
            })
            Whispr.Messages:LoadConversation(Whispr.Messages.target)
        end
        self:SetText("")
        self:ClearFocus()
    end)

    searchBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == "Search..." then
            self:SetText("")
            self:SetTextColor(1, 1, 1)
        end
    end)

    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText("Search...")
            self:SetTextColor(0.5, 0.5, 0.5)
        end
    end)

    searchBox:SetScript("OnTextChanged", function()
        Whispr.Contacts:UpdateSidebar()
    end)

    -- Add global keybind handler for TAB when frame is shown
    local function OnUpdate(self, elapsed)
        if self:IsShown() and IsKeyDown("TAB") then
            -- Small delay to prevent spam
            if not self.tabPressed then
                self.tabPressed = true
                if inputBox then
                    inputBox:SetFocus()
                end
                C_Timer.After(0.1, function()
                    if frame then
                        frame.tabPressed = false
                    end
                end)
            end
        end
    end
    frame:SetScript("OnUpdate", OnUpdate)

    Whispr.Contacts:UpdateSidebar()
end

function Whispr.Chat:GetFrame()
    return frame
end

function Whispr.Chat:GetChatArea()
    return chatArea
end

function Whispr.Chat:GetInputBox()
    return inputBox
end

function Whispr.Chat:GetContactList()
    return self.contactList
end

function Whispr.Chat:GetSearchBox()
    return self.searchBox
end

function Whispr.Chat:Show()
    if frame then
        frame:Show()
    end
end

function Whispr.Chat:Hide()
    if frame then
        frame:Hide()
    end
end

function Whispr.Chat:IsShown()
    return frame and frame:IsShown()
end

-- Register the module
Whispr:RegisterModule("Chat", Whispr.Chat)