--[[
    Nimbus UI
    a frosted glass ui library for roblox, made by me

    load it like this:
    local Nimbus = loadstring(game:HttpGet("https://raw.githubusercontent.com/4er2/Nimbus/main/source.lua"))()

    check the readme for how to use everything
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- if you run the script twice it kills the old one first so you dont get 2 menus
local genv = (type(getgenv) == "function" and getgenv()) or _G
if genv.__Nimbus then
	pcall(function()
		genv.__Nimbus:Destroy()
	end)
end

local Nimbus = {
	Version = "1.0.0",
	Flags = {},
	Elements = {},
	Keybind = "RightControl",
	Folder = "Nimbus",
	Windows = {},
	Destroyed = false,
	_connections = {},
	_picking = false,
	_pickedAt = 0,
}
genv.__Nimbus = Nimbus

--// themes

local Shared = {
	Stroke = Color3.fromRGB(255, 255, 255),
	StrokeTransparency = 0.9,
	BackgroundTransparency = 0.1,
	SurfaceTransparency = 0.35,
	ElementTransparency = 0.4,
	Success = Color3.fromRGB(74, 222, 128),
	Warning = Color3.fromRGB(250, 204, 21),
	Error = Color3.fromRGB(248, 113, 113),
}

local function themeOf(t)
	for k, v in pairs(Shared) do
		if t[k] == nil then
			t[k] = v
		end
	end
	return t
end

Nimbus.Themes = {
	Frost = themeOf({
		Background = Color3.fromRGB(13, 17, 23),
		Surface = Color3.fromRGB(22, 27, 34),
		Element = Color3.fromRGB(31, 42, 55),
		ElementHover = Color3.fromRGB(41, 55, 71),
		Track = Color3.fromRGB(50, 63, 80),
		Accent = Color3.fromRGB(56, 189, 248),
		Text = Color3.fromRGB(230, 237, 243),
		SubText = Color3.fromRGB(139, 148, 158),
	}),
	Midnight = themeOf({
		Background = Color3.fromRGB(10, 10, 16),
		Surface = Color3.fromRGB(18, 18, 28),
		Element = Color3.fromRGB(28, 28, 42),
		ElementHover = Color3.fromRGB(38, 38, 56),
		Track = Color3.fromRGB(52, 52, 72),
		Accent = Color3.fromRGB(129, 140, 248),
		Text = Color3.fromRGB(235, 235, 245),
		SubText = Color3.fromRGB(140, 140, 165),
	}),
	Mint = themeOf({
		Background = Color3.fromRGB(12, 16, 15),
		Surface = Color3.fromRGB(20, 26, 24),
		Element = Color3.fromRGB(30, 40, 37),
		ElementHover = Color3.fromRGB(40, 54, 50),
		Track = Color3.fromRGB(52, 68, 63),
		Accent = Color3.fromRGB(61, 220, 151),
		Text = Color3.fromRGB(232, 240, 236),
		SubText = Color3.fromRGB(138, 156, 149),
	}),
	Ember = themeOf({
		Background = Color3.fromRGB(18, 13, 14),
		Surface = Color3.fromRGB(28, 20, 22),
		Element = Color3.fromRGB(42, 30, 33),
		ElementHover = Color3.fromRGB(56, 40, 44),
		Track = Color3.fromRGB(72, 52, 57),
		Accent = Color3.fromRGB(255, 107, 74),
		Text = Color3.fromRGB(245, 233, 236),
		SubText = Color3.fromRGB(166, 145, 150),
	}),
}
Nimbus.ThemeOrder = { "Frost", "Midnight", "Mint", "Ember" }

local function copy(t)
	local n = {}
	for k, v in pairs(t) do
		n[k] = v
	end
	return n
end

Nimbus.Theme = copy(Nimbus.Themes.Frost)
Nimbus.ThemeName = "Frost"

--// little helpers

local FONT = Enum.Font.Gotham
local FONT_MED = Enum.Font.GothamMedium
local FONT_BOLD = Enum.Font.GothamBold

local Themed = {}
local ThemeHooks = {}

local function create(class, props)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function themed(inst, map)
	for prop, key in pairs(map) do
		inst[prop] = Nimbus.Theme[key]
	end
	table.insert(Themed, { inst, map })
	return inst
end

local function onTheme(fn)
	table.insert(ThemeHooks, fn)
	fn()
end

local function tween(inst, props, t, style, dir)
	local tw = TweenService:Create(inst, TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function corner(parent, r)
	return create("UICorner", { CornerRadius = (r == "full") and UDim.new(1, 0) or UDim.new(0, r or 6), Parent = parent })
end

local function stroke(parent)
	local s = create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1, Parent = parent })
	themed(s, { Color = "Stroke", Transparency = "StrokeTransparency" })
	return s
end

local function padding(parent, top, right, bottom, left)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		Parent = parent,
	})
end

local function list(parent, pad, dir)
	return create("UIListLayout", {
		Padding = UDim.new(0, pad or 0),
		FillDirection = dir or Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

local function label(props, colorKey)
	local base = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = FONT,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = "",
	}
	for k, v in pairs(props) do
		base[k] = v
	end
	local l = create("TextLabel", base)
	if colorKey ~= false then
		themed(l, { TextColor3 = colorKey or "Text" })
	end
	return l
end

local function isClick(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch
end

local function typing()
	return UserInputService:GetFocusedTextBox() ~= nil
end

function Nimbus:_connect(signal, fn)
	local c = signal:Connect(fn)
	table.insert(self._connections, c)
	return c
end

local function fire(el, ...)
	for _, fn in ipairs(el._cb) do
		task.spawn(fn, ...)
	end
end

local function register(el)
	if el.Flag then
		Nimbus.Flags[el.Flag] = el:Get()
		Nimbus.Elements[el.Flag] = el
	end
end

local function setFlag(el)
	if el.Flag then
		Nimbus.Flags[el.Flag] = el:Get()
	end
end

-- drags a frame around by a handle (used for the window + mobile button)
local function draggable(handle, target)
	local dragging, startInput, startPos
	handle.InputBegan:Connect(function(input)
		if isClick(input) then
			dragging = true
			startInput = input.Position
			startPos = target.Position
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					c:Disconnect()
				end
			end)
		end
	end)
	Nimbus:_connect(UserInputService.InputChanged, function(input)
		if dragging and isMove(input) then
			local d = input.Position - startInput
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

-- for sliders and the color picker, calls onMove with the mouse position while held
local function holdDrag(handle, onMove)
	local active = false
	handle.InputBegan:Connect(function(input)
		if isClick(input) then
			active = true
			onMove(input.Position)
			local c
			c = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					active = false
					c:Disconnect()
				end
			end)
		end
	end)
	Nimbus:_connect(UserInputService.InputChanged, function(input)
		if active and isMove(input) then
			onMove(input.Position)
		end
	end)
end

local function ripple(button, x, y)
	local r = create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x - button.AbsolutePosition.X, y - button.AbsolutePosition.Y),
		Size = UDim2.fromOffset(0, 0),
		ZIndex = 5,
		Parent = button,
	})
	corner(r, "full")
	local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
	tween(r, { Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1 }, 0.55)
	task.delay(0.6, function()
		r:Destroy()
	end)
end

local ShortKeys = {
	LeftShift = "LShift", RightShift = "RShift", LeftControl = "LCtrl", RightControl = "RCtrl",
	LeftAlt = "LAlt", RightAlt = "RAlt", MouseButton2 = "MB2", MouseButton3 = "MB3",
}

local function keyName(k)
	if k == nil then
		return nil
	end
	if typeof(k) == "EnumItem" then
		return k.Name
	end
	return tostring(k)
end

--// the screengui

