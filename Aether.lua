--// AETHER v1.2 | Visuals + Combat | Delta Executor (phone-first)
--// Fix: ESP + Aimbot reworked, corner-box ESP, tracers, chams, crosshair, stats + target HUD

if getgenv().AetherLoaded then
    pcall(function()
        if getgenv().AetherGui then getgenv().AetherGui:Destroy() end
        if getgenv().AetherDrawings then
            for _,v in pairs(getgenv().AetherDrawings) do
                pcall(function() v:Remove() end)
            end
        end
        getgenv().AetherDrawings = {}
        if getgenv().AetherLoop then pcall(function() getgenv().AetherLoop:Disconnect() end) end
        if getgenv().AetherChams then
            for _,h in pairs(getgenv().AetherChams) do pcall(function() h:Destroy() end) end
        end
        getgenv().AetherChams = {}
    end)
end
getgenv().AetherLoaded = true
getgenv().AetherDrawings = {}
getgenv().AetherChams = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

local function cam()
    return workspace.CurrentCamera
end

--// Settings (defaults ON so it works right after execute)
getgenv().Aether = getgenv().Aether or {
    Box = true,
    Health = true,
    Name = true,
    Distance = true,
    Box3D = false,
    Tracer = true,
    HeadDot = true,
    Chams = true,
    Crosshair = true,
    Skeleton = true,
    Arrows = true,
    Hitbox = false,
    HitboxSize = 4,
    HitboxPart = "Head",
    Theme = "Purple",
    TeamCheck = false,
    Aimbot = true,
    ShowFOV = true,
    WallCheck = false,
    FOV = 180,
    Smoothness = 7,
    AimPart = "Head",
}
local S = getgenv().Aether
if type(S.FOV) ~= "number" or S.FOV < 60 then S.FOV = 180 end

local C = {
    Bg = Color3.fromRGB(16, 12, 27),
    Bg2 = Color3.fromRGB(22, 17, 38),
    Card = Color3.fromRGB(28, 22, 48),
    Accent = Color3.fromRGB(139, 92, 246),
    Accent2 = Color3.fromRGB(168, 85, 247),
    AccentDark = Color3.fromRGB(109, 40, 217),
    Text = Color3.fromRGB(240, 235, 255),
    Gray = Color3.fromRGB(150, 140, 180),
    Green = Color3.fromRGB(52, 211, 153),
    Red = Color3.fromRGB(248, 113, 113),
}

--// UI sync registry (for configs) + themes
local UIReg = {}
local function regSet(field, fn)
    if not field then return end
    UIReg[field] = UIReg[field] or {}
    table.insert(UIReg[field], fn)
end
local function applyReg(field, v)
    local list = UIReg[field]
    if list then for _, fn in ipairs(list) do pcall(fn, v) end end
end

local THEMES = {
    Purple = {Accent = Color3.fromRGB(139, 92, 246), Accent2 = Color3.fromRGB(168, 85, 247), Dark = Color3.fromRGB(109, 40, 217)},
    Blood  = {Accent = Color3.fromRGB(239, 68, 68),  Accent2 = Color3.fromRGB(248, 113, 113), Dark = Color3.fromRGB(127, 29, 29)},
    Cyan   = {Accent = Color3.fromRGB(34, 211, 238), Accent2 = Color3.fromRGB(103, 232, 249), Dark = Color3.fromRGB(14, 116, 144)},
    Lime   = {Accent = Color3.fromRGB(52, 211, 153), Accent2 = Color3.fromRGB(110, 231, 183), Dark = Color3.fromRGB(6, 95, 70)},
    Pink   = {Accent = Color3.fromRGB(236, 72, 153), Accent2 = Color3.fromRGB(249, 168, 212), Dark = Color3.fromRGB(131, 24, 67)},
}
getgenv().AetherApplyTheme = function(name, guiRefs)
    local t = THEMES[name] or THEMES.Purple
    C.Accent, C.Accent2, C.AccentDark = t.Accent, t.Accent2, t.Dark
    S.Theme = name
    pcall(function()
        local dr = getgenv().AetherDrawings
        if dr then
            if dr[1] then dr[1].Color = t.Accent end
            if dr[2] then dr[2].Color = t.Accent end
        end
    end)
    if guiRefs then
        pcall(function()
            guiRefs.MainStroke.Color = t.Accent
            guiRefs.SideStroke.Color = t.Accent
            guiRefs.ContentStroke.Color = t.Accent
            guiRefs.TargetStroke.Color = t.Accent
            guiRefs.LogoDot.BackgroundColor3 = t.Accent
            guiRefs.StatsLbl.TextColor3 = t.Accent2
            guiRefs.LogoBtnStroke.Color = t.Accent
            guiRefs.LogoBtnTxt.TextColor3 = t.Accent2
        end)
    end
    -- recolor live ESP drawings (table linked after ESP init)
    pcall(function()
        local reg = getgenv().AetherESP
        if reg then
            for _, e in pairs(reg) do
                if e.corners then for _, l in ipairs(e.corners) do if l then l.Color = t.Accent2 end end end
                if e.tracer then e.tracer.Color = t.Accent end
                if e.dot then e.dot.Color = t.Accent2 end
                if e.lines3d then for _, l in ipairs(e.lines3d) do if l then l.Color = t.Accent2 end end end
                if e.skeles then for _, l in ipairs(e.skeles) do if l then l.Color = t.Accent2 end end end
                if e.arrow then for _, l in ipairs(e.arrow) do if l then l.Color = t.Accent end end end
            end
        end
    end)
end
local function applyTheme(name, guiRefs)
    return getgenv().AetherApplyTheme(name, guiRefs)
end
-- early: tint C before UI is built (saved theme survives via getgenv)
pcall(function() getgenv().AetherApplyTheme(S.Theme or "Purple", nil) end)

local function getParent()
    local ok, h = pcall(function() return gethui() end)
    if ok and h then return h end
    local ok2, h2 = pcall(function() return get_hidden_gui and get_hidden_gui() end)
    if ok2 and h2 then return h2 end
    return game:GetService("CoreGui")
end

do local old = getParent():FindFirstChild("AetherGui") if old then old:Destroy() end end

local Gui = Instance.new("ScreenGui")
Gui.Name = "AetherGui"
Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 999
Gui.Parent = getParent()
getgenv().AetherGui = Gui

--// Drawings helpers (safe for Delta)
local function track(d)
    table.insert(getgenv().AetherDrawings, d)
    return d
end
local function safeDraw(kind)
    local ok, d = pcall(function() return Drawing.new(kind) end)
    if ok and d then return track(d) end
    return nil
end

local FOVCircle = safeDraw("Circle")
if FOVCircle then
    FOVCircle.Thickness = 2
    FOVCircle.NumSides = 64
    FOVCircle.Filled = false
    pcall(function() FOVCircle.Transparency = 1 end)
    FOVCircle.Color = Color3.fromRGB(139, 92, 246)
    FOVCircle.Visible = false
end
local FOVFill = safeDraw("Circle")
if FOVFill then
    FOVFill.Thickness = 0
    FOVFill.NumSides = 64
    FOVFill.Filled = true
    pcall(function() FOVFill.Transparency = 0.08 end)
    FOVFill.Color = Color3.fromRGB(139, 92, 246)
    FOVFill.Visible = false
end
local CH = {}
for i = 1, 4 do
    local l = safeDraw("Line")
    if l then
        l.Thickness = 2
        l.Color = C.Accent2
        pcall(function() l.Transparency = 1 end)
        l.Visible = false
    end
    CH[i] = l
end
local CHDot = safeDraw("Circle")
if CHDot then
    CHDot.Filled = true
    CHDot.Thickness = 0
    CHDot.NumSides = 12
    pcall(function() CHDot.Transparency = 1 end)
    CHDot.Color = Color3.new(1,1,1)
    CHDot.Visible = false
    pcall(function() CHDot.Radius = 3 end)
end

--// ============ GUI ============
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.new(0.5, 0, 0.5, 0)
Main.Size = UDim2.new(0, 0, 0, 0)
Main.BackgroundColor3 = C.Bg
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Visible = true
Main.Parent = Gui
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = Main
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = C.Accent
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.3
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = Main
local MainGrad = Instance.new("UIGradient")
MainGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 15, 34)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 19, 58)),
}
MainGrad.Rotation = 45
MainGrad.Parent = Main
local Shadow = Instance.new("ImageLabel")
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
Shadow.Size = UDim2.new(1, 60, 1, 60)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://6014261993"
Shadow.ImageColor3 = C.Accent
Shadow.ImageTransparency = 0.75
Shadow.ZIndex = 0
Shadow.Parent = Main

