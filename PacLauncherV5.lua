--// PacLauncher V5 - WinForms-like UI (No Login) - Layout fixed + Boost tab + Backend Logic + AP (Predict)
--// LocalScript: StarterPlayerScripts

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local VIM = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Table to hold connections for full Unload
local Connections = {}

-- Cleanup old UI
local old = PlayerGui:FindFirstChild("PacLauncher")
if old then old:Destroy() end

--========================
-- CONFIG (save/load if writefile exists)
--========================
local ConfigFile = "PacLauncher_Config.json"

local Config = {
	Theme = "Light",

	-- UI
	HideLauncher = false,       
	HideGameUI = false,    
	BlurBackground = true,
	DiscreetNotifications = true, -- NEW: coupe les notifs Roblox (macro/trigger/AP)

	-- Boost (UI-side “stability”)
	PingBoost = false,           
	PingBoostPlus = false,       -- Remplace StabilityMode
	PingHud = true,              

	-- Controls (UI only)
	CPS = 150,
	Binds = {
		Macro = "E",
		Trigger = "One",
		Ap = "Q", -- Ajout du Bind AP
		AppToggle = "LeftControl",
	},

	-- Toggles
	MacroEnabled = false,
	TriggerEnabled = false,
	ApEnabled = false, -- Ajout du statut AP
}

local function SaveConfig()
	if writefile then
		local ok, data = pcall(function()
			return HttpService:JSONEncode(Config)
		end)
		if ok then
			pcall(function() writefile(ConfigFile, data) end)
		end
	end
end

local function LoadConfig()
	if isfile and readfile and isfile(ConfigFile) then
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(readfile(ConfigFile))
		end)
		if ok and type(decoded) == "table" then
			for k, v in pairs(decoded) do
				if type(v) == "table" and type(Config[k]) == "table" then
					for k2, v2 in pairs(v) do Config[k][k2] = v2 end
				else
					Config[k] = v
				end
			end
		end
	end
end

LoadConfig()

--========================
-- THEMES
--========================
local Themes = {
	Light = {
		Bg1 = Color3.fromRGB(245, 247, 252),
		Bg2 = Color3.fromRGB(235, 242, 255),
		Card1 = Color3.fromRGB(255, 255, 255),
		Card2 = Color3.fromRGB(242, 245, 252),
		Text = Color3.fromRGB(18, 22, 32),
		SubText = Color3.fromRGB(90, 98, 115),
		Accent = Color3.fromRGB(80, 170, 255),
		Accent2 = Color3.fromRGB(120, 80, 255),
		Stroke = Color3.fromRGB(220, 226, 238),
		Sidebar1 = Color3.fromRGB(255, 255, 255),
		Sidebar2 = Color3.fromRGB(245, 247, 252),
	},
	Blue = {
		Bg1 = Color3.fromRGB(9, 12, 22),
		Bg2 = Color3.fromRGB(10, 18, 36),
		Card1 = Color3.fromRGB(16, 20, 36),
		Card2 = Color3.fromRGB(20, 28, 50),
		Text = Color3.fromRGB(235, 245, 255),
		SubText = Color3.fromRGB(160, 190, 215),
		Accent = Color3.fromRGB(70, 175, 255),
		Accent2 = Color3.fromRGB(120, 110, 255),
		Stroke = Color3.fromRGB(55, 58, 72),
		Sidebar1 = Color3.fromRGB(14, 18, 32),
		Sidebar2 = Color3.fromRGB(16, 22, 40),
	},
	Violet = {
		Bg1 = Color3.fromRGB(14, 10, 26),
		Bg2 = Color3.fromRGB(10, 12, 26),
		Card1 = Color3.fromRGB(22, 16, 40),
		Card2 = Color3.fromRGB(30, 20, 58),
		Text = Color3.fromRGB(245, 240, 255),
		SubText = Color3.fromRGB(190, 175, 220),
		Accent = Color3.fromRGB(190, 90, 255),
		Accent2 = Color3.fromRGB(90, 210, 255),
		Stroke = Color3.fromRGB(70, 60, 95),
		Sidebar1 = Color3.fromRGB(18, 14, 34),
		Sidebar2 = Color3.fromRGB(22, 16, 40),
	},
	Red = {
		Bg1 = Color3.fromRGB(18, 10, 14),
		Bg2 = Color3.fromRGB(12, 10, 20),
		Card1 = Color3.fromRGB(28, 16, 22),
		Card2 = Color3.fromRGB(40, 22, 30),
		Text = Color3.fromRGB(255, 245, 248),
		SubText = Color3.fromRGB(220, 175, 185),
		Accent = Color3.fromRGB(255, 85, 110),
		Accent2 = Color3.fromRGB(255, 155, 80),
		Stroke = Color3.fromRGB(85, 60, 70),
		Sidebar1 = Color3.fromRGB(24, 14, 18),
		Sidebar2 = Color3.fromRGB(30, 16, 22),
	}
}

local function T()
	return Themes[Config.Theme] or Themes.Light
end

