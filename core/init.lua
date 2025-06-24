Whispr = {}
Whispr.modules = {}

function Whispr:RegisterModule(name, module)
    self.modules[name] = module
end

function Whispr:Init()
    for name, module in pairs(self.modules) do
        if module.OnInit then
            module:OnInit()
        end
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, event, addonName)
    if addonName == "Whispr" then
        Whispr:Init()
    end
end)