local Top = Instance.new("Frame")
Top.Name = "Top"
Top.Size = UDim2.new(1, 0, 0, 52)
Top.BackgroundColor3 = C.Bg2
Top.BorderSizePixel = 0
Top.Parent = Main
local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 14)
TopCorner.Parent = Top
local TopFix = Instance.new("Frame")
TopFix.Position = UDim2.new(0, 0, 1, -14)
TopFix.Size = UDim2.new(1, 0, 0, 14)
TopFix.BackgroundColor3 = C.Bg2
TopFix.BorderSizePixel = 0
TopFix.Parent = Top

local LogoDot = Instance.new("Frame")
LogoDot.Position = UDim2.new(0, 14, 0.5, -11)
LogoDot.Size = UDim2.new(0, 22, 0, 22)
LogoDot.BackgroundColor3 = C.Accent
LogoDot.BorderSizePixel = 0
LogoDot.Parent = Top
local LogoDotC = Instance.new("UICorner")
LogoDotC.CornerRadius = UDim.new(0, 7)
LogoDotC.Parent = LogoDot
local LogoDotG = Instance.new("UIGradient")
LogoDotG.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, C.Accent2),
    ColorSequenceKeypoint.new(1, C.AccentDark),
}
LogoDotG.Rotation = 45
LogoDotG.Parent = LogoDot
local LogoTxt = Instance.new("TextLabel")
LogoTxt.Size = UDim2.new(1, 0, 1, 0)
LogoTxt.BackgroundTransparency = 1
LogoTxt.Text = "A"
LogoTxt.Font = Enum.Font.GothamBlack
LogoTxt.TextSize = 14
LogoTxt.TextColor3 = Color3.new(1,1,1)
LogoTxt.Parent = LogoDot

local Title = Instance.new("TextLabel")
Title.Position = UDim2.new(0, 44, 0, 6)
Title.Size = UDim2.new(0, 200, 0, 22)
Title.BackgroundTransparency = 1
Title.Text = "AETHER"
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = C.Text
Title.Parent = Top
local Sub = Instance.new("TextLabel")
Sub.Position = UDim2.new(0, 45, 0, 26)
Sub.Size = UDim2.new(0, 220, 0, 14)
Sub.BackgroundTransparency = 1
Sub.Text = "v1.2  •  phone ready"
Sub.Font = Enum.Font.Gotham
Sub.TextSize = 11
Sub.TextXAlignment = Enum.TextXAlignment.Left
Sub.TextColor3 = C.Gray
Sub.Parent = Top

local CloseBtn = Instance.new("TextButton")
CloseBtn.AnchorPoint = Vector2.new(1, 0.5)
CloseBtn.Position = UDim2.new(1, -12, 0.5, 0)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.BackgroundColor3 = Color3.fromRGB(45, 28, 75)
CloseBtn.Text = "—"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.TextColor3 = C.Text
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Top
local CloseC = Instance.new("UICorner")
CloseC.CornerRadius = UDim.new(0, 8)
CloseC.Parent = CloseBtn

-- target HUD pill: shows locked enemy (new cool thing)
local TargetPill = Instance.new("Frame")
TargetPill.Position = UDim2.new(0, 154, 0, 64)
TargetPill.Size = UDim2.new(1, -166, 0, 26)
TargetPill.BackgroundColor3 = Color3.fromRGB(38, 29, 64)
TargetPill.BorderSizePixel = 0
TargetPill.Parent = Main
local TargetPillC = Instance.new("UICorner")
TargetPillC.CornerRadius = UDim.new(0, 8)
TargetPillC.Parent = TargetPill
local TargetStroke = Instance.new("UIStroke")
TargetStroke.Color = C.Accent
TargetStroke.Transparency = 0.6
TargetStroke.Thickness = 1
TargetStroke.Parent = TargetPill
local TargetDot = Instance.new("Frame")
TargetDot.AnchorPoint = Vector2.new(0, 0.5)
TargetDot.Position = UDim2.new(0, 10, 0.5, 0)
TargetDot.Size = UDim2.new(0, 8, 0, 8)
TargetDot.BackgroundColor3 = C.Red
TargetDot.BorderSizePixel = 0
TargetDot.Parent = TargetPill
local TargetDotC = Instance.new("UICorner")
TargetDotC.CornerRadius = UDim.new(1, 0)
TargetDotC.Parent = TargetDot
local TargetLbl = Instance.new("TextLabel")
TargetLbl.Position = UDim2.new(0, 26, 0, 0)
TargetLbl.Size = UDim2.new(1, -32, 1, 0)
TargetLbl.BackgroundTransparency = 1
TargetLbl.Text = "TARGET: searching..."
TargetLbl.Font = Enum.Font.GothamBold
TargetLbl.TextSize = 11
TargetLbl.TextXAlignment = Enum.TextXAlignment.Left
TargetLbl.TextTruncate = Enum.TextTruncate.AtEnd
TargetLbl.TextColor3 = C.Gray
TargetLbl.Parent = TargetPill

-- side tabs
local Side = Instance.new("Frame")
Side.Position = UDim2.new(0, 12, 0, 64)
Side.Size = UDim2.new(0, 132, 1, -116)
Side.BackgroundColor3 = C.Card
Side.BorderSizePixel = 0
Side.Parent = Main
local SideC = Instance.new("UICorner")
SideC.CornerRadius = UDim.new(0, 10)
SideC.Parent = Side
local SideStroke = Instance.new("UIStroke")
SideStroke.Color = C.Accent
SideStroke.Transparency = 0.75
SideStroke.Thickness = 1
SideStroke.Parent = Side
local SidePad = Instance.new("UIPadding")
SidePad.PaddingTop = UDim.new(0, 8)
SidePad.PaddingLeft = UDim.new(0, 8)
SidePad.PaddingRight = UDim.new(0, 8)
SidePad.Parent = Side
local SideList = Instance.new("UIListLayout")
SideList.Padding = UDim.new(0, 8)
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Parent = Side

