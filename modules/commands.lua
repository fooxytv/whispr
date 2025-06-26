Whispr.Commands = {}

function Whispr.Commands:OnInit()
    -- Register slash commands when addon loads
    self:RegisterSlashCommands()
end

function Whispr.Commands:RegisterSlashCommands()
    -- Primary command
    SLASH_WHISPR1 = "/whispr"
    SLASH_WHISPR2 = "/wp" -- Short version
    SLASH_WHISPR3 = "/whisper" -- Alternative

    SlashCmdList["WHISPR"] = function(msg)
        self:HandleCommand(msg)
    end
end

function Whispr.Commands:HandleCommand(msg)
    local args = {}
    for word in string.gmatch(msg, "%S+") do
        table.insert(args, string.lower(word))
    end

    local command = args[1] or ""

    if command == "" or command == "show" or command == "open" then
        -- Open the main chat window
        self:ShowChat()

    elseif command == "hide" or command == "close" then
        -- Hide the main chat window
        self:HideChat()

    elseif command == "toggle" then
        -- Toggle chat window visibility
        self:ToggleChat()

    elseif command == "tell" or command == "whisper" or command == "w" then
        -- Start a conversation with someone: /whispr tell PlayerName
        local playerName = args[2]
        if playerName then
            self:StartConversation(playerName)
        else
            print("|cffff6b6bWhispr:|r Usage: /whispr tell <playername>")
        end

    elseif command == "settings" or command == "config" then
        -- Open settings panel
        self:ShowSettings()

    elseif command == "clear" then
        -- Clear notifications
        if args[2] == "notifications" then
            self:ClearNotifications()
        else
            print("|cffff6b6bWhispr:|r Usage: /whispr clear notifications")
        end

    elseif command == "status" then
        -- Show addon status
        self:ShowStatus()

    elseif command == "help" then
        -- Show help
        self:ShowHelp()

    else
        -- Unknown command, show help
        print("|cffff6b6bWhispr:|r Unknown command '" .. command .. "'. Type /whispr help for available commands.")
    end
end

function Whispr.Commands:ShowChat()
    -- Ensure chat UI exists
    if not Whispr.Chat.frame then
        Whispr.Chat:Create()
    end

    Whispr.Chat:Show()
    print("|cff6bb6ffWhispr:|r Chat window opened.")
end

function Whispr.Commands:HideChat()
    if Whispr.Chat:IsShown() then
        Whispr.Chat:Hide()
        print("|cff6bb6ffWhispr:|r Chat window closed.")
    else
        print("|cffff6b6bWhispr:|r Chat window is not currently open.")
    end
end

function Whispr.Commands:ToggleChat()
    if Whispr.Chat:IsShown() then
        self:HideChat()
    else
        self:ShowChat()
    end
end

function Whispr.Commands:StartConversation(playerName)
    -- Capitalize first letter for consistency
    playerName = string.upper(string.sub(playerName, 1, 1)) .. string.lower(string.sub(playerName, 2))

    if Whispr.Messages and Whispr.Messages.SetTarget then
        Whispr.Messages:SetTarget(playerName)
        print("|cff6bb6ffWhispr:|r Started conversation with " .. playerName .. ".")
    else
        print("|cffff6b6bWhispr:|r Error: Messages module not available.")
    end
end

function Whispr.Commands:ShowSettings()
    -- Ensure chat UI exists first
    if not Whispr.Chat.frame then
        Whispr.Chat:Create()
    end

    -- Show chat window if hidden
    if not Whispr.Chat:IsShown() then
        Whispr.Chat:Show()
    end

    -- Toggle settings panel
    if Whispr.Settings and Whispr.Settings.ToggleSettings then
        if not Whispr.Settings.expanded then
            Whispr.Settings:ExpandSettings()
            print("|cff6bb6ffWhispr:|r Settings panel opened.")
        else
            print("|cff6bb6ffWhispr:|r Settings panel is already open.")
        end
    else
        print("|cffff6b6bWhispr:|r Error: Settings module not available.")
    end
end

function Whispr.Commands:ClearNotifications()
    if Whispr.Notifications and Whispr.Notifications.ClearAll then
        local count = Whispr.Notifications:GetActiveCount()
        Whispr.Notifications:ClearAll()
        print("|cff6bb6ffWhispr:|r Cleared " .. count .. " notification(s).")
    else
        print("|cffff6b6bWhispr:|r Error: Notifications module not available.")
    end
