Whispr.Chat = {}

local frame, chatArea, inputBox

function Whispr.Chat:OnInit()
    -- Initialize when addon loads
end

function Whispr.Chat:GetPlayerSuggestions(partial)
    local suggestions = {}
    
    -- Get friends list
    local numFriends = C_FriendList.GetNumFriends()
    for i = 1, numFriends do
        local friendInfo = C_FriendList.GetFriendInfoByIndex(i)
        if friendInfo and friendInfo.name then
            local name = friendInfo.name:match("^[^-]+") or friendInfo.name
            if string.lower(name):find(string.lower(partial), 1, true) then
                table.insert(suggestions, {
                    name = name,
                    fullName = friendInfo.name,
                    online = friendInfo.connected,
                    type = "friend"
                })
            end
        end
    end
    
    -- Get guild members if in guild
    if IsInGuild() then
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local name, _, _, _, _, _, _, _, online = GetGuildRosterInfo(i)
            if name then
                local shortName = name:match("^[^-]+") or name
                if string.lower(shortName):find(string.lower(partial), 1, true) then
                    table.insert(suggestions, {
                        name = shortName,
                        fullName = name,
                        online = online,
                        type = "guild"
                    })
                end
            end
        end
    end
    
    -- Get recent conversations
    if Whispr.Messages and Whispr.Messages.conversations then
        for playerName in pairs(Whispr.Messages.conversations) do
            local shortName = playerName:match("^[^-]+") or playerName
            if string.lower(shortName):find(string.lower(partial), 1, true) then
                table.insert(suggestions, {
                    name = shortName,
                    fullName = playerName,
                    online = nil,
                    type = "recent"
                })
            end
        end
    end
    
    -- Remove duplicates and limit to 8 suggestions
    local seen = {}
    local unique = {}
    for _, suggestion in ipairs(suggestions) do
        if not seen[suggestion.name] and #unique < 8 then
            seen[suggestion.name] = true
            table.insert(unique, suggestion)
        end
    end
    
    return unique
end

function Whispr.Chat:CreateDropdown(parent, nameBox)
    local dropdown = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    dropdown:SetSize(300, 0)
    dropdown:SetPoint("TOP", nameBox, "BOTTOM", 0, -2)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    dropdown:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    dropdown:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    dropdown:SetFrameStrata("FULLSCREEN_DIALOG")
    dropdown:SetFrameLevel(parent:GetFrameLevel() + 10)
    dropdown:Hide()
    
    dropdown.entries = {}
    
    function dropdown:UpdateSuggestions(suggestions)
        -- Clear existing entries
        for _, entry in ipairs(self.entries) do
            entry:Hide()
        end
        
        if #suggestions == 0 then
            self:Hide()
            return
        end
        
        -- Create/update entries
        for i, suggestion in ipairs(suggestions) do
            local entry = self.entries[i]
            if not entry then
                entry = CreateFrame("Button", nil, self)
                entry:SetSize(296, 24)
                entry:SetPoint("TOPLEFT", 2, -2 - (i-1) * 24)
                
                -- Background
                entry.bg = entry:CreateTexture(nil, "BACKGROUND")
                entry.bg:SetAllPoints()
                entry.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
                entry.bg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
                
                -- Highlight
                entry.highlight = entry:CreateTexture(nil, "HIGHLIGHT")
                entry.highlight:SetAllPoints()
                entry.highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
                entry.highlight:SetVertexColor(0.3, 0.5, 0.8, 0.6)
                
                -- Name text
                entry.nameText = entry:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                entry.nameText:SetPoint("LEFT", 8, 0)
                
                -- Status icon
                entry.statusIcon = entry:CreateTexture(nil, "OVERLAY")
                entry.statusIcon:SetSize(12, 12)
                entry.statusIcon:SetPoint("RIGHT", -8, 0)
                
                -- Type text
                entry.typeText = entry:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                entry.typeText:SetPoint("RIGHT", entry.statusIcon, "LEFT", -4, 0)
                
                self.entries[i] = entry
            end
            
            -- Update entry data
            entry.suggestion = suggestion
            entry.nameText:SetText(suggestion.name)
            
            -- Set type and color
            if suggestion.type == "friend" then
                entry.typeText:SetText("Friend")
                entry.typeText:SetTextColor(0.5, 1, 0.5)
            elseif suggestion.type == "guild" then
                entry.typeText:SetText("Guild")
                entry.typeText:SetTextColor(1, 0.8, 0.5)
            else
                entry.typeText:SetText("Recent")
                entry.typeText:SetTextColor(0.7, 0.7, 0.7)
            end
            
            -- Set online status icon
            if suggestion.online == true then
                entry.statusIcon:SetTexture("Interface\\FriendsFrame\\StatusIcon-Online")
            elseif suggestion.online == false then
                entry.statusIcon:SetTexture("Interface\\FriendsFrame\\StatusIcon-Offline")
            else
                entry.statusIcon:SetTexture(nil)
            end
            
            -- Click handler
            entry:SetScript("OnClick", function()
                nameBox:SetText(suggestion.name)
                nameBox:SetCursorPosition(string.len(suggestion.name))
                self:Hide()
                nameBox:SetFocus()
            end)
            
            entry:Show()
        end
        
        -- Adjust dropdown height
        local height = #suggestions * 24 + 4
        self:SetHeight(height)
        self:Show()
    end
    
    return dropdown
