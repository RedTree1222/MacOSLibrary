for _, v in pairs(game:GetService("Lighting"):GetChildren()) do
    if v:IsA("DepthOfFieldEffect") then v:Destroy() end
end
local Lib = {}
local Blur = loadstring(game:HttpGet("https://raw.githubusercontent.com/RedTree1222/MacOSLibrary/main/Blur.luau"))()
local LucideIcons = loadstring(game:HttpGet("https://raw.githubusercontent.com/latte-soft/lucide-roblox/master/lib/Icons.luau"))()
Lib.ButtonStyle = "Modern"
Lib.FolderName = "MacOSLibrary"
local Sections = {}
local Workareas = {}
local MainTabs = {}
local ExtraTabs = {}
local IsExtraMode = false
local TabSwapCooldown = false
local IsSidebarCollapsed = false
local ExpandedSidebarWidth = 190
local CollapseCooldown = false
local visible = true
local Dbcooper = false
local ScrollSyncConnected = false
local BlurEnabled = false
local CleanupKeybinds = {}
local CleanupToggles = {}
local RegisteredElements = {}
local ActiveKeybindData = {} 
local IsPromptingKeybind = false
local KeybindPromptCallback = nil
local KeybindPromptElementName = nil
local RefreshKeybindsUI = nil
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local function Tp(ins, pos, time)
    TweenService:Create(ins, TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut), {Position = pos}):Play()
end
local ThemeElements = {}
local HttpService = game:GetService("HttpService")
local ConfigManager = {
    Elements = {},
    CurrentTheme = "light"
}
function ConfigManager:Save(name)
    local Data = { Elements = {}, Keybinds = {} }
    for Flag, element in pairs(self.Elements) do
        if element.Value ~= nil and not string.find(Flag, "^Settings_") then
            Data.Elements[Flag] = element.Value
        end
    end
    for _, bindInfo in ipairs(ActiveKeybindData) do
        Data.Keybinds[bindInfo.Name] = { Key = bindInfo.Key, Enabled = bindInfo.Enabled }
    end
    if makefolder and not isfolder(Lib.FolderName) then makefolder(Lib.FolderName) end
    if makefolder and not isfolder(Lib.FolderName .. "/Configs") then makefolder(Lib.FolderName .. "/Configs") end
    writefile(Lib.FolderName .. "/Configs/" .. name .. ".json", HttpService:JSONEncode(Data))
end
function ConfigManager:Load(name)
    local Path = Lib.FolderName .. "/Configs/" .. name .. ".json"
    if isfile and not isfile(Path) then return end
    local Ok, Content = pcall(function() return readfile(Path) end)
    if Ok and type(Content) == "string" and Content ~= "" then
        local Success, Data = pcall(function() return HttpService:JSONDecode(Content) end)
        if Success and Data then
            local ElementsData = Data.Elements or Data
            for Flag, value in pairs(ElementsData) do
                if self.Elements[Flag] and self.Elements[Flag].Set then
                    self.Elements[Flag]:Set(value)
                end
            end
            if Data.Keybinds then
                for elemName, bindData in pairs(Data.Keybinds) do
                    local KeyName = type(bindData) == "table" and bindData.Key or bindData
                    local IsEnabled = type(bindData) == "table" and bindData.Enabled or true
                    local keyCode = Enum.KeyCode[KeyName]
                    if keyCode and RegisteredElements[elemName] then
                        local AlreadyBound = false
                        for _, existing in ipairs(ActiveKeybindData) do
                            if existing.Name == elemName then AlreadyBound = true break end
                        end
                        if not AlreadyBound then
                            table.insert(ActiveKeybindData, { Name = elemName, Key = KeyName, Enabled = IsEnabled, Callback = RegisteredElements[elemName] })
                        end
                    end
                end
                if RefreshKeybindsUI then RefreshKeybindsUI() end
            end
        end
    end
end
function ConfigManager:Delete(name)
    local Path = Lib.FolderName .. "/Configs/" .. name .. ".json"
    if isfile and isfile(Path) then
        pcall(function() delfile(Path) end)
    elseif pcall(function() return readfile(Path) end) then
        delfile(Path)
    end
end
function ConfigManager:GetConfigs()
    local Configs = {}
    if isfolder(Lib.FolderName .. "/Configs") then
        local Files = listfiles(Lib.FolderName .. "/Configs")
        for _, file in ipairs(Files) do
            local name = string.match(file, "([^/\\]+)%.json$")
            if name then table.insert(Configs, name) end
        end
    end
    return Configs
end
function ConfigManager:SaveAutoLoad(name)
    if makefolder and not isfolder(Lib.FolderName) then makefolder(Lib.FolderName) end
    writefile(Lib.FolderName .. "/autoload.txt", name)
end
function ConfigManager:GetAutoLoad()
    local Path = Lib.FolderName .. "/autoload.txt"
    if isfile and isfile(Path) then
        local Ok, Content = pcall(function() return readfile(Path) end)
        if Ok and type(Content) == "string" and Content ~= "" then
            return Content
        end
    end
    return nil
end
function ConfigManager:SaveUISettings()
    if makefolder and not isfolder(Lib.FolderName) then makefolder(Lib.FolderName) end
    local Data = {
        theme = self.CurrentTheme,
        disableSplash = self.DisableSplash,
        accentR = self.AccentColor and self.AccentColor.R or nil,
        accentG = self.AccentColor and self.AccentColor.G or nil,
        accentB = self.AccentColor and self.AccentColor.B or nil,
        rainbow = self.Rainbow,
        welcomeShown = self.WelcomeShown,
        Settings = {}
    }
    for Flag, element in pairs(self.Elements) do
        if element.Value ~= nil and type(Flag) == "string" and string.find(Flag, "^Settings_") then
            Data.Settings[Flag] = element.Value
        end
    end
    writefile(Lib.FolderName .. "/ui_settings.json", HttpService:JSONEncode(Data))
end
function ConfigManager:LoadUISettings()
    local Path = Lib.FolderName .. "/ui_settings.json"
    if isfile and not isfile(Path) then return end
    local Ok, Content = pcall(function() return readfile(Path) end)
    if Ok and type(Content) == "string" and Content ~= "" then
        local Success, Data = pcall(function() return HttpService:JSONDecode(Content) end)
        if Success and Data then
            if Data.theme then self.CurrentTheme = Data.theme end
            if Data.disableSplash ~= nil then self.DisableSplash = Data.disableSplash end
            if Data.accentR and Data.accentG and Data.accentB then self.AccentColor = Color3.new(Data.accentR, Data.accentG, Data.accentB) end
            if Data.rainbow ~= nil then self.Rainbow = Data.rainbow end
            if Data.welcomeShown ~= nil then self.WelcomeShown = Data.welcomeShown end
            if Data.Settings then
                for Flag, val in pairs(Data.Settings) do
                    if self.Elements[Flag] then
                        self.Elements[Flag]:Set(val)
                    else
                        self.Elements[Flag] = { Value = val }
                    end
                end
            end
        end
    end
end
local CurrentTheme = ConfigManager.CurrentTheme
local CurrentAccentColor = Color3.fromRGB(21, 103, 251)
local IconMap = {
    ["arrow-left-to-line"] = "rbxassetid://10709768114",
    ["refresh-ccw"] = "rbxassetid://10734933056",
    ["settings"] = "rbxassetid://10734950309",
    ["users"] = "rbxassetid://10747373426",
    ["keyboard"] = "rbxassetid://10723416765",
    ["bell"] = "rbxassetid://10709775704",
    ["package"] = "rbxassetid://10734909540",
    ["warning"] = "rbxassetid://12608260095",
    ["info"] = "rbxassetid://4871684504"
}
local function RegisterTheme(instance, propertyName, lightValue, darkValue)
    table.insert(ThemeElements, {
        Instance = instance,
        Property = propertyName,
        Light = lightValue,
        Dark = darkValue
    })
    instance[propertyName] = (CurrentTheme == "light") and lightValue or darkValue