--========================
-- THEME BUS
--========================
local ThemeBus = { bindings = {}, custom = {} }
function ThemeBus:bind(obj, prop, getter)
	table.insert(self.bindings, { obj = obj, prop = prop, getter = getter })
end
function ThemeBus:bindCustom(fn)
	table.insert(self.custom, fn)
end
function ThemeBus:apply()
	local t = T()
	for _, b in ipairs(self.bindings) do
		if b.obj and b.obj.Parent then
			b.obj[b.prop] = b.getter(t)
		end
	end
	for _, fn in ipairs(self.custom) do fn(t) end
end

--========================
-- UI HELPERS
--========================
local function Inst(className, props)
	local o = Instance.new(className)
	for k, v in pairs(props or {}) do o[k] = v end
	return o
end

local function Corner(parent, px)
	local c = Inst("UICorner", { CornerRadius = UDim.new(0, px or 12) })
	c.Parent = parent
	return c
end

local function Stroke(parent, thickness, transparency)
	local s = Inst("UIStroke", {
		Thickness = thickness or 1,
		Transparency = transparency or 0.3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	})
	s.Parent = parent
	return s
end

local function Gradient(parent, rot)
	local g = Inst("UIGradient", { Rotation = rot or 90 })
	g.Parent = parent
	return g
end

local function Pad(parent, p)
	local u = Inst("UIPadding", {
		PaddingLeft = UDim.new(0, p),
		PaddingRight = UDim.new(0, p),
		PaddingTop = UDim.new(0, p),
		PaddingBottom = UDim.new(0, p),
	})
	u.Parent = parent
	return u
end

local function List(parent, padding)
	local l = Inst("UIListLayout", {
		Padding = UDim.new(0, padding or 10),
		SortOrder = Enum.SortOrder.LayoutOrder
	})
	l.Parent = parent
	return l
end

local function Clamp(n, a, b)
	if n < a then return a end
	if n > b then return b end
	return n
end

local function KeyNameToKeyCode(name)
	local ok, kc = pcall(function() return Enum.KeyCode[name] end)
	return ok and kc or Enum.KeyCode.Unknown
end

--========================
-- Responsive window size + UIScale
--========================
local cam = workspace.CurrentCamera
local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)

local baseW, baseH = 980, 620
local maxW = math.max(720, math.floor(vp.X - 40))
local maxH = math.max(480, math.floor(vp.Y - 40))

local winW = math.min(baseW, maxW)
local winH = math.min(baseH, maxH)

local scale = math.min(vp.X / baseW, vp.Y / baseH, 1)

--========================
-- BUILD UI
--========================
local ScreenGui = Inst("ScreenGui", {
	Name = "PacLauncher",
	ResetOnSpawn = false,
	IgnoreGuiInset = true
})
ScreenGui.Parent = PlayerGui

local uiScale = Inst("UIScale", { Scale = scale })
uiScale.Parent = ScreenGui

--========================
-- DISCREET NOTIFICATIONS (silent mode)
--========================
local function Notify(title, text)
	if Config.DiscreetNotifications then return end
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = tostring(title),
			Text = tostring(text),
			Duration = 0.2,
		})
	end)
end


-- Blur
local Blur = Lighting:FindFirstChild("PacLauncherBlur")
if not Blur then
	Blur = Inst("BlurEffect", { Name = "PacLauncherBlur", Size = 0 })
	Blur.Parent = Lighting
end

local Overlay = Inst("Frame", {
	Parent = ScreenGui,
	BackgroundColor3 = Color3.new(0,0,0),
	BackgroundTransparency = 0.45,
	Size = UDim2.fromScale(1,1),
	BorderSizePixel = 0,
})

-- Glow
local Glow = Inst("Frame", {
	Parent = ScreenGui,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(winW + 26, winH + 26),
	BorderSizePixel = 0,
	BackgroundTransparency = 0.65,
})
Corner(Glow, 22)
local glowGrad = Gradient(Glow, 25)

-- Main window
local Main = Inst("Frame", {
	Parent = ScreenGui,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(winW, winH),
	BorderSizePixel = 0,
})
Corner(Main, 18)

local mainStroke = Stroke(Main, 2, 0.25)
local mainGrad = Gradient(Main, 25)

ThemeBus:bind(Main, "BackgroundColor3", function(t) return t.Bg1 end)
ThemeBus:bind(mainStroke, "Color", function(t) return t.Stroke end)
ThemeBus:bindCustom(function(t)
	mainGrad.Color = ColorSequence.new(t.Bg1, t.Bg2)
	glowGrad.Color = ColorSequence.new(t.Accent, t.Accent2)
end)

-- TopBar
local TopBar = Inst("Frame", {
	Parent = Main,
	Size = UDim2.new(1, 0, 0, 64),
	BackgroundTransparency = 1
})
Pad(TopBar, 16)

local Title = Inst("TextLabel", {
	Parent = TopBar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(0.55, 0, 1, 0),
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "PacLauncher"
})
ThemeBus:bind(Title, "TextColor3", function(t) return t.Text end)