local function getHolder()
	local ok, h = pcall(function()
		return gethui()
	end)
	if ok and typeof(h) == "Instance" then
		return h
	end
	local ok2 = pcall(function()
		local f = Instance.new("Folder")
		f.Parent = CoreGui
		f:Destroy()
	end)
	if ok2 then
		return CoreGui
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local ScreenGui = create("ScreenGui", {
	Name = "Nimbus_" .. HttpService:GenerateGUID(false):sub(1, 8),
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999,
})
pcall(function()
	if syn and syn.protect_gui then
		syn.protect_gui(ScreenGui)
	end
end)
ScreenGui.Parent = getHolder()
Nimbus.ScreenGui = ScreenGui

local Blur = create("BlurEffect", { Name = "NimbusBlur", Size = 0, Parent = Lighting })
Nimbus.BlurEnabled = true

--// theme switching

function Nimbus:SetTheme(t)
	if type(t) == "string" then
		local preset = self.Themes[t]
		if not preset then
			return
		end
		self.Theme = copy(preset)
		self.ThemeName = t
	elseif type(t) == "table" then
		for k, v in pairs(t) do
			self.Theme[k] = v
		end
	end
	for _, e in ipairs(Themed) do
		for prop, key in pairs(e[2]) do
			pcall(function()
				e[1][prop] = self.Theme[key]
			end)
		end
	end
	for _, fn in ipairs(ThemeHooks) do
		pcall(fn)
	end
end

--// notifications

local NotifyHolder = create("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16),
	Size = UDim2.new(0, 300, 1, -32),
	ZIndex = 50,
	Parent = ScreenGui,
})
do
	local l = list(NotifyHolder, 8)
	l.VerticalAlignment = Enum.VerticalAlignment.Bottom
	l.HorizontalAlignment = Enum.HorizontalAlignment.Right
end

local notifyCount = 0
function Nimbus:Notify(o, content, duration)
	if type(o) ~= "table" then
		o = { Title = tostring(o), Content = content, Duration = duration }
	end
	local th = self.Theme
	local color = th[o.Type or ""] or th.Accent
	local dur = o.Duration or 4
	local W = 300
	local contentH = 0
	if o.Content and o.Content ~= "" then
		contentH = TextService:GetTextSize(tostring(o.Content), 12, FONT, Vector2.new(W - 40, 1000)).Y
	end
	local H = 40 + (contentH > 0 and contentH + 4 or 0)

	notifyCount += 1
	local Wrap = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(W, 0), LayoutOrder = notifyCount, Parent = NotifyHolder })
	local Card = create("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(W + 30, 0),
		Size = UDim2.fromOffset(W, H),
		Parent = Wrap,
	})
	themed(Card, { BackgroundColor3 = "Background" })
	Card.BackgroundTransparency = 0.05
	corner(Card, 10)
	stroke(Card)
	local Bar = create("Frame", { BorderSizePixel = 0, BackgroundColor3 = color, Position = UDim2.fromOffset(10, 12), Size = UDim2.new(0, 3, 1, -24), Parent = Card })
	corner(Bar, "full")
	label({ Text = o.Title or "Nimbus", Font = FONT_BOLD, TextSize = 13, Position = UDim2.fromOffset(22, 11), Size = UDim2.new(1, -34, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, Parent = Card })
	if contentH > 0 then
		label({ Text = tostring(o.Content), TextSize = 12, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(22, 30), Size = UDim2.new(1, -36, 0, contentH), Parent = Card }, "SubText")
	end
	local Progress = create("Frame", { BorderSizePixel = 0, BackgroundColor3 = color, BackgroundTransparency = 0.4, Position = UDim2.new(0, 22, 1, -5), Size = UDim2.new(1, -36, 0, 2), Parent = Card })
	corner(Progress, "full")

	tween(Wrap, { Size = UDim2.fromOffset(W, H) }, 0.25)
	tween(Card, { Position = UDim2.fromOffset(0, 0) }, 0.45)
	tween(Progress, { Size = UDim2.new(0, 0, 0, 2) }, dur, Enum.EasingStyle.Linear)

	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		tween(Card, { Position = UDim2.fromOffset(W + 30, 0) }, 0.3)
		task.wait(0.25)
		tween(Wrap, { Size = UDim2.fromOffset(W, 0) }, 0.2)
		task.wait(0.22)
		Wrap:Destroy()
	end
	Card.MouseButton1Click:Connect(function()
		task.spawn(close)
	end)
	task.delay(dur, close)
end

--// elements (these get put on sections)

local Elements = {}

-- makes the rounded row every element sits in
local function newRow(section, o)
	local hasDesc = o.Desc ~= nil and o.Desc ~= ""
	local top = o.Top or hasDesc
	local h = o.Height or (hasDesc and 46 or 34)
	local Row = create("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, h),
		LayoutOrder = section:_next(),
		Parent = section.Container,
	})
	themed(Row, { BackgroundColor3 = "Element", BackgroundTransparency = "ElementTransparency" })
	corner(Row, 7)
	local right = o.Right or 0
	local Title = label({
		Text = o.Name or "",
		Font = FONT_MED,
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.fromOffset(12, top and 8 or 0),
		Size = top and UDim2.new(1, -(24 + right), 0, 16) or UDim2.new(1, -(24 + right), 0, h),
		Parent = Row,
	})
	local Desc
	if hasDesc then
		Desc = label({ Text = o.Desc, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(12, 25), Size = UDim2.new(1, -(24 + right), 0, 14), Parent = Row }, "SubText")
	end
	Row.MouseEnter:Connect(function()
		tween(Row, { BackgroundColor3 = Nimbus.Theme.ElementHover }, 0.15)
	end)
	Row.MouseLeave:Connect(function()
		tween(Row, { BackgroundColor3 = Nimbus.Theme.Element }, 0.15)
	end)
	table.insert(section.Items, { Name = string.lower(o.Name or ""), Row = Row })
	return Row, Title, Desc, h
end

function Elements:AddToggle(o)
	o = o or {}
	local T = { Type = "Toggle", Value = o.Default == true, Flag = o.Flag, NoSave = o.NoSave, _cb = {} }
	if o.Callback then
		table.insert(T._cb, o.Callback)
	end
	local Row = newRow(self, { Name = o.Name or "Toggle", Desc = o.Description, Right = 46 })
	local Switch = create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(38, 20), BorderSizePixel = 0, Parent = Row })
	corner(Switch, "full")
	stroke(Switch)
	local Knob = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(14, 14), BorderSizePixel = 0, Parent = Switch })
	corner(Knob, "full")

	local function render(instant)
		local th = Nimbus.Theme
		local sw = { BackgroundColor3 = T.Value and th.Accent or th.Track }
		local kn = {
			Position = T.Value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3 = T.Value and Color3.new(1, 1, 1) or th.SubText,
		}
		if instant then
			for k, v in pairs(sw) do Switch[k] = v end
			for k, v in pairs(kn) do Knob[k] = v end
		else
			tween(Switch, sw, 0.2)
			tween(Knob, kn, 0.25, Enum.EasingStyle.Back)
		end
	end

	function T:Set(v, silent)
		T.Value = v and true or false
		render()
		setFlag(T)
		if not silent then
			fire(T, T.Value)
		end
	end
	function T:Get()
		return T.Value
	end
	function T:OnChanged(fn)
		table.insert(T._cb, fn)
	end
	T._save = function()
		return T.Value
	end
	T._load = function(v)
		T:Set(v)
	end

	Row.MouseButton1Click:Connect(function()
		T:Set(not T.Value)
	end)
	onTheme(function()
		render(true)
	end)
	register(T)
	return T
end

