Whispr.EventFrame = CreateFrame("Frame")

function Whispr:RegisterEvent(event)
    Whispr.EventFrame:RegisterEvent(event)
end

Whispr.EventFrame:SetScript("OnEvent", function(_, event, ...)
    for _, module in pairs(Whispr.modules) do
        if module.OnEvent then
            module:OnEvent(event, ...)
        end
    end
end)