end
function Lib:Init(ti, dosplash, visiblekey, deleteprevious)
    ConfigManager:LoadUISettings()
    do
        local BindPath = Lib.FolderName .. "/menu_bind.txt"
        if isfile and isfile(BindPath) then
            local Ok, Saved = pcall(readfile, BindPath)
            if Ok and Saved and Saved ~= "" then
                local Kc = Enum.KeyCode[Saved]
                if Kc then visiblekey = Kc end
            end
        end
    end
    local IconMap = {
        ["arrow-left-to-line"] = "rbxassetid://10709768114",
        ["refresh-ccw"] = "rbxassetid://10734933056",
        ["settings"] = "rbxassetid://10734950309",
        ["users"] = "rbxassetid://10747373426",
        ["keyboard"] = "rbxassetid://10723416765",
        ["bell"] = "rbxassetid://10709775704",
        ["package"] = "rbxassetid://10734909540",
        ["warning"] = "rbxassetid://12608260095",
        ["info"] = "rbxassetid://4871684504"
    }
    local function ResolveIcon(imageLabel, iconId)
        if type(iconId) ~= "string" then iconId = "rbxassetid://10709768114" end
        if string.find(iconId, "rbxassetid://") then
            imageLabel.Image = iconId
            imageLabel.ImageRectSize = Vector2.new(0, 0)
            imageLabel.ImageRectOffset = Vector2.new(0, 0)
        elseif LucideIcons["48px"] and LucideIcons["48px"][iconId] then
            local Data = LucideIcons["48px"][iconId]
            imageLabel.Image = "rbxassetid://" .. tostring(Data[1])
            imageLabel.ImageRectSize = Vector2.new(Data[2][1], Data[2][2])
            imageLabel.ImageRectOffset = Vector2.new(Data[3][1], Data[3][2])
        elseif IconMap[iconId] then
            imageLabel.Image = IconMap[iconId]
            imageLabel.ImageRectSize = Vector2.new(0, 0)
            imageLabel.ImageRectOffset = Vector2.new(0, 0)
        else
            imageLabel.Image = "rbxassetid://10734909540"
            imageLabel.ImageRectSize = Vector2.new(0, 0)
            imageLabel.ImageRectOffset = Vector2.new(0, 0)
        end
    end
    local function ApplyLucide(imgLabel, iconName)
        if IconMap[iconName] then
            imgLabel.Image = IconMap[iconName]
        else
            imgLabel.Image = "rbxassetid://10734909540" 
        end
    end
    CurrentTheme = ConfigManager.CurrentTheme
    local ErrorCatcherEnabled = false
    if ConfigManager.DisableSplash then dosplash = false end
    local CustomKeybinds = {}
    local IsPromptingKeybind = false
    local KeybindPromptCallback = nil
    if deleteprevious then
        local Container = gethui and gethui() or game:GetService("CoreGui")
        for _, v in pairs(Container:GetChildren()) do
            if v.Name == "MacOSLibrary_GUI" then
                v:Destroy()
            end
        end
    end
    scrgui = Instance.new("ScreenGui")
    scrgui.Name = "MacOSLibrary_GUI"
    if syn then syn.protect_gui(scrgui) end
    if gethui then scrgui.Parent = gethui() else scrgui.Parent = game:GetService("CoreGui") end
    scrgui.IgnoreGuiInset = true
    local ModalUnlocker = Instance.new("TextButton")
    ModalUnlocker.Name = "ModalUnlocker"
    ModalUnlocker.Parent = scrgui
    ModalUnlocker.BackgroundTransparency = 1
    ModalUnlocker.Text = ""
    ModalUnlocker.Size = UDim2.new(0, 0, 0, 0)
    ModalUnlocker.Modal = false
    if dosplash then
        local Splash = Instance.new("Frame")
        Splash.Name = "splash"
        Splash.Parent = scrgui
        Splash.AnchorPoint = Vector2.new(0.5, 0.5)
        Splash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Splash.BackgroundTransparency = 0.600
        Splash.Position = UDim2.new(0.5, 0, 2, 0)
        Splash.Size = UDim2.new(0, 340, 0, 340)
        Splash.Visible = true
        Splash.ZIndex = 40
        local Uc_22 = Instance.new("UICorner")
        Uc_22.CornerRadius = UDim.new(0, 18)
        Uc_22.Parent = Splash
        local Sicon = Instance.new("ImageLabel")
        Sicon.Name = "sicon"
        Sicon.Parent = Splash
        Sicon.AnchorPoint = Vector2.new(0.5, 0.5)
        Sicon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Sicon.BackgroundTransparency = 1
        Sicon.Position = UDim2.new(0.5, 0, 0.5, 0)
        Sicon.Size = UDim2.new(0, 191, 0, 190)
        Sicon.ZIndex = 40
        Sicon.Image = "rbxassetid://12621719043"
        Sicon.ScaleType = Enum.ScaleType.Fit
        Sicon.TileSize = UDim2.new(1, 0, 20, 0)
        local Ug = Instance.new("UIGradient")
        Ug.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(0.01, Color3.fromRGB(61, 61, 61)), ColorSequenceKeypoint.new(0.47, Color3.fromRGB(41, 41, 41)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))}
        Ug.Rotation = 90
        Ug.Parent = Sicon
        local Sshadow = Instance.new("ImageLabel")
        Sshadow.Name = "sshadow"
        Sshadow.Parent = Splash
        Sshadow.AnchorPoint = Vector2.new(0.5, 0.5)
        Sshadow.BackgroundTransparency = 1
        Sshadow.Position = UDim2.new(0.5, 0, 0.5, 0)
        Sshadow.Size = UDim2.new(1.20000005, 0, 1.20000005, 0)
        Sshadow.ZIndex = 39
        Sshadow.Image = "rbxassetid://313486536"
        Sshadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        Sshadow.ImageTransparency = 0.400
        Sshadow.TileSize = UDim2.new(0, 1, 0, 1)
        Splash:TweenPosition(UDim2.new(0.5, 0, 0.5, 0), "InOut", "Quart", 1)
        wait(2)
        Splash:TweenPosition(UDim2.new(0.5, 0, 2, 0), "InOut", "Quart", 1)
        game:GetService("Debris"):AddItem(Splash, 1)
    end
    local IsMob = UserInputService.TouchEnabled
    local CScale = IsMob and 0.85 or 1.0
    local Main = Instance.new("Frame")
    Main.ClipsDescendants = true
    local KeybindsWindowFrame = Instance.new("Frame")
    KeybindsWindowFrame.Name = "keybindsWindowFrame"
    KeybindsWindowFrame.Parent = scrgui
    KeybindsWindowFrame.BorderSizePixel = 0
    KeybindsWindowFrame.Size = UDim2.new(0, 220, 0, 40)
    KeybindsWindowFrame.Position = UDim2.new(0.85, 0, 0.5, 0)
    KeybindsWindowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    KeybindsWindowFrame.AutomaticSize = Enum.AutomaticSize.Y
    KeybindsWindowFrame.Visible = false
    RegisterTheme(KeybindsWindowFrame, "BackgroundColor3", Color3.fromRGB(249, 249, 255), Color3.fromRGB(18, 18, 24))
    local KbBlurFrame = Instance.new("Frame")
    KbBlurFrame.Name = "blurFrame"
    KbBlurFrame.Parent = KeybindsWindowFrame
    KbBlurFrame.BackgroundTransparency = 1
    KbBlurFrame.Position = UDim2.new(0, 24, 0, 24)
    KbBlurFrame.Size = UDim2.new(1, -48, 1, -48)
    KbBlurFrame.ZIndex = 0
    local Kb_uc = Instance.new("UICorner")
    Kb_uc.CornerRadius = UDim.new(0, 8)
    Kb_uc.Parent = KeybindsWindowFrame
    local Kb_stroke = Instance.new("UIStroke")
    Kb_stroke.Parent = KeybindsWindowFrame
    Kb_stroke.Transparency = 0.8
    Kb_stroke.Thickness = 1
    RegisterTheme(Kb_stroke, "Color", Color3.fromRGB(216, 216, 216), Color3.fromRGB(40, 40, 40))
    local Kb_topbar = Instance.new("Frame")
    Kb_topbar.Name = "topbar"
    Kb_topbar.Parent = KeybindsWindowFrame
    Kb_topbar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Kb_topbar.BackgroundTransparency = 1
    Kb_topbar.Size = UDim2.new(1, 0, 0, 40)
    local Kb_title = Instance.new("TextLabel")
    Kb_title.Parent = Kb_topbar
    Kb_title.BackgroundTransparency = 1
    Kb_title.Position = UDim2.new(0, 15, 0, 0)
    Kb_title.Size = UDim2.new(1, -30, 1, 0)
    Kb_title.Font = Enum.Font.BuilderSansMedium
    Kb_title.Text = "Keybinds"
    Kb_title.TextSize = 14
    Kb_title.TextXAlignment = Enum.TextXAlignment.Left
    RegisterTheme(Kb_title, "TextColor3", Color3.fromRGB(100, 100, 100), Color3.fromRGB(140, 140, 155))
    local Kb_container = Instance.new("Frame")
    Kb_container.Parent = KeybindsWindowFrame
    Kb_container.BackgroundTransparency = 1
    Kb_container.Position = UDim2.new(0, 0, 0, 40)
    Kb_container.Size = UDim2.new(1, 0, 0, 0)
    Kb_container.AutomaticSize = Enum.AutomaticSize.Y
    local Kb_layout = Instance.new("UIListLayout")
    Kb_layout.Parent = Kb_container
    Kb_layout.SortOrder = Enum.SortOrder.LayoutOrder
    Kb_layout.Padding = UDim.new(0, 5)
    local Kb_padding = Instance.new("UIPadding")
    Kb_padding.Parent = Kb_container
    Kb_padding.PaddingBottom = UDim.new(0, 10)
    local KbDragging = false
    local KbDragStart, KbStartPos
    Kb_topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            KbDragging = true
            KbDragStart = input.Position
            KbStartPos = KeybindsWindowFrame.Position
            local c; c = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    KbDragging = false
                    c:Disconnect()
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if KbDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local Delta = input.Position - KbDragStart
            KeybindsWindowFrame.Position = UDim2.new(KbStartPos.X.Scale, KbStartPos.X.Offset + Delta.X, KbStartPos.Y.Scale, KbStartPos.Y.Offset + Delta.Y)
        end
    end)
    Main.Name = "main"
    Main.Parent = scrgui
    local BlurFrame = Instance.new("Frame")
    BlurFrame.Name = "blurFrame"
    BlurFrame.Parent = Main
    BlurFrame.BackgroundTransparency = 1
    BlurFrame.Position = UDim2.new(0, 24, 0, 24)
    BlurFrame.Size = UDim2.new(1, -48, 1, -48)
    BlurFrame.ZIndex = 0
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.new(0.5, 0, 2, 0)
    local function UpdateMainSize()
        local Vp = workspace.CurrentCamera.ViewportSize
        local w = math.clamp(721, 400, Vp.X - 40)
        local h = math.clamp(584, 300, Vp.Y - 40)
        Main.Size = UDim2.new(0, w, 0, h)
    end
    UpdateMainSize()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateMainSize)
    RegisterTheme(Main, "BackgroundColor3", Color3.fromRGB(245, 245, 250), Color3.fromRGB(18, 18, 24))
    if IsMob then
        local Fab = Instance.new("ImageButton")
        Fab.Name = "MobileFAB"
        Fab.Parent = scrgui
        Fab.ZIndex = 99999
        Fab.AnchorPoint = Vector2.new(1, 0.5)
        Fab.Position = UDim2.new(1, -20, 0.5, 0)
        Fab.Size = UDim2.new(0, 46, 0, 46)
        Fab.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
        Fab.Image = "rbxassetid://12621719043" 
        Fab.ImageRectOffset = Vector2.new(0, 0)
        Fab.ImageRectSize = Vector2.new(0, 0)
        Fab.ScaleType = Enum.ScaleType.Fit
        local FabCorner = Instance.new("UICorner")
        FabCorner.CornerRadius = UDim.new(1, 0)
        FabCorner.Parent = Fab
        local FabStroke = Instance.new("UIStroke")
        FabStroke.Parent = Fab
        FabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        FabStroke.Color = Color3.fromRGB(41, 41, 41)
        FabStroke.Thickness = 1.5
        local FabDrag = false
        local FabStart = nil
        local FabStartPos = nil
        Fab.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                FabDrag = true
                FabStart = input.Position
                FabStartPos = Fab.Position
                for _, v in ipairs(scrgui:GetDescendants()) do
                    if v:IsA("ScrollingFrame") then v.ScrollingEnabled = false end
                end
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if FabDrag and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
                local Delta = input.Position - FabStart
                Fab.Position = UDim2.new(FabStartPos.X.Scale, FabStartPos.X.Offset + Delta.X, FabStartPos.Y.Scale, FabStartPos.Y.Offset + Delta.Y)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                if FabDrag and FabStart then
                    local Dist = (input.Position - FabStart).Magnitude
                    if Dist < 10 then
                        if Window.ToggleVisible then Window:ToggleVisible() end
                    end
                end
                if FabDrag then
                    for _, v in ipairs(scrgui:GetDescendants()) do
                        if v:IsA("ScrollingFrame") then v.ScrollingEnabled = true end
                    end
                end
                FabDrag = false
            end
        end)
    end
    local Uiscale = Instance.new("UIScale")
    Uiscale.Parent = Main
    Uiscale.Scale = CScale
    Main.BackgroundTransparency = 0.08
    local Uc = Instance.new("UICorner")
    Uc.CornerRadius = UDim.new(0, 14)
    Uc.Parent = Main
    local Topbar = Instance.new("TextButton")
    Topbar.Name = "topbar"
    Topbar.Parent = Main
    Topbar.BackgroundTransparency = 1
    Topbar.Text = ""
    Topbar.Size = UDim2.new(1, -150, 0, 50)
    Topbar.Position = UDim2.new(0, 150, 0, 0)
    Topbar.ZIndex = 20
    local Dragging = false
    local ActiveResize = false
    local IsAnimatingVis = false
    local DragStart
    local StartPos
    local TargetX = Main.Position.X.Offset
    local TargetY = Main.Position.Y.Offset
    local CurrentX = TargetX
    local CurrentY = TargetY
    Topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)
    local function UpdateDrag(input)
        local Delta = input.Position - DragStart
        TargetX = StartPos.X.Offset + Delta.X
        TargetY = StartPos.Y.Offset + Delta.Y
    end
    UserInputService.InputChanged:Connect(function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            UpdateDrag(input)
        end
    end)
    Main:GetPropertyChangedSignal("Position"):Connect(function()
        if not Dragging and not ActiveResize and not IsAnimatingVis then
            TargetX = Main.Position.X.Offset
            TargetY = Main.Position.Y.Offset
        end
    end)
    RunService.RenderStepped:Connect(function(dt)
        local FollowSpeed = 15
        CurrentX = CurrentX + (TargetX - CurrentX) * (1 - math.exp(-FollowSpeed * dt))
        CurrentY = CurrentY + (TargetY - CurrentY) * (1 - math.exp(-FollowSpeed * dt))
        Main.Position = UDim2.new(0.5, CurrentX, 0.5, CurrentY)
    end)
    
    local SidebarResizer = Instance.new("TextButton")
    SidebarResizer.Name = "SidebarResizer"
    SidebarResizer.Parent = Main
    SidebarResizer.BackgroundTransparency = 1
    SidebarResizer.Text = ""
    SidebarResizer.Position = UDim2.new(0, 18 + ExpandedSidebarWidth - 4, 0, 106)
    SidebarResizer.Size = UDim2.new(0, 12, 1, -124)
    SidebarResizer.ZIndex = 50
    
    local SidebarResizing = false
    local SidebarStartX = 0
    local SidebarStartWidth = ExpandedSidebarWidth
    
    SidebarResizer.InputBegan:Connect(function(input)
        if not IsSidebarCollapsed and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            SidebarResizing = true
            SidebarStartX = input.Position.X
            SidebarStartWidth = ExpandedSidebarWidth
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            SidebarResizing = false
        end
    end)
    
    local Workarea = Instance.new("Frame")
    Workarea.Name = "workarea"
    Workarea.Parent = Main
    RegisterTheme(Workarea, "BackgroundColor3", Color3.fromRGB(238, 238, 245), Color3.fromRGB(24, 24, 32))
    Workarea.Position = UDim2.new(0, ExpandedSidebarWidth + 30, 0, 0)
    Workarea.Size = UDim2.new(1, -(ExpandedSidebarWidth + 30), 1, 0)
    Workarea.BackgroundTransparency = 1
    local Uc_2 = Instance.new("UICorner")
    Uc_2.CornerRadius = UDim.new(0, 14)
    Uc_2.Parent = Workarea
    local Workareacornerhider = Instance.new("Frame")
    Workareacornerhider.Name = "workareacornerhider"
    Workareacornerhider.Parent = Workarea
    RegisterTheme(Workareacornerhider, "BackgroundColor3", Color3.fromRGB(238, 238, 245), Color3.fromRGB(24, 24, 32))
    Workareacornerhider.BorderSizePixel = 0
    Workareacornerhider.Size = UDim2.new(0, 18, 1, 0)
    Workareacornerhider.BackgroundTransparency = 1
    local EllipsisBtn = Instance.new("ImageButton")
    EllipsisBtn.Name = "ellipsisBtn"
    EllipsisBtn.Parent = Main
    EllipsisBtn.Size = UDim2.new(0, 24, 0, 24)
    EllipsisBtn.AnchorPoint = Vector2.new(1, 0)
    EllipsisBtn.Position = UDim2.new(1, -16, 0, 12)
    EllipsisBtn.BackgroundTransparency = 1
    EllipsisBtn.ZIndex = 26
    ResolveIcon(EllipsisBtn, "ellipsis-vertical")
    RegisterTheme(EllipsisBtn, "ImageColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
    local CollapseBtn = Instance.new("ImageButton")
    CollapseBtn.Name = "collapseBtn"
    CollapseBtn.Parent = Main
    CollapseBtn.Size = UDim2.new(0, 24, 0, 24)
    CollapseBtn.AnchorPoint = Vector2.new(1, 0)
    CollapseBtn.Position = UDim2.new(1, -16, 0, 12)
    CollapseBtn.BackgroundTransparency = 1
    CollapseBtn.ImageTransparency = 1
    CollapseBtn.Active = false
    CollapseBtn.Visible = false
    CollapseBtn.ZIndex = 25
    ResolveIcon(CollapseBtn, "panel-left-close")
    RegisterTheme(CollapseBtn, "ImageColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
    local RefreshBtn = Instance.new("ImageButton")
    RefreshBtn.Name = "refreshBtn"
    RefreshBtn.Parent = Main
    RefreshBtn.Size = UDim2.new(0, 24, 0, 24)
    RefreshBtn.AnchorPoint = Vector2.new(1, 0)
    RefreshBtn.Position = UDim2.new(1, -16, 0, 12)
    RefreshBtn.BackgroundTransparency = 1
    RefreshBtn.ImageTransparency = 1
    RefreshBtn.Active = false
    RefreshBtn.Visible = false
    RefreshBtn.ZIndex = 25
    ResolveIcon(RefreshBtn, "rotate-cw")
    RegisterTheme(RefreshBtn, "ImageColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
    local Moonbtn = Instance.new("ImageButton")
    Moonbtn.Name = "moonbtn"
    Moonbtn.Parent = Main
    Moonbtn.Size = UDim2.new(0, 24, 0, 24)
    Moonbtn.AnchorPoint = Vector2.new(1, 0)
    Moonbtn.Position = UDim2.new(1, -16, 0, 12)
    Moonbtn.BackgroundTransparency = 1
    Moonbtn.ImageTransparency = 1
    Moonbtn.Active = false
    Moonbtn.Visible = false
    Moonbtn.ZIndex = 25
    ResolveIcon(Moonbtn, CurrentTheme == "light" and "moon" or "sun")
    RegisterTheme(Moonbtn, "ImageColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
    local EllipsisExpanded = false
    EllipsisBtn.MouseButton1Click:Connect(function()
        EllipsisExpanded = not EllipsisExpanded
        local TwInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        if EllipsisExpanded then
            CollapseBtn.Visible = true
            RefreshBtn.Visible = true
            Moonbtn.Visible = true
            CollapseBtn.Active = true
            RefreshBtn.Active = true
            Moonbtn.Active = true
            TweenService:Create(CollapseBtn, TwInfo, { Position = UDim2.new(1, -112, 0, 12), ImageTransparency = 0 }):Play()
            TweenService:Create(RefreshBtn, TwInfo, { Position = UDim2.new(1, -80, 0, 12), ImageTransparency = 0 }):Play()
            TweenService:Create(Moonbtn, TwInfo, { Position = UDim2.new(1, -48, 0, 12), ImageTransparency = 0 }):Play()
            TweenService:Create(EllipsisBtn, TwInfo, { Rotation = 90 }):Play()
        else
            CollapseBtn.Active = false
            RefreshBtn.Active = false
            Moonbtn.Active = false
            TweenService:Create(CollapseBtn, TwInfo, { Position = UDim2.new(1, -16, 0, 12), ImageTransparency = 1 }):Play()
            TweenService:Create(RefreshBtn, TwInfo, { Position = UDim2.new(1, -16, 0, 12), ImageTransparency = 1 }):Play()
            TweenService:Create(Moonbtn, TwInfo, { Position = UDim2.new(1, -16, 0, 12), ImageTransparency = 1 }):Play()
            TweenService:Create(EllipsisBtn, TwInfo, { Rotation = 0 }):Play()
            task.delay(0.3, function()
                if not EllipsisExpanded then
                    CollapseBtn.Visible = false
                    RefreshBtn.Visible = false
                    Moonbtn.Visible = false
                end
            end)
        end
    end)
    local function ToggleTheme()
        CurrentTheme = (CurrentTheme == "light") and "dark" or "light"
        ConfigManager:SaveUISettings(CurrentTheme, ConfigManager.DisableSplash, ConfigManager.AccentColor, ConfigManager.Rainbow)
        ResolveIcon(Moonbtn, CurrentTheme == "light" and "moon" or "sun")
        for _, item in ipairs(ThemeElements) do
            pcall(function()
                if item.IsToggle and item.GetToggleState() then
                    item.Instance[item.Property] = CurrentAccentColor
                else
                    item.Instance[item.Property] = (CurrentTheme == "light") and item.Light or item.Dark
                end
            end)
        end
        local BgL = Color3.fromRGB(0, 0, 0)
        local BgD = Color3.fromRGB(255, 255, 255)
        local TxtL = Color3.fromRGB(100, 100, 100)
        local TxtD = Color3.fromRGB(140, 140, 155)
        for _, v in next, Sections do
            v.BackgroundColor3 = (CurrentTheme == "light") and BgL or BgD
            local Ico = v:FindFirstChild("iconImg")
            if v.Name == "sidebar2_selected" then
                v.TextColor3 = Color3.fromRGB(255, 255, 255)
                if Ico then Ico.ImageColor3 = Color3.fromRGB(255, 255, 255) end
            else
                v.TextColor3 = (CurrentTheme == "light") and TxtL or TxtD
                if Ico then Ico.ImageColor3 = (CurrentTheme == "light") and TxtL or TxtD end
            end
        end
    end
    Moonbtn.MouseButton1Click:Connect(function()
        local TwClick = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(Moonbtn, TwClick, { Rotation = Moonbtn.Rotation - 180 }):Play()
        ToggleTheme()
    end)
    local Search = Instance.new("Frame")
    Search.Name = "search"
    Search.Parent = Main
    RegisterTheme(Search, "BackgroundColor3", Color3.fromRGB(228, 228, 238), Color3.fromRGB(32, 32, 42))
    Search.Position = UDim2.new(0, 18, 0, 56)
    Search.Size = UDim2.new(0, IsSidebarCollapsed and 26 or 182, 0, 34)
    local Uc_8 = Instance.new("UICorner")
    Uc_8.CornerRadius = UDim.new(0, 10)
    Uc_8.Parent = Search
    local Searchicon = Instance.new("ImageButton")
    Searchicon.Name = "searchicon"
    Searchicon.Parent = Search
    Searchicon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Searchicon.BackgroundTransparency = 1
    Searchicon.BorderColor3 = Color3.fromRGB(27, 42, 53)
    Searchicon.AnchorPoint = Vector2.new(0.5, 0.5)
    Searchicon.Position = UDim2.new(0, 16, 0.5, 0)
    Searchicon.Size = UDim2.new(0, 20, 0, 20)
    Searchicon.Image = "rbxassetid://2804603863"
    Searchicon.ImageColor3 = Color3.fromRGB(95, 95, 95)
    Searchicon.ScaleType = Enum.ScaleType.Fit
    local Searchtextbox = Instance.new("TextBox")
    Searchtextbox.Name = "searchtextbox"
    Searchtextbox.Parent = Search
    Searchtextbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Searchtextbox.BackgroundTransparency = 1
    Searchtextbox.ClipsDescendants = true
    Searchtextbox.Position = UDim2.new(0, 34, 0, 0)
    Searchtextbox.Size = UDim2.new(1, -34, 1, 0)
    Searchtextbox.Font = Enum.Font.BuilderSansMedium
    Searchtextbox.LineHeight = 1
      Searchtextbox.TextYAlignment = Enum.TextYAlignment.Center
    Searchtextbox.PlaceholderText = "Search"
    Searchtextbox.Text = ""
    RegisterTheme(Searchtextbox, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
    Searchtextbox.TextSize = 15
    Searchtextbox.TextXAlignment = Enum.TextXAlignment.Left
    Searchicon.MouseButton1Click:Connect(function()
        Searchtextbox:CaptureFocus()
    end)
    local Sidebar = Instance.new("ScrollingFrame")
    Sidebar.Name = "sidebar"
    Sidebar.Parent = Main
    RegisterTheme(Sidebar, "BackgroundColor3", Color3.fromRGB(245, 245, 250), Color3.fromRGB(18, 18, 24))
    Sidebar.BackgroundTransparency = 1
    Sidebar.BorderSizePixel = 0
    Sidebar.Position = UDim2.new(0, 18, 0, 106)
    Sidebar.Size = UDim2.new(0, ExpandedSidebarWidth, 1, -124)
    Sidebar.AutomaticCanvasSize = "Y"
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    Sidebar.ScrollBarThickness = 0
    
    local SidebarList = Instance.new("Frame")
    SidebarList.Name = "sidebarList"
    SidebarList.Parent = Sidebar
    SidebarList.BackgroundTransparency = 1
    SidebarList.Size = UDim2.new(1, 0, 1, 0)
    SidebarList.ZIndex = 20
    
    local Ull_2 = Instance.new("UIListLayout")
    Ull_2.Parent = SidebarList
    Ull_2.HorizontalAlignment = Enum.HorizontalAlignment.Left
    local SidebarListPadding = Instance.new("UIPadding", SidebarList)
    SidebarListPadding.PaddingLeft = UDim.new(0, 3.5)
    Ull_2.SortOrder = Enum.SortOrder.LayoutOrder
    Ull_2.Padding = UDim.new(0, 3)
    Ull_2.SortOrder = Enum.SortOrder.LayoutOrder
    Ull_2.Padding = UDim.new(0, 3)
    Searchtextbox:GetPropertyChangedSignal("Text"):Connect(function()
        local InputText = string.upper(Searchtextbox.Text)
        local AllTabs = {}
        if IsExtraMode then
            for _, t in ipairs(ExtraTabs) do table.insert(AllTabs, t) end
        else
            for _, t in ipairs(MainTabs) do table.insert(AllTabs, t) end
        end
        local Highlight = Sidebar:FindFirstChild("TabHighlight")
        local ActiveTab = nil
        for _, s in ipairs(Sections) do
            if s.TextColor3 == Color3.fromRGB(255, 255, 255) then
                ActiveTab = s
                break
            end
        end
        if InputText == "" then
            for _, t in ipairs(AllTabs) do
                local BelongsToExtra = false
                for _, et in ipairs(ExtraTabs) do if t == et then BelongsToExtra = true end end
                if t.IsDivider then
                    t.Label.Visible = BelongsToExtra and IsExtraMode or not IsExtraMode
                else
                    t.TabButton.Visible = BelongsToExtra and IsExtraMode or not IsExtraMode
                end
                if t.ElementsList then
                    for _, elemData in ipairs(t.ElementsList) do
                        if elemData.gui then elemData.gui.Visible = true end
                    end
                end
            end
            if Highlight then Highlight.Visible = true end
        else
            for _, t in ipairs(AllTabs) do
                if t.IsDivider then
                    t.Label.Visible = false
                else
                    local Btn = t.TabButton
                    local match = false
                    if string.find(string.upper(Btn.Text), InputText) then
                        match = true
                    end
                    if t.ElementsList then
                        for _, elemData in ipairs(t.ElementsList) do
                            local ElemMatch = string.find(elemData.text, InputText) ~= nil
                            if elemData.gui then elemData.gui.Visible = ElemMatch end
                            if ElemMatch then match = true end
                        end
                    end
                    Btn.Visible = match
                end
            end
            if ActiveTab and Highlight then
                Highlight.Visible = ActiveTab.Visible
            end
        end
        if ActiveTab and Highlight then
            local Connection

        end
    end)
    local Buttons = Instance.new("Frame")
    Buttons.Name = "buttons"
    Buttons.Parent = Main
    Buttons.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Buttons.BackgroundTransparency = 1
    Buttons.Position = UDim2.new(0, 18, 0, 0)
    Buttons.Size = UDim2.new(0, 105, 0, 57)
    local Ull_3 = Instance.new("UIListLayout")
    Ull_3.Parent = Buttons
    Ull_3.FillDirection = Enum.FillDirection.Horizontal
    Ull_3.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Ull_3.SortOrder = Enum.SortOrder.LayoutOrder
    Ull_3.VerticalAlignment = Enum.VerticalAlignment.Center
    Ull_3.Padding = UDim.new(0, 10)
    local Close = Instance.new("TextButton")
    Close.Name = "close"
        Close.Parent = Buttons
    Close.BackgroundColor3 = Color3.fromRGB(254, 94, 86)
    Close.Size = UDim2.new(0, 16, 0, 16)
    Close.AutoButtonColor = false
    Close.Font = Enum.Font.SourceSans
    Close.Text = ""
    Close.TextColor3 = Color3.fromRGB(255, 50, 50)
    Close.TextSize = 14
    Close.MouseButton1Click:Connect(function()
        if Blur:HasBinding(BlurFrame) then
            Blur:UnbindFrame(BlurFrame)
        end
        for _, v in pairs(game:GetService("Lighting"):GetChildren()) do
            if v:IsA("DepthOfFieldEffect") then v:Destroy() end
        end
        local NeonFolder = workspace.CurrentCamera:FindFirstChild("Neon")
        if NeonFolder then NeonFolder:Destroy() end
        RunService:UnbindFromRenderStep("AppleLibMouseUnlock")
        UserInputService.MouseIconEnabled = true
        task.delay(0.1, function()
            UserInputService.MouseIconEnabled = true
        end)
        if VisibleKeyConn then VisibleKeyConn:Disconnect() end
        for _, conn in ipairs(CleanupKeybinds) do
            if conn.Connected then conn:Disconnect() end
        end
        for _, toggleInfo in ipairs(CleanupToggles) do
            if toggleInfo.callback then
                pcall(toggleInfo.callback, toggleInfo.default)
            end
        end
        scrgui:Destroy()
    end)
    local Uc_18 = Instance.new("UICorner")
    Uc_18.CornerRadius = UDim.new(1, 0)
    Uc_18.Parent = Close
    local Minimize = Instance.new("TextButton")
    Minimize.Name = "minimize"
        Minimize.Parent = Buttons
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 189, 46)
    Minimize.Size = UDim2.new(0, 16, 0, 16)
    Minimize.AutoButtonColor = false
    Minimize.Font = Enum.Font.SourceSans
    Minimize.Text = ""
    Minimize.TextColor3 = Color3.fromRGB(255, 50, 50)
    Minimize.TextSize = 14
    local Uc_19 = Instance.new("UICorner")
    Uc_19.CornerRadius = UDim.new(1, 0)
    Uc_19.Parent = Minimize
    local Resize = Instance.new("TextButton")
    Resize.Name = "resize"
    Resize.Parent = Buttons
    Resize.BackgroundColor3 = Color3.fromRGB(39, 200, 63)
    Resize.Size = UDim2.new(0, 16, 0, 16)
    Resize.AutoButtonColor = false
    Resize.Font = Enum.Font.SourceSans
    Resize.Text = ""
    Resize.TextColor3 = Color3.fromRGB(255, 50, 50)
    Resize.TextSize = 14
    Resize.MouseButton1Click:Connect(function()
        if TabSwapCooldown then return end
        TabSwapCooldown = true
        IsExtraMode = not IsExtraMode
        local OutgoingTabs = IsExtraMode and MainTabs or ExtraTabs
        local IncomingTabs = IsExtraMode and ExtraTabs or MainTabs
        local Highlight = Sidebar:FindFirstChild("TabHighlight")
        if Highlight then
            TweenService:Create(Highlight, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1
            }):Play()
        end
        for _, t in ipairs(OutgoingTabs) do
            if t.IsDivider then
                TweenService:Create(t.Label, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    TextTransparency = 1
                }):Play()
            else
                local Btn = t.TabButton
                TweenService:Create(Btn, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    Size = UDim2.new(0, 0, 0, 34),
                    TextTransparency = 1,
                    BackgroundTransparency = 1
                }):Play()
                local Ico = Btn:FindFirstChild("iconImg")
                if Ico then
                    TweenService:Create(Ico, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        ImageTransparency = 1
                    }):Play()
                end
            end
        end
        task.delay(0.25, function()
            for _, t in ipairs(OutgoingTabs) do
                if t.IsDivider then t.Label.Visible = false else t.TabButton.Visible = false end
            end
            local FirstSection = nil
            local FirstIncomingIdx = nil
            for i, t in ipairs(IncomingTabs) do
                if t.IsDivider and not FirstIncomingIdx then FirstIncomingIdx = i end
            end
            for i, t in ipairs(IncomingTabs) do
                local TxtTrans = IsSidebarCollapsed and 1 or 0
                local PadLeft = IsSidebarCollapsed and 0 or 40
                if t.IsDivider then
                    local IsFirstInMode = (i == FirstIncomingIdx)
                    local TargetHeight = IsSidebarCollapsed and 12 or 20
                    if IsFirstInMode and IsSidebarCollapsed then TargetHeight = 0 end
                    t.Label.TextTransparency = 1
                    t.Label.Visible = true
                    TweenService:Create(t.Label, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        TextTransparency = TxtTrans,
                        Size = UDim2.new(0, IsSidebarCollapsed and 34 or (ExpandedSidebarWidth - 7), 0, TargetHeight)
                    }):Play()
                    local Line = t.Label:FindFirstChild("Line")
                    if Line then
                        if IsFirstInMode then
                            TweenService:Create(Line, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
                        else
                            TweenService:Create(Line, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundTransparency = IsSidebarCollapsed and 0 or 1 }):Play()
                        end
                    end
                else
                    local Btn = t.TabButton
                    local CurrentTargetWidth = IsSidebarCollapsed and 34 or 183
                    Btn.Size = UDim2.new(0, CurrentTargetWidth, 0, 34)
                    Btn.TextTransparency = 1
                    Btn.BackgroundTransparency = 1
                    Btn.Visible = true
                    local Ico = Btn:FindFirstChild("iconImg")
                    if Ico then Ico.ImageTransparency = 1 end
                    local padding = Btn:FindFirstChildOfClass("UIPadding")
                    if padding then
                        TweenService:Create(padding, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { PaddingLeft = UDim.new(0, PadLeft) }):Play()
                    end
                    if not FirstSection then FirstSection = t end
                    local BgTrans = (Btn.Name == "sidebar2_selected") and 1 or 0.93
                    local CurrentTargetWidth = IsSidebarCollapsed and 34 or 183
                    TweenService:Create(Btn, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, CurrentTargetWidth, 0, 34),
                        TextTransparency = TxtTrans,
                        BackgroundTransparency = BgTrans
                    }):Play()
                    if Ico then
                        TweenService:Create(Ico, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                            ImageTransparency = 0,
                            Position = IsSidebarCollapsed and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, -16, 0.5, 0)
                        }):Play()
                    end
                end
            end
            if FirstSection and type(FirstSection.Select) == "function" then
        task.spawn(function()
            RunService.RenderStepped:Wait()
            FirstSection:Select(true)
        end)
    end
            task.delay(0.3, function()
                TabSwapCooldown = false
            end)
        end)
    end)
    local Uc_20 = Instance.new("UICorner")
    Uc_20.CornerRadius = UDim.new(1, 0)
    Uc_20.Parent = Resize
    local Title = Instance.new("TextLabel")
    Title.Name = "title"
    Title.Parent = Workarea
    Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Title.BackgroundTransparency = 1
    Title.BorderSizePixel = 2
    Title.Position = UDim2.new(0, 16, 0, 16)
    Title.Size = UDim2.new(1, -32, 0, 30)
    Title.Font = Enum.Font.BuilderSansBold
    Title.LineHeight = 1.180
    RegisterTheme(Title, "TextColor3", Color3.fromRGB(15, 15, 20), Color3.fromRGB(240, 240, 245))
    Title.TextSize = 22
    Title.TextWrapped = true
    Title.TextXAlignment = Enum.TextXAlignment.Left
    local ResizeRight = Instance.new("TextButton")
    ResizeRight.Name = "resizeRight"
    ResizeRight.Parent = Main
    ResizeRight.Size = UDim2.new(0, 8, 1, -10)
    ResizeRight.Position = UDim2.new(1, -8, 0, 0)
    ResizeRight.BackgroundTransparency = 1
    ResizeRight.Text = ""
    ResizeRight.ZIndex = 11
    local ResizeBottom = Instance.new("TextButton")
    ResizeBottom.Name = "resizeBottom"
    ResizeBottom.Parent = Main
    ResizeBottom.Size = UDim2.new(1, -10, 0, 8)
    ResizeBottom.Position = UDim2.new(0, 0, 1, -8)
    ResizeBottom.BackgroundTransparency = 1
    ResizeBottom.Text = ""
    ResizeBottom.ZIndex = 11
    local ResizeCorner = Instance.new("TextButton")
    ResizeCorner.Name = "resizeCorner"
    ResizeCorner.Parent = Main
    ResizeCorner.Size = UDim2.new(0, 15, 0, 15)
    ResizeCorner.Position = UDim2.new(1, -15, 1, -15)
    ResizeCorner.BackgroundTransparency = 1
    ResizeCorner.Text = ""
    ResizeCorner.ZIndex = 12
    local ResizeStartSize
    local ResizeStartMouse
    local ResizeStartPos
    local function SetupResize(Btn, type)
        Btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                ActiveResize = type
                ResizeStartSize = Main.Size
                ResizeStartMouse = input.Position
                ResizeStartPos = Main.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        ActiveResize = false
                    end
                end)
            end
        end)
    end
    SetupResize(ResizeRight, "right")
    SetupResize(ResizeBottom, "bottom")
    SetupResize(ResizeCorner, "corner")
    UserInputService.InputChanged:Connect(function(input)
        if SidebarResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local DeltaX = input.Position.X - SidebarStartX
            ExpandedSidebarWidth = math.clamp(SidebarStartWidth + DeltaX, 75, 400)
            if not IsSidebarCollapsed then
                Sidebar.Size = UDim2.new(0, ExpandedSidebarWidth, 1, -124)
                SidebarResizer.Position = UDim2.new(0, 18 + ExpandedSidebarWidth - 4, 0, 106)
                Workarea.Position = UDim2.new(0, ExpandedSidebarWidth + 30, 0, 0)
                Workarea.Size = UDim2.new(1, -(ExpandedSidebarWidth + 30), 1, 0)
                local CurrentSearch = Main:FindFirstChild("search")
                if CurrentSearch then CurrentSearch.Size = UDim2.new(0, ExpandedSidebarWidth - 8, 0, 34) end
            end
        end
        if ActiveResize and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local Delta = input.Position - ResizeStartMouse
            local NewWidth = Main.Size.X.Offset
            local NewHeight = Main.Size.Y.Offset
            if ActiveResize == "right" or ActiveResize == "corner" then
                NewWidth = math.max(ResizeStartSize.X.Offset + Delta.X, 350)
            end
            if ActiveResize == "bottom" or ActiveResize == "corner" then
                NewHeight = math.max(ResizeStartSize.Y.Offset + Delta.Y, 250)
            end
            local DeltaWidth = NewWidth - ResizeStartSize.X.Offset
            local DeltaHeight = NewHeight - ResizeStartSize.Y.Offset
            TargetX = ResizeStartPos.X.Offset + (DeltaWidth / 2)
            TargetY = ResizeStartPos.Y.Offset + (DeltaHeight / 2)
            Main.Size = UDim2.new(0, NewWidth, 0, NewHeight)
            CurrentX = TargetX
            CurrentY = TargetY
            Main.Position = UDim2.new(0.5, CurrentX, 0.5, CurrentY)
        end
    end)
    local Notif = Instance.new("Frame")
    Notif.Name = "notif"
    Notif.Parent = Main
    Notif.AnchorPoint = Vector2.new(0.5, 0.5)
    RegisterTheme(Notif, "BackgroundColor3", Color3.fromRGB(255, 255, 255), Color3.fromRGB(40, 40, 40))
    Notif.Position = UDim2.new(0.5, 0, 0.5, 0)
    Notif.Size = UDim2.new(0, 304, 0, 362)
    Notif.Visible = false
    Notif.ZIndex = 101
    local Uc_11 = Instance.new("UICorner")
    Uc_11.CornerRadius = UDim.new(0, 18)
    Uc_11.Parent = Notif
    local Notificon = Instance.new("ImageLabel")
    Notificon.Name = "notificon"
    Notificon.Parent = Notif
    Notificon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Notificon.BackgroundTransparency = 1
    Notificon.Position = UDim2.new(0.335526317, 0, 0.0994475111, 0)
    Notificon.Size = UDim2.new(0, 100, 0, 100)
    Notificon.ZIndex = 102
    Notificon.Image = "rbxassetid://4871684504"
    Notificon.ImageColor3 = Color3.fromRGB(95, 95, 95)
    local Notifbutton1 = Instance.new("TextButton")
    Notifbutton1.Name = "notifbutton1"
    Notifbutton1.Parent = Notif
    Notifbutton1.BackgroundColor3 = CurrentAccentColor
    Notifbutton1.Position = UDim2.new(0.0559210554, 0, 0.817679524, 0)
    Notifbutton1.Size = UDim2.new(0, 270, 0, 50)
    Notifbutton1.ZIndex = 102
    Notifbutton1.Font = Enum.Font.BuilderSans
    Notifbutton1.Text = "OK"
    Notifbutton1.TextColor3 = Color3.fromRGB(255, 255, 255)
    Notifbutton1.TextSize = 21
    local Uc_12 = Instance.new("UICorner")
    Uc_12.CornerRadius = UDim.new(0, 9)
    Uc_12.Parent = Notifbutton1
    local Notifshadow = Instance.new("ImageLabel")
    Notifshadow.Name = "notifshadow"
    Notifshadow.Parent = Notif
    Notifshadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Notifshadow.BackgroundTransparency = 1
    Notifshadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Notifshadow.Size = UDim2.new(1.20000005, 0, 1.20000005, 0)
    Notifshadow.Image = "rbxassetid://313486536"
    Notifshadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    local Notifdarkness = Instance.new("Frame")
    Notifdarkness.Name = "notifdarkness"
    Notifdarkness.Parent = Main
    Notifdarkness.AnchorPoint = Vector2.new(0.5, 0.5)
    Notifdarkness.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Notifdarkness.BackgroundTransparency = 0.600
    Notifdarkness.Position = UDim2.new(0.5, 0, 0.5, 0)
    Notifdarkness.Size = UDim2.new(0, 721, 0, 584)
    Notifdarkness.ZIndex = 100
    Notifdarkness.Visible = false
    local Uc_13 = Instance.new("UICorner")
    Uc_13.CornerRadius = UDim.new(0, 18)
    Uc_13.Parent = Notifdarkness
    local KeybindPromptFrame = Instance.new("Frame")
    KeybindPromptFrame.Name = "keybindPromptFrame"
    KeybindPromptFrame.Parent = Main
    KeybindPromptFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    RegisterTheme(KeybindPromptFrame, "BackgroundColor3", Color3.fromRGB(255, 255, 255), Color3.fromRGB(40, 40, 40))
    KeybindPromptFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    KeybindPromptFrame.Size = UDim2.new(0, 304, 0, 160)
    KeybindPromptFrame.Visible = false
    KeybindPromptFrame.ZIndex = 101
    local Uc_kp = Instance.new("UICorner")
    Uc_kp.CornerRadius = UDim.new(0, 18)
    Uc_kp.Parent = KeybindPromptFrame
    local KpTitle = Instance.new("TextLabel")
    KpTitle.Name = "kpTitle"
    KpTitle.Parent = KeybindPromptFrame
    KpTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    KpTitle.BackgroundTransparency = 1
    KpTitle.Position = UDim2.new(0, 0, 0, 30)
    KpTitle.Size = UDim2.new(1, 0, 0, 50)
    KpTitle.ZIndex = 102
    KpTitle.Font = Enum.Font.BuilderSansMedium
    KpTitle.Text = "Press a key to bind..."
    RegisterTheme(KpTitle, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
    KpTitle.TextSize = 24
    local KpSub = Instance.new("TextLabel")
    KpSub.Name = "kpSub"
    KpSub.Parent = KeybindPromptFrame
    KpSub.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    KpSub.BackgroundTransparency = 1
    KpSub.Position = UDim2.new(0, 0, 0, 80)
    KpSub.Size = UDim2.new(1, 0, 0, 30)
    KpSub.ZIndex = 102
    KpSub.Font = Enum.Font.BuilderSans
    KpSub.Text = "Press ESC to cancel"
    RegisterTheme(KpSub, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(150, 150, 170))
    KpSub.TextSize = 16
    local Notiftitle = Instance.new("TextLabel")
    Notiftitle.Name = "notiftitle"
    Notiftitle.Parent = Notif
    Notiftitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Notiftitle.BackgroundTransparency = 1
    Notiftitle.Position = UDim2.new(0.167763159, 0, 0.375690609, 0)
    Notiftitle.Size = UDim2.new(0, 200, 0, 50)
    Notiftitle.ZIndex = 102
    Notiftitle.Font = Enum.Font.BuilderSansMedium
    Notiftitle.Text = "Notice"
    RegisterTheme(Notiftitle, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
    Notiftitle.TextSize = 28
    local Notiftext = Instance.new("TextLabel")
    Notiftext.Name = "notiftext"
    Notiftext.Parent = Notif
    Notiftext.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Notiftext.BackgroundTransparency = 1
    Notiftext.Position = UDim2.new(0.0822368413, 0, 0.513812184, 0)
    Notiftext.Size = UDim2.new(0, 254, 0, 66)
    Notiftext.ZIndex = 102
    Notiftext.Font = Enum.Font.BuilderSans
    Notiftext.Text = "We would like to contact you regarding your car's extended warranty."
    RegisterTheme(Notiftext, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
    Notiftext.TextSize = 16
    Notiftext.TextWrapped = true
    Notiftext.TextScaled = true
    local Notif2 = Instance.new("Frame")
    Notif2.Name = "notif2"
    Notif2.Parent = Main
    Notif2.AnchorPoint = Vector2.new(0.5, 0.5)
    RegisterTheme(Notif2, "BackgroundColor3", Color3.fromRGB(255, 255, 255), Color3.fromRGB(40, 40, 40))
    Notif2.Position = UDim2.new(0.5, 0, 0.5, 0)
    Notif2.Size = UDim2.new(0, 304, 0, 362)
    Notif2.Visible = false
    Notif2.ZIndex = 101
    local Uc_14 = Instance.new("UICorner")
    Uc_14.CornerRadius = UDim.new(0, 18)
    Uc_14.Parent = Notif2
    local Notif2icon = Instance.new("ImageLabel")
    Notif2icon.Name = "notif2icon"
    Notif2icon.Parent = Notif2
    Notif2icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Notif2icon.BackgroundTransparency = 1
    Notif2icon.Position = UDim2.new(0.335526317, 0, 0.0994475111, 0)
    Notif2icon.Size = UDim2.new(0, 100, 0, 100)
    Notif2icon.ZIndex = 102
    Notif2icon.Image = "rbxassetid://12608260095"
    Notif2icon.ImageColor3 = Color3.fromRGB(95, 95, 95)
    local Notif2title = Instance.new("TextLabel")
    Notif2title.Name = "notif2title"
    Notif2title.Parent = Notif2
    Notif2title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Notif2title.BackgroundTransparency = 1
    Notif2title.Position = UDim2.new(0.167763159, 0, 0.375690609, 0)
    Notif2title.Size = UDim2.new(0, 200, 0, 50)
    Notif2title.ZIndex = 102
    Notif2title.Font = Enum.Font.BuilderSansMedium
    Notif2title.Text = "Notice"
    RegisterTheme(Notif2title, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
    Notif2title.TextSize = 28
    local Notif2text = Instance.new("TextLabel")
    Notif2text.Name = "notif2text"
    Notif2text.Parent = Notif2
    Notif2text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Notif2text.BackgroundTransparency = 1
    Notif2text.Position = UDim2.new(0.0822368413, 0, 0.513812184, 0)
    Notif2text.Size = UDim2.new(0, 254, 0, 66)
    Notif2text.ZIndex = 102
    Notif2text.Font = Enum.Font.BuilderSans
    Notif2text.Text = "We would like to contact you regarding your car's extended warranty."
    RegisterTheme(Notif2text, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
    Notif2text.TextSize = 16
    Notif2text.TextWrapped = true
    local Notif2button1 = Instance.new("TextButton")
    Notif2button1.Name = "notif2button1"
    Notif2button1.Parent = Notif2
    Notif2button1.BackgroundColor3 = CurrentAccentColor
    Notif2button1.Position = UDim2.new(0.0559210517, 0, 0.715469658, 0)
    Notif2button1.Size = UDim2.new(0, 270, 0, 40)
    Notif2button1.ZIndex = 102
    Notif2button1.Font = Enum.Font.BuilderSans
    Notif2button1.Text = "Sure!"
    Notif2button1.TextColor3 = Color3.fromRGB(255, 255, 255)
    Notif2button1.TextSize = 21
    local Uc_15 = Instance.new("UICorner")
    Uc_15.CornerRadius = UDim.new(0, 9)
    Uc_15.Parent = Notif2button1
    local Notif2shadow = Instance.new("ImageLabel")
    Notif2shadow.Name = "notif2shadow"
    Notif2shadow.Parent = Notif2
    Notif2shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Notif2shadow.BackgroundTransparency = 1
    Notif2shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    Notif2shadow.Size = UDim2.new(1.20000005, 0, 1.20000005, 0)
    Notif2shadow.Image = "rbxassetid://313486536"
    Notif2shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    local Notif2darkness = Instance.new("Frame")
    Notif2darkness.Name = "notif2darkness"
    Notif2darkness.Parent = Main
    Notif2darkness.AnchorPoint = Vector2.new(0.5, 0.5)
    Notif2darkness.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Notif2darkness.BackgroundTransparency = 0.600
    Notif2darkness.Position = UDim2.new(0.5, 0, 0.5, 0)
    Notif2darkness.Size = UDim2.new(0, 721, 0, 584)
    Notif2darkness.ZIndex = 100
    Notif2darkness.Visible = false
    local Uc_16 = Instance.new("UICorner")
    Uc_16.CornerRadius = UDim.new(0, 18)
    Uc_16.Parent = Notif2darkness
    local Notif2button2 = Instance.new("TextButton")
    Notif2button2.Name = "notif2button2"
    Notif2button2.Parent = Notif2
    Notif2button2.BackgroundColor3 = CurrentAccentColor
    Notif2button2.BackgroundTransparency = 1
    Notif2button2.Position = UDim2.new(0.0526315793, 0, 0.842541456, 0)
    Notif2button2.Size = UDim2.new(0, 270, 0, 40)
    Notif2button2.ZIndex = 102
    Notif2button2.Font = Enum.Font.BuilderSans
    Notif2button2.Text = "Go away."
    RegisterTheme(Notif2button2, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
    Notif2button2.TextSize = 21
    local Uc_17 = Instance.new("UICorner")
    Uc_17.CornerRadius = UDim.new(0, 9)
    Uc_17.Parent = Notif2button2
    if ti then
        Title.Text = ti
    else
        Title.Text = ""
    end
    Tp(Main, UDim2.new(0.5, 0, 0.5, 0), 1)
    Window = {}
    local OriginalMouseIconEnabled = true
    local OriginalMouseBehavior = Enum.MouseBehavior.Default
    local CursorRenderName = "AppleLibMouseUnlock"
    pcall(function() RunService:UnbindFromRenderStep(CursorRenderName) end)
    RunService:BindToRenderStep(CursorRenderName, 2000, function() 
        if visible then
            UserInputService.MouseIconEnabled = true
            if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end
        end
    end)
    local LastX, LastY = 0, 0
    function Window:PromptKeybind(callback, Flag)
        if IsPromptingKeybind then return end
        IsPromptingKeybind = true
        KeybindPromptCallback = callback
        KeybindPromptElementName = Flag or "Unknown"
        if KpTitle then KpTitle.Text = "Binding: " .. (Flag or "") end
        if KpSub then KpSub.Text = "Press a key... [ESC to cancel]" end
        if Notifdarkness then 
            Notifdarkness.ZIndex = 100
            Notifdarkness.Visible = true 
        end
        if KeybindPromptFrame then KeybindPromptFrame.Visible = true end
    end
    function Window:ToggleVisible()
        if Dbcooper then return end
        if not visible then
            OriginalMouseIconEnabled = UserInputService.MouseIconEnabled
        end
        visible = not visible
        Dbcooper = true
        IsAnimatingVis = true
        ModalUnlocker.Modal = visible
        if visible then
            if BlurEnabled then
                Blur:BindFrame(BlurFrame, {
                    Transparency = 0.98,
                    Color = Color3.fromRGB(255, 255, 255)
                })
            end
            TargetX = LastX
            TargetY = LastY
            CurrentX = LastX
            CurrentY = LastY
            Uiscale.Scale = 0
            Main.Position = UDim2.new(0.5, CurrentX, 0.5, CurrentY)
            TweenService:Create(Uiscale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = CScale}):Play()
            task.delay(0.3, function() 
                Dbcooper = false 
                IsAnimatingVis = false 
            end)
        else
            if Blur:HasBinding(BlurFrame) then
                Blur:UnbindFrame(BlurFrame)
            end
            LastX = TargetX
            LastY = TargetY
            TweenService:Create(Uiscale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0}):Play()
            task.delay(0.25, function() 
                if not visible then
                    TargetY = -2000
                    CurrentY = -2000
                    UserInputService.MouseIconEnabled = OriginalMouseIconEnabled
                end
                Dbcooper = false 
                IsAnimatingVis = false 
            end)
        end
    end
    local VisibleKeyConn
    local function RebindVisibleKey(newKey)
        if VisibleKeyConn then VisibleKeyConn:Disconnect() end
        visiblekey = newKey
        VisibleKeyConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.KeyCode == visiblekey then
                Window:ToggleVisible()
            end
        end)
    end
    if visiblekey then
        Minimize.MouseButton1Click:Connect(function()
            Window:ToggleVisible()
        end)
        RebindVisibleKey(visiblekey)
    end
    local ActiveNotifs = {}
    local NotifBaseY = IsMob and 0.15 or 0.08
    local NotifSpacing = IsMob and 85 or 105
    function Window:TempNotify(text1, text2, icon)
        local TempNotifContainer = scrgui:FindFirstChild("TempNotifContainer")
        if not TempNotifContainer then
            TempNotifContainer = Instance.new("Frame")
            TempNotifContainer.Name = "TempNotifContainer"
            TempNotifContainer.Parent = scrgui
            TempNotifContainer.BackgroundTransparency = 1
            TempNotifContainer.Position = UDim2.new(1, -20, 0, 30)
            TempNotifContainer.Size = UDim2.new(0, 450, 1, -60)
            TempNotifContainer.AnchorPoint = Vector2.new(1, 0)
            TempNotifContainer.ZIndex = 1000
            TempNotifContainer.ClipsDescendants = false
            
            local UIList = Instance.new("UIListLayout")
            UIList.Parent = TempNotifContainer
            UIList.SortOrder = Enum.SortOrder.LayoutOrder
            UIList.HorizontalAlignment = Enum.HorizontalAlignment.Right
            UIList.VerticalAlignment = Enum.VerticalAlignment.Top
            UIList.Padding = UDim.new(0, 10)
        end
        
        local Tempnotif = Instance.new("Frame")
        Tempnotif.Name = "tempnotif"
        Tempnotif.Parent = TempNotifContainer
        Tempnotif.AnchorPoint = Vector2.new(0, 0)
        RegisterTheme(Tempnotif, "BackgroundColor3", Color3.fromRGB(255, 255, 255), Color3.fromRGB(40, 40, 40))
        Tempnotif.BackgroundTransparency = 1
        Tempnotif.Size = UDim2.new(0, 447, 0, 117)
        Tempnotif.Visible = true
        Tempnotif.ZIndex = 1001
        
        local Uc_21 = Instance.new("UICorner")
        Uc_21.CornerRadius = UDim.new(0, 18)
        Uc_21.Parent = Tempnotif
        
        local T1 = Instance.new("TextLabel")
        T1.Name = "t1"
        T1.Parent = Tempnotif
        T1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        T1.BackgroundTransparency = 1
        T1.Position = UDim2.new(0.234690696, 0, 0.193464488, 0)
        T1.Size = UDim2.new(0, 327, 0, 25)
        T1.ZIndex = 1002
        T1.Font = Enum.Font.BuilderSansMedium
        T1.Text = text1
        T1.TextTransparency = 1
        RegisterTheme(T1, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
        T1.TextSize = 28
        T1.TextXAlignment = Enum.TextXAlignment.Left
        
        local T2 = Instance.new("TextLabel")
        T2.Name = "t2"
        T2.Parent = Tempnotif
        T2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        T2.BackgroundTransparency = 1
        T2.Position = UDim2.new(0.236927822, 0, 0.470085472, 0)
        T2.Size = UDim2.new(0, 326, 0, 52)
        T2.ZIndex = 1002
        T2.Font = Enum.Font.BuilderSans
        T2.Text = text2
        T2.TextTransparency = 1
        RegisterTheme(T2, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
        T2.TextSize = 16
        T2.TextWrapped = true
        T2.TextXAlignment = Enum.TextXAlignment.Left
        T2.TextYAlignment = Enum.TextYAlignment.Top
        
        local Ticon = Instance.new("ImageLabel")
        Ticon.Name = "ticon"
        Ticon.Parent = Tempnotif
        Ticon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Ticon.BackgroundTransparency = 1
        Ticon.Position = UDim2.new(0.0311112702, 0, 0.193464488, 0)
        Ticon.Size = UDim2.new(0, 71, 0, 71)
        Ticon.ZIndex = 1002
        Ticon.ImageTransparency = 1
        ResolveIcon(Ticon, icon)
        RegisterTheme(Ticon, "ImageColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
        Ticon.ScaleType = Enum.ScaleType.Fit
        
        local Tshadow = Instance.new("ImageLabel")
        Tshadow.Name = "tshadow"
        Tshadow.Parent = Tempnotif
        Tshadow.AnchorPoint = Vector2.new(0.5, 0.5)
        Tshadow.BackgroundTransparency = 1
        Tshadow.Position = UDim2.new(0.5, 0, 0.5, 0)
        Tshadow.Size = UDim2.new(1.12, 0, 1.2, 0)
        Tshadow.ZIndex = 1000
        Tshadow.Image = "rbxassetid://313486536"
        Tshadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        Tshadow.ImageTransparency = 1
        Tshadow.TileSize = UDim2.new(0, 1, 0, 1)
        
        TweenService:Create(Tempnotif, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.150
        }):Play()
        TweenService:Create(T1, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 0
        }):Play()
        TweenService:Create(T2, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            TextTransparency = 0
        }):Play()
        TweenService:Create(Ticon, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ImageTransparency = 0
        }):Play()
        TweenService:Create(Tshadow, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            ImageTransparency = 0.400
        }):Play()
        
        task.delay(4.5, function()
            if Tempnotif and Tempnotif.Parent then
                local TwOut = TweenService:Create(Tempnotif, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    BackgroundTransparency = 1
                })
                TweenService:Create(T1, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
                TweenService:Create(T2, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 }):Play()
                TweenService:Create(Ticon, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { ImageTransparency = 1 }):Play()
                TweenService:Create(Tshadow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { ImageTransparency = 1 }):Play()
                TwOut:Play()
                TwOut.Completed:Connect(function()
                    Tempnotif:Destroy()
                end)
            end
        end)
    end
    function Window:Notify(txt1, txt2, b1, icohn, callback)
        if Notif.Visible == true or Notif2.Visible == true then return "Already visible" end
        Notiftitle.Text = txt1
        Notiftext.Text = txt2
        ResolveIcon(Notificon, icohn)
        if not Notif:FindFirstChild("NotifScale") then
            local NotifScale = Instance.new("UIScale")
            NotifScale.Name = "NotifScale"
            NotifScale.Parent = Notif
        end
        local NotifScale = Notif.NotifScale
        Notif.Size = UDim2.new(0, 304, 0, 362)
        NotifScale.Scale = 0.8
        Notif.Position = UDim2.new(0.5, 0, 0.5, 40)
        Notifdarkness.Visible = true
        Notif.Visible = true
        Notifbutton1.Text = b1
        TweenService:Create(NotifScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(Notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        con1 = Notifbutton1.MouseButton1Click:Connect(function()
            if con1 then con1:Disconnect() end
            if callback then callback() end
            TweenService:Create(NotifScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.8}):Play()
            TweenService:Create(Notif, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0.5, 40)
            }):Play()
            task.delay(0.3, function()
                Notif.Visible = false
                Notifdarkness.Visible = false
            end)
        end)
    end
    function Window:Notify2(txt1, txt2, b1, b2, icohn, callback, callback2)
        if Notif.Visible == true or Notif2.Visible == true then return "Already visible" end
        Notif2title.Text = txt1
        Notif2text.Text = txt2
        ResolveIcon(Notif2icon, icohn)
        if not Notif2:FindFirstChild("Notif2Scale") then
            local Notif2Scale = Instance.new("UIScale")
            Notif2Scale.Name = "Notif2Scale"
            Notif2Scale.Parent = Notif2
        end
        local Notif2Scale = Notif2.Notif2Scale
        Notif2.Size = UDim2.new(0, 304, 0, 362)
        Notif2Scale.Scale = 0.8
        Notif2.Position = UDim2.new(0.5, 0, 0.5, 40)
        Notif2darkness.Visible = true
        Notif2.Visible = true
        Notif2button1.Text = b1
        Notif2button2.Text = b2
        TweenService:Create(Notif2Scale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
        TweenService:Create(Notif2, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        con1 = Notif2button1.MouseButton1Click:Connect(function()
            if con1 then con1:Disconnect() end
            if con2 then con2:Disconnect() end
            if callback then callback() end
            TweenService:Create(Notif2Scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.8}):Play()
            TweenService:Create(Notif2, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0.5, 40)
            }):Play()
            task.delay(0.3, function()
                Notif2.Visible = false
                Notif2darkness.Visible = false
            end)
        end)
        con2 = Notif2button2.MouseButton1Click:Connect(function()
            if con1 then con1:Disconnect() end
            if con2 then con2:Disconnect() end
            if callback2 then callback2() end
            TweenService:Create(Notif2Scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0.8}):Play()
            TweenService:Create(Notif2, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0.5, 40)
            }):Play()
            task.delay(0.3, function()
                Notif2.Visible = false
                Notif2darkness.Visible = false
            end)
        end)
    end
    function Window:Divider(name, _internalExtra)
        local Sidebardivider = Instance.new("TextLabel")
        Sidebardivider.Name = "sidebardivider"
        Sidebardivider.Parent = SidebarList
        Sidebardivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Sidebardivider.BackgroundTransparency = 1
        Sidebardivider.BorderSizePixel = 2
        Sidebardivider.Position = UDim2.new(0, 0, 0.00215982716, 0)
        Sidebardivider.Size = UDim2.new(0, IsSidebarCollapsed and 34 or (ExpandedSidebarWidth - 7), 0, 20)
        Sidebardivider.Font = Enum.Font.BuilderSansBold
        Sidebardivider.Text = name
        RegisterTheme(Sidebardivider, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(100, 100, 120))
        Sidebardivider.TextSize = 11
        Sidebardivider.TextWrapped = true
        Sidebardivider.TextXAlignment = Enum.TextXAlignment.Left
        Sidebardivider.TextYAlignment = Enum.TextYAlignment.Bottom
        local Line = Instance.new("Frame")
        Line.Name = "Line"
        Line.Parent = Sidebardivider
        Line.Size = UDim2.new(0, 30, 0, 2)
        Line.Position = UDim2.new(0.5, 0, 0.5, 0)
        Line.AnchorPoint = Vector2.new(0.5, 0.5)
        Line.BackgroundTransparency = 1
        Line.BorderSizePixel = 0
        RegisterTheme(Line, "BackgroundColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(100, 100, 120))
        if _internalExtra then
            table.insert(ExtraTabs, {IsDivider = true, Label = Sidebardivider})
            Sidebardivider.Visible = false
        else
            table.insert(MainTabs, {IsDivider = true, Label = Sidebardivider})
        end
    end
    function Window:Section(name, iconId, _internalExtra)
        local Sidebar2 = Instance.new("TextButton")
        Sidebar2.ClipsDescendants = true
        Sidebar2.Name = "sidebar2"
        Sidebar2.Parent = SidebarList
        local BgL = Color3.fromRGB(0, 0, 0)
        local BgD = Color3.fromRGB(255, 255, 255)
        local TxtL = Color3.fromRGB(100, 100, 100)
        local TxtD = Color3.fromRGB(140, 140, 155)
        Sidebar2.BackgroundColor3 = (CurrentTheme == "light") and BgL or BgD
        Sidebar2.BackgroundTransparency = 0.93
        Sidebar2.Size = UDim2.new(0, IsSidebarCollapsed and 34 or (ExpandedSidebarWidth - 7), 0, 34)
        Sidebar2.ZIndex = 20
        Sidebar2.AutoButtonColor = false
        Sidebar2.Font = Enum.Font.BuilderSansMedium
        Sidebar2.Text = name
        Sidebar2.TextColor3 = (CurrentTheme == "light") and TxtL or TxtD
        Sidebar2.TextSize = 15
        Sidebar2.TextXAlignment = Enum.TextXAlignment.Left
        local Uipadding = Instance.new("UIPadding")
        Uipadding.PaddingLeft = UDim.new(0, iconId and 40 or 15)
        Uipadding.Parent = Sidebar2
        if iconId then
            local IconImg = Instance.new("ImageLabel")
            IconImg.Name = "iconImg"
            IconImg.Size = UDim2.new(0, 18, 0, 18)
            IconImg.Position = UDim2.new(0, -16, 0.5, 0)
            IconImg.AnchorPoint = Vector2.new(0.5, 0.5)
            IconImg.BackgroundTransparency = 1
            IconImg.Parent = Sidebar2
            IconImg.ZIndex = 20
            IconImg.Active = false
            ResolveIcon(IconImg, iconId)
            RegisterTheme(IconImg, "ImageColor3", TxtL, TxtD)
        end
        local Uc_10 = Instance.new("UICorner")
        Uc_10.CornerRadius = UDim.new(0, 9)
        Uc_10.Parent = Sidebar2
        table.insert(Sections, Sidebar2)
        local Workareamain = Instance.new("ScrollingFrame")
        Workareamain.Name = "workareamain"
        Workareamain.Parent = Workarea
        Workareamain.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Workareamain.BackgroundTransparency = 1
        Workareamain.BorderSizePixel = 0
        Workareamain.Position = UDim2.new(0, 0, 0, 56)
        Workareamain.Size = UDim2.new(1, 0, 1, -72)
        Workareamain.ZIndex = 3
        Workareamain.CanvasSize = UDim2.new(0, 0, 0, 0)
        Workareamain.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Workareamain.ScrollBarThickness = 2
        Workareamain.Visible = false
        local Ull = Instance.new("UIListLayout")
        Ull.Parent = Workareamain
        Ull.HorizontalAlignment = Enum.HorizontalAlignment.Center
        Ull.SortOrder = Enum.SortOrder.LayoutOrder
        Ull.Padding = UDim.new(0, 5)
        local UiPadding = Instance.new("UIPadding")
        UiPadding.Parent = Workareamain
        UiPadding.PaddingLeft = UDim.new(0, 16)
        UiPadding.PaddingRight = UDim.new(0, 16)
        UiPadding.PaddingTop = UDim.new(0, 5)
        UiPadding.PaddingBottom = UDim.new(0, 5)
        table.insert(Workareas, Workareamain)
        local Sec = {}
        Sec.SearchableText = {}
        Sec.ElementsList = {}
        Sec.TabButton = Sidebar2
        function Sec:Select(force)
            if Workareamain.Visible and Sidebar2.Name == "sidebar2_selected" and not force then return end
            
            local BgL = Color3.fromRGB(0, 0, 0)
            local BgD = Color3.fromRGB(255, 255, 255)
            local TxtL = Color3.fromRGB(100, 100, 100)
            local TxtD = Color3.fromRGB(140, 140, 155)
            
            for b, v in next, Sections do
                v.Name = "sidebar2"
                v.BackgroundColor3 = (CurrentTheme == "light") and BgL or BgD
                v.BackgroundTransparency = 0.93
                v.TextColor3 = (CurrentTheme == "light") and TxtL or TxtD
                local Ico = v:FindFirstChild("iconImg")
                if Ico then
                    Ico.ImageColor3 = (CurrentTheme == "light") and TxtL or TxtD
                end
            end
            
            Sidebar2.Name = "sidebar2_selected"
            Sidebar2.BackgroundTransparency = 1
            Sidebar2.TextColor3 = Color3.fromRGB(255, 255, 255)
            local MyIco = Sidebar2:FindFirstChild("iconImg")
            if MyIco then
                MyIco.ImageColor3 = Color3.fromRGB(255, 255, 255)
            end
            
            local Highlight = Sidebar:FindFirstChild("TabHighlight")
            local IsNew = false
            if not Highlight then
                IsNew = true
                Highlight = Instance.new("Frame")
                Highlight.Name = "TabHighlight"
                Highlight.Parent = Sidebar
                Highlight.BackgroundColor3 = CurrentAccentColor
                Highlight.ZIndex = 16
                local Uc = Instance.new("UICorner", Highlight)
                Uc.CornerRadius = UDim.new(0, 9)
                table.insert(ThemeElements, {
                    Instance = Highlight,
                    Property = "BackgroundColor3",
                    Light = CurrentAccentColor,
                    Dark = CurrentAccentColor
                })
            end
            
            Highlight.Visible = true
            local CurrentTargetWidth = IsSidebarCollapsed and 34 or 183
            local TargetX = 3.5
            local TargetW = CurrentTargetWidth
            local TargetH = 34
            local TargetY = Sidebar2.AbsolutePosition.Y - Sidebar.AbsolutePosition.Y + Sidebar.CanvasPosition.Y
            
            if shared.HighlightConnection then shared.HighlightConnection:Disconnect() end
            
            if IsNew or Highlight.BackgroundTransparency == 1 or (Highlight.Position.Y.Offset == 0 and Highlight.Position.X.Offset == 0) then
                Highlight.Position = UDim2.new(0, TargetX, 0, TargetY)
                Highlight.Size = UDim2.new(0, TargetW, 0, TargetH)
                TweenService:Create(Highlight, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0
                }):Play()
            else
                TweenService:Create(Highlight, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, TargetX, 0, TargetY),
                    Size = UDim2.new(0, TargetW, 0, TargetH),
                    BackgroundTransparency = 0
                }):Play()
            end
            
            for b, v in next, Workareas do
                if v ~= Workareamain then
                    v.Visible = false
                end
            end
            Workareamain.Visible = true
            Workareamain.Position = UDim2.new(0, 0, 0, 76)
            TweenService:Create(Workareamain, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 56)
            }):Play()
        end


        function Sec:GetContainer()
            return Workareamain
        end
        function Sec:Groupbox(title, side)
            local function GetColumnsFrame()
                local ColumnsFrame = Workareamain:FindFirstChild("ColumnsFrame")
                if not ColumnsFrame then
                    ColumnsFrame = Instance.new("Frame")
                    ColumnsFrame.Name = "ColumnsFrame"
                    ColumnsFrame.Parent = Workareamain
                    ColumnsFrame.BackgroundTransparency = 1
                    ColumnsFrame.Size = UDim2.new(1, 0, 0, 0)
                    ColumnsFrame.AutomaticSize = Enum.AutomaticSize.Y
                    ColumnsFrame.ZIndex = 4
                    
                    local LeftCol = Instance.new("Frame")
                    LeftCol.Name = "LeftColumn"
                    LeftCol.Parent = ColumnsFrame
                    LeftCol.BackgroundTransparency = 1
                    LeftCol.Position = UDim2.new(0, 0, 0, 0)
                    LeftCol.Size = UDim2.new(0.5, -4, 0, 0)
                    LeftCol.AutomaticSize = Enum.AutomaticSize.Y
                    LeftCol.ZIndex = 4
                    
                    local LeftList = Instance.new("UIListLayout")
                    LeftList.Parent = LeftCol
                    LeftList.SortOrder = Enum.SortOrder.LayoutOrder
                    LeftList.Padding = UDim.new(0, 8)
                    
                    local RightCol = Instance.new("Frame")
                    RightCol.Name = "RightColumn"
                    RightCol.Parent = ColumnsFrame
                    RightCol.BackgroundTransparency = 1
                    RightCol.Position = UDim2.new(0.5, 4, 0, 0)
                    RightCol.Size = UDim2.new(0.5, -4, 0, 0)
                    RightCol.AutomaticSize = Enum.AutomaticSize.Y
                    RightCol.ZIndex = 4
                    
                    local RightList = Instance.new("UIListLayout")
                    RightList.Parent = RightCol
                    RightList.SortOrder = Enum.SortOrder.LayoutOrder
                    RightList.Padding = UDim.new(0, 8)
                end
                return ColumnsFrame
            end

            local TargetColumn
            local TargetColName = "LeftColumn"
            if side == "left" then
                TargetColName = "LeftColumn"
            elseif side == "right" then
                TargetColName = "RightColumn"
            else
                if Sec.LastSide == "left" then
                    Sec.LastSide = "right"
                    TargetColName = "RightColumn"
                else
                    Sec.LastSide = "left"
                    TargetColName = "LeftColumn"
                end
            end
            TargetColumn = GetColumnsFrame():FindFirstChild(TargetColName)

            local GroupFrame = Instance.new("Frame")
            GroupFrame.Name = "groupbox"
            GroupFrame.Parent = TargetColumn
            GroupFrame.Size = UDim2.new(1, 0, 0, 36)
            GroupFrame.AutomaticSize = Enum.AutomaticSize.Y
            GroupFrame.BackgroundTransparency = 0.4
            GroupFrame.BorderSizePixel = 0
            GroupFrame.ClipsDescendants = true
            
            RegisterTheme(GroupFrame, "BackgroundColor3", Color3.fromRGB(235, 235, 242), Color3.fromRGB(32, 32, 40))
            
            local UcGroup = Instance.new("UICorner")
            UcGroup.CornerRadius = UDim.new(0, 10)
            UcGroup.Parent = GroupFrame
            
            local GroupStroke = Instance.new("UIStroke")
            GroupStroke.Parent = GroupFrame
            GroupStroke.Thickness = 1
            GroupStroke.Transparency = 0.6
            RegisterTheme(GroupStroke, "Color", Color3.fromRGB(200, 200, 215), Color3.fromRGB(50, 50, 65))
            
            local HeaderBar = Instance.new("Frame")
            HeaderBar.Name = "headerBar"
            HeaderBar.Parent = GroupFrame
            HeaderBar.Size = UDim2.new(1, 0, 0, 36)
            HeaderBar.BackgroundTransparency = 1
            
            local HeaderTitle = Instance.new("TextLabel")
            HeaderTitle.Name = "headerTitle"
            HeaderTitle.Parent = HeaderBar
            HeaderTitle.Position = UDim2.new(0, 12, 0, 0)
            HeaderTitle.Size = UDim2.new(1, -50, 1, 0)
            HeaderTitle.BackgroundTransparency = 1
            HeaderTitle.Font = Enum.Font.BuilderSansBold
            HeaderTitle.Text = title or "Groupbox"
            HeaderTitle.TextSize = 13
            HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
            RegisterTheme(HeaderTitle, "TextColor3", Color3.fromRGB(60, 60, 65), Color3.fromRGB(220, 220, 230))
            
            local ToggleBtn = Instance.new("ImageButton")
            ToggleBtn.Name = "toggleBtn"
            ToggleBtn.Parent = HeaderBar
            ToggleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
            ToggleBtn.Position = UDim2.new(1, -16, 0.5, 0)
            ToggleBtn.Size = UDim2.new(0, 16, 0, 16)
            ToggleBtn.BackgroundTransparency = 1
            ResolveIcon(ToggleBtn, "chevron-down")
            RegisterTheme(ToggleBtn, "ImageColor3", Color3.fromRGB(120, 120, 130), Color3.fromRGB(180, 180, 190))
            
            local ContentFrame = Instance.new("Frame")
            ContentFrame.Name = "contentFrame"
            ContentFrame.Parent = GroupFrame
            ContentFrame.Position = UDim2.new(0, 6, 0, 36)
            ContentFrame.Size = UDim2.new(1, -12, 0, 0)
            ContentFrame.AutomaticSize = Enum.AutomaticSize.Y
            ContentFrame.BackgroundTransparency = 1
            
            local ContentPadding = Instance.new("UIPadding")
            ContentPadding.Parent = ContentFrame
            ContentPadding.PaddingBottom = UDim.new(0, 8)
            
            local ContentLayout = Instance.new("UIListLayout")
            ContentLayout.Parent = ContentFrame
            ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ContentLayout.Padding = UDim.new(0, 6)
            
            local IsCollapsed = false
            local function ToggleCollapse()
                IsCollapsed = not IsCollapsed
                if IsCollapsed then
                    GroupFrame.Size = UDim2.new(1, 0, 0, GroupFrame.AbsoluteSize.Y)
                    GroupFrame.AutomaticSize = Enum.AutomaticSize.None
                    TweenService:Create(GroupFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, 36)
                    }):Play()
                    TweenService:Create(ToggleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Rotation = -90
                    }):Play()
                else
                    local targetHeight = ContentLayout.AbsoluteContentSize.Y + ContentPadding.PaddingBottom.Offset + 36
                    local expandTween = TweenService:Create(GroupFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, targetHeight)
                    })
                    expandTween:Play()
                    TweenService:Create(ToggleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Rotation = 0
                    }):Play()
                    
                    task.delay(0.25, function()
                        if not IsCollapsed then
                            GroupFrame.AutomaticSize = Enum.AutomaticSize.Y
                        end
                    end)
                end
            end
            
            ToggleBtn.MouseButton1Click:Connect(ToggleCollapse)
            HeaderTitle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    ToggleCollapse()
                end
            end)
            
            local GroupObj = {}
            GroupObj.Frame = GroupFrame
            
            function GroupObj:AddToggle(name, default, callback, Flag) return Sec:Switch(name, default, callback, Flag, ContentFrame) end
            function GroupObj:AddButton(name, callback, isDestructive) return Sec:Button(name, callback, isDestructive, ContentFrame) end
            function GroupObj:AddSlider(name, min, max, default, callback, Flag) return Sec:Slider(name, min, max, default, callback, Flag, ContentFrame) end
            function GroupObj:AddDropdown(name, options, default, callback, Flag) return Sec:Dropdown(name, options, default, callback, Flag, ContentFrame) end
            function GroupObj:AddMultiDropdown(name, options, defaultOptions, callback, Flag) return Sec:MultiDropdown(name, options, defaultOptions, callback, Flag, ContentFrame) end
            function GroupObj:AddColorPicker(name, default, callback, Flag) return Sec:ColorPicker(name, default, callback, Flag, ContentFrame) end
            function GroupObj:AddKeybind(name, default, callback, Flag) return Sec:Keybind(name, default, callback, Flag, ContentFrame) end
            function GroupObj:AddLabel(text) return Sec:Label(text, ContentFrame) end
            function GroupObj:AddParagraph(title, content) return Sec:Paragraph(title, content, ContentFrame) end
            function GroupObj:AddTextField(name, placeholder, callback, Flag) return Sec:TextField(name, placeholder, callback, Flag, ContentFrame) end
            function GroupObj:AddDivider(text) return Sec:Divider(text, ContentFrame) end
            
            GroupObj.Switch = function(self, ...) return GroupObj:AddToggle(...) end
            GroupObj.Button = function(self, ...) return GroupObj:AddButton(...) end
            GroupObj.Slider = function(self, ...) return GroupObj:AddSlider(...) end
            GroupObj.Dropdown = function(self, ...) return GroupObj:AddDropdown(...) end
            GroupObj.MultiDropdown = function(self, ...) return GroupObj:AddMultiDropdown(...) end
            GroupObj.ColorPicker = function(self, ...) return GroupObj:AddColorPicker(...) end
            GroupObj.Keybind = function(self, ...) return GroupObj:AddKeybind(...) end
            GroupObj.Label = function(self, ...) return GroupObj:AddLabel(...) end
            GroupObj.Paragraph = function(self, ...) return GroupObj:AddParagraph(...) end
            GroupObj.TextField = function(self, ...) return GroupObj:AddTextField(...) end
            GroupObj.Divider = function(self, ...) return GroupObj:AddDivider(...) end
            
            return GroupObj
        end
        function Sec:AddLeftGroupbox(title) return Sec:Groupbox(title, "left") end
        function Sec:AddRightGroupbox(title) return Sec:Groupbox(title, "right") end

        
        
        function Sec:Tabbox(side)
            local function GetColumnsFrame()
                local ColumnsFrame = Workareamain:FindFirstChild("ColumnsFrame")
                if not ColumnsFrame then
                    ColumnsFrame = Instance.new("Frame")
                    ColumnsFrame.Name = "ColumnsFrame"
                    ColumnsFrame.Parent = Workareamain
                    ColumnsFrame.BackgroundTransparency = 1
                    ColumnsFrame.Size = UDim2.new(1, 0, 0, 0)
                    ColumnsFrame.AutomaticSize = Enum.AutomaticSize.Y
                    ColumnsFrame.ZIndex = 4
                    
                    local LeftCol = Instance.new("Frame")
                    LeftCol.Name = "LeftColumn"
                    LeftCol.Parent = ColumnsFrame
                    LeftCol.BackgroundTransparency = 1
                    LeftCol.Position = UDim2.new(0, 0, 0, 0)
                    LeftCol.Size = UDim2.new(0.5, -4, 0, 0)
                    LeftCol.AutomaticSize = Enum.AutomaticSize.Y
                    LeftCol.ZIndex = 4
                    
                    local LeftList = Instance.new("UIListLayout")
                    LeftList.Parent = LeftCol
                    LeftList.SortOrder = Enum.SortOrder.LayoutOrder
                    LeftList.Padding = UDim.new(0, 8)
                    
                    local RightCol = Instance.new("Frame")
                    RightCol.Name = "RightColumn"
                    RightCol.Parent = ColumnsFrame
                    RightCol.BackgroundTransparency = 1
                    RightCol.Position = UDim2.new(0.5, 4, 0, 0)
                    RightCol.Size = UDim2.new(0.5, -4, 0, 0)
                    RightCol.AutomaticSize = Enum.AutomaticSize.Y
                    RightCol.ZIndex = 4
                    
                    local RightList = Instance.new("UIListLayout")
                    RightList.Parent = RightCol
                    RightList.SortOrder = Enum.SortOrder.LayoutOrder
                    RightList.Padding = UDim.new(0, 8)
                end
                return ColumnsFrame
            end

            local TargetColumn
            local TargetColName = "LeftColumn"
            if side == "left" then TargetColName = "LeftColumn"
            elseif side == "right" then TargetColName = "RightColumn"
            else
                if Sec.LastSide == "left" then Sec.LastSide = "right"; TargetColName = "RightColumn"
                else Sec.LastSide = "left"; TargetColName = "LeftColumn" end
            end
            
            TargetColumn = GetColumnsFrame():FindFirstChild(TargetColName)
            
            local TabboxFrame = Instance.new("Frame")
            TabboxFrame.Name = "Tabbox"
            TabboxFrame.Parent = TargetColumn
            TabboxFrame.Size = UDim2.new(1, 0, 0, 36)
            TabboxFrame.AutomaticSize = Enum.AutomaticSize.Y
            TabboxFrame.BackgroundTransparency = 0.4
            TabboxFrame.BorderSizePixel = 0
            TabboxFrame.ClipsDescendants = true
            RegisterTheme(TabboxFrame, "BackgroundColor3", Color3.fromRGB(235, 235, 242), Color3.fromRGB(32, 32, 40))
            
            local UcGroup = Instance.new("UICorner")
            UcGroup.CornerRadius = UDim.new(0, 10)
            UcGroup.Parent = TabboxFrame
            
            local GroupStroke = Instance.new("UIStroke")
            GroupStroke.Parent = TabboxFrame
            GroupStroke.Thickness = 1
            GroupStroke.Transparency = 0.6
            RegisterTheme(GroupStroke, "Color", Color3.fromRGB(200, 200, 215), Color3.fromRGB(50, 50, 65))
            
            local TopBar = Instance.new("Frame")
            TopBar.Name = "TopBar"
            TopBar.Parent = TabboxFrame
            TopBar.BackgroundTransparency = 1
            TopBar.Size = UDim2.new(1, 0, 0, 35)
            
            local TabList = Instance.new("UIListLayout")
            TabList.Parent = TopBar
            TabList.FillDirection = Enum.FillDirection.Horizontal
            TabList.SortOrder = Enum.SortOrder.LayoutOrder
            
            local Divider = Instance.new("Frame")
            Divider.Name = "Divider"
            Divider.Parent = TabboxFrame
            Divider.Position = UDim2.new(0, 0, 0, 35)
            Divider.Size = UDim2.new(1, 0, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundTransparency = 0.6
            RegisterTheme(Divider, "BackgroundColor3", Color3.fromRGB(200, 200, 215), Color3.fromRGB(50, 50, 65))
            
            local ContentArea = Instance.new("Frame")
            ContentArea.Name = "contentArea"
            ContentArea.Parent = TabboxFrame
            ContentArea.BackgroundTransparency = 1
            ContentArea.Position = UDim2.new(0, 6, 0, 36)
            ContentArea.Size = UDim2.new(1, -12, 0, 0)
            ContentArea.AutomaticSize = Enum.AutomaticSize.Y
            
            local ActiveLine = Instance.new("Frame")
            ActiveLine.Name = "ActiveLine"
            ActiveLine.Parent = TabboxFrame
            ActiveLine.BackgroundColor3 = CurrentAccentColor or Color3.fromRGB(21, 103, 251)
            ActiveLine.BorderSizePixel = 0
            ActiveLine.Size = UDim2.new(0, 0, 0, 2)
            ActiveLine.Position = UDim2.new(0, 0, 0, 34)
            ActiveLine.ZIndex = 5
            table.insert(ThemeElements, {Instance = ActiveLine, Property = "BackgroundColor3", Light = CurrentAccentColor, Dark = CurrentAccentColor})
            
            local TabboxObj = {}
            TabboxObj.Tabs = {}
            TabboxObj.ActiveTab = nil
            
            function TabboxObj:AddTab(name)
                local TabBtn = Instance.new("TextButton")
                TabBtn.Name = name
                TabBtn.Parent = TopBar
                TabBtn.BackgroundTransparency = 1
                TabBtn.Size = UDim2.new(0, 0, 1, 0)
                TabBtn.AutomaticSize = Enum.AutomaticSize.X
                TabBtn.Font = Enum.Font.BuilderSansBold
                TabBtn.Text = name
                RegisterTheme(TabBtn, "TextColor3", Color3.fromRGB(60, 60, 65), Color3.fromRGB(220, 220, 230))
                TabBtn.TextTransparency = 0.5
                TabBtn.TextSize = 13
                
                local TabPadding = Instance.new("UIPadding")
                TabPadding.PaddingLeft = UDim.new(0, 12)
                TabPadding.PaddingRight = UDim.new(0, 12)
                TabPadding.Parent = TabBtn
                
                local TabContent = Instance.new("Frame")
                TabContent.Name = "contentFrame"
                TabContent.Parent = ContentArea
                TabContent.BackgroundTransparency = 1
                TabContent.Size = UDim2.new(1, 0, 0, 0)
                TabContent.AutomaticSize = Enum.AutomaticSize.Y
                TabContent.Visible = false
                
                local ContentList = Instance.new("UIListLayout")
                ContentList.Parent = TabContent
                ContentList.SortOrder = Enum.SortOrder.LayoutOrder
                
                local ContentPadding = Instance.new("UIPadding")
                ContentPadding.PaddingTop = UDim.new(0, 8)
                ContentPadding.PaddingBottom = UDim.new(0, 8)
                ContentPadding.Parent = TabContent
                
                local TabObj = {}
                TabObj.Frame = TabContent
                TabObj.Btn = TabBtn
                function TabObj:AddToggle(n, d, c, f) return Sec:Switch(n, d, c, f, TabContent) end
                function TabObj:Switch(n, d, c, f) return Sec:Switch(n, d, c, f, TabContent) end
                function TabObj:AddSlider(n, min, max, d, c, f) return Sec:Slider(n, min, max, d, c, f, TabContent) end
                function TabObj:Slider(n, min, max, d, c, f) return Sec:Slider(n, min, max, d, c, f, TabContent) end
                function TabObj:AddDropdown(n, opt, d, c, f) return Sec:Dropdown(n, opt, d, c, f, TabContent) end
                function TabObj:Dropdown(n, opt, d, c, f) return Sec:Dropdown(n, opt, d, c, f, TabContent) end
                function TabObj:AddMultiDropdown(n, opt, d, c, f) return Sec:MultiDropdown(n, opt, d, c, f, TabContent) end
                function TabObj:MultiDropdown(n, opt, d, c, f) return Sec:MultiDropdown(n, opt, d, c, f, TabContent) end
                function TabObj:AddColorPicker(n, d, c, f) return Sec:ColorPicker(n, d, c, f, TabContent) end
                function TabObj:ColorPicker(n, d, c, f) return Sec:ColorPicker(n, d, c, f, TabContent) end
                function TabObj:AddKeybind(n, d, c, f) return Sec:Keybind(n, d, c, f, TabContent) end
                function TabObj:Keybind(n, d, c, f) return Sec:Keybind(n, d, c, f, TabContent) end
                function TabObj:AddTextField(n, p, c, f) return Sec:TextField(n, p, c, f, TabContent) end
                function TabObj:TextField(n, p, c, f) return Sec:TextField(n, p, c, f, TabContent) end
                function TabObj:AddButton(n, c) return Sec:Button(n, c, TabContent) end
                function TabObj:Button(n, c) return Sec:Button(n, c, TabContent) end
                function TabObj:AddLabel(n) return Sec:Label(n, TabContent) end
                function TabObj:Label(n) return Sec:Label(n, TabContent) end
                function TabObj:AddDivider(n) return Sec:Divider(n, TabContent) end
                function TabObj:Divider(n) return Sec:Divider(n, TabContent) end
                
                TabBtn.MouseButton1Click:Connect(function()
                    if TabboxObj.ActiveTab == TabObj then return end
                    TabboxObj.ActiveTab = TabObj
                    
                    for _, t in pairs(TabboxObj.Tabs) do
                        if t ~= TabObj then
                            TweenService:Create(t.Btn, TweenInfo.new(0.3), {TextTransparency = 0.5}):Play()
                            t.Frame.Visible = false
                        end
                    end
                    
                    TweenService:Create(TabBtn, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
                    TabContent.Visible = true
                    
                                        task.spawn(function()
                        RunService.RenderStepped:Wait()
                        TweenService:Create(ActiveLine, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.new(0, TabBtn.AbsoluteSize.X, 0, 2),
                            Position = UDim2.new(0, TabBtn.AbsolutePosition.X - TopBar.AbsolutePosition.X, 0, 34)
                        }):Play()
                    end)
                end)
                
                table.insert(TabboxObj.Tabs, TabObj)
                
                if #TabboxObj.Tabs == 1 then
                    TabboxObj.ActiveTab = TabObj
                    TabBtn.TextTransparency = 0
                    TabContent.Visible = true
                    task.spawn(function()
                        RunService.RenderStepped:Wait()
                        ActiveLine.Size = UDim2.new(0, TabBtn.AbsoluteSize.X, 0, 2)
                        ActiveLine.Position = UDim2.new(0, TabBtn.AbsolutePosition.X - TopBar.AbsolutePosition.X, 0, 34)
                    end)
                end
                
                return TabObj
            end
            
            return TabboxObj
        end
function Sec:AddLeftTabbox() return Sec:Tabbox("left") end
        function Sec:AddRightTabbox() return Sec:Tabbox("right") end

        Sec.LeftGroupbox = Sec.AddLeftGroupbox
        Sec.RightGroupbox = Sec.AddRightGroupbox
        Sec.AddGroupbox = Sec.Groupbox
        function Sec:Divider(name, targetParent)
            local Section = Instance.new("TextLabel")
            Section.Name = "section"
            Section.Parent = targetParent or Workareamain
            table.insert(Sec.ElementsList, { text = string.upper(name), gui = Section })
            Section.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Section.BackgroundTransparency = 1
            Section.BorderSizePixel = 2
            Section.Size = UDim2.new(1, 0, 0, 50)
            Section.Font = Enum.Font.BuilderSansBold
            Section.LineHeight = 1.180
            Section.Text = name
            RegisterTheme(Section, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(100, 100, 120))
            Section.TextSize = 13
            Section.TextWrapped = true
            Section.TextXAlignment = Enum.TextXAlignment.Left
            Section.TextYAlignment = Enum.TextYAlignment.Bottom
        end
        function Sec:Button(name, callback, isDestructive, targetParent)
            table.insert(Sec.SearchableText, string.upper(name))
            local Flag = name
            RegisteredElements[Flag] = callback
            local Button = Instance.new("TextButton")
            Button.Name = "button"
            Button.Text = name
            Button.Parent = targetParent or Workareamain
            table.insert(Sec.ElementsList, { text = string.upper(name), gui = Button })
            Button.Size = UDim2.new(1, 0, 0, 37)
            Button.ZIndex = 20
            Button.Font = Enum.Font.BuilderSansMedium
            Button.TextSize = 14
            local Uc_3 = Instance.new("UICorner")
            Uc_3.Parent = Button
            if Lib.ButtonStyle == "Glossy" then
                if isDestructive then
                    Button.TextColor3 = Color3.fromRGB(255, 59, 48)
                    RegisterTheme(Button, "BackgroundColor3", Color3.fromRGB(229, 229, 234), Color3.fromRGB(44, 44, 46))
                else
                    Button.BackgroundColor3 = CurrentAccentColor
                    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
                Button.BackgroundTransparency = 0
                Uc_3.CornerRadius = UDim.new(1, 0)
                local Grad2 = Instance.new("UIGradient", Button)
                Grad2.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.00, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(0.49, Color3.new(0.8, 0.8, 0.8)),
                    ColorSequenceKeypoint.new(0.50, Color3.new(0.6, 0.6, 0.6)),
                    ColorSequenceKeypoint.new(1.00, Color3.new(0.5, 0.5, 0.5))
                })
                Grad2.Rotation = 90
            else
                if isDestructive then
                    Button.TextColor3 = Color3.fromRGB(255, 59, 48)
                    RegisterTheme(Button, "BackgroundColor3", Color3.fromRGB(229, 229, 234), Color3.fromRGB(44, 44, 46))
                else
                    Button.BackgroundColor3 = CurrentAccentColor
                    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
                Button.BackgroundTransparency = 0
                Uc_3.CornerRadius = UDim.new(1, 0)
            end
            local OgSize = UDim2.new(1, 0, 0, 37)
            Button.MouseButton1Down:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, -6, 0, 35)}):Play()
            end)
            Button.MouseButton1Up:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Size = OgSize}):Play()
            end)
            Button.MouseLeave:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.1), {Size = OgSize}):Play()
            end)
            Button.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
            Button.MouseButton2Click:Connect(function()
                Window:PromptKeybind(callback, Flag)
            end)
        end
        function Sec:Label(name, targetParent)
            table.insert(Sec.SearchableText, string.upper(name))
            local Label = Instance.new("TextLabel")
            Label.Name = "label"
            Label.Parent = targetParent or Workareamain
            table.insert(Sec.ElementsList, { text = string.upper(name), gui = Label })
            Label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Label.BackgroundTransparency = 1
            Label.BorderSizePixel = 2
            Label.Size = UDim2.new(1, 0, 0, 37)
            Label.Font = Enum.Font.BuilderSansMedium
            RegisterTheme(Label, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(100, 100, 120))
            Label.TextSize = 16
            Label.TextWrapped = true
            Label.Text = name
        end
        function Sec:Switch(name, defaultmode, callback, Flag, targetParent)
            table.insert(Sec.SearchableText, string.upper(name))
            Flag = Flag or name
            local Mode = (ConfigManager.Elements[Flag] ~= nil and ConfigManager.Elements[Flag].Value ~= nil) and ConfigManager.Elements[Flag].Value or defaultmode
            table.insert(CleanupToggles, { default = defaultmode, callback = callback })
            local Toggleswitch = Instance.new("Frame")
            Toggleswitch.Name = "toggleswitch"
            Toggleswitch.Parent = targetParent or Workareamain
            table.insert(Sec.ElementsList, { text = string.upper(name), gui = Toggleswitch })
            Toggleswitch.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Toggleswitch.BackgroundTransparency = 1
            Toggleswitch.BorderSizePixel = 0
            Toggleswitch.Size = UDim2.new(1, 0, 0, 37)
            local Switchlabel = Instance.new("TextLabel")
            Switchlabel.Name = "switchlabel"
            Switchlabel.Parent = Toggleswitch
            Switchlabel.BackgroundTransparency = 1
            Switchlabel.Size = UDim2.new(1, -60, 1, 0)
            Switchlabel.Font = Enum.Font.BuilderSansMedium
            Switchlabel.Text = name
            RegisterTheme(Switchlabel, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
            Switchlabel.TextSize = 16
            Switchlabel.TextWrapped = true
            Switchlabel.TextXAlignment = Enum.TextXAlignment.Left
            local Frame = Instance.new("TextButton")
            Frame.Parent = Toggleswitch
            Frame.ZIndex = 20
            Frame.Position = UDim2.new(1, -56, 0.5, -14)
            Frame.Size = UDim2.new(0, 56, 0, 28)
            Frame.Text = ""
            Frame.AutoButtonColor = false
            local Uc_4 = Instance.new("UICorner")
            Uc_4.CornerRadius = UDim.new(5, 0)
            Uc_4.Parent = Frame
            local TextButton = Instance.new("TextButton")
            TextButton.Parent = Frame
            TextButton.ZIndex = 21
            TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextButton.Size = UDim2.new(0, 26, 0, 26)
            TextButton.AutoButtonColor = false
            TextButton.Text = ""
            local Uc_5 = Instance.new("UICorner")
            Uc_5.CornerRadius = UDim.new(5, 0)
            Uc_5.Parent = TextButton
            local function UpdateSwitchVisual()
                if Mode == false then
                    TextButton.Position = UDim2.new(0, 1, 0, 1)
                    Frame.BackgroundColor3 = (CurrentTheme == "light") and Color3.fromRGB(216, 216, 216) or Color3.fromRGB(60, 60, 60)
                else
                    TextButton.Position = UDim2.new(0, 29, 0, 1)
                    Frame.BackgroundColor3 = CurrentAccentColor
                end
            end
            UpdateSwitchVisual()
            if callback then
                pcall(callback, Mode)
            end
            local function Toggle()
                Mode = not Mode
                if ConfigManager.Elements[Flag] then ConfigManager.Elements[Flag].Value = Mode end
                if type(Flag) == "string" and string.find(Flag, "^Settings_") then ConfigManager:SaveUISettings() end
                if callback then callback(Mode) end
                if Mode then
                    TextButton:TweenPosition(UDim2.new(0, 29, 0, 1), "In", "Sine", 0.1, true)
                    Frame.BackgroundColor3 = CurrentAccentColor
                else
                    TextButton:TweenPosition(UDim2.new(0, 1, 0, 1), "In", "Sine", 0.1, true)
                    Frame.BackgroundColor3 = (CurrentTheme == "light") and Color3.fromRGB(216, 216, 216) or Color3.fromRGB(60, 60, 60)
                end
            end
            table.insert(ThemeElements, {
                Instance = Frame,
                Property = "BackgroundColor3",
                Light = Color3.fromRGB(216, 216, 216),
                Dark = Color3.fromRGB(60, 60, 60),
                IsToggle = true,
                GetToggleState = function() return Mode end
            })
            Frame.MouseButton1Click:Connect(Toggle)
            TextButton.MouseButton1Click:Connect(Toggle)
            Frame.MouseButton2Click:Connect(function()
                Window:PromptKeybind(Toggle, Flag)
            end)
            TextButton.MouseButton2Click:Connect(function()
                Window:PromptKeybind(Toggle, Flag)
            end)
            RegisteredElements[Flag] = Toggle
            ConfigManager.Elements[Flag] = { Value = Mode, Set = function(self, val) if Mode ~= val then Toggle() end end }
        end
        function Sec:TextField(name, placeholder, callback, Flag, targetParent)
            table.insert(Sec.SearchableText, string.upper(name))
            Flag = Flag or name
            local Textfield = Instance.new("Frame")
            Textfield.Name = "textfield"
            Textfield.Parent = targetParent or Workareamain
            table.insert(Sec.ElementsList, { text = string.upper(name), gui = Textfield })
            Textfield.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Textfield.BackgroundTransparency = 1
            Textfield.BorderSizePixel = 0
            Textfield.Size = UDim2.new(1, 0, 0, 37)
            local Textfieldlabel = Instance.new("TextLabel")
            Textfieldlabel.Name = "textfieldlabel"
            Textfieldlabel.Parent = Textfield
            Textfieldlabel.BackgroundTransparency = 1
            local isGroupbox = (targetParent and targetParent.Name == "contentFrame")
            Textfieldlabel.Size = UDim2.new(1, isGroupbox and -130 or -240, 1, 0)
            Textfieldlabel.Font = Enum.Font.BuilderSansMedium
            Textfieldlabel.Text = name
            RegisterTheme(Textfieldlabel, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
            Textfieldlabel.TextSize = 16
            Textfieldlabel.TextWrapped = true
            Textfieldlabel.TextXAlignment = Enum.TextXAlignment.Left
            local Frame_2 = Instance.new("Frame")
            Frame_2.Parent = Textfield
            RegisterTheme(Frame_2, "BackgroundColor3", Color3.fromRGB(228, 228, 238), Color3.fromRGB(32, 32, 42))
            Frame_2.Position = UDim2.new(1, isGroupbox and -123 or -233, 0.5, -17)
            Frame_2.Size = UDim2.new(0, isGroupbox and 123 or 233, 0, 34)
            local Uc_6 = Instance.new("UICorner")
            Uc_6.CornerRadius = UDim.new(0, 8)
            Uc_6.Parent = Frame_2
            local TextBox = Instance.new("TextBox")
            TextBox.Parent = Frame_2
            TextBox.ZIndex = 20
            TextBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextBox.BackgroundTransparency = 1
            TextBox.BorderColor3 = Color3.fromRGB(27, 42, 53)
            TextBox.BorderSizePixel = 0
            TextBox.ClipsDescendants = true
            TextBox.Position = UDim2.new(0.0643776804, 0, 0, 0)
            TextBox.Size = UDim2.new(0, 203, 0, 34)
            TextBox.ClearTextOnFocus = false
            TextBox.Font = Enum.Font.BuilderSansMedium
            TextBox.LineHeight = 1
            TextBox.TextYAlignment = Enum.TextYAlignment.Center
            TextBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
            TextBox.PlaceholderText = placeholder or "Type..."
            TextBox.Text = ""
            RegisterTheme(TextBox, "TextColor3", Color3.fromRGB(160, 160, 180), Color3.fromRGB(140, 140, 155))
            TextBox.TextSize = 15
            TextBox.TextXAlignment = Enum.TextXAlignment.Left
            ConfigManager.Elements[Flag] = { Value = TextBox.Text, Set = function(self, val) TextBox.Text = val; if callback then callback(val) end end }
            if callback then
                TextBox.FocusLost:Connect(function()
                    if ConfigManager.Elements[Flag] then ConfigManager.Elements[Flag].Value = TextBox.Text end
                    callback(TextBox.Text)
                end)
            end
        end
        function Sec:Slider(name, min, max, default, callback, Flag, targetParent)
            table.insert(Sec.SearchableText, string.upper(name))
            Flag = Flag or name
            default = (ConfigManager.Elements[Flag] ~= nil and ConfigManager.Elements[Flag].Value ~= nil) and ConfigManager.Elements[Flag].Value or default
            local Sliderrow = Instance.new("Frame")
            Sliderrow.Name = "sliderrow"
            Sliderrow.Parent = targetParent or Workareamain
            table.insert(Sec.ElementsList, { text = string.upper(name), gui = Sliderrow })
            Sliderrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Sliderrow.BackgroundTransparency = 1
            Sliderrow.BorderSizePixel = 0
            Sliderrow.Size = UDim2.new(1, 0, 0, 37)
            local Sliderlabel = Instance.new("TextLabel")
            Sliderlabel.Name = "sliderlabel"
            Sliderlabel.Parent = Sliderrow
            Sliderlabel.BackgroundTransparency = 1
            local isGroupbox = (targetParent and targetParent.Name == "contentFrame")
            Sliderlabel.Size = UDim2.new(1, isGroupbox and -130 or -250, 1, 0)
            Sliderlabel.Font = Enum.Font.BuilderSansMedium
            Sliderlabel.Text = name
            RegisterTheme(Sliderlabel, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
            Sliderlabel.TextSize = 16
            Sliderlabel.TextWrapped = true
            Sliderlabel.TextXAlignment = Enum.TextXAlignment.Left
            local Valuelabel = Instance.new("TextLabel")
            Valuelabel.Name = "valuelabel"
            Valuelabel.Parent = Sliderrow
            Valuelabel.BackgroundTransparency = 1
            Valuelabel.Position = UDim2.new(1, isGroupbox and -35 or -55, 0, 0)
            Valuelabel.Size = UDim2.new(0, isGroupbox and 35 or 55, 1, 0)
            Valuelabel.Font = Enum.Font.BuilderSansMedium
            Valuelabel.Text = tostring(default)
            Valuelabel.TextColor3 = CurrentAccentColor
            Valuelabel.TextSize = 19
            Valuelabel.TextXAlignment = Enum.TextXAlignment.Right
            local Rail = Instance.new("Frame")
            Rail.Name = "rail"
            Rail.Parent = Sliderrow
            RegisterTheme(Rail, "BackgroundColor3", Color3.fromRGB(200, 200, 215), Color3.fromRGB(45, 45, 58))
            Rail.Position = UDim2.new(1, isGroupbox and -120 or -240, 0.5, -3)
            Rail.Size = UDim2.new(0, isGroupbox and 80 or 180, 0, 4)
            Rail.BorderSizePixel = 0
            local Uc_r = Instance.new("UICorner")
            Uc_r.CornerRadius = UDim.new(1, 0)
            Uc_r.Parent = Rail
            local Fill = Instance.new("Frame")
            Fill.Name = "fill"
            Fill.Parent = Rail
            Fill.BackgroundColor3 = CurrentAccentColor
            Fill.BorderSizePixel = 0
            Fill.Size = UDim2.new(0, 0, 1, 0)
            local Uc_f = Instance.new("UICorner")
            Uc_f.CornerRadius = UDim.new(1, 0)
            Uc_f.Parent = Fill
            local Thumb = Instance.new("TextButton")
            Thumb.Name = "thumb"
            Thumb.Parent = Rail
            Thumb.BackgroundColor3 = CurrentAccentColor
            Thumb.Size = UDim2.new(0, 14, 0, 14)
            Thumb.Position = UDim2.new(0, -7, 0.5, -7)
            Thumb.Text = ""
            Thumb.AutoButtonColor = false
            Thumb.ZIndex = 20
            Thumb.BorderSizePixel = 0
            local Uc_t = Instance.new("UICorner")
            Uc_t.CornerRadius = UDim.new(1, 0)
            Uc_t.Parent = Thumb
            local CurrentValue = math.clamp(default, min, max)
            local function SetValue(v)
                CurrentValue = math.clamp(math.round(v), min, max)
                if ConfigManager.Elements[Flag] then ConfigManager.Elements[Flag].Value = CurrentValue end
                if type(Flag) == "string" and string.find(Flag, "^Settings_") then ConfigManager:SaveUISettings() end
                local scale = (CurrentValue - min) / (max - min)
                Fill.Size = UDim2.new(scale, 0, 1, 0)
                Thumb.Position = UDim2.new(scale, -7, 0.5, -7)
                Valuelabel.Text = tostring(CurrentValue)
                if callback then callback(CurrentValue) end
            end
            SetValue(default)
            local DraggingSlider = false
            Thumb.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = true
                end
            end)
            Rail.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = true
                    local RelX = math.clamp(input.Position.X - Rail.AbsolutePosition.X, 0, Rail.AbsoluteSize.X)
                    SetValue(min + (max - min) * (RelX / Rail.AbsoluteSize.X))
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if DraggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local RelX = math.clamp(input.Position.X - Rail.AbsolutePosition.X, 0, Rail.AbsoluteSize.X)
                    SetValue(min + (max - min) * (RelX / Rail.AbsoluteSize.X))
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSlider = false
                end
            end)
            ConfigManager.Elements[Flag] = { Value = CurrentValue, Set = function(self, val) SetValue(val) end }
        end
        function Sec:Dropdown(name, options, default, callback, Flag, targetParent)
            table.insert(Sec.SearchableText, string.upper(name))
            if type(options) == 'table' then for _, o in ipairs(options) do table.insert(Sec.SearchableText, string.upper(tostring(o))) end end
            Flag = Flag or name
            default = (ConfigManager.Elements[Flag] ~= nil and ConfigManager.Elements[Flag].Value ~= nil) and ConfigManager.Elements[Flag].Value or default
            local Droprow = Instance.new("Frame")
            Droprow.Name = "droprow"
            Droprow.Parent = targetParent or Workareamain
            local SearchStr = string.upper(name)
            if type(options) == "table" then for _, o in ipairs(options) do SearchStr = SearchStr .. " " .. string.upper(tostring(o)) end end
            table.insert(Sec.ElementsList, { text = SearchStr, gui = Droprow })
            Droprow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Droprow.BackgroundTransparency = 1
            Droprow.BorderSizePixel = 0
            Droprow.Size = UDim2.new(1, 0, 0, 37)
            local Droplabel_top = Instance.new("TextLabel")
            Droplabel_top.Name = "droplabel_top"
            Droplabel_top.Parent = Droprow
            Droplabel_top.BackgroundTransparency = 1
            local isGroupbox = (targetParent and targetParent.Name == "contentFrame")
            Droplabel_top.Size = UDim2.new(1, isGroupbox and -130 or -240, 1, 0)
            Droplabel_top.Font = Enum.Font.BuilderSansMedium
            Droplabel_top.Text = name
            RegisterTheme(Droplabel_top, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
            Droplabel_top.TextSize = 16
            Droplabel_top.TextWrapped = true
            Droplabel_top.TextXAlignment = Enum.TextXAlignment.Left
            local Dropbtn = Instance.new("TextButton")
            Dropbtn.Name = "dropbtn"
            Dropbtn.ZIndex = 20
            Dropbtn.Parent = Droprow
            RegisterTheme(Dropbtn, "BackgroundColor3", Color3.fromRGB(228, 228, 238), Color3.fromRGB(32, 32, 42))
            Dropbtn.Position = UDim2.new(1, isGroupbox and -123 or -233, 0.5, -17)
            Dropbtn.Size = UDim2.new(0, isGroupbox and 123 or 233, 0, 34)
            Dropbtn.Font = Enum.Font.BuilderSans
            local Droplabel = Instance.new("TextLabel", Dropbtn)
            Droplabel.BackgroundTransparency = 1
            Droplabel.Size = UDim2.new(1, -30, 1, 0)
            Droplabel.Position = UDim2.new(0, 10, 0, 0)
            Droplabel.Font = Enum.Font.BuilderSans
            Droplabel.ZIndex = 21
            RegisterTheme(Droplabel, "TextColor3", Color3.fromRGB(15, 15, 20), Color3.fromRGB(240, 240, 245))
            Droplabel.TextSize = 14
            Droplabel.TextXAlignment = Enum.TextXAlignment.Left
            Droplabel.TextTruncate = Enum.TextTruncate.AtEnd
            Dropbtn.AutoButtonColor = false
            Dropbtn.Text = ""
            Droplabel.Text = (default or (options[1] or ""))
            Dropbtn.ClipsDescendants = true
            local Uc_db = Instance.new("UICorner")
            Uc_db.CornerRadius = UDim.new(0, 9)
            Uc_db.Parent = Dropbtn
            local Arrow = Instance.new("TextLabel")
            Arrow.Name = "arrow"
            Arrow.Parent = Dropbtn
            Arrow.BackgroundTransparency = 1
            Arrow.Position = UDim2.new(1, -28, 0, 0)
            Arrow.Size = UDim2.new(0, 24, 1, 0)
            Arrow.Font = Enum.Font.BuilderSansMedium
            Arrow.Text = "v"
            Arrow.TextColor3 = Color3.fromRGB(95, 95, 95)
            Arrow.TextSize = 14
            Arrow.ZIndex = 21
            local CurrentValue = default or (options[1] or "")
            local Listframe = Instance.new("ScrollingFrame")
            Listframe.Name = "listframe"
            Listframe.Parent = targetParent or Workareamain
            RegisterTheme(Listframe, "BackgroundColor3", Color3.fromRGB(238, 238, 245), Color3.fromRGB(24, 24, 32))
            Listframe.BorderSizePixel = 0
            Listframe.Size = UDim2.new(1, 0, 0, 0)
            Listframe.ClipsDescendants = true
            Listframe.Visible = false
            Listframe.ZIndex = 30
            Listframe.CanvasSize = UDim2.new(0, 0, 0, 0)
            Listframe.AutomaticCanvasSize = Enum.AutomaticSize.Y
            Listframe.ScrollBarThickness = 2
            Listframe.ScrollBarImageColor3 = CurrentAccentColor
            local Uc_lf = Instance.new("UICorner")
            Uc_lf.CornerRadius = UDim.new(0, 9)
            Uc_lf.Parent = Listframe
            local Listlayout = Instance.new("UIListLayout")
            Listlayout.Parent = Listframe
            Listlayout.SortOrder = Enum.SortOrder.LayoutOrder
            Listlayout.Padding = UDim.new(0, 2)
            local Listpadding = Instance.new("UIPadding")
            Listpadding.Parent = Listframe
            Listpadding.PaddingTop = UDim.new(0, 4)
            Listpadding.PaddingBottom = UDim.new(0, 4)
            local Opened = false
            local function CloseList()
                Opened = false
                Arrow.Text = "v"
                TweenService:Create(Listframe, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                task.wait(0.15)
                Listframe.Visible = false
            end
            local function OpenList()
                Opened = true
                Arrow.Text = "^"
                local ContentH = Listlayout.AbsoluteContentSize.Y + 8
                local ClampedH = math.min(ContentH, 150)
                Listframe.Visible = true
                Listframe.Size = UDim2.new(1, 0, 0, 0)
                TweenService:Create(Listframe, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, ClampedH)}):Play()
            end
            local DropdownObj = {}
            function DropdownObj:Refresh(newOptions)
                for _, child in ipairs(Listframe:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                options = newOptions
                if #options > 0 then
                    CurrentValue = options[1]
                    Droplabel.Text = CurrentValue
                    if ConfigManager.Elements[Flag] then ConfigManager.Elements[Flag].Value = CurrentValue end
                if type(Flag) == "string" and string.find(Flag, "^Settings_") then ConfigManager:SaveUISettings() end
                    if callback then callback(CurrentValue) end
                end
                for _, opt in ipairs(options) do
                    local Optbtn = Instance.new("TextButton")
                    Optbtn.Name = "optbtn"
                    Optbtn.Parent = Listframe
                    Optbtn.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                    Optbtn.BackgroundTransparency = 1
                    Optbtn.Size = UDim2.new(1, -8, 0, 30)
                    Optbtn.Position = UDim2.new(0, 4, 0, 0)
                    Optbtn.Font = Enum.Font.BuilderSansMedium
                    Optbtn.Text = opt
                    RegisterTheme(Optbtn, "TextColor3", Color3.fromRGB(15, 15, 20), Color3.fromRGB(240, 240, 245))
                    Optbtn.TextSize = 14
                    Optbtn.AutoButtonColor = false
                    Optbtn.ZIndex = 35
                    local Uc_ob = Instance.new("UICorner")
                    Uc_ob.CornerRadius = UDim.new(0, 7)
                    Uc_ob.Parent = Optbtn
                    Optbtn.MouseEnter:Connect(function()
                        TweenService:Create(Optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 0.5}):Play()
                    end)
                    Optbtn.MouseLeave:Connect(function()
                        TweenService:Create(Optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
                    end)
                    Optbtn.MouseButton1Click:Connect(function()
                        TweenService:Create(Optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
                        CurrentValue = opt
                        if ConfigManager.Elements[Flag] then ConfigManager.Elements[Flag].Value = CurrentValue end
                if type(Flag) == "string" and string.find(Flag, "^Settings_") then ConfigManager:SaveUISettings() end
                        Droplabel.Text = opt
                        CloseList()
                        if callback then callback(CurrentValue) end
                    end)
                end
            end
            for _, opt in ipairs(options) do
                local Optbtn = Instance.new("TextButton")
                Optbtn.Name = "optbtn"
                Optbtn.Parent = Listframe
                Optbtn.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
                Optbtn.BackgroundTransparency = 1
                Optbtn.Size = UDim2.new(1, -8, 0, 30)
                Optbtn.Position = UDim2.new(0, 4, 0, 0)
                Optbtn.Font = Enum.Font.BuilderSansMedium
                Optbtn.Text = opt
                RegisterTheme(Optbtn, "TextColor3", Color3.fromRGB(15, 15, 20), Color3.fromRGB(240, 240, 245))
                Optbtn.TextSize = 14
                Optbtn.AutoButtonColor = false
                Optbtn.ZIndex = 35
                local Uc_ob = Instance.new("UICorner")
                Uc_ob.CornerRadius = UDim.new(0, 7)
                Uc_ob.Parent = Optbtn
                Optbtn.MouseEnter:Connect(function()
                    TweenService:Create(Optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 0.5}):Play()
                end)
                Optbtn.MouseLeave:Connect(function()
                    TweenService:Create(Optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
                end)
                Optbtn.MouseButton1Click:Connect(function()
                    TweenService:Create(Optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
                    CurrentValue = opt
                    if ConfigManager.Elements[Flag] then ConfigManager.Elements[Flag].Value = CurrentValue end
                if type(Flag) == "string" and string.find(Flag, "^Settings_") then ConfigManager:SaveUISettings() end
                    Droplabel.Text = opt
                    CloseList()
                    if callback then callback(CurrentValue) end
                end)
            end
            ConfigManager.Elements[Flag] = { Value = CurrentValue, Set = function(self, val) CurrentValue = val; Droplabel.Text = val; if callback then callback(val) end end }
            Dropbtn.MouseButton1Click:Connect(function()
                if Opened then
                    CloseList()
                else
                    OpenList()
                end
            end)
            UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and Opened then
                    local AbsPos = Dropbtn.AbsolutePosition
                    local AbsSize = Dropbtn.AbsoluteSize
                    local Mpos = Vector2.new(input.Position.X, input.Position.Y)
                    local InBtn = Mpos.X >= AbsPos.X and Mpos.X <= AbsPos.X + AbsSize.X and Mpos.Y >= AbsPos.Y and Mpos.Y <= AbsPos.Y + AbsSize.Y
                    local LPos = Listframe.AbsolutePosition
                    local LSize = Listframe.AbsoluteSize
                    local InList = Mpos.X >= LPos.X and Mpos.X <= LPos.X + LSize.X and Mpos.Y >= LPos.Y and Mpos.Y <= LPos.Y + LSize.Y
                    if not InBtn and not InList then
                        CloseList()
                    end
                end
            end)
            return DropdownObj
        end
        function Sec:MultiDropdown(name, options, defaultOptions, callback, Flag, targetParent)
            table.insert(Sec.SearchableText, string.upper(name))
            if type(options) == 'table' then for _, o in ipairs(options) do table.insert(Sec.SearchableText, string.upper(tostring(o))) end end
            Flag = Flag or name
            defaultOptions = defaultOptions or {}
            local Droprow = Instance.new("Frame")
            Droprow.Name = "droprow"
            Droprow.Parent = targetParent or Workareamain
            local SearchStr = string.upper(name)
            if type(options) == "table" then for _, o in ipairs(options) do SearchStr = SearchStr .. " " .. string.upper(tostring(o)) end end
            table.insert(Sec.ElementsList, { text = SearchStr, gui = Droprow })
            Droprow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Droprow.BackgroundTransparency = 1
            Droprow.BorderSizePixel = 0
            Droprow.Size = UDim2.new(1, 0, 0, 37)
            local Droplabel_top = Instance.new("TextLabel")
            Droplabel_top.Name = "droplabel_top"
            Droplabel_top.Parent = Droprow
            Droplabel_top.BackgroundTransparency = 1
            local isGroupbox = (targetParent and targetParent.Name == "contentFrame")
            Droplabel_top.Size = UDim2.new(1, isGroupbox and -130 or -240, 1, 0)
            Droplabel_top.Font = Enum.Font.BuilderSansMedium
            Droplabel_top.Text = name
            RegisterTheme(Droplabel_top, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
            Droplabel_top.TextSize = 16
            Droplabel_top.TextWrapped = true
            Droplabel_top.TextXAlignment = Enum.TextXAlignment.Left
            local Dropbtn = Instance.new("TextButton")
            Dropbtn.Name = "dropbtn"
            Dropbtn.ZIndex = 20
            Dropbtn.Parent = Droprow
            RegisterTheme(Dropbtn, "BackgroundColor3", Color3.fromRGB(228, 228, 238), Color3.fromRGB(32, 32, 42))
            Dropbtn.Position = UDim2.new(1, isGroupbox and -123 or -233, 0.5, -17)
            Dropbtn.Size = UDim2.new(0, isGroupbox and 123 or 233, 0, 34)
            Dropbtn.Font = Enum.Font.BuilderSans
            local Droplabel = Instance.new("TextLabel", Dropbtn)
            Droplabel.BackgroundTransparency = 1
            Droplabel.Size = UDim2.new(1, -30, 1, 0)
            Droplabel.Position = UDim2.new(0, 10, 0, 0)
            Droplabel.Font = Enum.Font.BuilderSans
            Droplabel.ZIndex = 21
            RegisterTheme(Droplabel, "TextColor3", Color3.fromRGB(15, 15, 20), Color3.fromRGB(240, 240, 245))
            Droplabel.TextSize = 14
            Droplabel.TextXAlignment = Enum.TextXAlignment.Left
            Droplabel.TextTruncate = Enum.TextTruncate.AtEnd
            Dropbtn.AutoButtonColor = false
            Dropbtn.Text = ""
            Dropbtn.ClipsDescendants = true
            local Uc_db = Instance.new("UICorner")
            Uc_db.CornerRadius = UDim.new(0, 9)
            Uc_db.Parent = Dropbtn
            local Arrow = Instance.new("TextLabel")
            Arrow.Name = "arrow"
            Arrow.Parent = Dropbtn
            Arrow.BackgroundTransparency = 1
            Arrow.Position = UDim2.new(1, -28, 0, 0)
            Arrow.Size = UDim2.new(0, 24, 1, 0)
            Arrow.Font = Enum.Font.BuilderSansMedium
            Arrow.Text = "v"
            Arrow.TextColor3 = Color3.fromRGB(95, 95, 95)
            Arrow.TextSize = 14
            Arrow.ZIndex = 21
            local CurrentValues = {}
            for _, v in ipairs(defaultOptions) do table.insert(CurrentValues, v) end
            local function UpdateLabel()
                if #CurrentValues == 0 then
                    Droplabel.Text = "None"
                else
                    if #CurrentValues > 2 then
                        Droplabel.Text = CurrentValues[1] .. ", " .. CurrentValues[2] .. ", ..."
                    else
                        Droplabel.Text = table.concat(CurrentValues, ", ")
                    end
                end
            end
            UpdateLabel()
            local Listframe = Instance.new("ScrollingFrame")
            Listframe.Name = "listframe"
            Listframe.Parent = targetParent or Workareamain
            RegisterTheme(Listframe, "BackgroundColor3", Color3.fromRGB(238, 238, 245), Color3.fromRGB(24, 24, 32))
            Listframe.BorderSizePixel = 0
            Listframe.Size = UDim2.new(1, 0, 0, 0)
            Listframe.ClipsDescendants = true
            Listframe.Visible = false
            Listframe.ZIndex = 30
            Listframe.CanvasSize = UDim2.new(0, 0, 0, 0)
            Listframe.AutomaticCanvasSize = Enum.AutomaticSize.Y
            Listframe.ScrollBarThickness = 2
            Listframe.ScrollBarImageColor3 = CurrentAccentColor
            local Uc_lf = Instance.new("UICorner")
            Uc_lf.CornerRadius = UDim.new(0, 9)
            Uc_lf.Parent = Listframe
            local Listlayout = Instance.new("UIListLayout")
            Listlayout.Parent = Listframe
            Listlayout.SortOrder = Enum.SortOrder.LayoutOrder
            Listlayout.Padding = UDim.new(0, 2)
            local Listpadding = Instance.new("UIPadding")
            Listpadding.Parent = Listframe
            Listpadding.PaddingTop = UDim.new(0, 4)
            Listpadding.PaddingBottom = UDim.new(0, 4)
            local Opened = false
            local function CloseList()
                Opened = false
                Arrow.Text = "v"
                TweenService:Create(Listframe, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                task.wait(0.15)
                Listframe.Visible = false
            end
            local function OpenList()
                Opened = true
                Arrow.Text = "^"
                local ContentH = Listlayout.AbsoluteContentSize.Y + 8
                local ClampedH = math.min(ContentH, 150)
                Listframe.Visible = true
                Listframe.Size = UDim2.new(1, 0, 0, 0)
                TweenService:Create(Listframe, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, ClampedH)}):Play()
            end
            local function IsSelected(opt)
                for _, v in ipairs(CurrentValues) do
                    if v == opt then return true end
                end
                return false
            end
            local DropdownObj = {}
            function DropdownObj:Refresh(newOptions)
                for _, child in ipairs(Listframe:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                options = newOptions
                for _, opt in ipairs(options) do
                    local Optbtn = Instance.new("TextButton")
                    Optbtn.Name = "optbtn"
                    Optbtn.Parent = Listframe
                    Optbtn.BackgroundColor3 = CurrentAccentColor
                    Optbtn.BackgroundTransparency = IsSelected(opt) and 0 or 1
                    Optbtn.Size = UDim2.new(1, -8, 0, 30)
                    Optbtn.Position = UDim2.new(0, 4, 0, 0)
                    Optbtn.Font = Enum.Font.BuilderSansMedium
                    Optbtn.Text = opt
                    if IsSelected(opt) then
                        Optbtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    else
                        RegisterTheme(Optbtn, "TextColor3", Color3.fromRGB(15, 15, 20), Color3.fromRGB(240, 240, 245))
                    end
                    Optbtn.TextSize = 14
                    Optbtn.AutoButtonColor = false
                    Optbtn.ZIndex = 35
                    local Uc_ob = Instance.new("UICorner")
                    Uc_ob.CornerRadius = UDim.new(0, 7)
                    Uc_ob.Parent = Optbtn
                    local IsHovering = false
                    Optbtn.MouseEnter:Connect(function()
                        IsHovering = true
                        if not IsSelected(opt) then
                            TweenService:Create(Optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 0.5}):Play()
                        end
                    end)
                    Optbtn.MouseLeave:Connect(function()
                        IsHovering = false
                        if not IsSelected(opt) then
                            TweenService:Create(Optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
                        end
                    end)
                    Optbtn.MouseButton1Click:Connect(function()
                        if IsSelected(opt) then
                            for i, v in ipairs(CurrentValues) do
                                if v == opt then table.remove(CurrentValues, i) break end
                            end
                            local TargetTrans = IsHovering and 0.5 or 1
                            TweenService:Create(Optbtn, TweenInfo.new(0.1), {BackgroundTransparency = TargetTrans}):Play()
                            RegisterTheme(Optbtn, "TextColor3", Color3.fromRGB(15, 15, 20), Color3.fromRGB(240, 240, 245))
                        else
                            table.insert(CurrentValues, opt)
                            TweenService:Create(Optbtn, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
                            Optbtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        end
                        UpdateLabel()
                        if ConfigManager.Elements[Flag] then ConfigManager.Elements[Flag].Value = CurrentValues end
                        if callback then callback(CurrentValues) end
                    end)
                end
            end
            DropdownObj:Refresh(options)
            ConfigManager.Elements[Flag] = { Value = CurrentValues, Set = function(self, val) CurrentValues = val; UpdateLabel(); DropdownObj:Refresh(options); if callback then callback(val) end end }
            Dropbtn.MouseButton1Click:Connect(function()
                if Opened then
                    CloseList()
                else
                    OpenList()
                end
            end)
            UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and Opened then
                    local AbsPos = Dropbtn.AbsolutePosition
                    local AbsSize = Dropbtn.AbsoluteSize
                    local Mpos = Vector2.new(input.Position.X, input.Position.Y)
                    local InBtn = Mpos.X >= AbsPos.X and Mpos.X <= AbsPos.X + AbsSize.X and Mpos.Y >= AbsPos.Y and Mpos.Y <= AbsPos.Y + AbsSize.Y
                    local LPos = Listframe.AbsolutePosition
                    local LSize = Listframe.AbsoluteSize
                    local InList = Mpos.X >= LPos.X and Mpos.X <= LPos.X + LSize.X and Mpos.Y >= LPos.Y and Mpos.Y <= LPos.Y + LSize.Y
                    if not InBtn and not InList then
                        CloseList()
                    end
                end
            end)
            return DropdownObj
        end
        function Sec:ColorPicker(name, default, callback, Flag, targetParent)
            table.insert(Sec.SearchableText, string.upper(name))
            Flag = Flag or name
            local Cprow = Instance.new("Frame")
            Cprow.Name = "cprow"
            Cprow.Parent = targetParent or Workareamain
            table.insert(Sec.ElementsList, { text = string.upper(name), gui = Cprow })
            Cprow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Cprow.BackgroundTransparency = 1
            Cprow.BorderSizePixel = 0
            Cprow.Size = UDim2.new(1, 0, 0, 37)
            local Cplabel = Instance.new("TextLabel")
            Cplabel.Name = "cplabel"
            Cplabel.Parent = Cprow
            Cplabel.BackgroundTransparency = 1
            Cplabel.Size = UDim2.new(1, -80, 1, 0)
            Cplabel.Font = Enum.Font.BuilderSansMedium
            Cplabel.Text = name
            RegisterTheme(Cplabel, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
            Cplabel.TextSize = 16
            Cplabel.TextWrapped = true
            Cplabel.TextXAlignment = Enum.TextXAlignment.Left
            local Preview = Instance.new("TextButton")
            Preview.Name = "preview"
            Preview.Parent = Cprow
            Preview.BackgroundColor3 = default or CurrentAccentColor
            Preview.Position = UDim2.new(1, -70, 0.5, -14)
            Preview.Size = UDim2.new(0, 70, 0, 28)
            Preview.Text = ""
            Preview.AutoButtonColor = false
            Preview.ZIndex = 20
            Preview.BorderSizePixel = 0
            local Uc_cp = Instance.new("UICorner")
            Uc_cp.CornerRadius = UDim.new(0, 8)
            Uc_cp.Parent = Preview
            
            local CurrentColor = default or CurrentAccentColor
            local PickerOpen = false
            local Pickerframe = Instance.new("Frame")
            Pickerframe.Name = "pickerframe"
            Pickerframe.Parent = targetParent or Workareamain
            RegisterTheme(Pickerframe, "BackgroundColor3", Color3.fromRGB(245, 245, 245), Color3.fromRGB(40, 40, 40))
            Pickerframe.BorderSizePixel = 0
            Pickerframe.Size = UDim2.new(1, 0, 0, 0)
            Pickerframe.ClipsDescendants = true
            Pickerframe.Visible = false
            Pickerframe.ZIndex = 5
            local Uc_pf = Instance.new("UICorner")
            Uc_pf.CornerRadius = UDim.new(0, 9)
            Uc_pf.Parent = Pickerframe
            local Hsvmap = Instance.new("ImageLabel")
            Hsvmap.Name = "hsvmap"
            Hsvmap.Parent = Pickerframe
            Hsvmap.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            Hsvmap.Position = UDim2.new(0, 8, 0, 8)
            Hsvmap.Size = UDim2.new(0, 200, 0, 130)
            Hsvmap.Image = "rbxassetid://4155801252"
            Hsvmap.ZIndex = 6
            Hsvmap.BorderSizePixel = 0
            local Uc_hm = Instance.new("UICorner")
            Uc_hm.CornerRadius = UDim.new(0, 6)
            Uc_hm.Parent = Hsvmap
            local Satcursor = Instance.new("Frame")
            Satcursor.Name = "satcursor"
            Satcursor.Parent = Hsvmap
            Satcursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Satcursor.AnchorPoint = Vector2.new(0.5, 0.5)
            Satcursor.Position = UDim2.new(1, 0, 0, 0)
            Satcursor.Size = UDim2.new(0, 10, 0, 10)
            Satcursor.ZIndex = 7
            Satcursor.BorderSizePixel = 0
            local Uc_sc = Instance.new("UICorner")
            Uc_sc.CornerRadius = UDim.new(1, 0)
            Uc_sc.Parent = Satcursor
            local Huerail = Instance.new("Frame")
            Huerail.Name = "huerail"
            Huerail.Parent = Pickerframe
            Huerail.Position = UDim2.new(0, 218, 0, 8)
            Huerail.Size = UDim2.new(0, 16, 0, 130)
            Huerail.BorderSizePixel = 0
            Huerail.ZIndex = 6
            local Uc_hr = Instance.new("UICorner")
            Uc_hr.CornerRadius = UDim.new(1, 0)
            Uc_hr.Parent = Huerail
            local Huegrad = Instance.new("UIGradient")
            local Huekeys = {}
            for i = 0, 1, 0.1 do
                table.insert(Huekeys, ColorSequenceKeypoint.new(math.min(i, 1), Color3.fromHSV(i, 1, 1)))
            end
            Huegrad.Color = ColorSequence.new(Huekeys)
            Huegrad.Rotation = 90
            Huegrad.Parent = Huerail
            local Huecursor = Instance.new("Frame")
            Huecursor.Name = "huecursor"
            Huecursor.Parent = Huerail
            Huecursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Huecursor.AnchorPoint = Vector2.new(0.5, 0.5)
            Huecursor.Position = UDim2.new(0.5, 0, 0, 0)
            Huecursor.Size = UDim2.new(1, 4, 0, 6)
            Huecursor.ZIndex = 7
            Huecursor.BorderSizePixel = 0
            local Uc_hc = Instance.new("UICorner")
            Uc_hc.CornerRadius = UDim.new(1, 0)
            Uc_hc.Parent = Huecursor
            local Hexlabel = Instance.new("TextLabel")
            Hexlabel.Name = "hexlabel"
            Hexlabel.Parent = Pickerframe
            Hexlabel.BackgroundTransparency = 1
            Hexlabel.Position = UDim2.new(0, 244, 0, 8)
            Hexlabel.Size = UDim2.new(0, 60, 0, 20)
            Hexlabel.Font = Enum.Font.BuilderSans
            Hexlabel.Text = "Hex"
            RegisterTheme(Hexlabel, "TextColor3", Color3.fromRGB(95, 95, 95), Color3.fromRGB(200, 200, 200))
            Hexlabel.TextSize = 16
            Hexlabel.TextXAlignment = Enum.TextXAlignment.Left
            Hexlabel.ZIndex = 6
            local Hexbox = Instance.new("TextBox")
            Hexbox.Name = "hexbox"
            Hexbox.Parent = Pickerframe
            RegisterTheme(Hexbox, "BackgroundColor3", Color3.fromRGB(240, 240, 240), Color3.fromRGB(45, 45, 45))
            Hexbox.Position = UDim2.new(0, 244, 0, 28)
            Hexbox.Size = UDim2.new(0, 156, 0, 28)
            Hexbox.Font = Enum.Font.BuilderSans
            Hexbox.Text = "#" .. CurrentColor:ToHex()
            RegisterTheme(Hexbox, "TextColor3", Color3.fromRGB(12, 12, 12), Color3.fromRGB(240, 240, 240))
            Hexbox.TextSize = 16
            Hexbox.ClearTextOnFocus = false
            Hexbox.ZIndex = 6
            Hexbox.BorderSizePixel = 0
            local Uc_hb = Instance.new("UICorner")
            Uc_hb.CornerRadius = UDim.new(0, 7)
            Uc_hb.Parent = Hexbox
            local H, S, V = Color3.toHSV(CurrentColor)
            local function RefreshDisplay()
                Hsvmap.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
                Huecursor.Position = UDim2.new(0.5, 0, H, 0)
                Satcursor.Position = UDim2.new(S, 0, 1 - V, 0)
                local Col = Color3.fromHSV(H, S, V)
                Preview.BackgroundColor3 = Col
                CurrentColor = Col
                if ConfigManager.Elements[Flag] then ConfigManager.Elements[Flag].Value = {R=Col.R, G=Col.G, B=Col.B} end
                Hexbox.Text = "#" .. Col:ToHex()
                if callback then callback(Col) end
            end
            local DraggingHSV = false
            local DraggingHue = false
            Hsvmap.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingHSV = true
                    if Workareamain then Workareamain.ScrollingEnabled = false end
                end
            end)
            Hsvmap.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingHSV = false
                    if Workareamain then Workareamain.ScrollingEnabled = true end
                end
            end)
            Huerail.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingHue = true
                    if Workareamain then Workareamain.ScrollingEnabled = false end
                end
            end)
            Huerail.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingHue = false
                    if Workareamain then Workareamain.ScrollingEnabled = true end
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    if DraggingHSV then
                        local RelX = math.clamp(input.Position.X - Hsvmap.AbsolutePosition.X, 0, Hsvmap.AbsoluteSize.X)
                        local RelY = math.clamp(input.Position.Y - Hsvmap.AbsolutePosition.Y, 0, Hsvmap.AbsoluteSize.Y)
                        S = RelX / Hsvmap.AbsoluteSize.X
                        V = 1 - (RelY / Hsvmap.AbsoluteSize.Y)
                        RefreshDisplay()
                    elseif DraggingHue then
                        local RelY = math.clamp(input.Position.Y - Huerail.AbsolutePosition.Y, 0, Huerail.AbsoluteSize.Y)
                        H = RelY / Huerail.AbsoluteSize.Y
                        RefreshDisplay()
                    end
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    DraggingHSV = false
                    DraggingHue = false
                end
            end)
            Hexbox.FocusLost:Connect(function(enter)
                if enter then
                    local Ok, Col = pcall(Color3.fromHex, Hexbox.Text)
                    if Ok and typeof(Col) == "Color3" then
                        H, S, V = Color3.toHSV(Col)
                        RefreshDisplay()
                    end
                end
            end)
            RefreshDisplay()
            ConfigManager.Elements[Flag] = { Value = {R=CurrentColor.R, G=CurrentColor.G, B=CurrentColor.B}, Set = function(self, val) local Col = Color3.new(val.R, val.G, val.B); H,S,V = Color3.toHSV(Col); RefreshDisplay() end }
            Preview.MouseButton1Click:Connect(function()
                if PickerOpen then
                    PickerOpen = false
                    TweenService:Create(Pickerframe, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)}):Play()
                    task.wait(0.15)
                    Pickerframe.Visible = false
                else
                    PickerOpen = true
                    Pickerframe.Visible = true
                    Pickerframe.Size = UDim2.new(1, 0, 0, 0)
                    TweenService:Create(Pickerframe, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 155)}):Play()
                end
            end)
        end
        function Sec:Keybind(name, default, callback, Flag, targetParent)
            table.insert(Sec.SearchableText, string.upper(name))
            Flag = Flag or name
            local Kbrow = Instance.new("Frame")
            Kbrow.Name = "kbrow"
            Kbrow.Parent = targetParent or Workareamain
            table.insert(Sec.ElementsList, { text = string.upper(name), gui = Kbrow })
            Kbrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Kbrow.BackgroundTransparency = 1
            Kbrow.BorderSizePixel = 0
            Kbrow.Size = UDim2.new(1, 0, 0, 37)
            local Kblabel = Instance.new("TextLabel")
            Kblabel.Name = "kblabel"
            Kblabel.Parent = Kbrow
            Kblabel.BackgroundTransparency = 1
            Kblabel.Size = UDim2.new(1, -80, 1, 0)
            Kblabel.Font = Enum.Font.BuilderSansMedium
            Kblabel.Text = name
            RegisterTheme(Kblabel, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
            Kblabel.TextSize = 16
            Kblabel.TextWrapped = true
            Kblabel.TextXAlignment = Enum.TextXAlignment.Left
            local Kbbtn = Instance.new("TextButton")
                        Kbbtn.Name = "kbbtn"
            Kbbtn.Parent = Kbrow
            RegisterTheme(Kbbtn, "BackgroundColor3", Color3.fromRGB(235, 235, 245), Color3.fromRGB(50, 50, 60))
            Kbbtn.Position = UDim2.new(1, -70, 0.5, -17)
            Kbbtn.Size = UDim2.new(0, 70, 0, 34)
            Kbbtn.Font = Enum.Font.BuilderSansBold
            RegisterTheme(Kbbtn, "TextColor3", Color3.fromRGB(90, 90, 100), Color3.fromRGB(200, 200, 210))
            Kbbtn.TextSize = 14
            Kbbtn.AutoButtonColor = false
            Kbbtn.Text = default and default.Name or "None"
            Kbbtn.ZIndex = 20
            Kbbtn.BorderSizePixel = 0
            local Uc_kb = Instance.new("UICorner")
            Uc_kb.CornerRadius = UDim.new(1, 0)
            Uc_kb.Parent = Kbbtn
            
            local CurrentKey = default
            local Picking = false
            Kbbtn.MouseButton1Click:Connect(function()
                if Picking then return end
                Picking = true
                Kbbtn.Text = "..."
                Kbbtn.TextColor3 = Color3.fromRGB(95, 95, 95)
                task.wait(0.2)
                local Con
                local Cancelled = false
                task.delay(5, function()
                    if Picking and not Cancelled then
                        Picking = false
                        Kbbtn.Text = CurrentKey and CurrentKey.Name or "None"
                        RegisterTheme(Kbbtn, "TextColor3", Color3.fromRGB(90, 90, 100), Color3.fromRGB(200, 200, 210))
                        if Con then Con:Disconnect() end
                    end
                end)
                Con = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                Cancelled = true
                if input.KeyCode == Enum.KeyCode.Escape then
                    Kbbtn.Text = CurrentKey and CurrentKey.Name or "None"
                elseif input.KeyCode == Enum.KeyCode.Backspace then
                    CurrentKey = nil
                    if ConfigManager.Elements[Flag] then ConfigManager.Elements[Flag].Value = "None" end
                    Kbbtn.Text = "None"
                elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                    CurrentKey = input.KeyCode
                    if ConfigManager.Elements[Flag] then ConfigManager.Elements[Flag].Value = CurrentKey.Name end
                    Kbbtn.Text = input.KeyCode.Name
                else
                    Kbbtn.Text = CurrentKey and CurrentKey.Name or "None"
                end
                RegisterTheme(Kbbtn, "TextColor3", Color3.fromRGB(90, 90, 100), Color3.fromRGB(200, 200, 210))
                Picking = false
                Con:Disconnect()
            end
        end)
            end)
            ConfigManager.Elements[Flag] = { Value = CurrentKey and CurrentKey.Name or "None", Set = function(self, val) if val == "None" then CurrentKey = nil; Kbbtn.Text = "None" else CurrentKey = Enum.KeyCode[val]; Kbbtn.Text = val end end }
            local KbConn = UserInputService.InputBegan:Connect(function(input, gp)
                if not Picking and not gp and input.UserInputType == Enum.UserInputType.Keyboard then
                    if CurrentKey and input.KeyCode == CurrentKey then
                        if callback then callback() end
                    end
                end
            end)
            table.insert(CleanupKeybinds, KbConn)
        end
        function Sec:Paragraph(Title, Content, targetParent)
            local Para = Instance.new("TextLabel")
            Para.Name = "para"
            Para.Parent = targetParent or Workareamain
            local SearchStr = string.upper(Title) .. " " .. string.upper(Content)
            table.insert(Sec.ElementsList, { text = SearchStr, gui = Para })
            Para.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Para.BackgroundTransparency = 1
            Para.BorderSizePixel = 0
            Para.Size = UDim2.new(1, 0, 0, 56)
            Para.Font = Enum.Font.BuilderSans
            Para.Text = ""
            Para.TextColor3 = Color3.fromRGB(95, 95, 95)
            Para.TextSize = 21
            local Ptitle = Instance.new("TextLabel")
            Ptitle.Name = "ptitle"
            Ptitle.Parent = Para
            Ptitle.BackgroundTransparency = 1
            Ptitle.Size = UDim2.new(1, 0, 0, 24)
            Ptitle.Position = UDim2.new(0, 0, 0, 0)
            Ptitle.Font = Enum.Font.BuilderSansMedium
            Ptitle.Text = Title
            RegisterTheme(Ptitle, "TextColor3", Color3.fromRGB(0, 0, 0), Color3.fromRGB(255, 255, 255))
            Ptitle.TextSize = 21
            Ptitle.TextWrapped = true
            Ptitle.TextXAlignment = Enum.TextXAlignment.Left
            local Pcontent = Instance.new("TextLabel")
            Pcontent.Name = "pcontent"
            Pcontent.Parent = Para
            Pcontent.BackgroundTransparency = 1
            Pcontent.Size = UDim2.new(1, 0, 0, 28)
            Pcontent.Position = UDim2.new(0, 0, 0, 24)
            Pcontent.Font = Enum.Font.BuilderSans
            Pcontent.Text = Content
            RegisterTheme(Pcontent, "TextColor3", Color3.fromRGB(100, 100, 120), Color3.fromRGB(140, 140, 155))
            Pcontent.TextSize = 14
            Pcontent.TextWrapped = true
            Pcontent.TextXAlignment = Enum.TextXAlignment.Left
        end
        Sidebar2.MouseButton1Click:Connect(function()
            Sec:Select()
        end)
        if _internalExtra then
            table.insert(ExtraTabs, Sec)
            Sidebar2.Visible = false
        else
            table.insert(MainTabs, Sec)
        end
        return Sec
    end
    local function CreateSettingsTab()
        local Setsec = Window:Section("Settings", "rbxassetid://10734950309", true)
        
        local LeftGroup = Setsec:AddLeftGroupbox("UI Settings")
        LeftGroup:Button("Unload Library", function()
            local Container = gethui and gethui() or game:GetService("CoreGui")
            for _, v in pairs(Container:GetChildren()) do
                if v.Name == "MacOSLibrary_GUI" then
                    v:Destroy()
                end
            end
        end)
        LeftGroup:Keybind("Menu Bind", Enum.KeyCode.LeftControl, function(v)
            if v then
                visiblekey = v.KeyCode
                if Lib.FolderName then
                    local BindPath = Lib.FolderName .. "/menu_bind.txt"
                    if makefolder and not isfolder(Lib.FolderName) then makefolder(Lib.FolderName) end
                    pcall(writefile, BindPath, v.KeyCode.Name)
                end
            end
        end, "Settings_MenuBind")
        LeftGroup:Switch("Keybinds Window", false, function(v)
            KeybindsWindowFrame.Visible = v
            if BlurEnabled then
                if v then
                    Blur:BindFrame(KeybindsWindowFrame:FindFirstChild("blurFrame"), {
                        Transparency = 0.98,
                        Color = Color3.fromRGB(255, 255, 255)
                    })
                else
                    if Blur:HasBinding(KeybindsWindowFrame:FindFirstChild("blurFrame")) then
                        Blur:UnbindFrame(KeybindsWindowFrame:FindFirstChild("blurFrame"))
                    end
                end
            end
        end, "Settings_KeybindsWindow")
        LeftGroup:Switch("Disable Splash Screen", ConfigManager.DisableSplash or false, function(v)
            ConfigManager.DisableSplash = v; ConfigManager:SaveUISettings()
        end)
        
        local RightGroup = Setsec:AddRightGroupbox("Config Manager")
        local ConfigsList = ConfigManager:GetConfigs()
        if #ConfigsList == 0 then ConfigsList = {"Default"} end
        local ActiveConfig = ConfigsList[1]
        local ConfigDropdown = RightGroup:Dropdown("Select Config", ConfigsList, ConfigsList[1], function(opt)
            ActiveConfig = opt
        end, "Settings_ConfigDropdown")
        RightGroup:Button("Refresh Configs", function()
            local NewList = ConfigManager:GetConfigs()
            if #NewList == 0 then NewList = {"Default"} end
            if ConfigDropdown and ConfigDropdown.Refresh then
                ConfigDropdown:Refresh(NewList)
            end
        end)
        RightGroup:TextField("Create New Config", "Type name and save...", function(txt)
            ActiveConfig = txt
        end, "ConfigNameInput")
        RightGroup:Button("Save Config", function()
            if ActiveConfig and ActiveConfig ~= "" then
                ConfigManager:Save(ActiveConfig)
                Window:TempNotify("Config Saved", "Saved config as " .. ActiveConfig, "rbxassetid://12608259004")
                local NewList = ConfigManager:GetConfigs()
                if #NewList == 0 then NewList = {"Default"} end
                if ConfigDropdown and ConfigDropdown.Refresh then
                    ConfigDropdown:Refresh(NewList)
                end
            end
        end)
        RightGroup:Button("Load Config", function()
            if ActiveConfig and ActiveConfig ~= "" then
                ConfigManager:Load(ActiveConfig)
                Window:TempNotify("Config Loaded", "Loaded config " .. ActiveConfig, "rbxassetid://12608259004")
            end
        end)
        RightGroup:Button("Delete Config", function()
            if ActiveConfig and ActiveConfig ~= "" then
                ConfigManager:Delete(ActiveConfig)
                Window:TempNotify("Config Deleted", "Deleted config " .. ActiveConfig, "rbxassetid://12608259004")
                local NewList = ConfigManager:GetConfigs()
                if #NewList == 0 then NewList = {"Default"} end
                if ConfigDropdown and ConfigDropdown.Refresh then
                    ConfigDropdown:Refresh(NewList)
                end
            end
        end)
        RightGroup:Button("Set as AutoLoad", function()
            if ActiveConfig and ActiveConfig ~= "" then
                ConfigManager:SaveAutoLoad(ActiveConfig)
                Window:TempNotify("AutoLoad Set", ActiveConfig .. " will now auto-load on start.", "rbxassetid://12608259004")
            end
        end)
        
        local CustomGroup = Setsec:AddLeftGroupbox("UI Customization")
        CustomGroup:Slider("UI Transparency", 0, 100, 15, function(v)
            Main.BackgroundTransparency = v / 100
            KeybindsWindowFrame.BackgroundTransparency = v / 100
        end, "Settings_UITransparency")
        local function MatchColor(c1, c2)
            return math.abs(c1.R - c2.R) < 0.01 and math.abs(c1.G - c2.G) < 0.01 and math.abs(c1.B - c2.B) < 0.01
        end
        local function ApplyAccent(c)
            local OldAccent = CurrentAccentColor
            CurrentAccentColor = c
            for _, item in ipairs(ThemeElements) do
                if type(item.Light) == "userdata" and MatchColor(item.Light, OldAccent) then item.Light = c end
                if type(item.Dark) == "userdata" and MatchColor(item.Dark, OldAccent) then item.Dark = c end
            end
            for _, obj in next, scrgui:GetDescendants() do
                if obj:IsA("GuiObject") or obj:IsA("UIStroke") then
                    pcall(function()
                        if MatchColor(obj.BackgroundColor3, OldAccent) then obj.BackgroundColor3 = c end
                    end)
                    pcall(function()
                        if MatchColor(obj.TextColor3, OldAccent) then obj.TextColor3 = c end
                    end)
                    pcall(function()
                        if MatchColor(obj.Color, OldAccent) then obj.Color = c end
                    end)
                end
            end
        end
        CustomGroup:ColorPicker("Accent Color", ConfigManager.AccentColor or Color3.fromRGB(21, 103, 251), function(c)
            ConfigManager.AccentColor = c
            ConfigManager:SaveUISettings()
            ApplyAccent(c)
        end, "Settings_AccentColor")
        local RainbowConnection
        if ConfigManager.AccentColor then
            ApplyAccent(ConfigManager.AccentColor)
        end
        CustomGroup:Switch("Rainbow Accent", ConfigManager.Rainbow or false, function(v)
            ConfigManager.Rainbow = v
            ConfigManager:SaveUISettings()
            if v then
                local Hue = 0
                RainbowConnection = RunService.RenderStepped:Connect(function(dt)
                    Hue = (Hue + dt * 0.1) % 1
                    ApplyAccent(Color3.fromHSV(Hue, 1, 1))
                end)
            else
                if RainbowConnection then RainbowConnection:Disconnect() end
            end
        end, "Settings_Rainbow")
        CustomGroup:Switch("Transparent Sidebar", false, function(v)
            if v then
                Workarea.BackgroundTransparency = 0
                Workareacornerhider.BackgroundTransparency = 0
            else
                Workarea.BackgroundTransparency = 1
                Workareacornerhider.BackgroundTransparency = 1
            end
        end, "Settings_TransparentSidebar")
        CustomGroup:Switch("Global Error Catcher", false, function(v)
            ErrorCatcherEnabled = v
        end, "Settings_ErrorCatcher")
        CustomGroup:Switch("Blur Background", false, function(v)
            BlurEnabled = v
            if v then
                if visible then
                    Blur:BindFrame(BlurFrame, {
                        Transparency = 0.98,
                        Color = Color3.fromRGB(255, 255, 255)
                    })
                    if KeybindsWindowFrame.Visible then
                        Blur:BindFrame(KeybindsWindowFrame:FindFirstChild("blurFrame"), {
                            Transparency = 0.98,
                            Color = Color3.fromRGB(255, 255, 255)
                        })
                    end
                end
            else
                if Blur:HasBinding(BlurFrame) then
                    Blur:UnbindFrame(BlurFrame)
                end
                if Blur:HasBinding(KeybindsWindowFrame:FindFirstChild("blurFrame")) then
                    Blur:UnbindFrame(KeybindsWindowFrame:FindFirstChild("blurFrame"))
                end
            end
        end, "Settings_BlurBackground")
        CustomGroup:Slider("UI Scale", 0.4, 1.5, CScale, function(v)
            Uiscale.Scale = v
        end, "Settings_UIScale")
    end