local function makeTabBtn(text, icon, order)
    local b = Instance.new("TextButton")
    b.LayoutOrder = order
    b.Size = UDim2.new(1, 0, 0, 40)
    b.BackgroundColor3 = Color3.fromRGB(38, 29, 64)
    b.Text = ""
    b.AutoButtonColor = false
    b.Parent = Side
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 8)
    cc.Parent = b
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -12, 1, 0)
    l.Position = UDim2.new(0, 12, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = icon .. "  " .. text
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = C.Gray
    l.Parent = b
    return b
end
local TabVisuals = makeTabBtn("Visuals", "◉", 1)
local TabCombat = makeTabBtn("Combat", "✛", 2)
local TabPlayers = makeTabBtn("Players", "☺", 3)
local TabSettings = makeTabBtn("Settings", "⚙", 4)
local VerLbl = Instance.new("TextLabel")
VerLbl.LayoutOrder = 99
VerLbl.Size = UDim2.new(1, 0, 0, 16)
VerLbl.BackgroundTransparency = 1
VerLbl.Text = "aether v1.2"
VerLbl.Font = Enum.Font.Gotham
VerLbl.TextSize = 10
VerLbl.TextColor3 = C.Gray
VerLbl.Parent = Side

-- content area
local Content = Instance.new("Frame")
Content.Position = UDim2.new(0, 154, 0, 98)
Content.Size = UDim2.new(1, -166, 1, -150)
Content.BackgroundColor3 = C.Card
Content.BorderSizePixel = 0
Content.Parent = Main
local ContentC = Instance.new("UICorner")
ContentC.CornerRadius = UDim.new(0, 10)
ContentC.Parent = Content
local ContentStroke = Instance.new("UIStroke")
ContentStroke.Color = C.Accent
ContentStroke.Transparency = 0.75
ContentStroke.Thickness = 1
ContentStroke.Parent = Content

-- stats footer (new cool thing: live FPS / ping / players)
local StatsBar = Instance.new("Frame")
StatsBar.AnchorPoint = Vector2.new(0, 1)
StatsBar.Position = UDim2.new(0, 12, 1, -12)
StatsBar.Size = UDim2.new(1, -24, 0, 26)
StatsBar.BackgroundColor3 = Color3.fromRGB(38, 29, 64)
StatsBar.BorderSizePixel = 0
StatsBar.Parent = Main
local StatsBarC = Instance.new("UICorner")
StatsBarC.CornerRadius = UDim.new(0, 8)
StatsBarC.Parent = StatsBar
local StatsLbl = Instance.new("TextLabel")
StatsLbl.Size = UDim2.new(1, -16, 1, 0)
StatsLbl.Position = UDim2.new(0, 8, 0, 0)
StatsLbl.BackgroundTransparency = 1
StatsLbl.Text = "FPS --  •  PING --  •  PLAYERS --"
StatsLbl.Font = Enum.Font.GothamBold
StatsLbl.TextSize = 11
StatsLbl.TextXAlignment = Enum.TextXAlignment.Left
StatsLbl.TextTruncate = Enum.TextTruncate.AtEnd
StatsLbl.TextColor3 = C.Accent2
StatsLbl.Parent = StatsBar

-- pages (created separately, NOT cloned -> old clone bug removed)
local function makePage(visible)
    local pg = Instance.new("ScrollingFrame")
    pg.Size = UDim2.new(1, 0, 1, 0)
    pg.BackgroundTransparency = 1
    pg.BorderSizePixel = 0
    pg.ScrollBarThickness = 3
    pg.ScrollBarImageColor3 = C.Accent
    pg.CanvasSize = UDim2.new(0, 0, 0, 0)
    pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pg.Visible = visible
    pg.Parent = Content
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent = pg
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = pg
    return pg
end
local PageVisuals = makePage(true)
local PageCombat = makePage(false)
local PagePlayers = makePage(false)
local PageSettings = makePage(false)

local function sectionTitle(parent, text, order)
    local t = Instance.new("TextLabel")
    t.LayoutOrder = order
    t.Size = UDim2.new(1, 0, 0, 20)
    t.BackgroundTransparency = 1
    t.Text = text:upper()
    t.Font = Enum.Font.GothamBold
    t.TextSize = 11
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextColor3 = C.Accent2
    t.Parent = parent
    return t
end

--// FIX: single-fire toggle (old version toggled twice on phone -> looked dead)
local function createToggle(parent, text, default, order, cb, field)
    local f = Instance.new("Frame")
    f.LayoutOrder = order
    f.Size = UDim2.new(1, 0, 0, 42)
    f.BackgroundColor3 = Color3.fromRGB(38, 29, 64)
    f.BorderSizePixel = 0
    f.Parent = parent
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 8)
    fc.Parent = f
    local l = Instance.new("TextLabel")
    l.Position = UDim2.new(0, 12, 0, 0)
    l.Size = UDim2.new(1, -64, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = C.Text
    l.Parent = f
    local sw = Instance.new("TextButton")
    sw.AnchorPoint = Vector2.new(1, 0.5)
    sw.Position = UDim2.new(1, -10, 0.5, 0)
    sw.Size = UDim2.new(0, 44, 0, 22)
    sw.BackgroundColor3 = default and C.Accent or Color3.fromRGB(55, 48, 80)
    sw.Text = ""
    sw.AutoButtonColor = false
    sw.Parent = f
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(1, 0)
    sc.Parent = sw
    local knob = Instance.new("Frame")
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = default and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    knob.Parent = sw
    local kc = Instance.new("UICorner")
    kc.CornerRadius = UDim.new(1, 0)
    kc.Parent = knob
    local state = default
    local busy = false
    local function refresh(anim)
        local goalSw = {BackgroundColor3 = state and C.Accent or Color3.fromRGB(55, 48, 80)}
        local goalKnob = {Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)}
        if anim then
            TweenService:Create(sw, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goalSw):Play()
            TweenService:Create(knob, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), goalKnob):Play()
        else
            sw.BackgroundColor3 = goalSw.BackgroundColor3
            knob.Position = goalKnob.Position
        end
    end
    local function flip()
        if busy then return end
        busy = true
        state = not state
        refresh(true)
        pcall(cb, state)
        task.delay(0.15, function() busy = false end)
    end
    sw.Activated:Connect(flip)
    if field then
        regSet(field, function(v)
            state = (v == true)
            refresh(true)
            pcall(cb, state)
        end)
    end
    return f
end

local function createSlider(parent, text, min, max, default, order, cb, field)
    local f = Instance.new("Frame")
    f.LayoutOrder = order
    f.Size = UDim2.new(1, 0, 0, 58)
    f.BackgroundColor3 = Color3.fromRGB(38, 29, 64)
    f.BorderSizePixel = 0
    f.Parent = parent
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 8)
    cc.Parent = f
    local l = Instance.new("TextLabel")
    l.Position = UDim2.new(0, 12, 0, 6)
    l.Size = UDim2.new(0.6, 0, 0, 18)
    l.BackgroundTransparency = 1
    l.Text = text
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = C.Text
    l.Parent = f
    local val = Instance.new("TextLabel")
    val.AnchorPoint = Vector2.new(1, 0)
    val.Position = UDim2.new(1, -12, 0, 6)
    val.Size = UDim2.new(0, 60, 0, 18)
    val.BackgroundTransparency = 1
    val.Text = tostring(default)
    val.Font = Enum.Font.GothamBold
    val.TextSize = 13
    val.TextXAlignment = Enum.TextXAlignment.Right
    val.TextColor3 = C.Accent2
    val.Parent = f
    local bar = Instance.new("TextButton")
    bar.Position = UDim2.new(0, 12, 0, 34)
    bar.Size = UDim2.new(1, -24, 0, 14)
    bar.BackgroundColor3 = Color3.fromRGB(55, 48, 80)
    bar.BorderSizePixel = 0
    bar.Text = ""
    bar.AutoButtonColor = false
    bar.Parent = f
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(1, 0)
    bc.Parent = bar
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = C.Accent
    fill.BorderSizePixel = 0
    fill.Parent = bar
    local fcc = Instance.new("UICorner")
    fcc.CornerRadius = UDim.new(1, 0)
    fcc.Parent = fill
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, C.Accent),
        ColorSequenceKeypoint.new(1, C.Accent2),
    }
    grad.Parent = fill
    local dragging = false
    local function setFromX(x)
        local absPos = bar.AbsolutePosition.X
        local absSize = math.max(bar.AbsoluteSize.X, 1)
        local a = math.clamp((x - absPos) / absSize, 0, 1)
        local v = math.floor(min + (max - min) * a)
        val.Text = tostring(v)
        fill.Size = UDim2.new(a, 0, 1, 0)
        pcall(cb, v)
    end
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    if field then
        regSet(field, function(v)
            v = math.clamp(tonumber(v) or default, min, max)
            val.Text = tostring(math.floor(v))
            fill.Size = UDim2.new((v - min) / (max - min), 0, 1, 0)
            pcall(cb, math.floor(v))
        end)
    end
    return f
end

local function createPartSelector(parent, order, title, parts, getCur, onPick, field)
    local f = Instance.new("Frame")
    f.LayoutOrder = order
    f.Size = UDim2.new(1, 0, 0, 58)
    f.BackgroundColor3 = Color3.fromRGB(38, 29, 64)
    f.BorderSizePixel = 0
    f.Parent = parent
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 8)
    cc.Parent = f
    local l = Instance.new("TextLabel")
    l.Position = UDim2.new(0, 12, 0, 6)
    l.Size = UDim2.new(1, -24, 0, 16)
    l.BackgroundTransparency = 1
    l.Text = title
    l.Font = Enum.Font.GothamSemibold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = C.Text
    l.Parent = f
    local row = Instance.new("Frame")
    row.Position = UDim2.new(0, 12, 0, 28)
    row.Size = UDim2.new(1, -24, 0, 22)
    row.BackgroundTransparency = 1
    row.Parent = f
    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Horizontal
    list.Padding = UDim.new(0, 6)
    list.Parent = row
    local btns = {}
    local function paint(cur)
        for pp, bb in pairs(btns) do
            TweenService:Create(bb, TweenInfo.new(0.2), {BackgroundColor3 = (pp == cur) and C.Accent or Color3.fromRGB(55, 48, 80)}):Play()
        end
    end
    for _, p in ipairs(parts) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1 / #parts, -6, 1, 0)
        b.BackgroundColor3 = (getCur() == p) and C.Accent or Color3.fromRGB(55, 48, 80)
        b.Text = p == "HumanoidRootPart" and "Root" or p
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.TextColor3 = Color3.new(1,1,1)
        b.AutoButtonColor = false
        b.Parent = row
        local bcc = Instance.new("UICorner")
        bcc.CornerRadius = UDim.new(0, 6)
        bcc.Parent = b
        b.Activated:Connect(function()
            onPick(p)
            paint(p)
        end)
        btns[p] = b
    end
    if field then
        regSet(field, function(v)
            onPick(v)
            paint(v)
        end)
    end
    return f
