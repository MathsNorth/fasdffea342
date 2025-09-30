-- SISTEMA DE LOGIN COM KEY (Horário de Brasília + Suporte PC/Mobile)
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local ZONA = "Horário de Brasília (UTC-3)"

-- calcula offset entre horário do servidor e UTC (segundos)
local function serverUTCOffset()
    return os.difftime(os.time(), os.time(os.date("!*t")))
end

-- converte uma tabela representando HORÁRIO DE BRASÍLIA para epoch UTC correto
local function epochUTCFromBrasilia(tbl)
    local server_offset = serverUTCOffset()
    local brasilia_offset = -3 * 3600 -- UTC-3
    return os.time(tbl) + (server_offset - brasilia_offset)
end

-- 🔑 CONFIGURAÇÃO DE KEYS
local expiraBrasilia = epochUTCFromBrasilia{
    year = 9999,
    month = 9,
    day = 30,
    hour = 23,
    min = 59,
    sec = 0
}

local Keys = {
    ["FUCKHAZE"] = { expira = expiraBrasilia }
}

-- GUI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "LoginSystem"

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 150)
Frame.Position = UDim2.new(0.5, -150, 0.5, -75)
Frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Frame.BorderSizePixel = 0
Frame.Visible = true

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1,0,0,40)
Title.BackgroundTransparency = 1
Title.Text = "🔑 Login Key System (BR)"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 20
Title.TextColor3 = Color3.fromRGB(255,255,255)

local TextBox = Instance.new("TextBox", Frame)
TextBox.Size = UDim2.new(1,-20,0,30)
TextBox.Position = UDim2.new(0,10,0,50)
TextBox.PlaceholderText = "Digite sua key..."
TextBox.BackgroundColor3 = Color3.fromRGB(45,45,45)
TextBox.TextColor3 = Color3.fromRGB(255,255,255)
TextBox.Text = ""
TextBox.ClearTextOnFocus = false

local Button = Instance.new("TextButton", Frame)
Button.Size = UDim2.new(1,-20,0,30)
Button.Position = UDim2.new(0,10,0,90)
Button.Text = "Login"
Button.BackgroundColor3 = Color3.fromRGB(70,0,0)
Button.TextColor3 = Color3.fromRGB(255,255,255)

local Status = Instance.new("TextLabel", Frame)
Status.Size = UDim2.new(1,0,0,20)
Status.Position = UDim2.new(0,0,1,-20)
Status.BackgroundTransparency = 1
Status.Text = "Aguardando..."
Status.TextColor3 = Color3.fromRGB(200,200,200)
Status.TextSize = 16

-- utils
local function trim(s)
    s = tostring(s or "")
    return s:match("^%s*(.-)%s*$")
end

local function findKeyEntry(input)
    local s = trim(input)
    for k, v in pairs(Keys) do
        if k:lower() == s:lower() then
            return k, v
        end
    end
    return nil, nil
end

local function setStatus(msg, color)
    Status.Text = msg
    Status.TextColor3 = color or Color3.fromRGB(200,200,200)
end

local function validarKey(input)
    local key, dados = findKeyEntry(input)
    if not key then
        return false, "❌ Key inválida", Color3.fromRGB(255,50,50)
    end
    if os.time() > dados.expira then
        return false, "⏰ Key expirada", Color3.fromRGB(255,150,0)
    end
    return true, "✅ Login autorizado (" .. ZONA .. ")", Color3.fromRGB(50,255,50)
end

-- URL correta conforme dispositivo
local function getScriptURL()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        -- Mobile
        return "https://raw.githubusercontent.com/MathsNorth/prncplmt/refs/heads/main/mthazemob.lua"
    else
        -- PC
        return "https://raw.githubusercontent.com/MathsNorth/prncplmt/refs/heads/main/mthazepc.lua"
    end
end

-- pós login
local function onLoginSuccess()
    local url = getScriptURL()
    print("🔗 Carregando script de:", url)

    local success, response = pcall(function()
        return game:HttpGetAsync(url)
    end)

    if not success then
        warn("❌ Falha ao baixar o script:", response)
        return
    end

    local func, err = loadstring(response)
    if not func then
        warn("❌ Erro ao carregar o script:", err)
        return
    end

    func()
end

-- clique do botão com anti-spam
local lastClick = 0
Button.MouseButton1Click:Connect(function()
    if tick() - lastClick < 2 then return end
    lastClick = tick()

    local raw = TextBox.Text
    local valido, msg, cor = validarKey(raw)
    setStatus(msg, cor)

    if valido then
        Frame.Visible = false
        print("🔓 Acesso liberado! Zona: " .. ZONA)
        onLoginSuccess()
    else
        TextBox.Text = "" -- limpa caso a key seja inválida
    end
end)