function Elements:AddButton(o, cb)
	if type(o) == "string" then
		o = { Name = o, Callback = cb }
	end
	o = o or {}
	local B = { Type = "Button" }
	local name = o.Name or "Button"
	local Row, Title = newRow(self, { Name = name, Desc = o.Description, Right = 16 })
	label({ Text = ">", Font = FONT_BOLD, TextSize = 13, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(12, 16), TextXAlignment = Enum.TextXAlignment.Right, Parent = Row }, "SubText")
	local armed = false

	Row.InputBegan:Connect(function(input)
		if isClick(input) then
			ripple(Row, input.Position.X, input.Position.Y)
		end
	end)
	Row.MouseButton1Click:Connect(function()
		if o.Confirm and not armed then
			armed = true
			Title.Text = "click again to confirm"
			Title.TextColor3 = Nimbus.Theme.Warning
			task.delay(2, function()
				if armed then
					armed = false
					Title.Text = name
					Title.TextColor3 = Nimbus.Theme.Text
				end
			end)
			return
		end
		if armed then
			armed = false
			Title.Text = name
			Title.TextColor3 = Nimbus.Theme.Text
		end
		if o.Callback then
			task.spawn(o.Callback)
		end
	end)

	function B:SetName(t)
		name = t
		Title.Text = t
	end
	return B
end