end

function Whispr.Commands:ShowStatus()
    local lines = {}
    table.insert(lines, "|cff6bb6ffWhispr Status:|r")

    -- Chat window status
    local chatStatus = Whispr.Chat:IsShown() and "|cff00ff00Open|r" or "|cffff0000Closed|r"
    table.insert(lines, "  Chat Window: " .. chatStatus)

    -- Settings panel status
    local settingsStatus = "Unknown"
    if Whispr.Settings then
        settingsStatus = Whispr.Settings.expanded and "|cff00ff00Open|r" or "|cffff0000Closed|r"
    end
    table.insert(lines, "  Settings Panel: " .. settingsStatus)

    -- Active conversations
    local conversationCount = 0
    if Whispr.Messages then
        local conversations = Whispr.Messages:GetConversations()
        for _ in pairs(conversations) do
            conversationCount = conversationCount + 1
        end
    end
    table.insert(lines, "  Active Conversations: |cffffff00" .. conversationCount .. "|r")

    -- Current target
    local currentTarget = "None"
    if Whispr.Messages and Whispr.Messages:GetTarget() then
        currentTarget = "|cffffff00" .. Whispr.Messages:GetTarget() .. "|r"
    end
    table.insert(lines, "  Current Chat: " .. currentTarget)

    -- Active notifications
    local notificationCount = 0
    if Whispr.Notifications then
        notificationCount = Whispr.Notifications:GetActiveCount()
    end
    table.insert(lines, "  Active Notifications: |cffffff00" .. notificationCount .. "|r")

    -- Settings
    local theme = "Unknown"
    if Whispr.Settings and Whispr.Settings:GetSetting("theme") then
        theme = "|cffffff00" .. Whispr.Settings:GetSetting("theme") .. "|r"
    end
    table.insert(lines, "  Theme: " .. theme)

    for _, line in ipairs(lines) do
        print(line)
    end
end

function Whispr.Commands:ShowHelp()
    local lines = {}
    table.insert(lines, "|cff6bb6ffWhispr Commands:|r")
    table.insert(lines, "  |cffffff00/whispr|r or |cffffff00/wp|r - Open chat window")
    table.insert(lines, "  |cffffff00/whispr show|r - Open chat window")
    table.insert(lines, "  |cffffff00/whispr hide|r - Hide chat window")
    table.insert(lines, "  |cffffff00/whispr toggle|r - Toggle chat window")
    table.insert(lines, "  |cffffff00/whispr tell <player>|r - Start conversation with player")
    table.insert(lines, "  |cffffff00/whispr settings|r - Open settings panel")
    table.insert(lines, "  |cffffff00/whispr clear notifications|r - Clear all notifications")
    table.insert(lines, "  |cffffff00/whispr status|r - Show addon status")
    table.insert(lines, "  |cffffff00/whispr help|r - Show this help")
    table.insert(lines, " ")
    table.insert(lines, "|cff99ff99Examples:|r")
    table.insert(lines, "  /wp - Quick open")
    table.insert(lines, "  /whispr tell Playername - Start chat")
    table.insert(lines, "  /wp settings - Open settings")

    for _, line in ipairs(lines) do
        print(line)
    end
end

-- Utility function to check if a player exists (optional enhancement)
function Whispr.Commands:ValidatePlayerName(playerName)
    -- You could add validation logic here
    -- For now, just check basic format
    if not playerName or playerName == "" then
        return false, "Player name cannot be empty"
    end

    if string.len(playerName) < 2 or string.len(playerName) > 12 then
        return false, "Player name must be 2-12 characters"
    end

    -- Check for valid characters (letters only for basic validation)
    if not string.match(playerName, "^[A-Za-z]+$") then
        return false, "Player name can only contain letters"
    end

    return true, nil
end

-- Auto-complete for player names (advanced feature)
function Whispr.Commands:GetPlayerSuggestions(partial)
    local suggestions = {}

    -- Add players from conversations
    if Whispr.Messages then
        local conversations = Whispr.Messages:GetConversations()
        for playerName in pairs(conversations) do
            local shortName = playerName:match("^[^-]+") or playerName
            if string.lower(shortName):find(string.lower(partial), 1, true) then
                table.insert(suggestions, shortName)
            end
        end
    end

    -- Could add more sources: guild members, friends, recent players, etc.

    return suggestions
end

-- Register the module
Whispr:RegisterModule("Commands", Whispr.Commands)