local PingLabel = Inst("TextLabel", {
	Parent = TopBar,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -260, 0.5, 0),
	Size = UDim2.new(0, 160, 0, 26),
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Right,
	Text = "ping: -- ms"
})
ThemeBus:bind(PingLabel, "TextColor3", function(t) return t.SubText end)

local BtnStrip = Inst("Frame", {
	Parent = TopBar,
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, 0, 0.5, 0),
	Size = UDim2.new(0, 240, 0, 36),
})
local stripLayout = Inst("UIListLayout", {
	Parent = BtnStrip,
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder
})

local function MakeTopButton(text)
	local b = Inst("TextButton", {
		Parent = BtnStrip,
		Size = UDim2.new(0, 92, 0, 32),
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	})
	Corner(b, 10)
	local st = Stroke(b, 1, 0.35)
	local grad = Gradient(b, 25)

	ThemeBus:bindCustom(function(t)
		grad.Color = ColorSequence.new(t.Card2, t.Card1)
		st.Color = t.Stroke
		b.TextColor3 = t.Text
	end)

	return b
end

local HideBtn = MakeTopButton("HIDE GUI")
local BoostBtn = MakeTopButton("PING BOOST")

local CloseBtn = Inst("TextButton", {
	Parent = BtnStrip,
	Size = UDim2.new(0, 32, 0, 32),
	Text = "✕",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	AutoButtonColor = false,
	BorderSizePixel = 0,
})
Corner(CloseBtn, 10)
local closeStroke = Stroke(CloseBtn, 1, 0.35)
ThemeBus:bindCustom(function(t)
	CloseBtn.BackgroundColor3 = t.Card2
	closeStroke.Color = t.Stroke
	CloseBtn.TextColor3 = t.Text
end)

--========================
-- Unload System Function
--========================
local function SetHideGameUI(hide)
	Config.HideGameUI = hide

	if hide then
		for _, gui in ipairs(PlayerGui:GetChildren()) do
			if gui:IsA("ScreenGui") and gui ~= ScreenGui then
				_G.hiddenStateScreen = _G.hiddenStateScreen or {}
				_G.hiddenStateScreen[gui] = gui.Enabled
				gui.Enabled = false
			end
		end

		local coreTypes = {
			Enum.CoreGuiType.PlayerList,
			Enum.CoreGuiType.Chat,
			Enum.CoreGuiType.Backpack,
			Enum.CoreGuiType.Health,
			Enum.CoreGuiType.EmotesMenu,
		}
		for _, ct in ipairs(coreTypes) do
			_G.hiddenStateCore = _G.hiddenStateCore or {}
			local ok, v = pcall(function() return StarterGui:GetCoreGuiEnabled(ct) end)
			_G.hiddenStateCore[ct] = ok and v or true
			pcall(function() StarterGui:SetCoreGuiEnabled(ct, false) end)
		end
	else
		if _G.hiddenStateScreen then
			for gui, wasEnabled in pairs(_G.hiddenStateScreen) do
				if gui and gui.Parent then gui.Enabled = wasEnabled end
			end
			_G.hiddenStateScreen = {}
		end

		if _G.hiddenStateCore then
			for ct, wasEnabled in pairs(_G.hiddenStateCore) do
				pcall(function() StarterGui:SetCoreGuiEnabled(ct, wasEnabled) end)
			end
			_G.hiddenStateCore = {}
		end
	end

	SaveConfig()
end

CloseBtn.MouseButton1Click:Connect(function()
	-- UNLOAD TOTAL SCRIPT
	Config.PingBoost = false
	Config.PingBoostPlus = false
	SetHideGameUI(false)
	pcall(function() settings().Network.IncomingReplicationLag = 0.01 end)
	pcall(function() settings().Rendering.QualityLevel = Enum.SavedQualitySetting.Automatic end)

	for _, conn in ipairs(Connections) do
		if conn and conn.Disconnect then
			pcall(function() conn:Disconnect() end)
		end
	end
	table.clear(Connections)

	ScreenGui:Destroy()
	if Overlay and Overlay.Parent then Overlay:Destroy() end
	if Blur and Blur.Parent then Blur.Size = 0 end
end)

-- Sidebar
local Sidebar = Inst("Frame", {
	Parent = Main,
	Position = UDim2.new(0, 0, 0, 64),
	Size = UDim2.new(0, 280, 1, -64),
	BorderSizePixel = 0,
})
Corner(Sidebar, 18)
local sideStroke = Stroke(Sidebar, 1, 0.35)
local sideGrad = Gradient(Sidebar, 90)
ThemeBus:bind(Sidebar, "BackgroundColor3", function(t) return t.Sidebar1 end)
ThemeBus:bind(sideStroke, "Color", function(t) return t.Stroke end)
ThemeBus:bindCustom(function(t)
	sideGrad.Color = ColorSequence.new(t.Sidebar1, t.Sidebar2)
end)

local SideTop = Inst("Frame", {
	Parent = Sidebar,
	BackgroundTransparency = 1,
	Size = UDim2.new(1, 0, 0, 110),
})
Pad(SideTop, 16)