function Elements:AddSlider(o)
	o = o or {}
	local S = {
		Type = "Slider",
		Min = o.Min or 0,
		Max = o.Max or 100,
		Increment = o.Increment or 1,
		Suffix = o.Suffix or "",
		Flag = o.Flag,
		NoSave = o.NoSave,
		_cb = {},
	}
	if o.Callback then
		table.insert(S._cb, o.Callback)
	end
	local function snap(v)
		v = math.clamp(tonumber(v) or S.Min, S.Min, S.Max)
		if S.Increment > 0 then
			v = math.floor((v - S.Min) / S.Increment + 0.5) * S.Increment + S.Min
		end
		v = math.clamp(v, S.Min, S.Max)
		return tonumber(string.format("%.4f", v))
	end
	S.Value = snap(o.Default or S.Min)

	local Row = newRow(self, { Name = o.Name or "Slider", Top = true, Height = 52, Right = 70 })
	local ValueBox = create("TextBox", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 7),
		Size = UDim2.fromOffset(70, 18),
		BackgroundTransparency = 1,
		Font = FONT_MED,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Right,
		ClearTextOnFocus = false,
		Text = "",
		Parent = Row,
	})
	themed(ValueBox, { TextColor3 = "Accent" })
	local Track = create("Frame", { Position = UDim2.new(0, 12, 1, -17), Size = UDim2.new(1, -24, 0, 6), BorderSizePixel = 0, Parent = Row })
	themed(Track, { BackgroundColor3 = "Track" })
	corner(Track, "full")
	local Fill = create("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = Track })
	themed(Fill, { BackgroundColor3 = "Accent" })
	corner(Fill, "full")
	create("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(190, 190, 190), Color3.new(1, 1, 1)), Parent = Fill })
	local Knob = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2, Parent = Track })
	corner(Knob, "full")
	local Hit = create("TextButton", { Text = "", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -28), Size = UDim2.new(1, 0, 0, 28), Parent = Row })

	local function fmt(v)
		if S.Increment % 1 == 0 then
			return tostring(math.floor(v + 0.5))
		end
		return tostring(v)
	end

	local function render(instant)
		local range = S.Max - S.Min
		local pct = range == 0 and 0 or (S.Value - S.Min) / range
		if instant then
			Fill.Size = UDim2.fromScale(pct, 1)
			Knob.Position = UDim2.new(pct, 0, 0.5, 0)
		else
			tween(Fill, { Size = UDim2.fromScale(pct, 1) }, 0.08)
			tween(Knob, { Position = UDim2.new(pct, 0, 0.5, 0) }, 0.08)
		end
		if not ValueBox:IsFocused() then
			ValueBox.Text = fmt(S.Value) .. S.Suffix
		end
	end

	function S:Set(v, silent)
		local nv = snap(v)
		if nv == S.Value then
			render()
			return
		end
		S.Value = nv
		render()
		setFlag(S)
		if not silent then
			fire(S, S.Value)
		end
	end
	function S:Get()
		return S.Value
	end
	function S:SetRange(min, max)
		S.Min, S.Max = min or S.Min, max or S.Max
		S:Set(S.Value)
		render(true)
	end
	function S:OnChanged(fn)
		table.insert(S._cb, fn)
	end
	S._save = function()
		return S.Value
	end
	S._load = function(v)
		S:Set(v)
	end

	holdDrag(Hit, function(pos)
		local rel = math.clamp((pos.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
		S:Set(S.Min + rel * (S.Max - S.Min))
	end)
	ValueBox.FocusLost:Connect(function()
		local n = tonumber((string.gsub(ValueBox.Text, "[^%d%.%-]", "")))
		if n then
			S:Set(n)
		end
		ValueBox.Text = fmt(S.Value) .. S.Suffix
	end)

	render(true)
	register(S)
	return S
end

function Elements:AddDropdown(o)
	o = o or {}
	local D = {
		Type = "Dropdown",
		Options = o.Options or {},
		Multi = o.Multi == true,
		Flag = o.Flag,
		NoSave = o.NoSave,
		_cb = {},
		_open = false,
	}
	if o.Callback then
		table.insert(D._cb, o.Callback)
	end

	if o.Players then
		local function playerList()
			local t = {}
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer then
					table.insert(t, p.Name)
				end
			end
			table.sort(t)
			return t
		end
		D.Options = playerList()
		task.defer(function()
			Nimbus:_connect(Players.PlayerAdded, function()
				D:Refresh(playerList(), true)
			end)
			Nimbus:_connect(Players.PlayerRemoving, function()
				task.defer(function()
					D:Refresh(playerList(), true)
				end)
			end)
		end)
	end

	local Row, _, _, H = newRow(self, { Name = o.Name or "Dropdown", Desc = o.Description, Right = 150 })
	local Header = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, H), Parent = Row })
	local Chevron = label({ Text = "v", Font = FONT_BOLD, TextSize = 11, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, H / 2), Size = UDim2.fromOffset(12, 12), TextXAlignment = Enum.TextXAlignment.Center, Parent = Row }, "SubText")
	local ValueLabel = label({ Text = "", TextSize = 12, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -30, 0, H / 2), Size = UDim2.fromOffset(130, 16), TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Parent = Row }, "SubText")

	local useSearch = o.Search == true or (o.Search ~= false and #D.Options > 6)
	local searchH = useSearch and 30 or 0
	local Holder = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, H), Size = UDim2.new(1, -16, 0, 0), Parent = Row })
	local SearchBox
	if useSearch then
		local bg = create("Frame", { Size = UDim2.new(1, 0, 0, 24), BorderSizePixel = 0, Parent = Holder })
		themed(bg, { BackgroundColor3 = "Background" })
		bg.BackgroundTransparency = 0.4
		corner(bg, 6)
		SearchBox = create("TextBox", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), Font = FONT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Text = "", PlaceholderText = "search...", Parent = bg })
		themed(SearchBox, { TextColor3 = "Text", PlaceholderColor3 = "SubText" })
	end
	local Scroll = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, searchH),
		Size = UDim2.new(1, 0, 1, -searchH),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = Holder,
	})
	themed(Scroll, { ScrollBarImageColor3 = "Accent" })
	list(Scroll, 2)

	local function normalize(v)
		if D.Multi then
			local t = {}
			if type(v) == "table" then
				for k, x in pairs(v) do
					if type(k) == "number" then
						t[x] = true
					elseif x then
						t[k] = true
					end
				end
			elseif v ~= nil then
				t[v] = true
			end
			return t
		end
		if type(v) == "table" then
			v = v[1]
		end
		return v
	end

	local function selectedList()
		local arr = {}
		for _, opt in ipairs(D.Options) do
			if D.Value[opt] then
				table.insert(arr, opt)
			end
		end
		return arr
	end

	local function isSelected(opt)
		if D.Multi then
			return D.Value[opt] == true
		end
		return D.Value == opt
	end

	local Buttons = {}

	local function visibleCount()
		local n = 0
		for _, e in ipairs(Buttons) do
			if e.Button.Visible then
				n += 1
			end
		end
		return n
	end

	local function resize()
		local listH = math.max(math.min(visibleCount(), 6), 1) * 28
		local full = listH + searchH
		Holder.Size = UDim2.new(1, -16, 0, full)
		tween(Row, { Size = UDim2.new(1, 0, 0, D._open and (H + full + 8) or H) }, 0.25)
		tween(Chevron, { Rotation = D._open and 180 or 0 }, 0.25)
	end

	local function paint()
		local th = Nimbus.Theme
		for _, e in ipairs(Buttons) do
			local sel = isSelected(e.Value)
			e.Label.TextColor3 = sel and th.Accent or th.Text
			e.Dot.BackgroundColor3 = sel and th.Accent or th.Track
		end
		if D.Multi then
			local arr = selectedList()
			local parts = {}
			for i, v in ipairs(arr) do
				parts[i] = tostring(v)
			end
			ValueLabel.Text = #parts > 0 and table.concat(parts, ", ") or "none"
		else
			ValueLabel.Text = D.Value ~= nil and tostring(D.Value) or "none"
		end
	end

	local function filter()
		local q = SearchBox and string.lower(SearchBox.Text) or ""
		for _, e in ipairs(Buttons) do
			e.Button.Visible = q == "" or string.find(string.lower(tostring(e.Value)), q, 1, true) ~= nil
		end
		if D._open then
			resize()
		end
	end

	local function build()
		for _, e in ipairs(Buttons) do
			e.Button:Destroy()
		end
		Buttons = {}
		for i, opt in ipairs(D.Options) do
			local B = create("TextButton", { AutoButtonColor = false, Text = "", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, -4, 0, 26), LayoutOrder = i, Parent = Scroll })
			themed(B, { BackgroundColor3 = "ElementHover" })
			corner(B, 6)
			local Dot = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0), Size = UDim2.fromOffset(6, 6), BorderSizePixel = 0, Parent = B })
			corner(Dot, "full")
			local L = label({ Text = tostring(opt), TextSize = 12, Position = UDim2.fromOffset(23, 0), Size = UDim2.new(1, -30, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = B }, false)
			table.insert(Buttons, { Button = B, Value = opt, Label = L, Dot = Dot })
			B.MouseEnter:Connect(function()
				tween(B, { BackgroundTransparency = 0.4 }, 0.12)
			end)
			B.MouseLeave:Connect(function()
				tween(B, { BackgroundTransparency = 1 }, 0.12)
			end)
			B.MouseButton1Click:Connect(function()
				if D.Multi then
					local arr = selectedList()
					local found = table.find(arr, opt)
					if found then
						table.remove(arr, found)
					else
						table.insert(arr, opt)
					end
					D:Set(arr)
				else
					if D.Value == opt and o.AllowNone then
						D:Set(nil)
					else
						D:Set(opt)
					end
					D._open = false
					resize()
				end
			end)
		end
		paint()
		filter()
	end

	function D:Set(v, silent)
		D.Value = normalize(v)
		paint()
		setFlag(D)
		if not silent then
			fire(D, D:Get())
		end
	end
	function D:Get()
		if D.Multi then
			return selectedList()
		end
		return D.Value
	end
	function D:Refresh(options, keep)
		D.Options = options or {}
		if not keep then
			D.Value = D.Multi and {} or nil
		elseif D.Multi then
			local t = {}
			for _, opt in ipairs(D.Options) do
				if D.Value[opt] then
					t[opt] = true
				end
			end
			D.Value = t
		elseif D.Value ~= nil and not table.find(D.Options, D.Value) then
			D.Value = nil
		end
		build()
		setFlag(D)
		if D._open then
			resize()
		end
	end
	function D:OnChanged(fn)
		table.insert(D._cb, fn)
	end
	D._save = function()
		return D:Get()
	end
	D._load = function(v)
		D:Set(v)
	end

	Header.MouseButton1Click:Connect(function()
		D._open = not D._open
		if D._open and SearchBox then
			SearchBox.Text = ""
		end
		resize()
	end)
	if SearchBox then
		SearchBox:GetPropertyChangedSignal("Text"):Connect(filter)
	end
	onTheme(paint)

	D.Value = D.Multi and {} or nil
	build()
	local default = o.Default
	if type(default) == "number" and not table.find(D.Options, default) and D.Options[default] ~= nil then
		default = D.Options[default]
	end
	D.Value = normalize(default)
	paint()
	register(D)
	return D
end

function Elements:AddInput(o)
	o = o or {}
	local I = { Type = "Input", Value = tostring(o.Default or ""), Flag = o.Flag, NoSave = o.NoSave, _cb = {} }
	if o.Callback then
		table.insert(I._cb, o.Callback)
	end
	local width = o.Width or 140
	local Row = newRow(self, { Name = o.Name or "Input", Desc = o.Description, Right = width })
	local Bg = create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(width, 24), BorderSizePixel = 0, Parent = Row })
	themed(Bg, { BackgroundColor3 = "Background" })
	Bg.BackgroundTransparency = 0.4
	corner(Bg, 6)
	local BgStroke = stroke(Bg)
	local Box = create("TextBox", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -16, 1, 0),
		Font = FONT,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		PlaceholderText = o.Placeholder or "",
		Text = I.Value,
		Parent = Bg,
	})
	themed(Box, { TextColor3 = "Text", PlaceholderColor3 = "SubText" })

	function I:Set(v, silent)
		v = tostring(v or "")
		if Box.Text ~= v then
			Box.Text = v
		end
		if I.Value == v then
			return
		end
		I.Value = v
		setFlag(I)
		if not silent then
			fire(I, v)
		end
	end
	function I:Get()
		return I.Value
	end
	function I:OnChanged(fn)
		table.insert(I._cb, fn)
	end
	I._save = function()
		return I.Value
	end
	I._load = function(v)
		I:Set(v)
	end

	Box:GetPropertyChangedSignal("Text"):Connect(function()
		local t = Box.Text
		if o.Numeric then
			local f = string.gsub(t, "[^%d%.%-]", "")
			if f ~= t then
				Box.Text = f
				return
			end
		end
		if o.MaxLength and #t > o.MaxLength then
			Box.Text = string.sub(t, 1, o.MaxLength)
			return
		end
		if o.Live then
			I:Set(t)
		end
	end)
	Box.Focused:Connect(function()
		BgStroke.Color = Nimbus.Theme.Accent
		BgStroke.Transparency = 0.3
	end)
	Box.FocusLost:Connect(function()
		BgStroke.Color = Nimbus.Theme.Stroke
		BgStroke.Transparency = Nimbus.Theme.StrokeTransparency
		if not o.Live then
			I:Set(Box.Text)
		end
	end)
	Row.MouseButton1Click:Connect(function()
		Box:CaptureFocus()
	end)
	register(I)
	return I
end

