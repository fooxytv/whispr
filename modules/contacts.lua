Whispr.Contacts = {}

function Whispr.Contacts:OnInit()
    -- Initialize when addon loads
    self.sectionStates = {
        conversations = true -- Default to expanded
    }
end

function Whispr.Contacts:GetRacePortrait(playerName)
    -- You can expand this to detect actual race if you have that data
    -- For now, we'll use a variety of portraits based on name hash
    local portraits = {
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Male-Human",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Female-Human", 
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Male-NightElf",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Female-NightElf",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Male-Dwarf",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Female-Dwarf",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Male-Orc",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Female-Orc",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Male-Troll",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Female-Troll",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Male-Undead",
        "Interface\\CHARACTERFRAME\\TemporaryPortrait-Female-Undead"
    }
    
    -- Simple hash to assign consistent portraits
    local hash = 0
    for i = 1, string.len(playerName) do
        hash = hash + string.byte(playerName, i)
    end
    
    return portraits[(hash % #portraits) + 1]
end

function Whispr.Contacts:CreateSectionHeader(parent, title, yOffset, sectionKey)
    local header = CreateFrame("Button", nil, parent)
    header:SetSize(180, 20)
    header:SetPoint("TOPLEFT", 0, yOffset)
    header:EnableMouse(true)
    
    -- Header background using the exact WoW profession frame style  
    header.leftPiece = header:CreateTexture(nil, "BACKGROUND")
    header.leftPiece:SetAtlas("Professions-recipe-header-left")
    header.leftPiece:SetPoint("LEFT", 0, 2)
    
    header.rightPiece = header:CreateTexture(nil, "BACKGROUND")
    header.rightPiece:SetAtlas("Professions-recipe-header-right") 
    header.rightPiece:SetPoint("RIGHT", 0, 2)
    
    header.centerPiece = header:CreateTexture(nil, "BACKGROUND")
    header.centerPiece:SetAtlas("Professions-recipe-header-middle")
    header.centerPiece:SetPoint("TOPLEFT", header.leftPiece, "TOPRIGHT")
    header.centerPiece:SetPoint("BOTTOMRIGHT", header.rightPiece, "BOTTOMLEFT")
    
    -- Expand/collapse arrow
    header.arrow = header:CreateTexture(nil, "OVERLAY")
    header.arrow:SetSize(12, 12)
    header.arrow:SetPoint("LEFT", 6, 0)
    header.arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    
    -- Header text with exact styling from the image
    header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header.text:SetPoint("LEFT", header.arrow, "RIGHT", 4, 0)
    header.text:SetText(title)
    header.text:SetTextColor(1, 0.82, 0, 1) -- Golden color like "Section I - Bismuth"
    
    -- Update arrow rotation based on expanded state
    local function UpdateArrow()
        if self.sectionStates[sectionKey] then
            header.arrow:SetRotation(0) -- Expanded (arrow pointing down)
        else
            header.arrow:SetRotation(-math.pi / 2) -- Collapsed (arrow pointing right)
        end
    end
    
    -- Initial arrow state
    UpdateArrow()
    
    -- Click handler to toggle section
    header:SetScript("OnClick", function()
        self.sectionStates[sectionKey] = not self.sectionStates[sectionKey]
        UpdateArrow()
        self:UpdateSidebar() -- Refresh the entire sidebar
    end)
    
    -- Hover effect
    header:SetScript("OnEnter", function(self)
        if self.leftPiece then
            self.leftPiece:SetVertexColor(1.1, 1.1, 1.1, 1)
            self.rightPiece:SetVertexColor(1.1, 1.1, 1.1, 1)
            self.centerPiece:SetVertexColor(1.1, 1.1, 1.1, 1)
        end
    end)
    
    header:SetScript("OnLeave", function(self)
        if self.leftPiece then
            self.leftPiece:SetVertexColor(1, 1, 1, 1)
            self.rightPiece:SetVertexColor(1, 1, 1, 1)
            self.centerPiece:SetVertexColor(1, 1, 1, 1)
        end
    end)
    
    return header
end

function Whispr.Contacts:CreateContactEntry(parent, contactData, yOffset)
    local contact = CreateFrame("Button", nil, parent)
    contact:SetSize(180, 28)
    contact:SetPoint("TOPLEFT", 0, yOffset)
    contact.contactName = contactData.name -- Store for selection tracking
    
    -- Clean background
    contact.bg = contact:CreateTexture(nil, "BACKGROUND")
    contact.bg:SetAllPoints()
    contact.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    contact.bg:SetVertexColor(0, 0, 0, 0) -- Transparent by default
    
    -- Hover highlight - simple and reliable
    contact.hoverHighlight = contact:CreateTexture(nil, "HIGHLIGHT")
    contact.hoverHighlight:SetAllPoints()
    contact.hoverHighlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    contact.hoverHighlight:SetVertexColor(1, 1, 1, 0.2) -- Subtle white highlight
    
    -- Selection highlight - gold bars at top and bottom
    contact.selectedTop = contact:CreateTexture(nil, "OVERLAY")
    contact.selectedTop:SetHeight(2)
    contact.selectedTop:SetPoint("TOPLEFT", 0, 0)
    contact.selectedTop:SetPoint("TOPRIGHT", 0, 0)
    contact.selectedTop:SetTexture("Interface\\Buttons\\WHITE8x8")
    contact.selectedTop:SetVertexColor(0.8, 0.6, 0.2, 0.8) -- Toned down gold color
    contact.selectedTop:Hide()
    
    contact.selectedBottom = contact:CreateTexture(nil, "OVERLAY")
    contact.selectedBottom:SetHeight(2)
    contact.selectedBottom:SetPoint("BOTTOMLEFT", 0, 0)
    contact.selectedBottom:SetPoint("BOTTOMRIGHT", 0, 0)
    contact.selectedBottom:SetTexture("Interface\\Buttons\\WHITE8x8")
    contact.selectedBottom:SetVertexColor(0.8, 0.6, 0.2, 0.8) -- Toned down gold color
    contact.selectedBottom:Hide()
    
    -- Selection background (subtle dark background like the sidebar)
    contact.selectedBg = contact:CreateTexture(nil, "BACKGROUND", nil, 1)
    contact.selectedBg:SetAllPoints()
    contact.selectedBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    contact.selectedBg:SetVertexColor(0.15, 0.12, 0.08, 0.8) -- Dark brown background like sidebar
    contact.selectedBg:Hide()
    
    -- Race portrait (small, clean, positioned at left edge)
    contact.portrait = contact:CreateTexture(nil, "ARTWORK")
    contact.portrait:SetSize(16, 16)
    contact.portrait:SetPoint("LEFT", 4, 0) -- Moved to left edge with small padding
    contact.portrait:SetTexture(self:GetRacePortrait(contactData.name))
    contact.portrait:SetTexCoord(0.1, 0.9, 0.1, 0.9) -- Clean crop
    
    -- Player name
    contact.nameText = contact:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    contact.nameText:SetPoint("LEFT", contact.portrait, "RIGHT", 6, 0)
    contact.nameText:SetPoint("RIGHT", -30, 0) -- Leave space for unread indicator
    contact.nameText:SetJustifyH("LEFT")
    contact.nameText:SetText(contactData.shortName or contactData.name)
    contact.nameText:SetTextColor(1, 1, 1, 1) -- White text
    
    -- Unread message indicator
    if contactData.unreadCount and contactData.unreadCount > 0 then
        contact.unreadIndicator = contact:CreateTexture(nil, "OVERLAY")
        contact.unreadIndicator:SetSize(12, 12)
        contact.unreadIndicator:SetPoint("RIGHT", -8, 0)
        contact.unreadIndicator:SetTexture("Interface\\Minimap\\ObjectIcons")
        contact.unreadIndicator:SetTexCoord(0.125, 0.25, 0.125, 0.25) -- Orange diamond
        
        -- Small unread count for multiple messages
        if contactData.unreadCount > 1 then
            contact.unreadText = contact:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
            contact.unreadText:SetPoint("TOPRIGHT", contact.unreadIndicator, "TOPRIGHT", 4, 4)
            contact.unreadText:SetText(tostring(contactData.unreadCount))
            contact.unreadText:SetTextColor(1, 0.8, 0, 1) -- Gold color
        end
    end
    
    -- Click handler
    contact:SetScript("OnClick", function(self)
        Whispr.Messages:SetTarget(contactData.name)
        Whispr.Contacts:UpdateSidebar() -- Refresh to update selection
    end)
    
    -- Hover tooltip
    contact:SetScript("OnEnter", function(self)
        if contactData.lastMessage and contactData.lastMessage ~= "" then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(contactData.name, 1, 1, 1)
            GameTooltip:AddLine("Last: " .. contactData.lastMessage, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end
    end)
    
    contact:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    return contact
end

function Whispr.Contacts:UpdateSidebar()
    local contactList = Whispr.Chat:GetContactList()
    if not contactList then return end

    -- Clear existing entries
    for _, child in ipairs({ contactList:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end

    local searchBox = Whispr.Chat:GetSearchBox()
    local query = ""
    if searchBox then
        query = string.lower(searchBox:GetText() or "")
        if query == "search..." then query = "" end
    end

    local offsetY = -8
    local currentTarget = Whispr.Messages and Whispr.Messages.target
    
    -- Get conversations first to check if we have any
    local conversations = Whispr.Messages:GetConversations()
    local hasConversations = false
    for _ in pairs(conversations) do
        hasConversations = true
        break
    end
    
    -- Only show header and content if we have conversations
    if hasConversations then
        -- Create "Recent Conversations" header
        local header = self:CreateSectionHeader(contactList, "Recent Conversations", offsetY, "conversations")
        offsetY = offsetY - 24

        -- Only show conversation entries if section is expanded
        if self.sectionStates.conversations then
            -- Get and sort conversations
            local sorted = {}
            
            for name, messages in pairs(conversations) do
                local shortName = name:match("^[^-]+") or name
                local lastMessage = ""
                local timestamp = ""
                local unreadCount = 0
                
                if messages and #messages > 0 then
                    local lastMsg = messages[#messages]
                    lastMessage = lastMsg.text or ""
                    timestamp = lastMsg.timestamp or ""
                    
                    -- Count unread messages
                    for _, msg in ipairs(messages) do
                        if msg.unread then
                            unreadCount = unreadCount + 1
                        end
                    end
                end
                
                -- Truncate long messages for tooltip
                if string.len(lastMessage) > 30 then
                    lastMessage = string.sub(lastMessage, 1, 27) .. "..."
                end
                
                table.insert(sorted, {
                    name = name,
                    shortName = shortName,
                    lastMessage = lastMessage,
                    timestamp = timestamp,
                    unreadCount = unreadCount
                })
            end
            
            -- Sort by timestamp (most recent first)
            table.sort(sorted, function(a, b) 
                return a.timestamp > b.timestamp 
            end)

            -- Create contact entries
            local visibleCount = 0
            for _, contactData in ipairs(sorted) do
                -- Apply search filter
                if query == "" or contactData.shortName:lower():find(query, 1, true) then
                    local contact = self:CreateContactEntry(contactList, contactData, offsetY)
                    
                    -- Highlight if this is the selected contact
                    if contactData.name == currentTarget then
                        contact.selectedTop:Show()
                        contact.selectedBottom:Show()
                        contact.selectedBg:Show()
                    end
                    
                    offsetY = offsetY - 30
                    visibleCount = visibleCount + 1
                end
            end
            
            -- Show "No matches found" only if searching and no results
            if visibleCount == 0 and query ~= "" then
                local emptyMessage = contactList:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                emptyMessage:SetPoint("TOPLEFT", 20, offsetY - 10)
                emptyMessage:SetText("No matches found")
                emptyMessage:SetTextColor(0.5, 0.5, 0.5, 1)
                offsetY = offsetY - 25
            end
        end
    end
    
    -- Add some padding at the bottom
    offsetY = offsetY - 10
    
    -- Set the contact list height
    contactList:SetHeight(math.abs(offsetY))
end

-- Function to mark a contact as selected (called from Messages module)
function Whispr.Contacts:SetSelectedContact(contactName)
    -- This will be called when a contact is selected
    -- The highlighting is now handled in UpdateSidebar()
    self:UpdateSidebar()
end

Whispr:RegisterModule("Contacts", Whispr.Contacts)