local Avatar = Inst("ImageLabel", {
	Parent = SideTop,
	BackgroundTransparency = 1,
	Size = UDim2.fromOffset(64, 64),
	Position = UDim2.new(0, 0, 0, 8)
})
Corner(Avatar, 16)

task.spawn(function()
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if ok then Avatar.Image = content end
end)

local NameLabel = Inst("TextLabel", {
	Parent = SideTop,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 78, 0, 16),
	Size = UDim2.new(1, -78, 0, 24),
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = Player.Name
})
ThemeBus:bind(NameLabel, "TextColor3", function(t) return t.Text end)

local SubLabel = Inst("TextLabel", {
	Parent = SideTop,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 78, 0, 44),
	Size = UDim2.new(1, -78, 0, 20),
	Font = Enum.Font.Gotham,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	Text = "v4 + AP"
})
ThemeBus:bind(SubLabel, "TextColor3", function(t) return t.SubText end)

local NavWrap = Inst("Frame", {
	Parent = Sidebar,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 16, 0, 120),
	Size = UDim2.new(1, -32, 1, -136),
})
List(NavWrap, 10)

-- Content
local Content = Inst("Frame", {
	Parent = Main,
	BackgroundTransparency = 1,
	Position = UDim2.new(0, 280, 0, 64),
	Size = UDim2.new(1, -280, 1, -64),
})
Pad(Content, 16)

-- Pages
local Pages = {}
local function CreatePage(name)
	local page = Inst("ScrollingFrame", {
		Parent = Content,
		Name = name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Visible = false,
	})
	local layout = List(page, 14)
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)
	Pages[name] = page
	return page
end

local PageMain = CreatePage("Main")
local PageBoost = CreatePage("Boost")
local PageSettings = CreatePage("Settings")

local CurrentPage = "Main"
PageMain.Visible = true

-- NavButton
local function CreateNavButton(text, target)
	local btn = Inst("TextButton", {
		Parent = NavWrap,
		Size = UDim2.new(1, 0, 0, 44),
		Text = text,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	})
	Corner(btn, 14)
	local st = Stroke(btn, 1, 0.35)

	local hovering = false
	local function repaint()
		local t = T()
		local selected = (CurrentPage == target)
		btn.BackgroundColor3 = selected and t.Accent or (hovering and t.Card1 or t.Card2)
		btn.TextColor3 = selected and Color3.new(1,1,1) or t.Text
		st.Color = t.Stroke
	end

	btn.MouseEnter:Connect(function() hovering = true; repaint() end)
	btn.MouseLeave:Connect(function() hovering = false; repaint() end)
	btn.MouseButton1Click:Connect(function()
		if CurrentPage == target then return end
		Pages[CurrentPage].Visible = false
		CurrentPage = target
		Pages[CurrentPage].Visible = true
		ThemeBus:apply()
		repaint()
	end)

	ThemeBus:bindCustom(repaint)
	repaint()
	return btn
end

CreateNavButton("🏠 Main", "Main")
CreateNavButton("🚀 Boost", "Boost")
CreateNavButton("⚙️ Settings", "Settings")

--========================
-- Card (AUTO HEIGHT)
--========================
local function CreateCardAuto(parent, titleText)
	local card = Inst("Frame", {
		Parent = parent,
		Size = UDim2.new(1, 0, 0, 160),
		BorderSizePixel = 0,
	})
	Corner(card, 16)
	local st = Stroke(card, 1, 0.35)
	local grad = Gradient(card, 90)

	ThemeBus:bind(card, "BackgroundColor3", function(t) return t.Card1 end)
	ThemeBus:bind(st, "Color", function(t) return t.Stroke end)
	ThemeBus:bindCustom(function(t)
		grad.Color = ColorSequence.new(t.Card1, t.Card2)
	end)

	local title = Inst("TextLabel", {
		Parent = card,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -24, 0, 40),
		Position = UDim2.new(0, 12, 0, 10),
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = titleText,
	})
	ThemeBus:bind(title, "TextColor3", function(t) return t.Text end)

	local body = Inst("Frame", {
		Parent = card,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -24, 0, 10),
		Position = UDim2.new(0, 12, 0, 50),
	})
	local layout = List(body, 10)

	local function updateHeight()
		local h = 50 + layout.AbsoluteContentSize.Y + 14
		card.Size = UDim2.new(1, 0, 0, math.max(110, h))
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateHeight)
	task.defer(updateHeight)

	return card, body
end

--========================
-- Rows
--========================
local captureConn = nil