function Elements:AddKeybind(o)
	o = o or {}
	local K = { Type = "Keybind", Value = keyName(o.Default) or "None", Mode = o.Mode or "Toggle", State = false, Flag = o.Flag, NoSave = o.NoSave, _cb = {}, _changed = {} }
	if o.Callback then
		table.insert(K._cb, o.Callback)
	end
	if o.ChangedCallback then
		table.insert(K._changed, o.ChangedCallback)
	end
	local Row = newRow(self, { Name = o.Name or "Keybind", Desc = o.Description, Right = 70 })
	local KeyBtn = create("TextButton", {
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BorderSizePixel = 0,
		Font = FONT_MED,
		TextSize = 12,
		Text = "",
		Parent = Row,
	})
	themed(KeyBtn, { BackgroundColor3 = "Track" })
	corner(KeyBtn, 6)
	padding(KeyBtn, 0, 9, 0, 9)
	create("UISizeConstraint", { MinSize = Vector2.new(40, 22), Parent = KeyBtn })
	local picking = false

	local function render()
		local th = Nimbus.Theme
		if picking then
			KeyBtn.Text = "..."
			KeyBtn.TextColor3 = th.Accent
		else
			KeyBtn.Text = ShortKeys[K.Value] or K.Value
			KeyBtn.TextColor3 = th.Text
		end
	end

	local function matches(input)
		if K.Value == "None" then
			return false
		end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			return input.KeyCode.Name == K.Value
		end
		return input.UserInputType.Name == K.Value
	end

	function K:Set(key, mode)
		K.Value = keyName(key) or "None"
		if mode then
			K.Mode = mode
		end
		render()
		setFlag(K)
		for _, fn in ipairs(K._changed) do
			task.spawn(fn, K.Value)
		end
	end
	function K:Get()
		return K.Value
	end
	function K:GetState()
		if K.Mode == "Always" then
			return true
		end
		return K.State
	end
	function K:OnChanged(fn)
		table.insert(K._changed, fn)
	end
	function K:OnPress(fn)
		table.insert(K._cb, fn)
	end
	K._save = function()
		return { Key = K.Value, Mode = K.Mode }
	end
	K._load = function(v)
		if type(v) == "table" then
			K:Set(v.Key, v.Mode)
		else
			K:Set(v)
		end
	end

	local function startPicking()
		if picking then
			return
		end
		picking = true
		Nimbus._picking = true
		render()
	end
	KeyBtn.MouseButton1Click:Connect(startPicking)
	Row.MouseButton1Click:Connect(startPicking)

	Nimbus:_connect(UserInputService.InputBegan, function(input)
		if picking then
			local name
			if input.UserInputType == Enum.UserInputType.Keyboard then
				name = input.KeyCode.Name
				if name == "Escape" or name == "Backspace" then
					name = "None"
				end
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
				name = input.UserInputType.Name
			else
				return
			end
			picking = false
			Nimbus._picking = false
			Nimbus._pickedAt = os.clock()
			K:Set(name)
			return
		end
		if typing() or not matches(input) then
			return
		end
		if K.Mode == "Toggle" then
			K.State = not K.State
			fire(K, K.State)
		elseif K.Mode == "Hold" then
			K.State = true
			fire(K, true)
		else
			fire(K)
		end
	end)
	Nimbus:_connect(UserInputService.InputEnded, function(input)
		if K.Mode == "Hold" and K.State and matches(input) then
			K.State = false
			fire(K, false)
		end
	end)

	onTheme(render)
	register(K)
	return K
end

function Elements:AddColorPicker(o)
	o = o or {}
	local C = { Type = "ColorPicker", Value = o.Default or Color3.fromRGB(255, 255, 255), Flag = o.Flag, NoSave = o.NoSave, _cb = {}, _open = false }
	if o.Callback then
		table.insert(C._cb, o.Callback)
	end
	local Row, _, _, H = newRow(self, { Name = o.Name or "Color", Desc = o.Description, Right = 40 })
	local Header = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, H), Parent = Row })
	local Swatch = create("TextButton", { AutoButtonColor = false, Text = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, H / 2), Size = UDim2.fromOffset(32, 18), BorderSizePixel = 0, Parent = Row })
	corner(Swatch, 5)
	stroke(Swatch)

	local PANEL = 132
	local Panel = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, H), Size = UDim2.new(1, -24, 0, PANEL), Parent = Row })
	local SV = create("TextButton", { AutoButtonColor = false, Text = "", BorderSizePixel = 0, Size = UDim2.new(1, -28, 0, 100), Parent = Panel })
	corner(SV, 6)
	local White = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = SV })
	corner(White, 6)
	create("UIGradient", { Transparency = NumberSequence.new(0, 1), Parent = White })
	local Black = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = SV })
	corner(Black, 6)
	create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0), Parent = Black })
	local SVCursor = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = 3, Parent = SV })
	corner(SVCursor, "full")
	create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Parent = SVCursor })

	local Hue = create("TextButton", { AutoButtonColor = false, Text = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 18, 0, 100), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = Panel })
	corner(Hue, 6)
	local kps = {}
	for i = 0, 6 do
		table.insert(kps, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
	end
	create("UIGradient", { Rotation = 90, Color = ColorSequence.new(kps), Parent = Hue })
	local HueCursor = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 4, 0, 4), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 3, Parent = Hue })
	corner(HueCursor, "full")

	local HexBg = create("Frame", { Position = UDim2.fromOffset(0, 108), Size = UDim2.fromOffset(90, 24), BorderSizePixel = 0, Parent = Panel })
	themed(HexBg, { BackgroundColor3 = "Background" })
	HexBg.BackgroundTransparency = 0.4
	corner(HexBg, 6)
	local HexBox = create("TextBox", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Font = FONT_MED, TextSize = 12, ClearTextOnFocus = false, Text = "", Parent = HexBg })
	themed(HexBox, { TextColor3 = "Text" })
	local RGBLabel = label({ Text = "", TextSize = 12, Position = UDim2.fromOffset(100, 108), Size = UDim2.new(1, -100, 0, 24), Parent = Panel }, "SubText")

	local h, s, v = C.Value:ToHSV()

	local function render()
		Swatch.BackgroundColor3 = C.Value
		SV.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		SVCursor.Position = UDim2.fromScale(s, 1 - v)
		HueCursor.Position = UDim2.new(0.5, 0, h, 0)
		if not HexBox:IsFocused() then
			HexBox.Text = "#" .. string.upper(C.Value:ToHex())
		end
		RGBLabel.Text = string.format("%d, %d, %d", math.floor(C.Value.R * 255 + 0.5), math.floor(C.Value.G * 255 + 0.5), math.floor(C.Value.B * 255 + 0.5))
	end

	local function commit(silent)
		C.Value = Color3.fromHSV(h, s, v)
		render()
		setFlag(C)
		if not silent then
			fire(C, C.Value)
		end
	end

	function C:Set(color, silent)
		if typeof(color) ~= "Color3" then
			return
		end
		h, s, v = color:ToHSV()
		commit(silent)
	end
	function C:Get()
		return C.Value
	end
	function C:OnChanged(fn)
		table.insert(C._cb, fn)
	end
	C._save = function()
		return C.Value:ToHex()
	end
	C._load = function(hex)
		local ok, col = pcall(Color3.fromHex, tostring(hex))
		if ok then
			C:Set(col)
		end
	end

	holdDrag(SV, function(pos)
		s = math.clamp((pos.X - SV.AbsolutePosition.X) / math.max(SV.AbsoluteSize.X, 1), 0, 1)
		v = 1 - math.clamp((pos.Y - SV.AbsolutePosition.Y) / math.max(SV.AbsoluteSize.Y, 1), 0, 1)
		commit()
	end)
	holdDrag(Hue, function(pos)
		h = math.clamp((pos.Y - Hue.AbsolutePosition.Y) / math.max(Hue.AbsoluteSize.Y, 1), 0, 1)
		commit()
	end)
	HexBox.FocusLost:Connect(function()
		local hex = string.gsub(HexBox.Text, "[^%x]", "")
		local ok, col = pcall(Color3.fromHex, hex)
		if ok and #hex == 6 then
			C:Set(col)
		else
			render()
		end
	end)

	local function toggleOpen()
		C._open = not C._open
		tween(Row, { Size = UDim2.new(1, 0, 0, C._open and (H + PANEL + 10) or H) }, 0.25)
	end
	Header.MouseButton1Click:Connect(toggleOpen)
	Swatch.MouseButton1Click:Connect(toggleOpen)

	commit(true)
	register(C)
	return C