end

function Whispr.Chat:CreateNewConversationPrompt()
    if Whispr.Chat.newConversationFrame then
        Whispr.Chat.newConversationFrame:Show()
        return
    end

    local prompt = CreateFrame("Frame", "WhisprNewConversationFrame", UIParent, "BackdropTemplate")
    prompt:SetSize(400, 180)
    prompt:SetPoint("CENTER", frame, "CENTER")
    
    -- Modern styling with golden border like WoW dialogs
    prompt:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    prompt:SetBackdropColor(0.0, 0.0, 0.0, 0.85)
    prompt:SetBackdropBorderColor(1, 0.8, 0, 1) -- Golden border
    prompt:SetFrameStrata("FULLSCREEN_DIALOG")
    
    -- Subtle glow effect with golden tint
    local glow = prompt:CreateTexture(nil, "BACKGROUND", nil, -1)
    glow:SetTexture("Interface\\Glues\\Models\\UI_MainMenu\\UI_MainMenu-Option")
    glow:SetPoint("TOPLEFT", -20, 20)
    glow:SetPoint("BOTTOMRIGHT", 20, -20)
    glow:SetVertexColor(1, 0.8, 0.2, 0.3) -- Golden glow

    -- Icon next to title
    local icon = prompt:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-Chat")
    icon:SetSize(20, 20)
    icon:SetPoint("TOP", 0, -15)

    local title = prompt:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", icon, "BOTTOM", 0, -5)
    title:SetText("Start New Conversation")
    title:SetTextColor(1, 1, 1, 1)

    -- Enhanced input box
    local nameBox = CreateFrame("EditBox", nil, prompt, "InputBoxTemplate")
    nameBox:SetSize(300, 32)
    nameBox:SetPoint("TOP", title, "BOTTOM", 0, -15)
    nameBox:SetAutoFocus(true)
    nameBox:SetMaxLetters(50)
    nameBox:SetTextInsets(10, 10, 0, 0)
    nameBox:SetFontObject("GameFontHighlight")
    
    -- Placeholder text
    nameBox.placeholder = "Enter player name..."
    nameBox:SetText(nameBox.placeholder)
    nameBox:SetTextColor(0.6, 0.6, 0.6)
    
    -- Create dropdown for suggestions
    local dropdown = self:CreateDropdown(prompt, nameBox)
    
    -- Placeholder text handling
    nameBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == self.placeholder then
            self:SetText("")
            self:SetTextColor(1, 1, 1)
        end
        dropdown:Hide()
    end)
    
    nameBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText(self.placeholder)
            self:SetTextColor(0.6, 0.6, 0.6)
        end
        -- Hide dropdown after a short delay
        C_Timer.After(0.1, function()
            if dropdown and not dropdown:IsMouseOver() then
                dropdown:Hide()
            end
        end)
    end)
    
    -- Text changed handler for autocomplete
    nameBox:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        if text == self.placeholder or text == "" or string.len(text) < 2 then
            dropdown:Hide()
            return
        end
        
        local suggestions = Whispr.Chat:GetPlayerSuggestions(text)
        dropdown:UpdateSuggestions(suggestions)
    end)
    
    -- Function to start conversation (shared between button and enter key)
    local function startConversation()
        local name = nameBox:GetText()
        if name and name ~= "" and name ~= nameBox.placeholder then
            -- Add realm if not specified and we're on retail
            if not string.find(name, "-") and GetRealmName() then
                name = name .. "-" .. GetRealmName()
            end
            
            if not Whispr.Messages.conversations[name] then
                Whispr.Messages.conversations[name] = {}
            end
            Whispr.Messages:SetTarget(name)
            Whispr.Contacts:UpdateSidebar()
            prompt:Hide()
        end
    end
    
    -- Handle Enter key press
    nameBox:SetScript("OnEnterPressed", startConversation)

    -- Enhanced buttons
    local confirm = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
    confirm:SetSize(100, 26)
    confirm:SetPoint("BOTTOMRIGHT", -15, 15)
    confirm:SetText("Start Chat")
    
    -- Better button styling
    confirm:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    confirm:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    confirm:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")

    local cancel = CreateFrame("Button", nil, prompt, "UIPanelButtonTemplate")
    cancel:SetSize(80, 26)
    cancel:SetPoint("BOTTOMLEFT", 15, 15)
    cancel:SetText("Cancel")

    confirm:SetScript("OnClick", startConversation)

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
    
    -- Register ESC key handling for main frame
    table.insert(UISpecialFrames, "WhisprChatWindow")

    local sidebarFrame = CreateFrame("Frame", nil, frame, "InsetFrameTemplate3")
    sidebarFrame:SetPoint("TOPLEFT", 4, -28)
    sidebarFrame:SetPoint("BOTTOMLEFT", 4, 4)
    sidebarFrame:SetWidth(200)

    -- New conversation button with better positioning
    local newConversationButton = CreateFrame("Button", nil, sidebarFrame, "BackdropTemplate")
    newConversationButton:SetSize(30, 30)
    newConversationButton:SetPoint("TOPLEFT", 148, -8)

    -- Use a more appropriate icon
    local plusTexture = "Interface\\FriendsFrame\\UI-Toast-FriendRequestIcon"
    local bg = newConversationButton:CreateTexture(nil, "ARTWORK")
    bg:SetAllPoints()
    bg:SetTexture(plusTexture)

    -- Make the button functional
    newConversationButton:SetScript("OnClick", function()
        Whispr.Chat:CreateNewConversationPrompt()
    end)

    -- Enhanced hover effects
    newConversationButton:SetScript("OnEnter", function(self)
        if bg then
            bg:SetVertexColor(1.3, 1.3, 1.3, 1)
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Start New Conversation", 1, 1, 1)
        GameTooltip:AddLine("Click to open chat with a new player", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    newConversationButton:SetScript("OnLeave", function(self)
        if bg then
            bg:SetVertexColor(1, 1, 1, 1)
        end
        GameTooltip:Hide()
    end)

    -- Add pressed effect
    newConversationButton:SetScript("OnMouseDown", function(self)
        if bg then
            bg:SetVertexColor(0.7, 0.7, 0.7, 1)
        end
    end)

    newConversationButton:SetScript("OnMouseUp", function(self)
        if bg then
            bg:SetVertexColor(1, 1, 1, 1)
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

    -- Add TAB key binding for focusing input box
    local function SetupTabBinding()
        if not Whispr.Chat.tabBindingSet then
            CreateFrame("Button", "WhisprTabBind", frame):SetScript("OnClick", function()
                if frame:IsShown() and inputBox then
                    inputBox:SetFocus()
                end
            end)
            
            SetBindingClick("TAB", "WhisprTabBind")
            Whispr.Chat.tabBindingSet = true
        end
    end
    
    frame:SetScript("OnShow", function()
        SetupTabBinding()
    end)
    
    frame:SetScript("OnHide", function()
        if Whispr.Chat.tabBindingSet then
            SetBinding("TAB")
            Whispr.Chat.tabBindingSet = false
        end
    end)

    -- Add global keybind handler for TAB when frame is shown
    local function OnUpdate(self, elapsed)
        if self:IsShown() and IsKeyDown("TAB") then
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

-- Add function to highlight selected contact
function Whispr.Chat:HighlightSelectedContact(contactName)
    if not self.contactList then return end
    
    -- Remove highlight from all contacts
    for i = 1, self.contactList:GetNumChildren() do
        local child = select(i, self.contactList:GetChildren())
        if child and child.contactName then
            if child.selectedBg then
                child.selectedBg:Hide()
            end
            if child.nameText then
                child.nameText:SetTextColor(1, 1, 1)
            end
        end
    end
    
    -- Add highlight to selected contact
    for i = 1, self.contactList:GetNumChildren() do
        local child = select(i, self.contactList:GetChildren())
        if child and child.contactName == contactName then
            -- Create selected background if it doesn't exist
            if not child.selectedBg then
                child.selectedBg = child:CreateTexture(nil, "BACKGROUND")
                child.selectedBg:SetAllPoints()
                child.selectedBg:SetTexture("Interface\\Buttons\\WHITE8x8")
                child.selectedBg:SetVertexColor(0.2, 0.4, 0.8, 0.6)
            end
            child.selectedBg:Show()
            
            -- Make text brighter
            if child.nameText then
                child.nameText:SetTextColor(1, 1, 0.8)
            end
            break
        end
    end
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