end

local function createAimPartSelector(parent, order)
    return createPartSelector(parent, order, "Aim Part", {"Head", "HumanoidRootPart", "Torso"},
        function() return S.AimPart end,
        function(p) S.AimPart = p end, "AimPart")
end

--// Hitbox expander system (client-side)
local HitboxOrig = {}
local function hitboxTargets()
    local out = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local ch = plr.Character
            if ch then
                local okTeam = true
                if S.TeamCheck and plr.Team ~= nil and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team then
                    okTeam = false
                end
                if okTeam then
                    local part = ch:FindFirstChild(S.HitboxPart or "Head") or ch:FindFirstChild("Head")
                    if part and part:IsA("BasePart") then
                        table.insert(out, {plr = plr, ch = ch, part = part})
                    end
                end
            end
        end
    end
    return out
end
local function applyHitboxes()
    if not S.Hitbox then return end
    local sz = math.clamp(tonumber(S.HitboxSize) or 4, 2, 12)
    for _, t in ipairs(hitboxTargets()) do
        pcall(function()
            local key = t.ch:GetDebugId()
            if HitboxOrig[key] == nil then
                HitboxOrig[key] = {Size = t.part.Size, Trans = t.part.Transparency, CanCollide = t.part.CanCollide}
            end
            t.part.Size = Vector3.new(sz, sz, sz)
            t.part.Transparency = 0.5
            t.part.CanCollide = false
        end)
    end
end
local function restoreHitboxes()
    for _, t in ipairs(hitboxTargets()) do
        pcall(function()
            local key = t.ch:GetDebugId()
            local o = HitboxOrig[key]
            if o then
                t.part.Size = o.Size
                t.part.Transparency = o.Trans
                t.part.CanCollide = o.CanCollide
            end
        end)
    end
end
task.spawn(function()
    while getgenv().AetherLoaded do
        task.wait(0.7)
        pcall(function()
            if S.Hitbox then applyHitboxes() end
        end)
    end
end)

--// Configs (Delta file IO with memory fallback)
local MemConfigs = getgenv().AetherMemConfigs or {}
getgenv().AetherMemConfigs = MemConfigs
local CONFIG_FIELDS = {"Box","Health","Name","Distance","Box3D","Tracer","HeadDot","Chams","Crosshair","Skeleton","Arrows","TeamCheck","Aimbot","ShowFOV","WallCheck","Hitbox","FOV","Smoothness","AimPart","HitboxSize","HitboxPart","Theme"}
local function configSnapshot()
    local t = {}
    for _, k in ipairs(CONFIG_FIELDS) do t[k] = S[k] end
    return t
end
local function configApply(t)
    if type(t) ~= "table" then return false end
    for _, k in ipairs(CONFIG_FIELDS) do
        if t[k] ~= nil then S[k] = t[k] end
    end
    -- theme first so toggles repaint with the right accent
    pcall(function()
        local gr = getgenv().AetherGuiRefs
        if t.Theme then getgenv().AetherApplyTheme(t.Theme, gr) end
    end)
    for _, k in ipairs(CONFIG_FIELDS) do
        if t[k] ~= nil and k ~= "Theme" then applyReg(k, t[k]) end
    end
    if not S.Hitbox then pcall(restoreHitboxes) end
    return true
end
local function configSave(slot)
    local data = configSnapshot()
    MemConfigs[slot] = data
    pcall(function()
        local js = game:GetService("HttpService"):JSONEncode(data)
        if writefile then writefile("AetherCfg" .. tostring(slot) .. ".json", js) end
    end)
    return true
end
local function configLoad(slot)
    if MemConfigs[slot] then return configApply(MemConfigs[slot]) end
    local ok, content = pcall(function()
        if readfile and isfile and isfile("AetherCfg" .. tostring(slot) .. ".json") then
            return readfile("AetherCfg" .. tostring(slot) .. ".json")
        end
        return nil
    end)
    if ok and content then
        local ok2, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(content)
        end)
        if ok2 and data then
            MemConfigs[slot] = data
            return configApply(data)
        end
    end
    return false
end

--// Build Visuals page
sectionTitle(PageVisuals, "ESP - boxes", 1)
createToggle(PageVisuals, "Corner Box", S.Box, 2, function(v) S.Box = v end, "Box")
createToggle(PageVisuals, "Health Bar", S.Health, 3, function(v) S.Health = v end, "Health")
createToggle(PageVisuals, "Name", S.Name, 4, function(v) S.Name = v end, "Name")
createToggle(PageVisuals, "Distance", S.Distance, 5, function(v) S.Distance = v end, "Distance")
createToggle(PageVisuals, "3D Box", S.Box3D, 6, function(v) S.Box3D = v end, "Box3D")
sectionTitle(PageVisuals, "ESP - extras", 7)
createToggle(PageVisuals, "Tracer (line)", S.Tracer, 8, function(v) S.Tracer = v end, "Tracer")
createToggle(PageVisuals, "Head Dot", S.HeadDot, 9, function(v) S.HeadDot = v end, "HeadDot")
createToggle(PageVisuals, "Skeleton", S.Skeleton, 10, function(v) S.Skeleton = v end, "Skeleton")
createToggle(PageVisuals, "Off-screen Arrows", S.Arrows, 11, function(v) S.Arrows = v end, "Arrows")
createToggle(PageVisuals, "Chams (purple glow)", S.Chams, 12, function(v)
    S.Chams = v
    if not v then
        for _,h in pairs(getgenv().AetherChams) do pcall(function() h.Enabled = false end) end
    end
end, "Chams")
createToggle(PageVisuals, "Crosshair", S.Crosshair, 13, function(v) S.Crosshair = v end, "Crosshair")
sectionTitle(PageVisuals, "Filters", 14)
createToggle(PageVisuals, "Team Check", S.TeamCheck, 15, function(v) S.TeamCheck = v end, "TeamCheck")

--// Build Combat page
sectionTitle(PageCombat, "Aimbot (auto phone)", 1)
createToggle(PageCombat, "Aimbot Auto", S.Aimbot, 2, function(v) S.Aimbot = v end, "Aimbot")
createToggle(PageCombat, "Draw FOV (always)", S.ShowFOV, 3, function(v) S.ShowFOV = v end, "ShowFOV")
createToggle(PageCombat, "Wall Check", S.WallCheck, 4, function(v) S.WallCheck = v end, "WallCheck")
createToggle(PageCombat, "Team Check (aim)", S.TeamCheck, 5, function(v) S.TeamCheck = v end, "TeamCheck")
sectionTitle(PageCombat, "Tuning", 6)
createSlider(PageCombat, "FOV Size", 60, 600, S.FOV, 7, function(v) S.FOV = v end, "FOV")
createSlider(PageCombat, "Smoothness", 1, 30, S.Smoothness, 8, function(v) S.Smoothness = v end, "Smoothness")
createAimPartSelector(PageCombat, 9)
sectionTitle(PageCombat, "Hitbox expander", 10)
createToggle(PageCombat, "Big Head Hitbox", S.Hitbox, 11, function(v) S.Hitbox = v if not v then restoreHitboxes() end end, "Hitbox")
createSlider(PageCombat, "Hitbox Size", 2, 12, S.HitboxSize or 4, 12, function(v) S.HitboxSize = v end, "HitboxSize")
createPartSelector(PageCombat, 13, "Hitbox Part", {"Head", "HumanoidRootPart", "Torso"},
    function() return S.HitboxPart or "Head" end,
    function(p) S.HitboxPart = p end, "HitboxPart")