end

function Elements:AddLabel(text)
	local L = { Type = "Label" }
	local T = label({
		Text = tostring(text or ""),
		TextSize = 12,
		TextWrapped = true,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self:_next(),
		Parent = self.Container,
	}, "SubText")
	padding(T, 2, 4, 2, 4)
	table.insert(self.Items, { Name = string.lower(tostring(text or "")), Row = T })
	function L:Set(t)
		T.Text = tostring(t)
	end
	return L
end

function Elements:AddParagraph(o)
	if type(o) == "string" then
		o = { Title = o }
	end
	o = o or {}
	local P = { Type = "Paragraph" }
	local Box = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, LayoutOrder = self:_next(), Parent = self.Container })
	themed(Box, { BackgroundColor3 = "Element", BackgroundTransparency = "ElementTransparency" })
	corner(Box, 7)
	padding(Box, 9, 12, 10, 12)
	list(Box, 4)
	local Title = label({ Text = o.Title or "", Font = FONT_BOLD, TextSize = 13, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1, Parent = Box })
	local Body = label({ Text = o.Content or "", TextSize = 12, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = Box }, "SubText")
	table.insert(self.Items, { Name = string.lower((o.Title or "") .. " " .. (o.Content or "")), Row = Box })
	function P:Set(t)
		if t.Title then
			Title.Text = t.Title
		end
		if t.Content then
			Body.Text = t.Content
		end
	end
	return P
end

function Elements:AddDivider()
	local Line = create("Frame", { Size = UDim2.new(1, 0, 0, 1), BorderSizePixel = 0, LayoutOrder = self:_next(), Parent = self.Container })
	themed(Line, { BackgroundColor3 = "Stroke", BackgroundTransparency = "StrokeTransparency" })
end

--// window

function Nimbus:Toggle(state)
	for _, w in ipairs(self.Windows) do
		if state == nil then
			w:SetVisible(not w.Open)
		else
			w:SetVisible(state)
		end
	end
end