local function CreateToggleRow(parent, label, get, set)
	local row = Inst("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1 })

	local txt = Inst("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -220, 1, 0),
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = label
	})
	ThemeBus:bind(txt, "TextColor3", function(t) return t.SubText end)

	local sw = Inst("TextButton", {
		Parent = row,
		Size = UDim2.new(0, 64, 0, 26),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
	})
	Corner(sw, 999)

	local dot = Inst("Frame", {
		Parent = sw,
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(0, 3, 0.5, -10),
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.new(1,1,1),
	})
	Corner(dot, 999)

	local state = get()

	local function paint(active)
		local t = T()
		sw.BackgroundColor3 = active and t.Accent or t.Stroke
		dot:TweenPosition(
			active and UDim2.new(1, -23, 0.5, -10) or UDim2.new(0, 3, 0.5, -10),
			"Out", "Back", 0.18, true
		)
	end

	local function setUI(active)
		state = active
		paint(state)
	end

	sw.MouseButton1Click:Connect(function()
		state = not state
		set(state)
		paint(state)
		SaveConfig()
	end)

	ThemeBus:bindCustom(function() paint(state) end)
	paint(state)

	return setUI
end

local function CreateHotkeyRow(parent, label, getKeyName, setKeyName)
	local row = Inst("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 })

	local txt = Inst("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -220, 1, 0),
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = label
	})
	ThemeBus:bind(txt, "TextColor3", function(t) return t.SubText end)

	local btn = Inst("TextButton", {
		Parent = row,
		Size = UDim2.new(0, 200, 0, 34),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Text = getKeyName(),
		Font = Enum.Font.Code,
		TextSize = 14,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	})
	Corner(btn, 12)
	local st = Stroke(btn, 1, 0.35)

	local function repaint()
		local t = T()
		btn.BackgroundColor3 = t.Card2
		btn.TextColor3 = t.Text
		st.Color = t.Stroke
	end

	local function setUI(text)
		btn.Text = text
	end

	btn.MouseButton1Click:Connect(function()
		btn.Text = "Press a key..."
		if captureConn then captureConn:Disconnect() end
		captureConn = UIS.InputBegan:Connect(function(input, gp)
			if gp then return end
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			local k = input.KeyCode
			if k == Enum.KeyCode.Unknown then return end

			if k == Enum.KeyCode.Escape then
				btn.Text = getKeyName()
				captureConn:Disconnect()
				captureConn = nil
				return
			end

			setKeyName(k.Name)
			btn.Text = k.Name
			SaveConfig()

			captureConn:Disconnect()
			captureConn = nil
		end)
	end)

	ThemeBus:bindCustom(repaint)
	repaint()

	return setUI
end

local function CreateNumberRow(parent, label, getValue, setValue, minV, maxV)
	local row = Inst("Frame", { Parent = parent, Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1 })

	local txt = Inst("TextLabel", {
		Parent = row,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -220, 1, 0),
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = label
	})
	ThemeBus:bind(txt, "TextColor3", function(t) return t.SubText end)

	local box = Inst("TextBox", {
		Parent = row,
		Size = UDim2.new(0, 200, 0, 34),
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Text = tostring(getValue()),
		ClearTextOnFocus = false,
		Font = Enum.Font.Code,
		TextSize = 14,
		BorderSizePixel = 0,
	})
	Corner(box, 12)
	local st = Stroke(box, 1, 0.35)

	local function repaint()
		local t = T()
		box.BackgroundColor3 = t.Card2
		box.TextColor3 = t.Text
		st.Color = t.Stroke
		box.PlaceholderColor3 = t.SubText
	end

	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if not n then
			box.Text = tostring(getValue())
			return
		end
		n = Clamp(math.floor(n + 0.5), minV or 1, maxV or 1000)
		setValue(n)
		box.Text = tostring(n)
		SaveConfig()
	end)

	ThemeBus:bindCustom(repaint)
	repaint()

	return function(v) box.Text = tostring(v) end
end


--========================
-- Apply states (single source of truth)
--========================
local function ApplyLauncherVisibility()
	local show = not Config.HideLauncher
	ScreenGui.Enabled = show
	Overlay.Visible = show
	Glow.Visible = show

	if Blur and Blur.Parent then
		Blur.Size = (Config.BlurBackground and show) and 14 or 0
	end
end

local function ApplyPingBoost()
	if Config.PingBoost then
		pcall(function() settings().Network.IncomingReplicationLag = 0 end)
	else
		pcall(function() settings().Network.IncomingReplicationLag = 0.01 end)
	end
	PingLabel.Visible = Config.PingHud
	SaveConfig()
end

local function ApplyPingBoostPlus()
	if Config.PingBoostPlus then
		pcall(function() settings().Network.IncomingReplicationLag = -100 end) -- Extrême network boost
		local ok, gs = pcall(function() return UserSettings().GameSettings end)
		if ok and gs then pcall(function() gs.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1 end) end
	else
		local ok, gs = pcall(function() return UserSettings().GameSettings end)
		if ok and gs then pcall(function() gs.SavedQualityLevel = Enum.SavedQualitySetting.Automatic end) end
	end
	SaveConfig()
end

--========================
-- MAIN PAGE
--========================
local uiControlsSetters = {}