--// Build Players page (tap to teleport)
sectionTitle(PagePlayers, "Players - tap to TP", 1)
local TPInfo = Instance.new("TextLabel")
TPInfo.LayoutOrder = 2
TPInfo.Size = UDim2.new(1, 0, 0, 18)
TPInfo.BackgroundTransparency = 1
TPInfo.Text = "tap a row to teleport"
TPInfo.Font = Enum.Font.Gotham
TPInfo.TextSize = 11
TPInfo.TextXAlignment = Enum.TextXAlignment.Left
TPInfo.TextColor3 = C.Gray
TPInfo.Parent = PagePlayers
local PlayerList = Instance.new("Frame")
PlayerList.LayoutOrder = 3
PlayerList.Size = UDim2.new(1, 0, 0, 220)
PlayerList.BackgroundTransparency = 1
PlayerList.Parent = PagePlayers
local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 6)
PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlayerListLayout.Parent = PlayerList

--// Build Settings page (configs + themes)
sectionTitle(PageSettings, "Configs", 1)
local function createConfigRow(slot, order)
    local f = Instance.new("Frame")
    f.LayoutOrder = order
    f.Size = UDim2.new(1, 0, 0, 42)
    f.BackgroundColor3 = Color3.fromRGB(38, 29, 64)
    f.BorderSizePixel = 0
    f.Parent = PageSettings
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 8)
    fc.Parent = f
    local l = Instance.new("TextLabel")
    l.Position = UDim2.new(0, 12, 0, 0)
    l.Size = UDim2.new(0, 80, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = "Slot " .. tostring(slot)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = C.Text
    l.Parent = f
    local save = Instance.new("TextButton")
    save.AnchorPoint = Vector2.new(1, 0.5)
    save.Position = UDim2.new(0.62, 0, 0.5, 0)
    save.Size = UDim2.new(0, 62, 0, 24)
    save.BackgroundColor3 = Color3.fromRGB(55, 48, 80)
    save.Text = "SAVE"
    save.Font = Enum.Font.GothamBold
    save.TextSize = 11
    save.TextColor3 = Color3.new(1,1,1)
    save.AutoButtonColor = false
    save.Parent = f
    local sc1 = Instance.new("UICorner")
    sc1.CornerRadius = UDim.new(0, 6)
    sc1.Parent = save
    local load = Instance.new("TextButton")
    load.AnchorPoint = Vector2.new(1, 0.5)
    load.Position = UDim2.new(1, -10, 0.5, 0)
    load.Size = UDim2.new(0, 62, 0, 24)
    load.BackgroundColor3 = C.Accent
    load.Text = "LOAD"
    load.Font = Enum.Font.GothamBold
    load.TextSize = 11
    load.TextColor3 = Color3.new(1,1,1)
    load.AutoButtonColor = false
    load.Parent = f
    local sc2 = Instance.new("UICorner")
    sc2.CornerRadius = UDim.new(0, 6)
    sc2.Parent = load
    local note = f:FindFirstChildOfClass("TextLabel")
    save.Activated:Connect(function()
        configSave(slot)
        l.Text = "Slot " .. tostring(slot) .. " ✓"
        task.delay(1, function() l.Text = "Slot " .. tostring(slot) end)
    end)
    load.Activated:Connect(function()
        local ok = configLoad(slot)
        l.Text = ok and ("Slot " .. tostring(slot) .. " ✓") or ("Slot " .. tostring(slot) .. " ✗")
        task.delay(1, function() l.Text = "Slot " .. tostring(slot) end)
    end)
    return f
end
createConfigRow(1, 2)
createConfigRow(2, 3)
createConfigRow(3, 4)
sectionTitle(PageSettings, "Theme", 5)
local ThemeRow = Instance.new("Frame")
ThemeRow.LayoutOrder = 6
ThemeRow.Size = UDim2.new(1, 0, 0, 64)
ThemeRow.BackgroundColor3 = Color3.fromRGB(38, 29, 64)
ThemeRow.BorderSizePixel = 0
ThemeRow.Parent = PageSettings
local ThemeRowC = Instance.new("UICorner")
ThemeRowC.CornerRadius = UDim.new(0, 8)
ThemeRowC.Parent = ThemeRow
local ThemeGrid = Instance.new("UIGridLayout")
ThemeGrid.CellSize = UDim2.new(0.33, -8, 0, 24)
ThemeGrid.CellPadding = UDim2.new(0, 6, 0, 6)
ThemeGrid.SortOrder = Enum.SortOrder.LayoutOrder
ThemeGrid.Parent = ThemeRow
local ThemePad = Instance.new("UIPadding")
ThemePad.PaddingTop = UDim.new(0, 8)
ThemePad.PaddingLeft = UDim.new(0, 8)
ThemePad.PaddingRight = UDim.new(0, 8)
ThemePad.Parent = ThemeRow
for _, tname in ipairs({"Purple", "Blood", "Cyan", "Lime", "Pink"}) do
    local t = THEMES[tname]
    local b = Instance.new("TextButton")
    b.Text = tname
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = t.Accent
    b.AutoButtonColor = false
    b.Parent = ThemeRow
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 6)
    bc.Parent = b
    b.Activated:Connect(function()
        local gr = getgenv().AetherGuiRefs
        getgenv().AetherApplyTheme(tname, gr)
        selectTab("s")
    end)
end

--// Tab logic
local function selectTab(which)
    PageVisuals.Visible = (which == "v")
    PageCombat.Visible = (which == "c")
    PagePlayers.Visible = (which == "p")
    PageSettings.Visible = (which == "s")
    local function style(btn, active)
        local l = btn:FindFirstChildOfClass("TextLabel")
        if active then
            TweenService:Create(btn, TweenInfo.new(0.25), {BackgroundColor3 = C.Accent}):Play()
            if l then l.TextColor3 = Color3.new(1,1,1) end
        else
            TweenService:Create(btn, TweenInfo.new(0.25), {BackgroundColor3 = Color3.fromRGB(38, 29, 64)}):Play()
            if l then l.TextColor3 = C.Gray end
        end
    end
    style(TabVisuals, which == "v")
    style(TabCombat, which == "c")
    style(TabPlayers, which == "p")
    style(TabSettings, which == "s")
end
TabVisuals.Activated:Connect(function() selectTab("v") end)
TabCombat.Activated:Connect(function() selectTab("c") end)
TabPlayers.Activated:Connect(function() selectTab("p") end)
TabSettings.Activated:Connect(function() selectTab("s") end)
selectTab("v")

--// Drag top bar (PC + touch)
do
    local dragging, dragStart, startPos = false, nil, nil
    Top.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = i.Position
            startPos = Main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

--// Logo button (square after close)
local LogoBtn = Instance.new("TextButton")
LogoBtn.Name = "LogoBtn"
LogoBtn.AnchorPoint = Vector2.new(0, 0.5)
LogoBtn.Position = UDim2.new(0, 16, 0.5, 0)
LogoBtn.Size = UDim2.new(0, 0, 0, 0)
LogoBtn.BackgroundColor3 = C.Bg2
LogoBtn.Text = ""
LogoBtn.Visible = false
LogoBtn.AutoButtonColor = false
LogoBtn.Parent = Gui
local LogoBtnC = Instance.new("UICorner")
LogoBtnC.CornerRadius = UDim.new(0, 14)
LogoBtnC.Parent = LogoBtn
local LogoBtnStroke = Instance.new("UIStroke")
LogoBtnStroke.Color = C.Accent
LogoBtnStroke.Thickness = 1.5
LogoBtnStroke.Transparency = 0.2
LogoBtnStroke.Parent = LogoBtn
local LogoBtnGrad = Instance.new("UIGradient")
LogoBtnGrad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 30, 120)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 18, 60)),
}
LogoBtnGrad.Rotation = 45
LogoBtnGrad.Parent = LogoBtn
local LogoBtnTxt = Instance.new("TextLabel")
LogoBtnTxt.Size = UDim2.new(1, 0, 1, 0)
LogoBtnTxt.BackgroundTransparency = 1
LogoBtnTxt.Text = "A"
LogoBtnTxt.Font = Enum.Font.GothamBlack
LogoBtnTxt.TextSize = 24
LogoBtnTxt.TextColor3 = C.Accent2
LogoBtnTxt.Parent = LogoBtn

-- gui refs for theme switching
getgenv().AetherGuiRefs = {
    MainStroke = MainStroke,
    SideStroke = SideStroke,
    ContentStroke = ContentStroke,
    TargetStroke = TargetStroke,
    LogoDot = LogoDot,
    StatsLbl = StatsLbl,
    LogoBtnStroke = LogoBtnStroke,
    LogoBtnTxt = LogoBtnTxt,
}
-- apply saved theme on start
pcall(function()
    getgenv().AetherApplyTheme(S.Theme or "Purple", getgenv().AetherGuiRefs)
end)