function Nimbus:CreateWindow(o)
	o = o or {}
	if o.Theme then
		self:SetTheme(o.Theme)
	end
	if o.Keybind then
		self.Keybind = keyName(o.Keybind)
	end
	if o.Blur ~= nil then
		self.BlurEnabled = o.Blur
	end
	if o.Folder then
		self.Folder = o.Folder
	end

	local size = o.Size or UDim2.fromOffset(640, 440)
	local Window = { Tabs = {}, Active = nil, Open = true, Minimized = false }

	local Root = create("Frame", {
		Name = "Window",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.5, -size.Y.Offset / 2),
		Size = size,
		Parent = ScreenGui,
	})
	local Scale = create("UIScale", { Scale = 1, Parent = Root })
	-- lets your mouse move in first person games while the menu is open
	create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0), Modal = true, Parent = Root })

	-- fake soft shadow
	for i, sh in ipairs({ { 12, 0.8 }, { 28, 0.9 } }) do
		local s = create("Frame", {
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = sh[2],
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 6),
			Size = UDim2.new(1, sh[1], 1, sh[1]),
			ZIndex = 0,
			Parent = Root,
		})
		corner(s, 14 + i * 6)
	end

	local Main = create("Frame", { Name = "Main", Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ClipsDescendants = true, Parent = Root })
	themed(Main, { BackgroundColor3 = "Background", BackgroundTransparency = "BackgroundTransparency" })
	corner(Main, 12)
	stroke(Main)
	-- the shiny glass bit in the top left
	local Sheen = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 0, Parent = Main })
	corner(Sheen, 12)
	create("UIGradient", {
		Rotation = 125,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(0.4, 0.985),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = Sheen,
	})

	--// top bar
	local Top = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), Parent = Main })
	local Logo
	if o.Logo then
		Logo = create("ImageLabel", { BackgroundTransparency = 1, Image = (type(o.Logo) == "number") and ("rbxassetid://" .. o.Logo) or o.Logo, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(22, 22), Parent = Top })
	else
		Logo = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(22, 22), BorderSizePixel = 0, Parent = Top })
		themed(Logo, { BackgroundColor3 = "Accent" })
		corner(Logo, 7)
		create("UIGradient", { Rotation = 45, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170)), Parent = Logo })
		label({ Text = string.upper(string.sub(o.Title or "N", 1, 1)), Font = FONT_BOLD, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = Logo }, "Background")
	end
	local TitleLabel = label({ Text = o.Title or "Nimbus", Font = FONT_BOLD, TextSize = 15, Position = UDim2.fromOffset(46, o.Subtitle and 8 or 0), Size = UDim2.new(0, 260, 0, o.Subtitle and 16 or 46), TextTruncate = Enum.TextTruncate.AtEnd, Parent = Top })
	local SubLabel
	if o.Subtitle then
		SubLabel = label({ Text = o.Subtitle, TextSize = 11, Position = UDim2.fromOffset(46, 25), Size = UDim2.new(0, 260, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd, Parent = Top }, "SubText")
	end
	draggable(Top, Root)

	local function topButton(txt, x)
		local b = create("TextButton", { AutoButtonColor = false, Text = txt, Font = FONT_BOLD, TextSize = 14, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, x, 0.5, 0), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = Top })
		themed(b, { BackgroundColor3 = "ElementHover", TextColor3 = "SubText" })
		corner(b, 7)
		b.MouseEnter:Connect(function()
			tween(b, { BackgroundTransparency = 0.3 }, 0.15)
		end)
		b.MouseLeave:Connect(function()
			tween(b, { BackgroundTransparency = 1 }, 0.15)
		end)
		return b
	end
	local CloseBtn = topButton("x", -12)
	local MinBtn = topButton("-", -42)

	local SearchBg = create("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -76, 0.5, 0), Size = UDim2.fromOffset(170, 28), BorderSizePixel = 0, Parent = Top })
	themed(SearchBg, { BackgroundColor3 = "Element" })
	SearchBg.BackgroundTransparency = 0.45
	corner(SearchBg, "full")
	stroke(SearchBg)
	local SearchBox = create("TextBox", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), Font = FONT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Text = "", PlaceholderText = "search this tab", Parent = SearchBg })
	themed(SearchBox, { TextColor3 = "Text", PlaceholderColor3 = "SubText" })

	--// sidebar
	local Sidebar = create("Frame", { Position = UDim2.fromOffset(10, 46), Size = UDim2.new(0, 150, 1, -56), BorderSizePixel = 0, Parent = Main })
	themed(Sidebar, { BackgroundColor3 = "Surface", BackgroundTransparency = "SurfaceTransparency" })
	corner(Sidebar, 10)
	stroke(Sidebar)
	local TabList = create("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -58), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 0, Parent = Sidebar })
	padding(TabList, 8, 8, 8, 8)
	list(TabList, 4)

	local Profile = create("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 8, 1, -8), Size = UDim2.new(1, -16, 0, 42), BorderSizePixel = 0, Parent = Sidebar })
	themed(Profile, { BackgroundColor3 = "Element", BackgroundTransparency = "ElementTransparency" })
	corner(Profile, 8)
	local Avatar = create("ImageLabel", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 7, 0.5, 0), Size = UDim2.fromOffset(28, 28), BorderSizePixel = 0, Image = "", Parent = Profile })
	themed(Avatar, { BackgroundColor3 = "Track" })
	corner(Avatar, "full")
	label({ Text = LocalPlayer and LocalPlayer.DisplayName or "player", Font = FONT_MED, TextSize = 12, Position = UDim2.fromOffset(42, 6), Size = UDim2.new(1, -48, 0, 15), TextTruncate = Enum.TextTruncate.AtEnd, Parent = Profile })
	label({ Text = LocalPlayer and ("@" .. LocalPlayer.Name) or "", TextSize = 11, Position = UDim2.fromOffset(42, 21), Size = UDim2.new(1, -48, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd, Parent = Profile }, "SubText")
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
		end)
		if ok and img then
			Avatar.Image = img
		end
	end)

	local Content = create("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(170, 46), Size = UDim2.new(1, -180, 1, -56), ClipsDescendants = true, Parent = Main })

	Window.Root = Root
	Window.Main = Main

	--// window functions

	function Window:SetVisible(state)
		Window.Open = state
		if state then
			Root.Visible = true
			Scale.Scale = 0.94
			tween(Scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
		else
			tween(Scale, { Scale = 0.94 }, 0.15)
			task.delay(0.15, function()
				if not Window.Open then
					Root.Visible = false
				end
			end)
		end
		tween(Blur, { Size = (state and Nimbus.BlurEnabled) and 14 or 0 }, 0.3)
	end

	function Window:SetTitle(t)
		TitleLabel.Text = t
	end

	function Window:SetSubtitle(t)
		if SubLabel then
			SubLabel.Text = t
		end
	end

	function Window:Minimize(state)
		if state == nil then
			state = not Window.Minimized
		end
		Window.Minimized = state
		if state then
			tween(Root, { Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 46) }, 0.3)
			task.delay(0.3, function()
				if Window.Minimized then
					Sidebar.Visible = false
					Content.Visible = false
				end
			end)
		else
			Sidebar.Visible = true
			Content.Visible = true
			tween(Root, { Size = size }, 0.3)
		end
	end

	CloseBtn.MouseButton1Click:Connect(function()
		Window:SetVisible(false)
		Nimbus:Notify({ Title = "menu hidden", Content = "press " .. (ShortKeys[Nimbus.Keybind] or Nimbus.Keybind) .. " to open it again", Duration = 3 })
	end)
	MinBtn.MouseButton1Click:Connect(function()
		Window:Minimize()
	end)

	-- search box filters stuff in the open tab
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local tab = Window.Active
		if not tab then
			return
		end
		local q = string.lower(SearchBox.Text)
		for _, sec in ipairs(tab.Sections) do
			local secMatch = q == "" or string.find(string.lower(sec.Name), q, 1, true) ~= nil
			local any = false
			for _, item in ipairs(sec.Items) do
				local show = secMatch or string.find(item.Name, q, 1, true) ~= nil
				item.Row.Visible = show
				if show then
					any = true
				end
			end
			sec.Frame.Visible = secMatch or any
		end
	end)

	--// tabs

	function Window:AddTab(to)
		if type(to) == "string" then
			to = { Name = to }
		end
		to = to or {}
		local Tab = { Name = to.Name or "Tab", Sections = {}, Window = Window }

		local Btn = create("TextButton", { AutoButtonColor = false, Text = "", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 34), LayoutOrder = #Window.Tabs + 1, Parent = TabList })
		themed(Btn, { BackgroundColor3 = "Element" })
		corner(Btn, 8)
		local Indicator = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 0), BorderSizePixel = 0, Parent = Btn })
		themed(Indicator, { BackgroundColor3 = "Accent" })
		corner(Indicator, "full")
		local IconBox = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(20, 20), BorderSizePixel = 0, Parent = Btn })
		corner(IconBox, 6)
		local IconLetter, IconImage
		if to.Icon then
			IconImage = create("ImageLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), Image = (type(to.Icon) == "number") and ("rbxassetid://" .. to.Icon) or to.Icon, Parent = IconBox })
		else
			IconLetter = label({ Text = string.upper(string.sub(Tab.Name, 1, 1)), Font = FONT_BOLD, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = IconBox }, false)
		end
		local NameLabel = label({ Text = Tab.Name, Font = FONT_MED, TextSize = 13, Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -44, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd, Parent = Btn }, false)

		local Page = create("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = Content })
		local function column(xs, xo)
			local c = create("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.new(xs, xo, 0, 0),
				Size = UDim2.new(0.5, -5, 1, 0),
				CanvasSize = UDim2.new(),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 2,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
				Parent = Page,
			})
			themed(c, { ScrollBarImageColor3 = "Accent" })
			list(c, 10)
			padding(c, 1, 2, 10, 1)
			return c
		end
		Tab.Page = Page
		Tab.Left = column(0, 0)
		Tab.Right = column(0.5, 5)

		local function refresh()
			local th = Nimbus.Theme
			local on = Window.Active == Tab
			tween(Btn, { BackgroundTransparency = on and 0.35 or 1 }, 0.18)
			tween(Indicator, { Size = UDim2.fromOffset(3, on and 16 or 0) }, 0.22)
			NameLabel.TextColor3 = on and th.Text or th.SubText
			IconBox.BackgroundColor3 = on and th.Accent or th.Track
			IconBox.BackgroundTransparency = on and 0 or 0.3
			if IconLetter then
				IconLetter.TextColor3 = on and th.Background or th.SubText
			end
			if IconImage then
				IconImage.ImageColor3 = on and th.Background or th.SubText
			end
		end
		Tab._refresh = refresh

		function Tab:Select()
			if Window.Active == Tab then
				return
			end
			local prev = Window.Active
			Window.Active = Tab
			if prev then
				prev.Page.Visible = false
			end
			for _, t in ipairs(Window.Tabs) do
				t._refresh()
			end
			SearchBox.Text = ""
			Page.Visible = true
			Page.Position = UDim2.fromOffset(0, 12)
			tween(Page, { Position = UDim2.fromOffset(0, 0) }, 0.3)
		end

		function Tab:AddSection(so)
			if type(so) == "string" then
				so = { Name = so }
			end
			so = so or {}
			local side = so.Side or ((#Tab.Sections % 2 == 0) and "Left" or "Right")
			local col = (string.lower(side) == "right") and Tab.Right or Tab.Left
			local Frame = create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, LayoutOrder = #Tab.Sections + 1, Parent = col })
			themed(Frame, { BackgroundColor3 = "Surface", BackgroundTransparency = "SurfaceTransparency" })
			corner(Frame, 10)
			stroke(Frame)
			padding(Frame, 10, 10, 10, 10)
			list(Frame, 6)
			local Head = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 0, Parent = Frame })
			local Dash = create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(3, 12), BorderSizePixel = 0, Parent = Head })
			themed(Dash, { BackgroundColor3 = "Accent" })
			corner(Dash, "full")
			label({ Text = so.Name or "", Font = FONT_BOLD, TextSize = 13, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -10, 1, 0), Parent = Head })

			local order = 0
			local Section = setmetatable({
				Name = so.Name or "",
				Tab = Tab,
				Frame = Frame,
				Container = Frame,
				Items = {},
				_next = function()
					order += 1
					return order
				end,
			}, { __index = Elements })
			table.insert(Tab.Sections, Section)
			return Section
		end

		Btn.MouseEnter:Connect(function()
			if Window.Active ~= Tab then
				tween(Btn, { BackgroundTransparency = 0.7 }, 0.15)
			end
		end)
		Btn.MouseLeave:Connect(function()
			if Window.Active ~= Tab then
				tween(Btn, { BackgroundTransparency = 1 }, 0.15)
			end
		end)
		Btn.MouseButton1Click:Connect(function()
			Tab:Select()
		end)

		table.insert(Window.Tabs, Tab)
		onTheme(refresh)
		if #Window.Tabs == 1 then
			Tab:Select()
		end
		return Tab
	end

	-- a ready made settings tab with themes, the menu key and configs
	function Window:AddSettingsTab(name)
		local Tab = Window:AddTab({ Name = name or "Settings" })

		local UI = Tab:AddSection({ Name = "Menu", Side = "Left" })
		UI:AddKeybind({
			Name = "Menu key",
			Default = Nimbus.Keybind,
			Mode = "Press",
			NoSave = true,
			ChangedCallback = function(k)
				if k ~= "None" then
					Nimbus.Keybind = k
				end
			end,
		})
		local AccentPicker
		UI:AddDropdown({
			Name = "Theme",
			Options = Nimbus.ThemeOrder,
			Default = Nimbus.ThemeName,
			Flag = "NimbusTheme",
			Callback = function(t)
				Nimbus:SetTheme(t)
				if AccentPicker then
					AccentPicker:Set(Nimbus.Theme.Accent, true)
				end
			end,
		})
		AccentPicker = UI:AddColorPicker({
			Name = "Accent color",
			Default = Nimbus.Theme.Accent,
			Flag = "NimbusAccent",
			Callback = function(c)
				Nimbus:SetTheme({ Accent = c })
			end,
		})
		UI:AddToggle({
			Name = "Blur the game behind",
			Default = Nimbus.BlurEnabled,
			NoSave = true,
			Callback = function(on)
				Nimbus.BlurEnabled = on
				tween(Blur, { Size = (on and Window.Open) and 14 or 0 }, 0.3)
			end,
		})
		UI:AddButton({
			Name = "Unload",
			Description = "closes everything",
			Confirm = true,
			Callback = function()
				Nimbus:Destroy()
			end,
		})

		local Cfg = Tab:AddSection({ Name = "Configs", Side = "Right" })
		local NameBox = Cfg:AddInput({ Name = "Name", Placeholder = "my config", NoSave = true, Width = 120 })
		local Saved = Cfg:AddDropdown({ Name = "Saved", Options = Nimbus:ListConfigs(), NoSave = true, Search = false })
		Cfg:AddButton("Save", function()
			local n = NameBox:Get()
			if n == "" then
				n = Saved:Get() or ""
			end
			local ok, err = Nimbus:SaveConfig(n)
			Nimbus:Notify({ Title = ok and "saved" or "couldnt save", Content = ok and ("saved " .. n) or tostring(err), Type = ok and "Success" or "Error" })
			Saved:Refresh(Nimbus:ListConfigs(), true)
		end)
		Cfg:AddButton("Load", function()
			local n = Saved:Get()
			if not n then
				Nimbus:Notify({ Title = "pick one first", Content = "choose a config from the list", Type = "Warning" })
				return
			end
			local ok, err = Nimbus:LoadConfig(n)
			Nimbus:Notify({ Title = ok and "loaded" or "couldnt load", Content = ok and ("loaded " .. n) or tostring(err), Type = ok and "Success" or "Error" })
		end)
		Cfg:AddButton({
			Name = "Delete",
			Confirm = true,
			Callback = function()
				local n = Saved:Get()
				if not n then
					return
				end
				Nimbus:DeleteConfig(n)
				Saved:Refresh(Nimbus:ListConfigs())
			end,
		})
		Cfg:AddButton("Refresh list", function()
			Saved:Refresh(Nimbus:ListConfigs(), true)
		end)
		Cfg:AddLabel("configs go in your executor's workspace folder under " .. Nimbus.Folder .. "/configs")
		return Tab
	end

	-- phones dont have keyboards so they get a little button to open the menu
	if UserInputService.TouchEnabled and o.MobileButton ~= false then
		local MB = create("TextButton", { AutoButtonColor = false, Text = "", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.4, 0), Size = UDim2.fromOffset(46, 46), BorderSizePixel = 0, ZIndex = 40, Parent = ScreenGui })
		themed(MB, { BackgroundColor3 = "Background" })
		MB.BackgroundTransparency = 0.1
		corner(MB, "full")
		stroke(MB)
		label({ Text = string.upper(string.sub(o.Title or "N", 1, 1)), Font = FONT_BOLD, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 41, Parent = MB }, "Accent")
		local downAt
		MB.InputBegan:Connect(function(input)
			if isClick(input) then
				downAt = input.Position
			end
		end)
		MB.InputEnded:Connect(function(input)
			if isClick(input) and downAt and (input.Position - downAt).Magnitude < 8 then
				Nimbus:Toggle()
			end
			downAt = nil
		end)
		draggable(MB, MB)
	end

	table.insert(self.Windows, Window)
	Root.Visible = true
	Scale.Scale = 0.94
	tween(Scale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
	tween(Blur, { Size = self.BlurEnabled and 14 or 0 }, 0.35)
	return Window
end

--// configs (needs writefile and stuff from your executor)

local function canSave()
	return type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
end

local function configFolder()
	local root = Nimbus.Folder
	local path = root .. "/configs"
	if type(isfolder) == "function" and type(makefolder) == "function" then
		if not isfolder(root) then
			makefolder(root)
		end
		if not isfolder(path) then
			makefolder(path)
		end
	end
	return path
end

local function cleanName(n)
	return (string.gsub(tostring(n or ""), "[^%w%-_ ]", ""))
end

function Nimbus:SaveConfig(name)
	if not canSave() then
		return false, "your executor cant save files"
	end
	name = cleanName(name)
	if name == "" then
		return false, "type a name first"
	end
	local data = {}
	for flag, el in pairs(self.Elements) do
		if el._save and not el.NoSave then
			data[flag] = el._save()
		end
	end
	return pcall(function()
		writefile(configFolder() .. "/" .. name .. ".json", HttpService:JSONEncode(data))
	end)
end

function Nimbus:LoadConfig(name)
	if not canSave() then
		return false, "your executor cant read files"
	end
	name = cleanName(name)
	local path = configFolder() .. "/" .. name .. ".json"
	if not isfile(path) then
		return false, "that config doesnt exist"
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not ok or type(data) ~= "table" then
		return false, "the file is broken"
	end
	for flag, value in pairs(data) do
		local el = self.Elements[flag]
		if el and el._load then
			pcall(el._load, value)
		end
	end
	return true
end

function Nimbus:DeleteConfig(name)
	if type(delfile) ~= "function" then
		return false
	end
	local path = configFolder() .. "/" .. cleanName(name) .. ".json"
	if isfile(path) then
		delfile(path)
		return true
	end
	return false
end

function Nimbus:ListConfigs()
	if type(listfiles) ~= "function" then
		return {}
	end
	local ok, files = pcall(listfiles, configFolder())
	if not ok then
		return {}
	end
	local out = {}
	for _, f in ipairs(files) do
		local n = string.match(f, "([^/\\]+)%.json$")
		if n then
			table.insert(out, n)
		end
	end
	table.sort(out)
	return out
end

--// cleanup

function Nimbus:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	for _, c in ipairs(self._connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	pcall(function()
		Blur:Destroy()
	end)
	pcall(function()
		ScreenGui:Destroy()
	end)
	if genv.__Nimbus == self then
		genv.__Nimbus = nil
	end
end

-- menu open/close key
Nimbus:_connect(UserInputService.InputBegan, function(input)
	if input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
	if typing() or Nimbus._picking or os.clock() - Nimbus._pickedAt < 0.2 then
		return
	end
	if input.KeyCode.Name == Nimbus.Keybind then
		Nimbus:Toggle()
	end
end)

return Nimbus
