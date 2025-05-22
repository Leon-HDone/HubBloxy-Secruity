local StarterGui = game:GetService("StarterGui")


local sensitiveKeywords = {
    getgenv = "Zugriff auf globale Umgebung",
    getfenv = "Zugriff auf Funktionsumgebung",
    setfenv = "Manipulation der Umgebung",
    getrawmetatable = "Zugriff auf geschützte Metadaten",
    setreadonly = "Entsichern geschützter Tabellen",
    debug = "Debugging-API (z.B. Hooks oder Tracing)",
    hookfunction = "Funktion manipulieren",
    newcclosure = "Undurchsichtige Closures",
    iscclosure = "Prüft Closures",
    identifyexecutor = "Versucht deinen Executor herauszufinden",
    is_synapse_function = "Prüft auf Synapse-Funktion",
    syn = "Synapse-spezifischer Zugriff (z.B. Exploits)",
    HttpGet = "Webanfrage (GET)",
    HttpPost = "Webanfrage (POST)",
    request = "Custom Webrequest",
    queueonteleport = "Teleport-Injection",
    loadstring = "Führt dynamisch Text als Code aus",
    dofile = "Dateiausführung",
    collectgarbage = "Umgebungsanalyse"
}


local screenGui = Instance.new("ScreenGui", game.Players.LocalPlayer:WaitForChild("PlayerGui"))
screenGui.Name = "SandboxAnalyzerGUI"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 500, 0, 350)
frame.Position = UDim2.new(0.5, -250, 0.5, -175)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Sandbox & Analyzer"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextScaled = true

local inputBox = Instance.new("TextBox", frame)
inputBox.Size = UDim2.new(0.9, 0, 0.6, 0)
inputBox.Position = UDim2.new(0.05, 0, 0.1, 40)
inputBox.MultiLine = true
inputBox.ClearTextOnFocus = false
inputBox.TextWrapped = true
inputBox.PlaceholderText = "Hier deinen loadstring-Code einfügen"
inputBox.Font = Enum.Font.Code
inputBox.TextColor3 = Color3.fromRGB(230, 230, 230)
inputBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)

local analyzeBtn = Instance.new("TextButton", frame)
analyzeBtn.Size = UDim2.new(0.3, 0, 0, 40)
analyzeBtn.Position = UDim2.new(0.35, 0, 0.75, 0)
analyzeBtn.Text = "Analysieren & Sandbox"
analyzeBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
analyzeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
analyzeBtn.Font = Enum.Font.GothamBold
analyzeBtn.TextScaled = true


local function createSandbox()
    local env = {}
    -- Kopiere sichere Standardfunktionen
    for k, v in pairs(_G) do
        if not sensitiveKeywords[k] then
            env[k] = v
        end
    end
   
    env.math = math
    env.string = string
    env.table = table
    env.pairs = pairs
    env.ipairs = ipairs
    env.print = print
    env.pcall = pcall
    env.error = error
   
    for func, reason in pairs(sensitiveKeywords) do
        env[func] = function(...)
            warn("[SandboxAnalyzer] Nutzte sensible Funktion: " .. func .. " → " .. reason)
            return _G[func] and _G[func](...)
        end
    end
    return env
end


local function staticAnalyze(scriptText)
    local found = {}
    for keyword, _ in pairs(sensitiveKeywords) do
        if scriptText:lower():find(keyword:lower()) then
            table.insert(found, "⚠️ `" .. keyword .. "`")
        end
    end
    return found
end


analyzeBtn.MouseButton1Click:Connect(function()
    local code = inputBox.Text
    -- Statische Analyse
    local found = staticAnalyze(code)
    if #found > 0 then
        StarterGui:SetCore("SendNotification", {Title = "⚠️ Statisch erkannt", Text = table.concat(found, ", "), Duration = 5})
    else
        StarterGui:SetCore("SendNotification", {Title = "✅ Statisch passt", Text = "Keine offensichtlichen Keywords", Duration = 3})
    end
   
    local func, err = loadstring(code)
    if not func then
        warn("Fehler beim Parsen: ", err)
        return
    end
    setfenv(func, createSandbox())
    local ok, runtimeErr = pcall(func)
    if not ok then
        warn("Fehler zur Laufzeit: ", runtimeErr)
        StarterGui:SetCore("SendNotification", {Title = "❗ Laufzeitfehler", Text = runtimeErr, Duration = 5})
    else
        StarterGui:SetCore("SendNotification", {Title = "✅ Sandbox OK", Text = "Kein Crash", Duration = 3})
    end
end)