local KeybindSec = nil
    local function CreateKeybindsTab()
        KeybindSec = Window:Section("Keybinds", "rbxassetid://10723416765", true)
        RefreshKeybindsUI = function()
            for _, child in ipairs(Kb_container:GetChildren()) do
                if child:IsA("Frame") then child:Destroy() end
            end
            for index, bindInfo in ipairs(ActiveKeybindData) do
                local Row = Instance.new("Frame")
                Row.Parent = Kb_container
                Row.BackgroundTransparency = 1
                Row.Size = UDim2.new(1, 0, 0, 20)
                local IsToggle = ConfigManager.Elements[bindInfo.Name] and type(ConfigManager.Elements[bindInfo.Name].Value) == "boolean"
                if IsToggle then
                    local TglFrame = Instance.new("Frame")
                    TglFrame.Parent = Row
                    TglFrame.ZIndex = 20
                    TglFrame.Position = UDim2.new(0, 15, 0.5, -6)
                    TglFrame.Size = UDim2.new(0, 24, 0, 12)
                    TglFrame.BackgroundColor3 = (CurrentTheme == "light") and Color3.fromRGB(216, 216, 216) or Color3.fromRGB(60, 60, 60)
                    local Uc_tgl = Instance.new("UICorner")
                    Uc_tgl.CornerRadius = UDim.new(5, 0)
                    Uc_tgl.Parent = TglFrame
                    local TglBtn = Instance.new("Frame")
                    TglBtn.Parent = TglFrame
                    TglBtn.ZIndex = 21
                    TglBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    TglBtn.Size = UDim2.new(0, 10, 0, 10)
                    TglBtn.Position = UDim2.new(0, 1, 0, 1)
                    local Uc_tglb = Instance.new("UICorner")
                    Uc_tglb.CornerRadius = UDim.new(5, 0)
                    Uc_tglb.Parent = TglBtn
                    task.spawn(function()
                        while TglFrame.Parent do
                            local State = ConfigManager.Elements[bindInfo.Name].Value
                            if State then
                                TglBtn.Position = UDim2.new(0, 13, 0, 1)
                                TglFrame.BackgroundColor3 = CurrentAccentColor
                            else
                                TglBtn.Position = UDim2.new(0, 1, 0, 1)
                                TglFrame.BackgroundColor3 = (CurrentTheme == "light") and Color3.fromRGB(216, 216, 216) or Color3.fromRGB(60, 60, 60)
                            end
                            task.wait(0.1)
                        end
                    end)
                end
                local NameLabel = Instance.new("TextLabel")
                NameLabel.Parent = Row
                NameLabel.BackgroundTransparency = 1
                NameLabel.Position = UDim2.new(0, IsToggle and 45 or 15, 0, 0)
                NameLabel.Size = UDim2.new(0.5, IsToggle and -45 or -15, 1, 0)
                NameLabel.Font = Enum.Font.BuilderSans
                NameLabel.Text = bindInfo.Name
                NameLabel.TextColor3 = (CurrentTheme == "light") and Color3.fromRGB(100, 100, 100) or Color3.fromRGB(140, 140, 155)
                NameLabel.TextSize = 13
                NameLabel.TextXAlignment = Enum.TextXAlignment.Left
                local KeyLabel = Instance.new("TextLabel")
                KeyLabel.Parent = Row
                KeyLabel.BackgroundTransparency = 1
                KeyLabel.Position = UDim2.new(0.5, 0, 0, 0)
                KeyLabel.Size = UDim2.new(0.5, -15, 1, 0)
                KeyLabel.Font = Enum.Font.BuilderSansBold
                KeyLabel.Text = "[" .. bindInfo.Key .. "]"
                KeyLabel.TextColor3 = CurrentAccentColor
                KeyLabel.TextSize = 13
                KeyLabel.TextXAlignment = Enum.TextXAlignment.Right
            end
            local Container = KeybindSec:GetContainer()
            for _, child in ipairs(Container:GetChildren()) do
                if child.Name == "kbrow" or child.Name == "label" then
                    child:Destroy()
                end
            end
            for index, bindInfo in ipairs(ActiveKeybindData) do
                local Kbrow = Instance.new("Frame")
                Kbrow.Name = "kbrow"
                Kbrow.Parent = Container
                Kbrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Kbrow.BackgroundTransparency = 1
                Kbrow.Size = UDim2.new(1, 0, 0, 37)
                local TglFrame = Instance.new("TextButton")
                TglFrame.Parent = Kbrow
                TglFrame.ZIndex = 20
                TglFrame.Position = UDim2.new(0, 0, 0.5, -14)
                TglFrame.Size = UDim2.new(0, 56, 0, 28)
                TglFrame.Text = ""
                TglFrame.AutoButtonColor = false
                TglFrame.BackgroundColor3 = bindInfo.Enabled and CurrentAccentColor or ((CurrentTheme == "light") and Color3.fromRGB(216, 216, 216) or Color3.fromRGB(60, 60, 60))
                local Uc_tgl = Instance.new("UICorner")
                Uc_tgl.CornerRadius = UDim.new(5, 0)
                Uc_tgl.Parent = TglFrame
                local TglBtn = Instance.new("TextButton")
                TglBtn.Parent = TglFrame
                TglBtn.ZIndex = 21
                TglBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TglBtn.Size = UDim2.new(0, 26, 0, 26)
                TglBtn.Position = bindInfo.Enabled and UDim2.new(0, 29, 0, 1) or UDim2.new(0, 1, 0, 1)
                TglBtn.AutoButtonColor = false
                TglBtn.Text = ""
                local Uc_tglb = Instance.new("UICorner")
                Uc_tglb.CornerRadius = UDim.new(5, 0)
                Uc_tglb.Parent = TglBtn
                local function ToggleBind()
                    bindInfo.Enabled = not bindInfo.Enabled
                    if bindInfo.Enabled then
                        TglBtn:TweenPosition(UDim2.new(0, 29, 0, 1), "In", "Sine", 0.1, true)
                        TglFrame.BackgroundColor3 = CurrentAccentColor
                    else
                        TglBtn:TweenPosition(UDim2.new(0, 1, 0, 1), "In", "Sine", 0.1, true)
                        TglFrame.BackgroundColor3 = (CurrentTheme == "light") and Color3.fromRGB(216, 216, 216) or Color3.fromRGB(60, 60, 60)
                    end
                end
                TglFrame.MouseButton1Click:Connect(ToggleBind)
                TglBtn.MouseButton1Click:Connect(ToggleBind)
                local Kblabel = Instance.new("TextLabel")
                Kblabel.Parent = Kbrow
                Kblabel.BackgroundTransparency = 1
                Kblabel.Position = UDim2.new(0, 66, 0, 0)
                Kblabel.Size = UDim2.new(1, -170, 1, 0)
                Kblabel.Font = Enum.Font.BuilderSansMedium
                Kblabel.Text = bindInfo.Name
                RegisterTheme(Kblabel, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(160, 160, 180))
                Kblabel.TextSize = 16
                Kblabel.TextXAlignment = Enum.TextXAlignment.Left
                local RebindBtn = Instance.new("TextButton")
                RebindBtn.Parent = Kbrow
                RebindBtn.ZIndex = 20
                RebindBtn.Position = UDim2.new(1, -95, 0.5, -14)
                RebindBtn.Size = UDim2.new(0, 60, 0, 28)
                RebindBtn.Font = Enum.Font.BuilderSansMedium
                RebindBtn.Text = "[" .. bindInfo.Key .. "]"
                RegisterTheme(RebindBtn, "BackgroundColor3", Color3.fromRGB(228, 228, 238), Color3.fromRGB(32, 32, 42))
                RegisterTheme(RebindBtn, "TextColor3", Color3.fromRGB(140, 140, 155), Color3.fromRGB(200, 200, 200))
                RebindBtn.TextSize = 14
                local Uc_reb = Instance.new("UICorner")
                Uc_reb.CornerRadius = UDim.new(0, 6)
                Uc_reb.Parent = RebindBtn
                RebindBtn.MouseButton1Click:Connect(function()
                    Window:PromptKeybind(bindInfo.Callback, bindInfo.Name)
                end)
                local DelBtn = Instance.new("TextButton")
                DelBtn.Parent = Kbrow
                DelBtn.ZIndex = 20
                DelBtn.Position = UDim2.new(1, -30, 0.5, -14)
                DelBtn.Size = UDim2.new(0, 28, 0, 28)
                DelBtn.Font = Enum.Font.BuilderSansMedium
                DelBtn.Text = "🗑️"
                RegisterTheme(DelBtn, "BackgroundColor3", Color3.fromRGB(255, 100, 100), Color3.fromRGB(180, 50, 50))
                DelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                DelBtn.TextSize = 16
                local Uc_del = Instance.new("UICorner")
                Uc_del.CornerRadius = UDim.new(0, 6)
                Uc_del.Parent = DelBtn
                DelBtn.MouseButton1Click:Connect(function()
                    table.remove(ActiveKeybindData, index)
                    RefreshKeybindsUI()
                end)
            end
        end
    end
    CreateSettingsTab()
        CreateKeybindsTab()
    local AutoloadConfig = ConfigManager:GetAutoLoad()
    if AutoloadConfig then
        task.spawn(function()
            task.wait(1)
            ConfigManager:Load(AutoloadConfig)
            Window:TempNotify("AutoLoad", "Loaded config: " .. AutoloadConfig, "rbxassetid://12608259004")
        end)
    end
    local ScriptContext = game:GetService("ScriptContext")
    local SeenErrors = {}
    ScriptContext.Error:Connect(function(message, trace, script)
        if ErrorCatcherEnabled then
            local ErrMsg = tostring(message)
            if not SeenErrors[ErrMsg] then
                SeenErrors[ErrMsg] = true
                task.spawn(function()
                    task.wait(0.5)
                    Window:Notify2("Script Error", ErrMsg, "Copy", "OK", "rbxassetid://12608259004", function()
                        if setclipboard then setclipboard(ErrMsg .. "\n" .. tostring(trace)) end
                    end, function() end)
                end)
            end
        end
    end)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if IsPromptingKeybind and input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Escape then
                IsPromptingKeybind = false
                if KeybindPromptFrame then KeybindPromptFrame.Visible = false end
                if Notifdarkness then Notifdarkness.Visible = false end
            elseif input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode ~= Enum.KeyCode.Backspace then
                IsPromptingKeybind = false
                if KeybindPromptFrame then KeybindPromptFrame.Visible = false end
                if Notifdarkness then Notifdarkness.Visible = false end
                for i = #ActiveKeybindData, 1, -1 do
                    if ActiveKeybindData[i].Name == KeybindPromptElementName then
                        table.remove(ActiveKeybindData, i)
                    end
                end
                table.insert(ActiveKeybindData, { Name = KeybindPromptElementName, Key = input.KeyCode.Name, Enabled = true, Callback = KeybindPromptCallback })
                if RefreshKeybindsUI then RefreshKeybindsUI() end
                Window:TempNotify("Keybind Set", "Bound to: " .. input.KeyCode.Name, "rbxassetid://12608259004")
            end
            return
        end
        if not IsPromptingKeybind and not gameProcessed and input.UserInputType == Enum.UserInputType.Keyboard then
            for _, bindInfo in ipairs(ActiveKeybindData) do
                if bindInfo.Enabled and bindInfo.Key == input.KeyCode.Name then
                    if bindInfo.Callback then
                        pcall(bindInfo.Callback)
                    end
                end
            end
        end
    end)
    CollapseBtn.MouseButton1Click:Connect(function()
        if CollapseCooldown then return end
        CollapseCooldown = true
        IsSidebarCollapsed = not IsSidebarCollapsed
        local TInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local Rot = IsSidebarCollapsed and 180 or 0
        TweenService:Create(CollapseBtn, TInfo, { Rotation = Rot }):Play()
        local SideWidth = IsSidebarCollapsed and 40 or ExpandedSidebarWidth
        local WorkPosX = IsSidebarCollapsed and 70 or (ExpandedSidebarWidth + 30)
        TweenService:Create(Sidebar, TInfo, { Size = UDim2.new(0, SideWidth, 1, -124) }):Play()
        TweenService:Create(Workarea, TInfo, {
            Position = UDim2.new(0, WorkPosX, 0, 0),
            Size = UDim2.new(1, -WorkPosX, 1, 0)
        }):Play()
        TweenService:Create(Title, TInfo, {
            Position = UDim2.new(0, IsSidebarCollapsed and 60 or 16, 0, IsSidebarCollapsed and 20 or 16),
            TextTransparency = 0
        }):Play()
        local SearchWidth = IsSidebarCollapsed and 34 or (ExpandedSidebarWidth - 8)
        TweenService:Create(Search, TInfo, { Size = UDim2.new(0, SearchWidth, 0, 34) }):Play()
        TweenService:Create(Searchtextbox, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            TextTransparency = IsSidebarCollapsed and 1 or 0
        }):Play()
        local SIconPos = IsSidebarCollapsed and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, 16, 0.5, 0)
        TweenService:Create(Searchicon, TInfo, { Position = SIconPos }):Play()
        local AllTabs = {}
        for _, t in ipairs(MainTabs) do table.insert(AllTabs, t) end
        for _, t in ipairs(ExtraTabs) do table.insert(AllTabs, t) end
        local FirstMainIdx = nil
        local FirstExtraIdx = nil
        for i, t in ipairs(MainTabs) do
            if t.IsDivider and not FirstMainIdx then FirstMainIdx = i end
        end
        for i, t in ipairs(ExtraTabs) do
            if t.IsDivider and not FirstExtraIdx then FirstExtraIdx = i end
        end
        local TxtTrans = IsSidebarCollapsed and 1 or 0
        local PadLeft = IsSidebarCollapsed and 0 or 40
        local HighlightWidth = IsSidebarCollapsed and 34 or 183
        local TargetIconPos = IsSidebarCollapsed and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, -16, 0.5, 0)
        local Highlight = Sidebar:FindFirstChild("TabHighlight")
        if Highlight then
            local TargetX = 3.5
            TweenService:Create(Highlight, TInfo, { 
                Size = UDim2.new(0, HighlightWidth, 0, 34)
            }):Play()
        end
        for i, t in ipairs(AllTabs) do
            local IsFirstMain = FirstMainIdx and (t == MainTabs[FirstMainIdx]) or false
            local IsFirstExtra = FirstExtraIdx and (t == ExtraTabs[FirstExtraIdx]) or false
            if t.IsDivider then
                local IsFirstInMode = (IsFirstMain and not IsExtraMode) or (IsFirstExtra and IsExtraMode)
                local TargetHeight = IsSidebarCollapsed and 12 or 20
                if IsFirstInMode and IsSidebarCollapsed then
                    TargetHeight = 0 
                end
                TweenService:Create(t.Label, TInfo, {
                    TextTransparency = TxtTrans,
                    Size = UDim2.new(0, HighlightWidth, 0, TargetHeight)
                }):Play()
                local Line = t.Label:FindFirstChild("Line")
                if Line then
                    if (IsFirstMain and not IsExtraMode) or (IsFirstExtra and IsExtraMode) then
                        TweenService:Create(Line, TInfo, { BackgroundTransparency = 1 }):Play()
                    else
                        TweenService:Create(Line, TInfo, { BackgroundTransparency = IsSidebarCollapsed and 0 or 1 }):Play()
                    end
                end
            else
                local Btn = t.TabButton
                local padding = Btn:FindFirstChildOfClass("UIPadding")
                if padding then
                    TweenService:Create(padding, TInfo, { PaddingLeft = UDim.new(0, PadLeft) }):Play()
                end
                TweenService:Create(Btn, TInfo, {
                    TextTransparency = TxtTrans,
                    Size = UDim2.new(0, HighlightWidth, 0, 34)
                }):Play()
                local Ico = Btn:FindFirstChild("iconImg")
                if Ico then
                    TweenService:Create(Ico, TInfo, { Position = TargetIconPos }):Play()
                end
            end
        end
        if shared.HighlightConnection then shared.HighlightConnection:Disconnect() end
        local startTick = tick()
        shared.HighlightConnection = RunService.RenderStepped:Connect(function()
            if tick() - startTick > 0.45 then
                if shared.HighlightConnection then shared.HighlightConnection:Disconnect() end
                return
            end
            local currentTab = nil
            for _, s in ipairs(Sections) do
                if s.TextColor3 == Color3.fromRGB(255, 255, 255) then
                    currentTab = s
                    break
                end
            end
            local Highlight = Sidebar:FindFirstChild("TabHighlight")
            if currentTab and Highlight then
                Highlight.Position = UDim2.new(0, 3.5, 0, currentTab.AbsolutePosition.Y - Sidebar.AbsolutePosition.Y + Sidebar.CanvasPosition.Y)
            end
        end)
        task.delay(0.4, function() CollapseCooldown = false end)
    end)
    RefreshBtn.MouseButton1Click:Connect(function()
        local TInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        TweenService:Create(RefreshBtn, TInfo, {Rotation = RefreshBtn.Rotation + 360}):Play()
        local Vp = workspace.CurrentCamera.ViewportSize
        local w = math.clamp(721, 400, Vp.X - 40)
        local h = math.clamp(584, 300, Vp.Y - 40)
        TweenService:Create(Main, TInfo, {Size = UDim2.new(0, w, 0, h)}):Play()
        ExpandedSidebarWidth = 190
        SidebarResizer.Position = UDim2.new(0, 18 + ExpandedSidebarWidth - 4, 0, 106)
        if not IsSidebarCollapsed then
            TweenService:Create(Sidebar, TInfo, {Size = UDim2.new(0, ExpandedSidebarWidth, 1, -124)}):Play()
            TweenService:Create(Workarea, TInfo, {
                Position = UDim2.new(0, ExpandedSidebarWidth + 30, 0, 0),
                Size = UDim2.new(1, -(ExpandedSidebarWidth + 30), 1, 0)
            }):Play()
            local SearchWidth = ExpandedSidebarWidth - 8
            TweenService:Create(Search, TInfo, {Size = UDim2.new(0, SearchWidth, 0, 34)}):Play()
            for _, Btn in ipairs(SidebarList:GetChildren()) do
                if Btn:IsA("TextButton") and (Btn.Name == "sidebar2" or Btn.Name == "sidebar2_selected") then
                    TweenService:Create(Btn, TInfo, {Size = UDim2.new(0, 183, 0, 34)}):Play()
                elseif Btn:IsA("TextLabel") and Btn.Name == "sidebardivider" then
                    TweenService:Create(Btn, TInfo, {Size = UDim2.new(0, 183, 0, 20)}):Play()
                end
            end
            local Highlight = Sidebar:FindFirstChild("TabHighlight")
            if Highlight then
                TweenService:Create(Highlight, TInfo, {Size = UDim2.new(0, 183, 0, 34)}):Play()
            end
        end
    end)
    
    if not ConfigManager.WelcomeShown then
        Window:Notify("Welcome to MacOSLibrary!", "Right click a toggle or button to set a keybind for it. Press the green buttons to manage settings or your keybinds. Hold the end of the tabs to change the size of them. Drag the corners of the ui to change the size of the ui.", "Got it!", "info", function()
            ConfigManager.WelcomeShown = true
            ConfigManager:SaveUISettings()
        end)
    end
    
    return Window
end
return Lib