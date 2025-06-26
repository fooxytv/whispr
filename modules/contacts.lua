Whispr.Contacts = {}

function Whispr.Contacts:OnInit()
    -- Initialize when addon loads
end

function Whispr.Contacts:UpdateSidebar()
    local contactList = Whispr.Chat:GetContactList()
    if not contactList then return end

    for _, child in ipairs({ contactList:GetChildren() }) do
        if child ~= contactList.searchBox and child ~= contactList.newButton then
            child:Hide()
            child:SetParent(nil)
        end
    end

    if not contactList.searchBox then
        contactList.searchBox = CreateFrame("EditBox", nil, contactList, "InputBoxTemplate")
        contactList.searchBox:SetSize(160, 20)
        contactList.searchBox:ClearAllPoints()
        contactList.searchBox:SetAutoFocus(false)
        contactList.searchBox:SetFontObject("GameFontHighlightSmall")
        contactList.searchBox:SetTextInsets(6, 6, 0, 0)
        contactList.searchBox:SetText("Search...")
        contactList.searchBox:SetTextColor(0.5, 0.5, 0.5)

        contactList.searchBox:SetScript("OnEditFocusGained", function(self)
            if self:GetText() == "Search..." then
                self:SetText("")
                self:SetTextColor(1, 1, 1)
            end
        end)

        contactList.searchBox:SetScript("OnEditFocusLost", function(self)
            if self:GetText() == "" then
                self:SetText("Search...")
                self:SetTextColor(0.5, 0.5, 0.5)
            end
        end)

        contactList.searchBox:SetScript("OnTextChanged", function()
            Whispr.Contacts:UpdateSidebar()
        end)
    end

    local searchBox = Whispr.Chat:GetSearchBox()
    local query = ""
    if searchBox then
        query = string.lower(searchBox:GetText() or "")
        if query == "search..." then query = "" end
    end

    local offsetY = -10
    local category = "Conversations"
    local expanded = true
    local toggles = {}
    toggles[category] = {}

    local header = CreateFrame("Button", nil, contactList)
    header:SetSize(180, 20)
    header:SetPoint("TOPLEFT", 10, offsetY)
    header:SetHighlightTexture("Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar")
    header:GetHighlightTexture():SetBlendMode("ADD")

    header.icon = header:CreateTexture(nil, "OVERLAY")
    header.icon:SetSize(14, 14)
    header.icon:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    header.icon:SetPoint("LEFT", 4, 0)

    header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header.text:SetPoint("LEFT", header.icon, "RIGHT", 4, 0)
    header.text:SetText(category)

    local function UpdateIconState()
        if expanded then
            header.icon:SetRotation(-math.pi / 2) -- ►
        else
            header.icon:SetRotation(0) -- ▼
        end
    end

    UpdateIconState()

    header:SetScript("OnClick", function()
        expanded = not expanded
        UpdateIconState()
        for _, entry in ipairs(toggles[category]) do
            if expanded then entry:Show() else entry:Hide() end
        end
    end)

    offsetY = offsetY - 28

    local sorted = {}
    local conversations = Whispr.Messages:GetConversations()
    for name, messages in pairs(conversations) do
        local time = ""
        if messages[#messages] then
            time = messages[#messages].timestamp or ""
        end
        table.insert(sorted, { name = name, time = time })
    end
    table.sort(sorted, function(a, b) return a.time > b.time end)

    for _, convo in ipairs(sorted) do
        local name = convo.name
        local shortName = name:match("^[^-]+")
        local lastMessage = ""
        local messages = conversations[name] or {}
        if messages and #messages > 0 then
            lastMessage = messages[#messages].text or ""
        end

        if query == "" or shortName:lower():find(query, 1, true) then
            local contact = CreateFrame("Button", nil, contactList)
            contact:SetSize(180, 48)
            contact:SetPoint("TOPLEFT", 10, offsetY)

            local highlight = contact:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetColorTexture(0.25, 0.45, 1, 0.1)
            highlight:SetAllPoints(contact)
            contact:SetHighlightTexture(highlight)

            local portrait = contact:CreateTexture(nil, "ARTWORK")
            portrait:SetTexture("Interface\\CHARACTERFRAME\\TemporaryPortrait-Female-NightElf")
            portrait:SetSize(32, 32)
            portrait:SetPoint("TOPLEFT", 6, -8)
            portrait:SetTexCoord(0.07, 0.93, 0.07, 0.93)

            local nameLabel = contact:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            nameLabel:SetPoint("TOPLEFT", portrait, "TOPRIGHT", 6, -2)
            nameLabel:SetText(shortName)

            local snippetLabel = contact:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            snippetLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -2)
            snippetLabel:SetWidth(120)
            snippetLabel:SetJustifyH("LEFT")
            snippetLabel:SetText(lastMessage:sub(1, 30))

            contact:SetScript("OnClick", function()
                Whispr.Messages:SetTarget(name)
            end)

            table.insert(toggles[category], contact)
            if not expanded then contact:Hide() end

            offsetY = offsetY - 54
        end
    end
    contactList:SetHeight(-offsetY + 10)
end

Whispr:RegisterModule("Contacts", Whispr.Contacts)