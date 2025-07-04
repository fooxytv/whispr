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

-- Add this to your Messages:SetTarget function in messages.lua

function Whispr.Messages:SetTarget(playerName)
    self.target = playerName
    
    -- Update the chat UI title
    if Whispr.Chat:GetChatArea() then
        Whispr.Chat:GetChatArea().titleText:SetText("Chat with " .. (playerName:match("^[^-]+") or playerName))
    end
    
    -- Clear unread count for this contact
    if self.conversations[playerName] then
        for _, message in ipairs(self.conversations[playerName]) do
            message.unread = false
        end
    end
    
    -- Update the contact list to show selection and refresh unread counts
    if Whispr.Contacts then
        Whispr.Contacts:SetSelectedContact(playerName)
    end
    
    -- Load the conversation messages
    self:LoadConversation(playerName)
end

-- Also update your message receiving function to mark messages as unread
-- Add this to wherever you handle incoming whispers

function Whispr.Messages:OnWhisperReceived(sender, message)
    if not self.conversations[sender] then
        self.conversations[sender] = {}
    end
    
    local isCurrentTarget = (sender == self.target)
    
    table.insert(self.conversations[sender], {
        sender = sender,
        text = message,
        fromPlayer = false,
        timestamp = date("%H:%M"),
        unread = not isCurrentTarget -- Mark as unread if not currently viewing this conversation
    })
    
    -- Update the sidebar to show new message
    if Whispr.Contacts then
        Whispr.Contacts:UpdateSidebar()
    end
    
    -- If this is the current conversation, load it to show the new message
    if isCurrentTarget then
        self:LoadConversation(sender)
    end
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