do
    local dragging, ds, sp = false, nil, nil
    LogoBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true ds = i.Position sp = LogoBtn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and LogoBtn.Visible and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            if d.Magnitude > 10 then
                LogoBtn.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
            end
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local isOpen = false
local isAnim = false
local TARGET_SIZE = UDim2.new(0, 520, 0, 380)

local function openGui()
    if isOpen or isAnim then return end
    isAnim = true
    LogoBtn.Visible = false
    Main.Visible = true
    TweenService:Create(LogoBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0,0,0,0), Rotation = 90}):Play()
    task.wait(0.15)
    LogoBtn.Visible = false
    Main.Size = UDim2.new(0, 0, 0, 0)
    local tw = TweenService:Create(Main, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = TARGET_SIZE})
    tw:Play()
    tw.Completed:Wait()
    isOpen = true
    isAnim = false
end

local function closeGui()
    if not isOpen or isAnim then return end
    isAnim = true
    local tw = TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
    tw:Play()
    tw.Completed:Wait()
    Main.Visible = false
    LogoBtn.Visible = true
    LogoBtn.Rotation = -90
    LogoBtn.Size = UDim2.new(0, 0, 0, 0)
    local tw2 = TweenService:Create(LogoBtn, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 56, 0, 56), Rotation = 0})
    tw2:Play()
    tw2.Completed:Wait()
    isOpen = false
    isAnim = false
end

CloseBtn.Activated:Connect(closeGui)
LogoBtn.Activated:Connect(openGui)
UserInputService.InputBegan:Connect(function(i, gpe)
    if gpe then return end
    if i.KeyCode == Enum.KeyCode.RightShift then
        if isOpen then closeGui() else openGui() end
    end
end)

task.spawn(function()
    task.wait(0.25)
    local c = cam()
    if c then
        local vs = c.ViewportSize
        if vs.X < 640 then
            TARGET_SIZE = UDim2.new(0, math.max(320, vs.X - 16), 0, 380)
        end
    end
    openGui()
end)

--// cool: pulsing border + rotating gradient
task.spawn(function()
    while getgenv().AetherLoaded do
        pcall(function()
            TweenService:Create(MainStroke, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.05}):Play()
        end)
        task.wait(1.5)
        pcall(function()
            TweenService:Create(MainStroke, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.35}):Play()
        end)
        task.wait(1.5)
    end
end)
task.spawn(function()
    local r = 0
    while getgenv().AetherLoaded do
        r = (r + 2) % 360
        pcall(function() MainGrad.Rotation = r end)
        task.wait(0.05)
    end
end)

--// ============ ESP CORE (reworked) ============
local ESP = {}
getgenv().AetherESP = ESP

local function clearESP(plr)
    local e = ESP[plr]
    if e then
        pcall(function()
            for _, l in ipairs(e.corners) do if l then l:Remove() end end
            e.hpBg:Remove() e.hp:Remove()
            e.name:Remove() e.dist:Remove()
            e.tracer:Remove() e.dot:Remove()
            for _, l in ipairs(e.lines3d) do if l then l:Remove() end end
            if e.skeles then for _, l in ipairs(e.skeles) do if l then l:Remove() end end end
            if e.arrow then for _, l in ipairs(e.arrow) do if l then l:Remove() end end end
        end)
        ESP[plr] = nil
    end
end

local function makeESP(plr)
    if ESP[plr] then return ESP[plr] end
    local e = { corners = {}, lines3d = {}, skeles = {}, arrow = {} }
    for i = 1, 8 do
        local l = safeDraw("Line")
        if l then
            l.Thickness = 2
            l.Color = C.Accent2
            pcall(function() l.Transparency = 1 end)
            l.Visible = false
        end
        e.corners[i] = l
    end
    local hpBg = safeDraw("Square")
    if hpBg then hpBg.Thickness = 1 hpBg.Filled = true hpBg.Color = Color3.fromRGB(10,10,15) pcall(function() hpBg.Transparency = 0.7 end) hpBg.Visible = false end
    local hp = safeDraw("Square")
    if hp then hp.Thickness = 1 hp.Filled = true hp.Color = C.Green pcall(function() hp.Transparency = 1 end) hp.Visible = false end
    local nm = safeDraw("Text")
    if nm then nm.Text = "" pcall(function() nm.Size = 14 nm.Transparency = 1 end) nm.Center = true nm.Outline = true nm.Color = Color3.new(1,1,1) nm.Visible = false end
    local ds = safeDraw("Text")
    if ds then ds.Text = "" pcall(function() ds.Size = 13 ds.Transparency = 1 end) ds.Center = true ds.Outline = true ds.Color = Color3.fromRGB(190,170,255) ds.Visible = false end
    local tr = safeDraw("Line")
    if tr then tr.Thickness = 1.5 tr.Color = C.Accent pcall(function() tr.Transparency = 0.9 end) tr.Visible = false end
    local dot = safeDraw("Circle")
    if dot then dot.Filled = true dot.Thickness = 0 dot.NumSides = 12 pcall(function() dot.Transparency = 1 dot.Radius = 4 end) dot.Color = C.Accent2 dot.Visible = false end
    for i = 1, 12 do
        local l = safeDraw("Line")
        if l then l.Thickness = 1.5 l.Color = C.Accent2 pcall(function() l.Transparency = 1 end) l.Visible = false end
        e.lines3d[i] = l
    end
    for i = 1, 14 do
        local l = safeDraw("Line")
        if l then l.Thickness = 1.5 l.Color = Color3.new(1,1,1) pcall(function() l.Transparency = 1 end) l.Visible = false end
        e.skeles[i] = l
    end
    for i = 1, 3 do
        local l = safeDraw("Line")
        if l then l.Thickness = 2 l.Color = C.Accent pcall(function() l.Transparency = 1 end) l.Visible = false end
        e.arrow[i] = l
    end
    e.hpBg, e.hp, e.name, e.dist, e.tracer, e.dot = hpBg, hp, nm, ds, tr, dot
    ESP[plr] = e
    return e
end

local function hideESP(e)
    pcall(function()
        for _, l in ipairs(e.corners) do if l then l.Visible = false end end
        if e.hpBg then e.hpBg.Visible = false end
        if e.hp then e.hp.Visible = false end
        if e.name then e.name.Visible = false end
        if e.dist then e.dist.Visible = false end
        if e.tracer then e.tracer.Visible = false end
        if e.dot then e.dot.Visible = false end
        for _, l in ipairs(e.lines3d) do if l then l.Visible = false end end
        if e.skeles then for _, l in ipairs(e.skeles) do if l then l.Visible = false end end end
        if e.arrow then for _, l in ipairs(e.arrow) do if l then l.Visible = false end end end
    end)
end

-- skeleton pairs (R15 names, R6 fallback handled at draw time)
local SKEL_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local SKEL_R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
}
local function drawSkeleton(e, ch)
    local pairs = SKEL_R15
    if not ch:FindFirstChild("UpperTorso") then
        pairs = SKEL_R6
    end
    for i = 1, 14 do
        local ln = e.skeles[i]
        local pr = pairs[i]
        if ln and pr then
            local a = ch:FindFirstChild(pr[1])
            local b = ch:FindFirstChild(pr[2])
            if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                local sa, ona = w2s(a.Position)
                local sb, onb = w2s(b.Position)
                if ona or onb then
                    ln.From = sa ln.To = sb ln.Visible = true
                else
                    ln.Visible = false
                end
            else
                ln.Visible = false
            end
        elseif ln then
            ln.Visible = false
        end
    end
end
local function hideSkeleton(e)
    if e.skeles then for _, l in ipairs(e.skeles) do if l then l.Visible = false end end end