do
	local _, bodyCps = CreateCardAuto(PageMain, "CPS")
	CreateNumberRow(bodyCps, "CPS value", function() return Config.CPS end, function(v) Config.CPS = v end, 1, 1000)

	local _, bodyControls = CreateCardAuto(PageMain, "Controls")
	
	uiControlsSetters.setMacro = CreateToggleRow(bodyControls, "Macro enabled", function() return Config.MacroEnabled end, function(v) Config.MacroEnabled = v end)
	CreateHotkeyRow(bodyControls, "Macro key", function() return Config.Binds.Macro end, function(k) Config.Binds.Macro = k end)

	uiControlsSetters.setTrigger = CreateToggleRow(bodyControls, "Trigger enabled", function() return Config.TriggerEnabled end, function(v) Config.TriggerEnabled = v end)
	CreateHotkeyRow(bodyControls, "Trigger key", function() return Config.Binds.Trigger end, function(k) Config.Binds.Trigger = k end)

	-- AP Controls
	uiControlsSetters.setAp = CreateToggleRow(bodyControls, "AP enabled", function() return Config.ApEnabled end, function(v) Config.ApEnabled = v end)
	CreateHotkeyRow(bodyControls, "AP key", function() return Config.Binds.Ap end, function(k) Config.Binds.Ap = k end)
end

--========================
-- BOOST TAB (renamed network)
--========================
local uiSetters = {
	setHideLauncher = nil,
	setPingBoost = nil,
	setPingBoostPlus = nil,
}

do
	local _, bodyBoost = CreateCardAuto(PageBoost, "Boost")
	
	uiSetters.setPingBoost = CreateToggleRow(bodyBoost, "Ping Boost", function() return Config.PingBoost end, function(v)
		Config.PingBoost = v
		ApplyPingBoost()
	end)

	uiSetters.setPingBoostPlus = CreateToggleRow(bodyBoost, "Ping Boost +", function() return Config.PingBoostPlus end, function(v)
		Config.PingBoostPlus = v
		ApplyPingBoostPlus()
	end)

	local note = Inst("TextLabel", {
		Parent = bodyBoost,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 56),
		Font = Enum.Font.Gotham,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Ping Boost + : Réduit drastiquement la latence réseau via une interpolation négative (-100) pour une priorité absolue."
	})
	ThemeBus:bind(note, "TextColor3", function(t) return t.SubText end)
end

--========================
-- SETTINGS TAB
--========================
local settersSettings = { setAppToggle = nil }

do
	local _, bodyUi = CreateCardAuto(PageSettings, "UI")
	CreateToggleRow(bodyUi, "Hide launcher", function() return Config.HideLauncher end, function(v)
		Config.HideLauncher = v
		ApplyLauncherVisibility()
		if uiSetters.setHideLauncher then uiSetters.setHideLauncher(v) end
	end)

	CreateToggleRow(bodyUi, "Hide game UI", function() return Config.HideGameUI end, function(v)
		SetHideGameUI(v)
	end)

	CreateToggleRow(bodyUi, "Blur background", function() return Config.BlurBackground end, function(v)
		Config.BlurBackground = v
		ApplyLauncherVisibility()
		SaveConfig()
	end)

	CreateToggleRow(bodyUi, "Discreet notifications", function() return Config.DiscreetNotifications end, function(v)
		Config.DiscreetNotifications = v
		SaveConfig()
	end)

	local _, bodyTheme = CreateCardAuto(PageSettings, "Themes")
	local function ThemeButton(name)
		local btn = Inst("TextButton", {
			Parent = bodyTheme,
			Size = UDim2.new(1, 0, 0, 42),
			Text = "Theme: " .. name,
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			AutoButtonColor = false,
			BorderSizePixel = 0,
		})
		Corner(btn, 12)
		local st = Stroke(btn, 1, 0.35)

		local function repaint()
			local t = T()
			local selected = (Config.Theme == name)
			btn.BackgroundColor3 = selected and t.Accent or t.Card2
			btn.TextColor3 = selected and Color3.new(1,1,1) or t.Text
			st.Color = t.Stroke
		end

		btn.MouseButton1Click:Connect(function()
			Config.Theme = name
			ThemeBus:apply()
			SaveConfig()
		end)

		ThemeBus:bindCustom(repaint)
		repaint()
	end

	ThemeButton("Light")
	ThemeButton("Blue")
	ThemeButton("Violet")
	ThemeButton("Red")

	-- App Toggle key
	local _, bodyKey = CreateCardAuto(PageSettings, "App toggle key (CTRL by default)")
	settersSettings.setAppToggle = CreateHotkeyRow(bodyKey, "Toggle launcher key", function()
		return Config.Binds.AppToggle
	end, function(k)
		Config.Binds.AppToggle = k
	end)
end

--========================
-- TOP BUTTONS (Hide GUI + Ping Boost)
--========================
HideBtn.MouseButton1Click:Connect(function()
	Config.HideLauncher = not Config.HideLauncher
	ApplyLauncherVisibility()
	SaveConfig()
	if uiSetters.setHideLauncher then uiSetters.setHideLauncher(Config.HideLauncher) end
end)

BoostBtn.MouseButton1Click:Connect(function()
	Config.PingBoost = not Config.PingBoost
	ApplyPingBoost()
	if uiSetters.setPingBoost then uiSetters.setPingBoost(Config.PingBoost) end
end)

