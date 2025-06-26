Whispr.Messages = {}

Whispr.Messages.conversations = {}
Whispr.Messages.target = nil

function Whispr.Messages:OnInit()
    Whispr:RegisterEvent("CHAT_MSG_WHISPER")
end

function Whispr.Messages:LoadConversation(playerName)
    local chatArea = Whispr.Chat:GetChatArea()
    if not chatArea or not chatArea.scroll then return end

    chatArea.scroll:Clear()

    local messages = self.conversations[playerName] or {}
    for _, msg in ipairs(messages) do
        local sender = msg.fromPlayer and "|cff00ccffYou|r" or ("|cffffcc00" .. msg.sender .. "|r")
        local timestamp = msg.timestamp or "--:--"
        local line = string.format("[%s] %s: %s", timestamp, sender, msg.text)
        chatArea.scroll:AddMessage(line)
    end

    -- Scroll to bottom
    chatArea.scroll:ScrollToBottom()
end

function Whispr.Messages:OnEvent(event, msg, sender)
    if not self.conversations[sender] then
        self.conversations[sender] = {}
    end

    table.insert(self.conversations[sender], {
        sender = sender,
        text = msg,
        fromPlayer = false,
        timestamp = date("%H:%M")
    })

    local frame = Whispr.Chat:GetFrame()
    if not frame then
        Whispr.Chat:Create()
        frame = Whispr.Chat:GetFrame()
    end

    Whispr.Contacts:UpdateSidebar()

    if not frame:IsShown() or (frame:IsShown() and self.target ~= sender) then
        if Whispr.Notifications then
            Whispr.Notifications:ShowNotification(sender, msg)
        end
    end

    if frame:IsShown() and self.target == sender then
        self:LoadConversation(sender)
    end
end

function Whispr.Messages:SetTarget(playerName)
    self.target = playerName
    local frame = Whispr.Chat:GetFrame()
    if not frame then
        Whispr.Chat:Create()
        frame = Whispr.Chat:GetFrame()
    end

    local chatArea = Whispr.Chat:GetChatArea()
    if chatArea and chatArea.titleText then
        chatArea.titleText:SetText(("Talking to: |cff00ccff%s|r"):format(playerName))
    end

    self:LoadConversation(playerName)
    frame:Show()
end

function Whispr.Messages:GetConversations()
    return self.conversations
end

function Whispr.Messages:GetTarget()
    return self.target
end

function Whispr.Messages:GetConversation(playerName)
    return self.conversations[playerName] or {}
end

function Whispr.Messages:HasConversation(playerName)
    return self.conversations[playerName] ~= nil
end

function Whispr.Messages:GetLastMessage(playerName)
    local conversation = self.conversations[playerName]
    if conversation and #conversation > 0 then
        return conversation[#conversation]
    end
    return nil
end

-- Register the module
Whispr:RegisterModule("Messages", Whispr.Messages)