end
local function drawArrow(e, targetScreenPos, vs)
    local cx, cy = vs.X / 2, vs.Y / 2
    local dx, dy = targetScreenPos.X - cx, targetScreenPos.Y - cy
    local m = math.sqrt(dx * dx + dy * dy)
    if m < 1 then
        for _, l in ipairs(e.arrow) do if l then l.Visible = false end end
        return
    end
    dx, dy = dx / m, dy / m
    local R = math.min(vs.X, vs.Y) / 2 - 46
    local tip = Vector2.new(cx + dx * R, cy + dy * R)
    local base = Vector2.new(tip.X - dx * 20, tip.Y - dy * 20)
    local px, py = -dy, dx
    local left = Vector2.new(base.X + px * 10, base.Y + py * 10)
    local right = Vector2.new(base.X - px * 10, base.Y - py * 10)
    local pts = {{tip, left}, {left, right}, {right, tip}}
    for i = 1, 3 do
        local ln = e.arrow[i]
        if ln then ln.From = pts[i][1] ln.To = pts[i][2] ln.Visible = true end
    end
end
local function hideArrow(e)
    if e.arrow then for _, l in ipairs(e.arrow) do if l then l.Visible = false end end end
end

local function getCorners(cf, size)
    local hxs, hys, hzs = size.X/2, size.Y/2, size.Z/2
    local pts = {}
    for _, sx in ipairs({-1, 1}) do
        for _, sy in ipairs({-1, 1}) do
            for _, sz in ipairs({-1, 1}) do
                table.insert(pts, (cf * CFrame.new(sx*hxs, sy*hys, sz*hzs)).Position)
            end
        end
    end
    return pts
end
local EDGES = {{1,2},{3,4},{5,6},{7,8},{1,3},{2,4},{5,7},{6,8},{1,5},{2,6},{3,7},{4,8}}

local function w2s(p)
    local c = cam()
    if not c then return Vector2.new(0,0), false, -1 end
    local ok, v, on = pcall(function() return c:WorldToViewportPoint(p) end)
    if not ok then return Vector2.new(0,0), false, -1 end
    return Vector2.new(v.X, v.Y), on, v.Z
end

local function wallCheck(targetPos, targetChar)
    if not S.WallCheck then return true end
    local c = cam()
    if not c then return true end
    local ch = LocalPlayer.Character
    local ok, res = pcall(function()
        local origin = c.CFrame.Position
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {ch, targetChar, c}
        params.IgnoreWater = true
        return workspace:Raycast(origin, (targetPos - origin), params)
    end)
    if not ok then return true end
    return res == nil
end

--// chams (Highlight, always works even if Drawing blocked)
local function ensureCham(plr, ch)
    if not S.Chams then return end
    pcall(function()
        if not ch then return end
        local old = ch:FindFirstChild("AetherCham")
        if old then old.Enabled = true return end
        local hl = Instance.new("Highlight")
        hl.Name = "AetherCham"
        hl.FillColor = C.Accent
        hl.OutlineColor = Color3.new(1,1,1)
        hl.FillTransparency = 0.55
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Enabled = true
        hl.Parent = ch
        table.insert(getgenv().AetherChams, hl)
    end)
end

local function validTarget(plr)
    if plr == LocalPlayer then return nil end
    local ch = plr.Character
    if not ch then return nil end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    local root = ch:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 then return nil end
    if S.TeamCheck then
        pcall(function()
            if plr.Team ~= nil and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team then
                ch = nil
            end
        end)
        if ch == nil then return nil end
    end
    local part = ch:FindFirstChild(S.AimPart) or ch:FindFirstChild("Head") or root
    if not part then return nil end
    return ch, hum, part
end

local function getAimOrigin()
    local c = cam()
    if not c then return Vector2.new(0,0) end
    if UserInputService.TouchEnabled then
        local vs = c.ViewportSize
        return Vector2.new(vs.X / 2, vs.Y / 2)
    end
    return UserInputService:GetMouseLocation()
end

local function getClosest()
    local m = getAimOrigin()
    local best, bestD, bestPos = nil, S.FOV, nil
    local c = cam()
    if not c then return nil, nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        local ch, hum, part = validTarget(plr)
        if ch and part then
            local ok, sp, on = pcall(function() return c:WorldToViewportPoint(part.Position) end)
            if ok and on then
                local d = (Vector2.new(sp.X, sp.Y) - m).Magnitude
                if d < bestD then
                    if wallCheck(part.Position, ch) then
                        bestD = d
                        best = plr
                        -- small prediction for moving targets
                        local vel = Vector3.new(0,0,0)
                        pcall(function()
                            local r = ch:FindFirstChild("HumanoidRootPart")
                            if r then vel = r.Velocity end
                        end)
                        bestPos = part.Position + vel * 0.12
                    end
                end
            end
        end
    end
    return best, bestPos
end

local CurrentTarget = nil
local CurrentDist = 0

--// main loop (nil-safe, per-player pcall so 1 bad char can't kill ESP)
if getgenv().AetherLoop then pcall(function() getgenv().AetherLoop:Disconnect() end) end