--========================
-- DRAG WINDOW
--========================
do
	local dragging = false
	local dragStart, startPos

	table.insert(Connections, TopBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = Main.Position
		end
	end))

	table.insert(Connections, TopBar.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			Glow.Position = Main.Position
		end
	end))

	table.insert(Connections, UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end))
end

--========================
-- BACKGROUND VARIABLES
--========================
local LAST_TRIGGER = 0
local TRIGGER_COOLDOWN = 0.002
local TRIGGERED = false
local MACRO_KEY = Enum.KeyCode.F

local AP_TARGETED = false
local AP_REACTION_BUFFER = 0.19
local AP_MIN_SPEED = 5

--========================
-- HOTKEY SYSTEM (AppToggle, Macro, Triggerbot, AP)
--========================
table.insert(Connections, UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	local kcToggle = KeyNameToKeyCode(Config.Binds.AppToggle)
	local kcMacro = KeyNameToKeyCode(Config.Binds.Macro)
	local kcTrigger = KeyNameToKeyCode(Config.Binds.Trigger)
	local kcAp = KeyNameToKeyCode(Config.Binds.Ap)

	-- 1. App Toggle
	local okToggle = (input.KeyCode == kcToggle)
	if not okToggle and (Config.Binds.AppToggle == "LeftControl" or Config.Binds.AppToggle == "RightControl") then
		okToggle = (input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl)
	end

	if okToggle then
		Config.HideLauncher = not Config.HideLauncher
		ApplyLauncherVisibility()
		SaveConfig()
		if uiSetters.setHideLauncher then uiSetters.setHideLauncher(Config.HideLauncher) end
		return
	end

	-- 2. Macro Toggle
	if input.KeyCode == kcMacro then
		Config.MacroEnabled = not Config.MacroEnabled
		if Config.MacroEnabled then
			Config.TriggerEnabled = false
			Config.ApEnabled = false
			TRIGGERED = false
			AP_TARGETED = false
		end
		
		uiControlsSetters.setMacro(Config.MacroEnabled)
		uiControlsSetters.setTrigger(Config.TriggerEnabled)
		uiControlsSetters.setAp(Config.ApEnabled)
		
		SaveConfig()
		Notify("Macro", Config.MacroEnabled and "ACTIVÉ" or "DÉSACTIVÉ")
		return
	end

	-- 3. Triggerbot Toggle
	if input.KeyCode == kcTrigger then
		Config.TriggerEnabled = not Config.TriggerEnabled
		TRIGGERED = false
		if Config.TriggerEnabled then
			Config.MacroEnabled = false
			Config.ApEnabled = false
			AP_TARGETED = false
		end
		
		uiControlsSetters.setMacro(Config.MacroEnabled)
		uiControlsSetters.setTrigger(Config.TriggerEnabled)
		uiControlsSetters.setAp(Config.ApEnabled)

		SaveConfig()
		Notify("Triggerbot", Config.TriggerEnabled and "ACTIVÉ" or "DÉSACTIVÉ")
		return
	end
	
	-- 4. AP Toggle
	if input.KeyCode == kcAp then
		Config.ApEnabled = not Config.ApEnabled
		AP_TARGETED = false
		if Config.ApEnabled then
			Config.MacroEnabled = false
			Config.TriggerEnabled = false
			TRIGGERED = false
		end
		
		uiControlsSetters.setMacro(Config.MacroEnabled)
		uiControlsSetters.setTrigger(Config.TriggerEnabled)
		uiControlsSetters.setAp(Config.ApEnabled)

		SaveConfig()
		Notify("AP", Config.ApEnabled and "ACTIVÉ" or "DÉSACTIVÉ")
		return
	end
end))

--========================
-- BACKGROUND LOGIC: MACRO & TRIGGERBOT & AP
--========================
local function SendF()
	VIM:SendKeyEvent(true, MACRO_KEY, false, game)
	VIM:SendKeyEvent(false, MACRO_KEY, false, game)
end

local function SendFAp()
	-- Variante pour AP avec le léger delay de ta logique old script
	VIM:SendKeyEvent(true, MACRO_KEY, false, game)
	task.wait(0.005)
	VIM:SendKeyEvent(false, MACRO_KEY, false, game)
end

local function GetBalls()
	local folder = workspace:FindFirstChild("Balls")
	if not folder then return {} end

	local t = {}
	for _, b in ipairs(folder:GetChildren()) do
		if b:GetAttribute("realBall") then
			t[#t + 1] = b
		end
	end
	return t
end

local function GetSingleBall()
	for _, v in ipairs(workspace:GetChildren()) do
		if v.Name == "Ball" or v:GetAttribute("target") then return v end
	end
	local bFolder = workspace:FindFirstChild("Balls")
	if bFolder then return bFolder:FindFirstChildOfClass("Part") or bFolder:FindFirstChildOfClass("MeshPart") end
	return nil
end

-- Boucle Macro (Spam Vitesse pure avec Accumulateur Temporel)
local macroAcc = 0
table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
	if not Config.MacroEnabled then 
		macroAcc = 0
		return 
	end

	macroAcc = macroAcc + dt
	local interval = 1 / (Config.CPS or 150)
	
	if macroAcc >= interval then
		local clicksThisFrame = math.floor(macroAcc / interval)
		clicksThisFrame = math.min(clicksThisFrame, 10) 

		for i = 1, clicksThisFrame do
			SendF()
		end

		macroAcc = macroAcc - (clicksThisFrame * interval)
	end
end))

-- Boucle Triggerbot (Précision PreSimulation)
table.insert(Connections, RunService.PreSimulation:Connect(function()
	if not Config.TriggerEnabled then return end
	if TRIGGERED then return end
	if (os.clock() - LAST_TRIGGER) < TRIGGER_COOLDOWN then return end

	for _, ball in ipairs(GetBalls()) do
		if ball:GetAttribute("target") == tostring(Player.Name) then
			TRIGGERED = true
			LAST_TRIGGER = os.clock()

			-- Appui F UNIQUE, précis
			SendF()

			-- Reset quand la cible change
			ball:GetAttributeChangedSignal("target"):Once(function()
				TRIGGERED = false
			end)

			break
		end
	end
end))

-- Boucle AP (OLD SCRIPT BLB INTEGRATION)
table.insert(Connections, RunService.PreSimulation:Connect(function()
	if not Config.ApEnabled then return end

	local ball = GetSingleBall()
	if not ball then return end

	-- Vérification Target (Base V5)
	local target = ball:GetAttribute("target") or ball:GetAttribute("Target")
	if tostring(target) ~= Player.Name then
		AP_TARGETED = false
		return
	end

	if AP_TARGETED then return end

	local char = Player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- LOGIQUE MATHÉMATIQUE OLD_SCRIPT
	local ballPos = ball.Position
	local playerPos = hrp.Position
	local distance = (ballPos - playerPos).Magnitude
	
	-- On récupère la vélocité (soit Assembly, soit via 'zoomies' comme dans ton vieux script)
	local velocityVec = ball.AssemblyLinearVelocity
	local zoomies = ball:FindFirstChild("zoomies")
	if zoomies then velocityVec = zoomies.VectorVelocity end
	
	local speed = velocityVec.Magnitude
	if speed < AP_MIN_SPEED then return end

	-- 1. Calcul du Ping sécurisé
	local pingValue = 0
	pcall(function() pingValue = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000 end)
	
	-- 2. Reach Time (Temps avant impact)
	-- Formule : Temps = Distance / Vitesse - (Ping + Buffer)
	local reachTime = distance / speed
	
	-- 3. Seuil de Distance Adaptatif (Inspiré de Speed_Threshold du vieux script)
	-- Plus la vitesse est haute, plus le seuil de distance de sécurité augmente
	local speedThreshold = math.min(speed / 100, 40)
	local ballDistanceThreshold = 17 - math.min(distance / 1000, 15) + speedThreshold

	-- 4. CONDITION DE DÉCLENCHEMENT (Fusionnée)
	-- On parre si le temps d'arrivée est inférieur à notre réaction + ping
	-- OU si la balle entre dans le seuil de distance critique calculé
	local triggerThreshold = pingValue + AP_REACTION_BUFFER

	if reachTime <= triggerThreshold or distance <= ballDistanceThreshold then
		-- Anti-Curve : On vérifie que la balle se dirige bien vers nous (Dot Product de old_script)
		local ballDirection = velocityVec.Unit
		local playerDirection = (playerPos - ballPos).Unit
		local dot = ballDirection:Dot(playerDirection)

		-- Si la balle nous fonce dessus (dot > 0) ou si elle est ultra proche
		if dot > 0.1 or distance < 10 then
			AP_TARGETED = true
			SendFAp()
			
			-- Reset quand la cible change
			local signal
			signal = ball:GetAttributeChangedSignal("target"):Connect(function()
				AP_TARGETED = false
				if signal then signal:Disconnect() end
			end)
		end
	end
end))

--========================
-- Ping read
--========================
local function readPingMs()
	local ok, pingStr = pcall(function()
		local item = Stats.Network.ServerStatsItem["Data Ping"]
		return item and item:GetValueString() or nil
	end)
	if not ok or not pingStr then return nil end
	return tonumber(string.match(pingStr, "([%d%.]+)"))
end

local acc = 0
table.insert(Connections, RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.25 then return end
	acc = 0

	if Config.PingHud then
		local p = readPingMs()
		if p then
			PingLabel.Text = ("ping: %d ms"):format(math.floor(p + 0.5))
		else
			PingLabel.Text = "ping: -- ms"
		end
	end
end))

--========================
-- INIT
--========================
ThemeBus:apply()

if Config.HideGameUI then
	SetHideGameUI(true)
end

ApplyPingBoost()
ApplyPingBoostPlus()
ApplyLauncherVisibility()

SaveConfig()
print("PacLauncher V5 loaded")