getgenv().AetherLoop = RunService.RenderStepped:Connect(function()
    local c = cam()
    if not c then return end
    local m = getAimOrigin()
    local vs = c.ViewportSize

    -- FOV (always when toggle on)
    if FOVCircle and FOVFill then
        FOVCircle.Position = m
        FOVCircle.Radius = S.FOV
        FOVFill.Position = m
        FOVFill.Radius = S.FOV
        FOVCircle.Visible = S.ShowFOV
        FOVFill.Visible = S.ShowFOV
    end

    -- crosshair at screen center
    local chOn = S.Crosshair
    local cx, cy = vs.X / 2, vs.Y / 2
    if CH[1] then
        local gap, len = 6, 10
        local pts = {
            {Vector2.new(cx - gap - len, cy), Vector2.new(cx - gap, cy)},
            {Vector2.new(cx + gap, cy), Vector2.new(cx + gap + len, cy)},
            {Vector2.new(cx, cy - gap - len), Vector2.new(cx, cy - gap)},
            {Vector2.new(cx, cy + gap), Vector2.new(cx, cy + gap + len)},
        }
        for i = 1, 4 do
            if CH[i] then
                CH[i].From = pts[i][1]
                CH[i].To = pts[i][2]
                CH[i].Visible = chOn
            end
        end
    end
    if CHDot then
        CHDot.Position = Vector2.new(cx, cy)
        CHDot.Visible = chOn
    end

    -- ESP
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then
            local e0 = ESP[plr]
            if e0 then hideESP(e0) end
        else
            local ok = pcall(function()
                local ch = plr.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                local root = ch and ch:FindFirstChild("HumanoidRootPart")
                local head = ch and ch:FindFirstChild("Head")
                local e = makeESP(plr)
                local showAny = S.Box or S.Health or S.Name or S.Distance or S.Box3D or S.Tracer or S.HeadDot or S.Skeleton or S.Arrows
                if S.Chams and ch and hum and hum.Health > 0 then ensureCham(plr, ch) end
                if not showAny or not ch or not hum or not root or hum.Health <= 0 then
                    hideESP(e)
                    hideArrow(e)
                    return
                end
                if S.TeamCheck and plr.Team ~= nil and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team then
                    hideESP(e)
                    hideArrow(e)
                    return
                end
                local top, topOn = w2s((root.CFrame * CFrame.new(0, 3, 0)).Position)
                local bot, botOn = w2s((root.CFrame * CFrame.new(0, -3, 0)).Position)
                local _, _, z = w2s(root.Position)
                local onScreen = (topOn or botOn) and z > 0
                if not onScreen then
                    hideESP(e)
                    -- off-screen arrow still points the way
                    if S.Arrows then
                        local rs = w2s(root.Position)
                        drawArrow(e, rs, vs)
                    else
                        hideArrow(e)
                    end
                    return
                else
                    if S.Arrows then
                        -- hide arrow when target visible (or show when outside FOV circle)
                        local rs = w2s(root.Position)
                        local dC = (rs - Vector2.new(vs.X / 2, vs.Y / 2)).Magnitude
                        if dC > (tonumber(S.FOV) or 180) then
                            drawArrow(e, rs, vs)
                        else
                            hideArrow(e)
                        end
                    else
                        hideArrow(e)
                    end
                end

                local h = math.max(math.abs(bot.Y - top.Y), 4)
                local w = h * 0.62
                local x = (top.X + bot.X) / 2 - w / 2
                local y = math.min(top.Y, bot.Y)
                local dist = (root.Position - c.CFrame.Position).Magnitude

                -- corner box (pretty)
                if S.Box then
                    local cl = math.clamp(math.min(w, h) * 0.28, 6, 22)
                    local cols = {
                        {Vector2.new(x, y), Vector2.new(x + cl, y)},
                        {Vector2.new(x, y), Vector2.new(x, y + cl)},
                        {Vector2.new(x + w - cl, y), Vector2.new(x + w, y)},
                        {Vector2.new(x + w, y), Vector2.new(x + w, y + cl)},
                        {Vector2.new(x, y + h - cl), Vector2.new(x, y + h)},
                        {Vector2.new(x, y + h), Vector2.new(x + cl, y + h)},
                        {Vector2.new(x + w, y + h - cl), Vector2.new(x + w, y + h)},
                        {Vector2.new(x + w - cl, y + h), Vector2.new(x + w, y + h)},
                    }
                    for i = 1, 8 do
                        local ln = e.corners[i]
                        if ln then ln.From = cols[i][1] ln.To = cols[i][2] ln.Visible = true end
                    end
                else
                    for i = 1, 8 do if e.corners[i] then e.corners[i].Visible = false end end
                end

                -- health
                if S.Health and e.hpBg and e.hp then
                    local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                    local bw = 4
                    e.hpBg.Size = Vector2.new(bw, h)
                    e.hpBg.Position = Vector2.new(x - bw - 3, y)
                    e.hpBg.Visible = true
                    local hh = math.max(h * pct, 1)
                    e.hp.Size = Vector2.new(bw - 1, hh)
                    e.hp.Position = Vector2.new(x - bw - 2.5, y + (h - hh))
                    e.hp.Color = Color3.fromRGB(math.floor(255 * (1 - pct)), math.floor(255 * pct), 80)
                    e.hp.Visible = true
                else
                    if e.hpBg then e.hpBg.Visible = false end
                    if e.hp then e.hp.Visible = false end
                end

                -- name
                if S.Name and e.name then
                    e.name.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
                    e.name.Position = Vector2.new(x + w / 2, y - 18)
                    e.name.Visible = true
                elseif e.name then
                    e.name.Visible = false
                end

                -- distance
                if S.Distance and e.dist then
                    e.dist.Text = "[" .. math.floor(dist) .. "m]"
                    e.dist.Position = Vector2.new(x + w / 2, y + h + 2)
                    e.dist.Visible = true
                elseif e.dist then
                    e.dist.Visible = false
                end

                -- tracer from bottom center
                if S.Tracer and e.tracer then
                    e.tracer.From = Vector2.new(vs.X / 2, vs.Y)
                    e.tracer.To = Vector2.new(x + w / 2, y + h)
                    e.tracer.Visible = true
                elseif e.tracer then
                    e.tracer.Visible = false
                end

                -- head dot
                if S.HeadDot and e.dot and head then
                    local hs, hon = w2s(head.Position)
                    if hon then
                        e.dot.Position = hs
                        e.dot.Visible = true
                    else
                        e.dot.Visible = false
                    end
                elseif e.dot then
                    e.dot.Visible = false
                end

                -- 3D box
                if S.Box3D then
                    local cf = root.CFrame
                    local corners = getCorners(cf, Vector3.new(4, 6, 3))
                    local sp = {}
                    for i, cp in ipairs(corners) do
                        local s2 = w2s(cp)
                        sp[i] = s2
                    end
                    for i, eg in ipairs(EDGES) do
                        local ln = e.lines3d[i]
                        if ln then ln.From = sp[eg[1]] ln.To = sp[eg[2]] ln.Visible = true end
                    end
                else
                    for _, l in ipairs(e.lines3d) do if l then l.Visible = false end end
                end

                -- skeleton
                if S.Skeleton then
                    drawSkeleton(e, ch)
                else
                    hideSkeleton(e)
                end
            end)
            if not ok then
                pcall(function() hideESP(ESP[plr]) end)
            end
        end
    end

    -- aimbot auto (no key, phone)
    CurrentTarget = nil
    if S.Aimbot then
        local t, pos = getClosest()
        if t and pos then
            CurrentTarget = t
            local okp = pcall(function()
                local rp = t.Character and t.Character:FindFirstChild("HumanoidRootPart")
                if rp then CurrentDist = math.floor((rp.Position - c.CFrame.Position).Magnitude) else CurrentDist = 0 end
            end)
            local smooth = math.clamp(tonumber(S.Smoothness) or 7, 1, 30)
            local k = math.clamp((1 / smooth + 0.02) * 2.2, 0.05, 1)
            local cur = c.CFrame
            c.CFrame = cur:Lerp(CFrame.new(cur.Position, pos), k)
        end
    end

    -- target HUD
    pcall(function()
        if CurrentTarget then
            TargetLbl.Text = "TARGET: " .. CurrentTarget.DisplayName .. "  [" .. tostring(CurrentDist) .. "m]"
            TargetLbl.TextColor3 = C.Text
            TargetDot.BackgroundColor3 = C.Green
        else
            TargetLbl.Text = S.Aimbot and "TARGET: searching..." or "AIMBOT OFF"
            TargetLbl.TextColor3 = C.Gray
            TargetDot.BackgroundColor3 = C.Red
        end
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    clearESP(p)
end)
LocalPlayer.CharacterAdded:Connect(function()
    task.delay(1, function() pcall(applyHitboxes) end)
end)

-- player list (tap row = teleport to player)
local function teleportTo(plr)
    pcall(function()
        local my = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local tc = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        if my and tc then
            my.CFrame = tc.CFrame * CFrame.new(0, 0, 4)
        end
    end)
end
task.spawn(function()
    while getgenv().AetherLoaded do
        task.wait(1)
        pcall(function()
            for _, ch in ipairs(PlayerList:GetChildren()) do
                if ch:IsA("TextButton") then ch:Destroy() end
            end
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local n = 0
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and n < 12 then
                    n = n + 1
                    local dstr = "--"
                    pcall(function()
                        local tc = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                        if myRoot and tc then
                            dstr = tostring(math.floor((tc.Position - myRoot.Position).Magnitude)) .. "m"
                        end
                    end)
                    local b = Instance.new("TextButton")
                    b.LayoutOrder = n
                    b.Size = UDim2.new(1, 0, 0, 32)
                    b.BackgroundColor3 = Color3.fromRGB(38, 29, 64)
                    b.Text = ""
                    b.AutoButtonColor = false
                    b.Parent = PlayerList
                    local bc = Instance.new("UICorner")
                    bc.CornerRadius = UDim.new(0, 8)
                    bc.Parent = b
                    local lbl = Instance.new("TextLabel")
                    lbl.Position = UDim2.new(0, 10, 0, 0)
                    lbl.Size = UDim2.new(1, -70, 1, 0)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = plr.DisplayName .. "  [" .. dstr .. "]"
                    lbl.Font = Enum.Font.GothamSemibold
                    lbl.TextSize = 12
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.TextTruncate = Enum.TextTruncate.AtEnd
                    lbl.TextColor3 = C.Text
                    lbl.Parent = b
                    local go = Instance.new("TextLabel")
                    go.AnchorPoint = Vector2.new(1, 0.5)
                    go.Position = UDim2.new(1, -10, 0.5, 0)
                    go.Size = UDim2.new(0, 40, 0, 20)
                    go.BackgroundColor3 = C.Accent
                    go.Text = "TP"
                    go.Font = Enum.Font.GothamBold
                    go.TextSize = 11
                    go.TextColor3 = Color3.new(1,1,1)
                    go.Parent = b
                    local gc = Instance.new("UICorner")
                    gc.CornerRadius = UDim.new(0, 6)
                    gc.Parent = go
                    local target = plr
                    b.Activated:Connect(function() teleportTo(target) end)
                end
            end
            PlayerList.Size = UDim2.new(1, 0, 0, math.max(n * 38 - 6, 32))
        end)
    end
end)

-- stats updater (FPS / ping / players)
task.spawn(function()
    local frames = 0
    local last = tick()
    local fps = 60
    RunService.RenderStepped:Connect(function() frames = frames + 1 end)
    while getgenv().AetherLoaded do
        task.wait(0.5)
        local now = tick()
        local dt = now - last
        if dt > 0 then fps = math.floor(frames / dt) frames = 0 last = now end
        local ping = 0
        pcall(function()
            local s = Stats.Network.ServerStatsItem["Data Ping"]
            if s then ping = math.floor(s:GetValue()) end
        end)
        local n = #Players:GetPlayers()
        pcall(function()
            StatsLbl.Text = "FPS " .. tostring(fps) .. "  •  PING " .. tostring(ping) .. "  •  PLAYERS " .. tostring(n)
        end)
    end
end)
