--[[
	MainUI (LocalScript)  ->  StarterPlayer.StarterPlayerScripts.MainUI

	The whole interface, built in code. Design language:
	  * Builder Sans, fixed type scale (no auto-scaled text)
	  * Graphite dark palette, VEX red as the single accent
	  * Grouped lists with hairline separators, segmented controls,
	    capsule buttons, a floating dock, banner notifications
	  * Subtle fades only
	Everything scales to fit phones, tablets and desktops.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local RobotBuilder = require(ReplicatedStorage:WaitForChild("RobotBuilder"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestRemote = Remotes:WaitForChild("Request")
local ArenaRemote = Remotes:WaitForChild("ArenaRequest")
local DataUpdate = Remotes:WaitForChild("DataUpdate")
local NotifyRemote = Remotes:WaitForChild("Notify")
local OpenUIRemote = Remotes:WaitForChild("OpenUI")
local ArenaState = Remotes:WaitForChild("ArenaState")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local State = nil
local Arena = { Mode = "None" }
local cooldownEnds = {}

---------------------------------------------------------------------
-- Design tokens
---------------------------------------------------------------------
local C = {
	Base = Color3.fromRGB(0, 0, 0),
	Sheet = Color3.fromRGB(28, 28, 30), -- window background
	Group = Color3.fromRGB(44, 44, 46), -- grouped list / card
	Fill = Color3.fromRGB(58, 58, 60), -- controls, tracks
	FillHi = Color3.fromRGB(72, 72, 74),
	Separator = Color3.fromRGB(64, 64, 67),
	Label = Color3.fromRGB(255, 255, 255),
	Secondary = Color3.fromRGB(152, 152, 159),
	Tertiary = Color3.fromRGB(99, 99, 104),
	Accent = Color3.fromRGB(226, 35, 42), -- VEX red
	Green = Color3.fromRGB(48, 209, 88),
	TeamRed = Color3.fromRGB(255, 69, 58),
	TeamBlue = Color3.fromRGB(10, 132, 255),
}

local FAMILY = "rbxasset://fonts/families/BuilderSans.json"
local F = {
	Regular = Font.new(FAMILY, Enum.FontWeight.Regular),
	Medium = Font.new(FAMILY, Enum.FontWeight.Medium),
	Semi = Font.new(FAMILY, Enum.FontWeight.SemiBold),
	Bold = Font.new(FAMILY, Enum.FontWeight.Bold),
}

-- type scale: { font, size }
local TYPE = {
	Display = { F.Bold, 34 },
	Title = { F.Bold, 28 },
	Title2 = { F.Bold, 22 },
	Headline = { F.Semi, 17 },
	Body = { F.Regular, 16 },
	Callout = { F.Medium, 15 },
	Subhead = { F.Regular, 14 },
	Footnote = { F.Regular, 13 },
	Caption = { F.Semi, 12 },
}

local LEFT, CENTER, RIGHT = Enum.TextXAlignment.Left, Enum.TextXAlignment.Center, Enum.TextXAlignment.Right
local EASE = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local STATS = { "Speed", "Power", "Control", "Scoring" }
local STAT_MAX = {}
for _, key in ipairs(STATS) do
	local total = 0
	for _, slot in ipairs(Config.ModuleSlots) do
		local best = 0
		for _, def in ipairs(Config.Modules[slot]) do
			best = math.max(best, def[key] or 0)
		end
		total += best
	end
	STAT_MAX[key] = math.max(total, 1)
end

---------------------------------------------------------------------
-- Toolkit
---------------------------------------------------------------------
local function tween(obj, props, info)
	local t = TweenService:Create(obj, info or EASE, props)
	t:Play()
	return t
end

local function new(className, props)
	local inst = Instance.new(className)
	local parent = nil
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			inst[key] = value
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(inst, radius)
	new("UICorner", { Parent = inst, CornerRadius = radius == "pill" and UDim.new(1, 0) or UDim.new(0, radius or 12) })
end

local function hairline(inst, transparency)
	return new("UIStroke", { Parent = inst, Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = transparency or 0.9, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function Frame(p)
	local f = new("Frame", {
		Name = p.Name or "Frame",
		BorderSizePixel = 0,
		BackgroundColor3 = p.Color or C.Group,
		BackgroundTransparency = p.Transparency or (p.Color and 0 or 1),
		Size = p.Size or UDim2.fromScale(1, 1),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.Anchor or Vector2.zero,
		LayoutOrder = p.Order or 0,
		Visible = p.Visible ~= false,
		AutomaticSize = p.AutoSize or Enum.AutomaticSize.None,
		ClipsDescendants = p.Clip == true,
		Parent = p.Parent,
	})
	if p.Radius then
		corner(f, p.Radius)
	end
	if p.Hairline then
		hairline(f, p.Hairline ~= true and p.Hairline or nil)
	end
	return f
end

local function Text(p)
	local style = TYPE[p.Style or "Body"]
	return new("TextLabel", {
		Name = p.Name or "Text",
		BackgroundTransparency = 1,
		FontFace = p.Font or style[1],
		TextSize = p.TextSize or style[2],
		TextColor3 = p.Color or C.Label,
		Text = p.Text or "",
		RichText = true,
		TextWrapped = p.Wrap ~= false,
		TextTruncate = p.Wrap == false and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
		TextXAlignment = p.AlignX or LEFT,
		TextYAlignment = p.AlignY or Enum.TextYAlignment.Center,
		Size = p.Size or UDim2.new(1, 0, 0, style[2] + 6),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.Anchor or Vector2.zero,
		LayoutOrder = p.Order or 0,
		Visible = p.Visible ~= false,
		Parent = p.Parent,
	})
end

-- Button kinds: primary (VEX red), secondary (gray), get (App Store style), plain (text only)
local KIND = {
	primary = { Bg = C.Accent, Text = C.Label, Transparency = 0 },
	secondary = { Bg = C.Fill, Text = C.Label, Transparency = 0 },
	get = { Bg = C.Fill, Text = C.Accent, Transparency = 0 },
	plain = { Bg = C.Fill, Text = C.Accent, Transparency = 1 },
	disabled = { Bg = C.Fill, Text = C.Tertiary, Transparency = 0.4 },
}

local function applyKind(b, kind)
	local k = KIND[kind] or KIND.secondary
	b.BackgroundColor3 = k.Bg
	b.BackgroundTransparency = k.Transparency
	b.Label.TextColor3 = k.Text
	b:SetAttribute("Kind", kind)
	b:SetAttribute("Enabled", kind ~= "disabled")
end

local function Button(p, onClick)
	local b = new("TextButton", {
		Name = p.Name or "Button",
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		Size = p.Size or UDim2.new(0, 120, 0, 36),
		Position = p.Position or UDim2.new(),
		AnchorPoint = p.Anchor or Vector2.zero,
		LayoutOrder = p.Order or 0,
		Visible = p.Visible ~= false,
		Parent = p.Parent,
	})
	corner(b, p.Radius or "pill")
	Text({ Parent = b, Name = "Label", Text = p.Text or "", Font = p.Font or F.Semi, TextSize = p.TextSize or 15, AlignX = CENTER, Wrap = false, Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0) })
	applyKind(b, p.Kind or "secondary")
	b.MouseEnter:Connect(function()
		local kind = b:GetAttribute("Kind")
		if b:GetAttribute("Enabled") and kind ~= "plain" then
			tween(b, { BackgroundTransparency = KIND[kind].Transparency + 0.12 })
		end
	end)
	b.MouseLeave:Connect(function()
		local k = KIND[b:GetAttribute("Kind")]
		if k then
			tween(b, { BackgroundTransparency = k.Transparency })
		end
		tween(b.Label, { TextTransparency = 0 })
	end)
	b.MouseButton1Down:Connect(function()
		if b:GetAttribute("Enabled") then
			tween(b.Label, { TextTransparency = 0.4 }, TweenInfo.new(0.05))
		end
	end)
	b.MouseButton1Up:Connect(function()
		tween(b.Label, { TextTransparency = 0 })
	end)
	b.Activated:Connect(function()
		if b:GetAttribute("Enabled") and onClick then
			onClick(b)
		end
	end)
	return b
end

local function setButton(b, text, kind)
	if text then
		b.Label.Text = text
	end
	if kind then
		applyKind(b, kind)
	end
end

local function Scroll(p)
	local s = new("ScrollingFrame", {
		Name = p.Name or "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = C.Secondary,
		ScrollBarImageTransparency = 0.4,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Size = p.Size or UDim2.fromScale(1, 1),
		Position = p.Position or UDim2.new(),
		Parent = p.Parent,
	})
	if p.Grid then
		new("UIGridLayout", { Parent = s, CellSize = p.Grid, CellPadding = UDim2.new(0, 14, 0, 14), SortOrder = Enum.SortOrder.LayoutOrder })
	else
		new("UIListLayout", { Parent = s, Padding = UDim.new(0, p.Gap or 0), SortOrder = Enum.SortOrder.LayoutOrder })
	end
	new("UIPadding", { Parent = s, PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) })
	return s
end

-- Inset grouped list: one rounded container, rows separated by hairlines
local function Group(parent, props)
	props = props or {}
	local g = Frame({ Parent = parent, Name = "Group", Color = C.Group, Radius = 14, Size = props.Size or UDim2.new(1, 0, 0, 0), Position = props.Position, AutoSize = Enum.AutomaticSize.Y, Order = props.Order })
	new("UIListLayout", { Parent = g, SortOrder = Enum.SortOrder.LayoutOrder })
	g:SetAttribute("Rows", 0)
	return g
end

local function Row(group, height)
	local index = group:GetAttribute("Rows") + 1
	group:SetAttribute("Rows", index)
	local r = Frame({ Parent = group, Name = "Row" .. index, Size = UDim2.new(1, 0, 0, height), Order = index })
	if index > 1 then
		Frame({ Parent = r, Name = "Separator", Color = C.Separator, Size = UDim2.new(1, -16, 0, 1), Position = UDim2.new(0, 16, 0, 0) })
	end
	return r
end

local function Section(parent, text, position)
	return Text({ Parent = parent, Text = string.upper(text), Style = "Footnote", Color = C.Secondary, Position = position, Size = UDim2.new(1, -16, 0, 28), AlignY = Enum.TextYAlignment.Bottom })
end

local function Progress(parent, position, size, fraction, color)
	local track = Frame({ Parent = parent, Color = C.Fill, Radius = "pill", Position = position, Size = size })
	local fill = Frame({ Parent = track, Color = color or C.Label, Radius = "pill", Size = UDim2.new(0, 0, 1, 0) })
	tween(fill, { Size = UDim2.new(math.clamp(fraction, 0, 1), 0, 1, 0) }, TweenInfo.new(0.5, Enum.EasingStyle.Quint))
	return track, fill
end

local function Segmented(parent, items, selected, onSelect, position, size)
	local track = Frame({ Parent = parent, Color = C.Fill, Transparency = 0.2, Radius = 9, Position = position, Size = size })
	local n = #items
	for i, item in ipairs(items) do
		local active = item == selected
		local seg = new("TextButton", {
			Parent = track,
			AutoButtonColor = false,
			Text = item,
			FontFace = active and F.Semi or F.Medium,
			TextSize = 14,
			TextColor3 = C.Label,
			BackgroundColor3 = C.FillHi,
			BackgroundTransparency = active and 0 or 1,
			Position = UDim2.new((i - 1) / n, 2, 0, 2),
			Size = UDim2.new(1 / n, -4, 1, -4),
		})
		corner(seg, 7)
		if active then
			hairline(seg, 0.92)
		end
		seg.Activated:Connect(function()
			if not active then
				onSelect(item)
			end
		end)
	end
	return track
end

local function Keycap(parent, key, position, width)
	local cap = Frame({ Parent = parent, Color = C.Fill, Radius = 6, Position = position, Size = UDim2.new(0, width or 28, 0, 26) })
	Text({ Parent = cap, Text = key, Font = F.Semi, TextSize = 12, AlignX = CENTER, Size = UDim2.fromScale(1, 1) })
	return cap
end

---------------------------------------------------------------------
-- Screens + scaling
---------------------------------------------------------------------
local mainGui = new("ScreenGui", { Name = "VexUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1, Parent = playerGui })
local modalGui = new("ScreenGui", { Name = "VexModal", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 10, Parent = playerGui })

local scalers = {}
local uiScale = 1
local function autoScale(guiObject)
	table.insert(scalers, new("UIScale", { Parent = guiObject, Scale = uiScale }))
end
local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local vp = camera.ViewportSize
	uiScale = math.clamp(math.min(vp.X / 1400, vp.Y / 820), 0.5, 1.15)
	for _, s in ipairs(scalers) do
		s.Scale = uiScale
	end
end

---------------------------------------------------------------------
-- 3D robot previews ("product shots")
---------------------------------------------------------------------
local previews = {}
local previewAngle = 0.6

local function RobotPreview(parent, loadout, size, position, background)
	local vp = new("ViewportFrame", {
		BackgroundColor3 = background or C.Group,
		BorderSizePixel = 0,
		Size = size,
		Position = position or UDim2.new(),
		Ambient = Color3.fromRGB(140, 140, 150),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-0.5, -1, -0.6),
		Parent = parent,
	})
	corner(vp, 14)
	local camera = new("Camera", { FieldOfView = 30, CFrame = CFrame.lookAt(Vector3.new(11, 7, -15), Vector3.new(0, 1, 0)), Parent = vp })
	vp.CurrentCamera = camera
	local ok, model = pcall(RobotBuilder.Build, loadout, { NoNameplate = true })
	if ok and model then
		model:PivotTo(CFrame.Angles(0, previewAngle, 0))
		model.Parent = vp
		table.insert(previews, model)
	end
	return vp
end

RunService.RenderStepped:Connect(function(dt)
	previewAngle = (previewAngle + dt * 0.35) % (math.pi * 2)
	for i = #previews, 1, -1 do
		local model = previews[i]
		if model.Parent == nil then
			table.remove(previews, i)
		else
			model:PivotTo(CFrame.Angles(0, previewAngle, 0))
		end
	end
end)

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local function cash()
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild("Cash")
	return value and value.Value or (State and State.Cash or 0)
end

local live = { Cash = {}, Tick = {} }
local function onCash(fn)
	table.insert(live.Cash, fn)
	fn(cash())
end
local function onTick(fn)
	table.insert(live.Tick, fn)
	fn()
end

local function isDriving()
	return Arena.Mode == "Practice" or Arena.Mode == "Ranked"
end

---------------------------------------------------------------------
-- Banners (notifications)
---------------------------------------------------------------------
local bannerHost = Frame({ Parent = mainGui, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96), Size = UDim2.new(0, 420, 0, 200) })
new("UIListLayout", { Parent = bannerHost, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder })
autoScale(bannerHost)

local DOT = { success = C.Green, error = C.Accent, cash = C.Green, info = C.Secondary }
local bannerCount = 0

local function toast(text, kind)
	if type(text) ~= "string" or text == "" then
		return
	end
	bannerCount += 1
	local banner = Frame({ Parent = bannerHost, Color = C.Group, Radius = "pill", Hairline = 0.9, Order = bannerCount, Size = UDim2.new(0, 0, 0, 44), AutoSize = Enum.AutomaticSize.X })
	new("UIPadding", { Parent = banner, PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 20) })
	new("UIListLayout", { Parent = banner, FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
	local dot = Frame({ Parent = banner, Color = DOT[kind] or C.Secondary, Radius = "pill", Size = UDim2.new(0, 8, 0, 8), Order = 1 })
	local label = new("TextLabel", {
		Parent = banner,
		BackgroundTransparency = 1,
		FontFace = F.Medium,
		TextSize = 15,
		TextColor3 = C.Label,
		Text = text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = 2,
	})
	new("UISizeConstraint", { Parent = label, MaxSize = Vector2.new(360, 44) })

	banner.BackgroundTransparency = 1
	label.TextTransparency = 1
	dot.BackgroundTransparency = 1
	tween(banner, { BackgroundTransparency = 0.04 })
	tween(label, { TextTransparency = 0 })
	tween(dot, { BackgroundTransparency = 0 })

	local banners = {}
	for _, child in ipairs(bannerHost:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(banners, child)
		end
	end
	if #banners > 3 then
		table.sort(banners, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		banners[1]:Destroy()
	end

	task.delay(3.2, function()
		if banner.Parent then
			tween(banner, { BackgroundTransparency = 1 })
			tween(label, { TextTransparency = 1 })
			tween(dot, { BackgroundTransparency = 1 })
			local stroke = banner:FindFirstChildOfClass("UIStroke")
			if stroke then
				tween(stroke, { Transparency = 1 })
			end
			task.wait(0.25)
			banner:Destroy()
		end
	end)
end

NotifyRemote.OnClientEvent:Connect(toast)

---------------------------------------------------------------------
-- Server calls
---------------------------------------------------------------------
local busy = false
local function request(remote, ...)
	if busy then
		return false, nil
	end
	busy = true
	local ok, a, b = pcall(remote.InvokeServer, remote, ...)
	busy = false
	if not ok then
		return false, "Connection problem. Try again."
	end
	return a, b
end

local function act(action, ...)
	local ok, msg = request(RequestRemote, action, ...)
	if type(msg) == "string" then
		toast(msg, ok and "success" or "error")
	end
	return ok, msg
end

---------------------------------------------------------------------
-- Status capsule (top center)
---------------------------------------------------------------------
local statusHost = Frame({ Parent = mainGui, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.new(0, 520, 0, 76) })
autoScale(statusHost)
local capsule = Frame({ Parent = statusHost, Color = C.Sheet, Transparency = 0.08, Radius = "pill", Hairline = 0.9, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0, 470, 0, 44) })

local function Segment(x, width)
	local seg = Frame({ Parent = capsule, Position = UDim2.new(0, x, 0, 0), Size = UDim2.new(0, width, 1, 0) })
	return Text({ Parent = seg, Style = "Headline", Wrap = false, AlignX = CENTER, Size = UDim2.fromScale(1, 1) })
end
local function Divider(x)
	Frame({ Parent = capsule, Color = C.Separator, Position = UDim2.new(0, x, 0.5, 0), Anchor = Vector2.new(0, 0.5), Size = UDim2.new(0, 1, 0, 20) })
end

local cashText = Segment(0, 220)
Divider(220)
local trophyText = Segment(221, 120)
Divider(341)
local seasonText = Segment(342, 128)

local goalText = Text({ Parent = statusHost, Style = "Footnote", Color = C.Secondary, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 0, 0, 50), Size = UDim2.new(1, 0, 0, 16) })
local goalTrack = Frame({ Parent = statusHost, Color = C.Fill, Transparency = 0.3, Radius = "pill", Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 70), Size = UDim2.new(0, 180, 0, 3) })
local goalFill = Frame({ Parent = goalTrack, Color = C.Label, Radius = "pill", Size = UDim2.new(0, 0, 1, 0) })

local cashDisplay = new("NumberValue", { Value = 0 })
local function renderCashText()
	local income = State and State.RobotIncome or 0
	local incomeText = income > 0 and ('  <font color="#98989F" size="13">+' .. Config.Money(income) .. "/s</font>") or ""
	cashText.Text = Config.Money(cashDisplay.Value) .. incomeText
end
cashDisplay.Changed:Connect(renderCashText)

local lastCash = nil
local function setCash(value)
	if lastCash == nil then
		cashDisplay.Value = value
		renderCashText()
	else
		tween(cashDisplay, { Value = value }, TweenInfo.new(0.45, Enum.EasingStyle.Quint))
	end
	lastCash = value
end

local function nextGoal()
	if not State then
		return nil, 0
	end
	local best = nil
	for _, item in ipairs(Config.Items) do
		if not State.Purchased[item.Id] and (item.Requires == nil or State.Purchased[item.Requires]) then
			if not best or item.Cost < best.Cost then
				best = item
			end
		end
	end
	if best then
		return best.Name, best.Cost
	end
	return "Season " .. (State.Season + 1), Config.GetSeasonCost(State.Season)
end

local function updateGoal(money)
	local name, cost = nextGoal()
	local show = name ~= nil and not isDriving()
	goalText.Visible = show
	goalTrack.Visible = show
	if not name then
		return
	end
	local done = money >= cost
	goalText.Text = done and ("Next  " .. name .. "  ·  Ready") or ("Next  " .. name .. "  ·  " .. Config.Money(money) .. " of " .. Config.Money(cost))
	local fraction = cost > 0 and math.clamp(money / cost, 0, 1) or 1
	tween(goalFill, { Size = UDim2.new(fraction, 0, 1, 0) })
end

local function updateStatus()
	if not State then
		return
	end
	renderCashText()
	trophyText.Text = Config.Format(State.Trophies) .. '  <font color="#98989F" size="13">Trophies</font>'
	seasonText.Text = "Season " .. State.Season .. '  <font color="#98989F" size="13">' .. string.format("%.1f×", State.Multiplier) .. "</font>"
	updateGoal(cash())
end

---------------------------------------------------------------------
-- Sheet (window)
---------------------------------------------------------------------
local panels = {}
local openName = nil

local sheetHost = Frame({ Parent = mainGui, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 6), Size = UDim2.new(0, 860, 0, 580), Visible = false })
autoScale(sheetHost)
local sheet = Frame({ Parent = sheetHost, Color = C.Sheet, Transparency = 0.02, Radius = 22, Hairline = 0.9 })
local sheetTitle = Text({ Parent = sheet, Style = "Title", Wrap = false, Position = UDim2.new(0, 28, 0, 22), Size = UDim2.new(1, -120, 0, 34) })
local sheetSubtitle = Text({ Parent = sheet, Style = "Subhead", Color = C.Secondary, Wrap = false, Position = UDim2.new(0, 28, 0, 56), Size = UDim2.new(1, -120, 0, 20) })
local body = Frame({ Parent = sheet, Position = UDim2.new(0, 28, 0, 96), Size = UDim2.new(1, -56, 1, -120) })

local closeSheet -- forward
local closeButton = Button({ Parent = sheet, Text = "×", Font = F.Medium, TextSize = 22, Kind = "secondary", Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 22), Size = UDim2.new(0, 32, 0, 32) }, function()
	closeSheet()
end)
closeButton.Label.TextColor3 = C.Secondary

local dockItems = {}

local function updateDock()
	for key, item in pairs(dockItems) do
		local active = key == openName
		tween(item.Pill, { BackgroundTransparency = active and 0 or 1 })
		item.Label.TextColor3 = active and C.Label or C.Secondary
	end
end

local function renderOpen()
	if not openName or not sheetHost.Visible then
		return
	end
	local panel = panels[openName]
	local saved = {}
	for _, d in ipairs(body:GetDescendants()) do
		if d:IsA("ScrollingFrame") then
			saved[d.Name] = d.CanvasPosition
		end
	end
	body:ClearAllChildren()
	live.Cash, live.Tick = {}, {}
	sheetTitle.Text = panel.Title
	sheetSubtitle.Text = panel.Subtitle
	panel.Render(body)
	task.defer(function()
		for _, d in ipairs(body:GetDescendants()) do
			if d:IsA("ScrollingFrame") and saved[d.Name] then
				d.CanvasPosition = saved[d.Name]
			end
		end
	end)
end

local function openSheet(name)
	if openName == name and sheetHost.Visible then
		closeSheet()
		return
	end
	local wasOpen = sheetHost.Visible
	openName = name
	sheetHost.Visible = true
	renderOpen()
	updateDock()
	if not wasOpen then
		sheetHost.Position = UDim2.new(0.5, 0, 0.5, 22)
		tween(sheetHost, { Position = UDim2.new(0.5, 0, 0.5, 6) }, TweenInfo.new(0.3, Enum.EasingStyle.Quint))
		sheet.BackgroundTransparency = 1
		tween(sheet, { BackgroundTransparency = 0.02 })
	end
end

function closeSheet()
	if not sheetHost.Visible then
		return
	end
	openName = nil
	live.Cash, live.Tick = {}, {}
	updateDock()
	sheetHost.Visible = false
	body:ClearAllChildren()
end

local function emptyState(parent, title, message, buttonText, onClick)
	local holder = Frame({ Parent = parent, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.new(0, 420, 0, 150) })
	Text({ Parent = holder, Text = title, Style = "Title2", AlignX = CENTER, Size = UDim2.new(1, 0, 0, 30) })
	Text({ Parent = holder, Text = message, Style = "Body", Color = C.Secondary, AlignX = CENTER, AlignY = Enum.TextYAlignment.Top, Position = UDim2.new(0, 0, 0, 38), Size = UDim2.new(1, 0, 0, 44) })
	if buttonText then
		Button({ Parent = holder, Text = buttonText, Kind = "primary", Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 98), Size = UDim2.new(0, 180, 0, 38) }, onClick)
	end
end

---------------------------------------------------------------------
-- Lab
---------------------------------------------------------------------
local labSlot = "Drivetrain"

local function moduleDetail(def)
	local parts = {}
	for _, key in ipairs(STATS) do
		local v = def[key] or 0
		if v > 0 then
			table.insert(parts, key .. " " .. v)
		end
	end
	if def.Slot == "Intake" then
		table.insert(parts, "Holds " .. def.Capacity)
	elseif def.Slot == "Lift" then
		table.insert(parts, def.Points .. " pts per ball")
	elseif def.Slot == "Brain" then
		table.insert(parts, "Auton +" .. def.Auton)
	elseif def.Strafe then
		table.insert(parts, "Strafes")
	end
	return table.concat(parts, "  ·  ")
end

panels.Lab = {
	Title = "Robot Lab",
	Subtitle = "Choose parts, then build your design.",
	Render = function(root)
		if not State then
			return
		end
		if not State.Purchased.assembly then
			emptyState(root, "Robot Lab", "Buy the Robot Assembly Station in your workshop to start designing robots.")
			return
		end

		local left = Frame({ Parent = root, Size = UDim2.new(1, -340, 1, 0) })
		local right = Frame({ Parent = root, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, 316, 1, 0) })

		Segmented(left, Config.ModuleSlots, labSlot, function(slot)
			labSlot = slot
			renderOpen()
		end, UDim2.new(), UDim2.new(1, 0, 0, 32))
		Text({ Parent = left, Text = Config.SlotInfo[labSlot].Desc, Style = "Footnote", Color = C.Secondary, Wrap = false, Position = UDim2.new(0, 4, 0, 40), Size = UDim2.new(1, -8, 0, 20) })

		local scroll = Scroll({ Parent = left, Name = "Modules", Position = UDim2.new(0, 0, 0, 68), Size = UDim2.new(1, 0, 1, -68) })
		local group = Group(scroll)
		for _, def in ipairs(Config.Modules[labSlot]) do
			local owned = State.Modules[def.Id] == true
			local equipped = State.Loadout[labSlot] == def.Id
			local locked = (def.Season or 0) > State.Season
			local r = Row(group, 68)
			Text({ Parent = r, Text = def.Name, Style = "Headline", Wrap = false, Position = UDim2.new(0, 16, 0, 12), Size = UDim2.new(1, -170, 0, 22) })
			Text({ Parent = r, Text = moduleDetail(def), Style = "Footnote", Color = C.Secondary, Wrap = false, Position = UDim2.new(0, 16, 0, 36), Size = UDim2.new(1, -170, 0, 18) })

			local accessory = { Parent = r, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, 104, 0, 30), TextSize = 14 }
			if equipped then
				Text({ Parent = r, Text = "Equipped", Font = F.Semi, TextSize = 15, Color = C.Accent, AlignX = RIGHT, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0, 120, 0, 20) })
			elseif owned then
				accessory.Text, accessory.Kind = "Equip", "secondary"
				Button(accessory, function()
					act("EquipModule", def.Id)
				end)
			elseif locked then
				Text({ Parent = r, Text = "Season " .. def.Season, Style = "Subhead", Color = C.Tertiary, AlignX = RIGHT, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0, 120, 0, 20) })
			else
				accessory.Kind = "get"
				local b = Button(accessory, function()
					act("UnlockModule", def.Id)
				end)
				onCash(function(money)
					setButton(b, Config.Money(def.Cost), money >= def.Cost and "get" or "disabled")
				end)
			end
		end

		-- design card
		local stats = Config.GetRobotStats(State.Loadout)
		local card = Frame({ Parent = right, Color = C.Group, Radius = 18 })
		RobotPreview(card, State.Loadout, UDim2.new(1, 0, 0, 200), UDim2.new(), C.Group)
		Text({ Parent = card, Text = "CURRENT DESIGN", Style = "Caption", Color = C.Secondary, Position = UDim2.new(0, 18, 0, 14), Size = UDim2.new(1, -36, 0, 16) })
		Text({ Parent = card, Text = tostring(stats.Rating), Style = "Display", Position = UDim2.new(0, 18, 0, 30), Size = UDim2.new(0, 120, 0, 40) })
		Text({ Parent = card, Text = "Rating", Style = "Footnote", Color = C.Secondary, Position = UDim2.new(0, 18, 0, 68), Size = UDim2.new(0, 120, 0, 16) })

		for i, key in ipairs(STATS) do
			local y = 212 + (i - 1) * 26
			Text({ Parent = card, Text = key, Style = "Subhead", Position = UDim2.new(0, 18, 0, y), Size = UDim2.new(0, 74, 0, 20) })
			Progress(card, UDim2.new(0, 96, 0, y + 9), UDim2.new(1, -150, 0, 4), stats[key] / STAT_MAX[key])
			Text({ Parent = card, Text = tostring(stats[key]), Font = F.Semi, TextSize = 14, AlignX = RIGHT, Position = UDim2.new(1, -46, 0, y), Size = UDim2.new(0, 28, 0, 20) })
		end
		local details = {
			"Holds " .. stats.Capacity .. "  ·  " .. stats.PointsPerBall .. " pts per ball",
			"Auton +" .. stats.Auton .. "  ·  " .. (stats.Strafe and "Strafes" or "No strafe"),
			"Earns " .. Config.Money(stats.Income * State.Multiplier) .. "/s  ·  Bays " .. #State.Garage .. " of " .. State.GarageSlots,
		}
		for i, line in ipairs(details) do
			Text({ Parent = card, Text = line, Style = "Footnote", Color = C.Secondary, Wrap = false, Position = UDim2.new(0, 18, 0, 324 + (i - 1) * 19), Size = UDim2.new(1, -36, 0, 18) })
		end
		local full = #State.Garage >= State.GarageSlots
		local build = Button({ Parent = card, Kind = "primary", Text = "Build", TextSize = 16, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.new(1, -32, 0, 44) }, function()
			act("BuildRobot")
		end)
		onCash(function(money)
			if full then
				setButton(build, "All Bays Full", "disabled")
			else
				setButton(build, "Build Robot  ·  " .. Config.Money(stats.BuildCost), money >= stats.BuildCost and "primary" or "disabled")
			end
		end)
	end,
}

---------------------------------------------------------------------
-- Garage
---------------------------------------------------------------------
panels.Garage = {
	Title = "Garage",
	Subtitle = "Robots in bays earn money every second.",
	Render = function(root)
		if not State then
			return
		end
		if State.GarageSlots == 0 then
			emptyState(root, "No Bays Yet", "Buy the Robot Assembly Station to get your first robot bay.")
			return
		end
		local scroll = Scroll({ Parent = root, Name = "Robots", Grid = UDim2.new(0, 255, 0, 252) })
		for i = 1, State.GarageSlots do
			local robot = State.Garage[i]
			local card = Frame({ Parent = scroll, Color = C.Group, Radius = 18, Order = i })
			if robot then
				local stats, defs = Config.GetRobotStats(robot)
				local active = State.Active == i
				RobotPreview(card, robot, UDim2.new(1, 0, 0, 138), UDim2.new(), C.Group)
				Text({ Parent = card, Text = "Robot " .. i, Style = "Headline", Wrap = false, Position = UDim2.new(0, 16, 0, 144), Size = UDim2.new(1, -100, 0, 22) })
				if active then
					Text({ Parent = card, Text = "Active", Font = F.Semi, TextSize = 13, Color = C.Accent, AlignX = RIGHT, Position = UDim2.new(1, -96, 0, 144), Size = UDim2.new(0, 80, 0, 22) })
				end
				Text({ Parent = card, Text = "Rating " .. stats.Rating .. "  ·  " .. Config.Money(stats.Income * State.Multiplier) .. "/s", Style = "Footnote", Color = C.Secondary, Wrap = false, Position = UDim2.new(0, 16, 0, 166), Size = UDim2.new(1, -32, 0, 18) })
				Text({ Parent = card, Text = defs.Drivetrain.Name, Style = "Footnote", Color = C.Tertiary, Wrap = false, Position = UDim2.new(0, 16, 0, 184), Size = UDim2.new(1, -32, 0, 18) })
				Button({ Parent = card, Text = active and "Active" or "Use This Robot", Kind = active and "disabled" or "secondary", TextSize = 14, Position = UDim2.new(0, 16, 1, -44), Size = UDim2.new(0, 140, 0, 30) }, function()
					act("SetActive", i)
				end)
				local refund = math.floor(stats.BuildCost * Config.ScrapRefund)
				Button({ Parent = card, Text = "Scrap", Kind = "plain", TextSize = 14, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -8, 1, -44), Size = UDim2.new(0, 76, 0, 30) }, function(b)
					if b:GetAttribute("Confirm") then
						act("ScrapRobot", i)
					else
						b:SetAttribute("Confirm", true)
						setButton(b, "+" .. Config.Money(refund) .. "?")
						task.delay(3, function()
							if b.Parent then
								b:SetAttribute("Confirm", false)
								setButton(b, "Scrap")
							end
						end)
					end
				end)
			else
				card.BackgroundTransparency = 0.6
				hairline(card, 0.9)
				Text({ Parent = card, Text = "Bay " .. i, Style = "Headline", AlignX = CENTER, Position = UDim2.new(0, 0, 0, 86), Size = UDim2.new(1, 0, 0, 22) })
				Text({ Parent = card, Text = "Empty", Style = "Footnote", Color = C.Secondary, AlignX = CENTER, Position = UDim2.new(0, 0, 0, 110), Size = UDim2.new(1, 0, 0, 18) })
				Button({ Parent = card, Text = "Open Robot Lab", Kind = "plain", TextSize = 14, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 140), Size = UDim2.new(0, 150, 0, 30) }, function()
					openSheet("Lab")
				end)
			end
		end
	end,
}

---------------------------------------------------------------------
-- Competition results sheet
---------------------------------------------------------------------
local dim = Frame({ Parent = modalGui, Color = C.Base, Transparency = 0.5, Visible = false })
dim.Active = true

local resultHost = Frame({ Parent = modalGui, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 520, 0, 440), Visible = false })
autoScale(resultHost)
local resultSheet = Frame({ Parent = resultHost, Color = C.Sheet, Radius = 22, Hairline = 0.9 })
local resultTitle = Text({ Parent = resultSheet, Style = "Title2", AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 24, 0, 26), Size = UDim2.new(1, -48, 0, 28) })
Text({ Parent = resultSheet, Text = "Tournament Results", Style = "Subhead", Color = C.Secondary, AlignX = CENTER, Position = UDim2.new(0, 24, 0, 56), Size = UDim2.new(1, -48, 0, 20) })
local roundsGroup = nil
local resultSummary = Text({ Parent = resultSheet, Style = "Title2", AlignX = CENTER, Position = UDim2.new(0, 24, 0, 300), Size = UDim2.new(1, -48, 0, 30) })
local resultDetail = Text({ Parent = resultSheet, Style = "Subhead", Color = C.Secondary, AlignX = CENTER, Position = UDim2.new(0, 24, 0, 332), Size = UDim2.new(1, -48, 0, 20) })
local resultToken = 0
local resultDone = Button({ Parent = resultSheet, Text = "Done", Kind = "primary", TextSize = 16, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.new(0, 200, 0, 42) }, function()
	resultToken += 1
	dim.Visible = false
	resultHost.Visible = false
end)

local function showCompResult(result)
	resultToken += 1
	local token = resultToken
	dim.Visible = true
	resultHost.Visible = true
	resultDone.Visible = false
	resultTitle.Text = result.Competition
	resultSummary.Text = ""
	resultDetail.Text = ""
	if roundsGroup then
		roundsGroup:Destroy()
	end
	roundsGroup = Group(resultSheet, { Position = UDim2.new(0, 24, 0, 92), Size = UDim2.new(1, -48, 0, 0) })

	task.spawn(function()
		for _, r in ipairs(result.Rounds) do
			task.wait(0.6)
			if token ~= resultToken then
				return
			end
			local row = Row(roundsGroup, 58)
			local name = Text({ Parent = row, Text = r.Round, Style = "Headline", Position = UDim2.new(0, 16, 0, 9), Size = UDim2.new(0.5, 0, 0, 22) })
			local opp = Text({ Parent = row, Text = "vs " .. r.OppTeam, Style = "Footnote", Color = C.Secondary, Position = UDim2.new(0, 16, 0, 31), Size = UDim2.new(0.5, 0, 0, 18) })
			local score = Text({ Parent = row, Text = r.You .. " – " .. r.Opp, Font = F.Semi, TextSize = 17, AlignX = RIGHT, Position = UDim2.new(0.5, 0, 0, 9), Size = UDim2.new(0.5, -16, 0, 22) })
			local outcome = Text({ Parent = row, Text = r.Won and "Won" or "Lost", Font = F.Semi, TextSize = 13, Color = r.Won and C.Green or C.Accent, AlignX = RIGHT, Position = UDim2.new(0.5, 0, 0, 31), Size = UDim2.new(0.5, -16, 0, 18) })
			for _, t in ipairs({ name, opp, score, outcome }) do
				t.TextTransparency = 1
				tween(t, { TextTransparency = 0 }, TweenInfo.new(0.35))
			end
		end
		task.wait(0.6)
		if token ~= resultToken then
			return
		end
		if result.Champion then
			resultSummary.Text = "Champions"
			resultDetail.Text = "+" .. Config.Money(result.Prize) .. "  ·  +" .. result.Trophies .. " trophies"
		elseif result.Reached == 2 then
			resultSummary.Text = "Finalist"
			resultDetail.Text = "+" .. Config.Money(result.Prize) .. "  ·  +" .. result.Trophies .. " trophies"
		elseif result.Reached == 1 then
			resultSummary.Text = "Semifinalist"
			resultDetail.Text = "+" .. Config.Money(result.Prize)
		else
			resultSummary.Text = "Eliminated"
			resultDetail.Text = "Improve your robot's rating and try again."
		end
		resultSummary.TextTransparency = 1
		tween(resultSummary, { TextTransparency = 0 }, TweenInfo.new(0.4))
		resultDone.Visible = true
	end)
end

---------------------------------------------------------------------
-- Compete
---------------------------------------------------------------------
panels.Compete = {
	Title = "Competitions",
	Subtitle = "Results are decided by your active robot's rating.",
	Render = function(root)
		if not State then
			return
		end
		local robot = State.Garage[State.Active]
		local rating = robot and Config.GetRobotStats(robot).Rating or 0

		local summary = Frame({ Parent = root, Color = C.Group, Radius = 14, Size = UDim2.new(1, 0, 0, 72) })
		if robot then
			RobotPreview(summary, robot, UDim2.new(0, 72, 0, 72), UDim2.new(), C.Group)
			Text({ Parent = summary, Text = "Robot " .. State.Active, Style = "Headline", Position = UDim2.new(0, 84, 0, 14), Size = UDim2.new(1, -220, 0, 22) })
			Text({ Parent = summary, Text = "Win all three rounds for the full prize.", Style = "Footnote", Color = C.Secondary, Position = UDim2.new(0, 84, 0, 38), Size = UDim2.new(1, -220, 0, 18) })
			Text({ Parent = summary, Text = tostring(rating), Style = "Title", AlignX = RIGHT, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 10), Size = UDim2.new(0, 100, 0, 32) })
			Text({ Parent = summary, Text = "Rating", Style = "Footnote", Color = C.Secondary, AlignX = RIGHT, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 42), Size = UDim2.new(0, 100, 0, 16) })
		else
			Text({ Parent = summary, Text = "Build a robot to compete.", Style = "Headline", Position = UDim2.new(0, 18, 0, 0), Size = UDim2.new(1, -200, 1, 0) })
			Button({ Parent = summary, Text = "Open Robot Lab", Kind = "primary", TextSize = 14, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0, 150, 0, 34) }, function()
				openSheet("Lab")
			end)
		end

		local scroll = Scroll({ Parent = root, Name = "Comps", Position = UDim2.new(0, 0, 0, 84), Size = UDim2.new(1, 0, 1, -84) })
		local group = Group(scroll)
		for _, comp in ipairs(Config.Competitions) do
			local meets = robot ~= nil and rating >= comp.MinRating
			local r = Row(group, 64)
			Text({ Parent = r, Text = comp.Name, Style = "Headline", Wrap = false, Position = UDim2.new(0, 16, 0, 11), Size = UDim2.new(1, -330, 0, 22) })
			local requirement = meets and ("Rating " .. comp.MinRating .. "+") or ('<font color="#E2232A">Requires rating ' .. comp.MinRating .. "</font>")
			local fee = comp.Fee > 0 and ("Entry " .. Config.Money(comp.Fee)) or "Free entry"
			Text({ Parent = r, Text = requirement .. "  ·  " .. fee, Style = "Footnote", Color = C.Secondary, Wrap = false, Position = UDim2.new(0, 16, 0, 35), Size = UDim2.new(1, -330, 0, 18) })
			Text({ Parent = r, Text = Config.Money(comp.Prize * State.Multiplier), Font = F.Semi, TextSize = 16, AlignX = RIGHT, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -140, 0, 11), Size = UDim2.new(0, 160, 0, 22) })
			Text({ Parent = r, Text = comp.Trophies .. " trophies", Style = "Footnote", Color = C.Secondary, AlignX = RIGHT, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -140, 0, 35), Size = UDim2.new(0, 160, 0, 18) })
			local b = Button({ Parent = r, Text = "Enter", Kind = "primary", TextSize = 14, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.new(0, 108, 0, 32) }, function()
				local ok, result = request(RequestRemote, "EnterCompetition", comp.Id)
				if ok and type(result) == "table" then
					cooldownEnds[comp.Id] = os.clock() + comp.Cooldown
					showCompResult(result)
				elseif type(result) == "string" then
					toast(result, "error")
				end
			end)
			local function update()
				local remaining = math.ceil((cooldownEnds[comp.Id] or 0) - os.clock())
				if not meets then
					setButton(b, "Locked", "disabled")
				elseif remaining > 0 then
					setButton(b, string.format("%d:%02d", math.floor(remaining / 60), remaining % 60), "disabled")
				elseif cash() < comp.Fee then
					setButton(b, "Enter", "disabled")
				else
					setButton(b, "Enter", "primary")
				end
			end
			onTick(update)
			onCash(update)
		end
	end,
}

---------------------------------------------------------------------
-- Drive
---------------------------------------------------------------------
local function arena(action)
	local ok, msg = request(ArenaRemote, action)
	if type(msg) == "string" then
		toast(msg, ok and "info" or "error")
	end
	if ok and action == "Practice" then
		closeSheet()
	end
	task.defer(renderOpen)
end

local function ModeTile(parent, x, eyebrow, title, lines)
	local tile = Frame({ Parent = parent, Color = C.Group, Radius = 18, Position = UDim2.new(x, x > 0 and 7 or 0, 0, 0), Size = UDim2.new(0.5, -7, 0, 206) })
	Text({ Parent = tile, Text = eyebrow, Style = "Caption", Color = C.Accent, Position = UDim2.new(0, 20, 0, 18), Size = UDim2.new(1, -40, 0, 16) })
	Text({ Parent = tile, Text = title, Style = "Title2", Wrap = false, Position = UDim2.new(0, 20, 0, 36), Size = UDim2.new(1, -40, 0, 28) })
	for i, line in ipairs(lines) do
		Text({ Parent = tile, Text = line, Style = "Subhead", Color = C.Secondary, Wrap = false, Position = UDim2.new(0, 20, 0, 72 + (i - 1) * 20), Size = UDim2.new(1, -40, 0, 20) })
	end
	return tile
end

panels.Drive = {
	Title = "Drive",
	Subtitle = "Practice on your own, or play ranked matches against other teams.",
	Render = function(root)
		if not State then
			return
		end
		local robot = State.Garage[State.Active]
		local driving = player:GetAttribute("Driving") == true
		local inQueue = player:GetAttribute("InQueue") == true
		local queueSize = Remotes:GetAttribute("QueueSize") or 0
		local matchLive = Remotes:GetAttribute("MatchLive") == true

		if driving then
			local tile = Frame({ Parent = root, Color = C.Group, Radius = 18, Size = UDim2.new(1, 0, 0, 96) })
			Text({ Parent = tile, Text = "You're driving.", Style = "Title2", Position = UDim2.new(0, 20, 0, 20), Size = UDim2.new(1, -220, 0, 28) })
			Text({ Parent = tile, Text = "Leaving a ranked match counts as a forfeit.", Style = "Subhead", Color = C.Secondary, Position = UDim2.new(0, 20, 0, 52), Size = UDim2.new(1, -220, 0, 20) })
			Button({ Parent = tile, Text = "Stop Driving", Kind = "primary", Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.new(0, 160, 0, 38) }, function()
				arena("Stop")
			end)
		else
			local practice = ModeTile(root, 0, "PRACTICE", "Practice Field", {
				"Drive freely with no opponents.",
				Config.Money(Config.Practice.CashPerPoint * State.Multiplier) .. " for every point you score.",
			})
			Button({ Parent = practice, Text = robot and "Start Driving" or "Build a Robot First", Kind = robot and "primary" or "disabled", Position = UDim2.new(0, 20, 1, -58), Size = UDim2.new(0, 170, 0, 38) }, function()
				arena("Practice")
			end)

			local status = matchLive and "A match is being played now." or (queueSize == 1 and "1 team waiting." or (queueSize .. " teams waiting."))
			local ranked = ModeTile(root, 0.5, "RANKED", "1v1 Match", {
				Config.Match.Duration .. " seconds. Win for +" .. Config.Match.WinTrophies .. " trophies.",
				status,
			})
			Button({ Parent = ranked, Text = not robot and "Build a Robot First" or (inQueue and "Leave Queue" or "Join Queue"), Kind = not robot and "disabled" or (inQueue and "secondary" or "primary"), Position = UDim2.new(0, 20, 1, -58), Size = UDim2.new(0, 170, 0, 38) }, function()
				arena("Queue")
			end)
		end

		local top = driving and 108 or 220
		Section(root, "Controls", UDim2.new(0, 16, 0, top - 4))
		local controls = Frame({ Parent = root, Color = C.Group, Radius = 14, Position = UDim2.new(0, 0, 0, top + 28), Size = UDim2.new(1, 0, 0, 132) })
		local entries = {
			{ { "W", "S" }, "Drive forward and back" },
			{ { "A", "D" }, "Turn" },
			{ { "Q", "E" }, "Strafe (Mecanum, X-Drive)" },
			{ { "F" }, "Score held balls in a goal" },
			{ { "Space" }, "Leave the robot" },
			{ { "Auto" }, "Intake picks up balls" },
		}
		for i, entry in ipairs(entries) do
			local col = (i - 1) % 2
			local rowIndex = math.floor((i - 1) / 2)
			local holder = Frame({ Parent = controls, Position = UDim2.new(col * 0.5, 16, 0, 12 + rowIndex * 38), Size = UDim2.new(0.5, -32, 0, 30) })
			local x = 0
			for _, key in ipairs(entry[1]) do
				local w = #key > 1 and 52 or 28
				Keycap(holder, key, UDim2.new(0, x, 0, 2), w)
				x += w + 6
			end
			Text({ Parent = holder, Text = entry[2], Style = "Subhead", Wrap = false, Position = UDim2.new(0, 72, 0, 0), Size = UDim2.new(1, -72, 1, 0) })
		end
	end,
}

---------------------------------------------------------------------
-- Season
---------------------------------------------------------------------
panels.Season = {
	Title = "Season",
	Subtitle = "Start a new season to permanently multiply your earnings.",
	Render = function(root)
		if not State then
			return
		end
		local cost = Config.GetSeasonCost(State.Season)
		local nowMult = Config.GetMultiplier(State.Season, false)
		local nextMult = Config.GetMultiplier(State.Season + 1, false)

		Text({ Parent = root, Text = "Season " .. State.Season, Style = "Display", TextSize = 40, Position = UDim2.new(0, 2, 0, 0), Size = UDim2.new(0.6, 0, 0, 46) })
		Text({ Parent = root, Text = string.format("Earnings %.1f× now, %.1f× next season.", nowMult, nextMult), Style = "Body", Color = C.Secondary, Position = UDim2.new(0, 2, 0, 48), Size = UDim2.new(0.6, 0, 0, 22) })
		local _, fill = Progress(root, UDim2.new(0, 2, 0, 88), UDim2.new(0.6, -2, 0, 6), 0)
		local progressText = Text({ Parent = root, Style = "Footnote", Color = C.Secondary, Position = UDim2.new(0, 2, 0, 98), Size = UDim2.new(0.6, 0, 0, 18) })
		local start = Button({ Parent = root, Kind = "primary", Text = "Start", TextSize = 16, Anchor = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 30), Size = UDim2.new(0, 230, 0, 44) }, function(b)
			if b:GetAttribute("Confirm") then
				act("Rebirth")
			else
				b:SetAttribute("Confirm", true)
				setButton(b, "Tap Again to Confirm")
				task.delay(3, function()
					if b.Parent then
						b:SetAttribute("Confirm", false)
						setButton(b, "Start Season " .. (State.Season + 1))
					end
				end)
			end
		end)
		onCash(function(money)
			local fraction = math.clamp(money / cost, 0, 1)
			tween(fill, { Size = UDim2.new(fraction, 0, 1, 0) })
			progressText.Text = Config.Money(money) .. " of " .. Config.Money(cost)
			if not start:GetAttribute("Confirm") then
				setButton(start, "Start Season " .. (State.Season + 1), money >= cost and "primary" or "disabled")
			end
		end)

		local unlocks = {}
		for _, slot in ipairs(Config.ModuleSlots) do
			for _, def in ipairs(Config.Modules[slot]) do
				if def.Season == State.Season + 1 then
					table.insert(unlocks, def.Name)
				end
			end
		end
		if #unlocks == 0 then
			unlocks = { "A higher multiplier" }
		end
		local columns = {
			{ "Resets", { "Cash", "Workshop", "Robot parts", "Robots" } },
			{ "Keeps", { "Trophies", "Stats", "Season multiplier" } },
			{ "Unlocks", unlocks },
		}
		for i, col in ipairs(columns) do
			local x = (i - 1) / 3
			Section(root, col[1], UDim2.new(x, 16, 0, 128))
			local group = Group(root, { Position = UDim2.new(x, i > 1 and 7 or 0, 0, 160), Size = UDim2.new(1 / 3, -10, 0, 0) })
			for k, line in ipairs(col[2]) do
				if k <= 4 then
					local r = Row(group, 38)
					Text({ Parent = r, Text = line, Style = "Callout", Wrap = false, Position = UDim2.new(0, 16, 0, 0), Size = UDim2.new(1, -32, 1, 0) })
				end
			end
		end

		local s = State.Stats
		local tiles = {
			{ s.CompWins .. " / " .. s.CompsEntered, "Tournaments won" },
			{ s.MatchesWon .. " / " .. s.MatchesPlayed, "Ranked wins" },
			{ Config.Format(s.BallsScored), "Balls scored" },
			{ tostring(s.RobotsBuilt), "Robots built" },
			{ Config.Money(s.TotalEarned), "Lifetime earnings" },
		}
		Section(root, "Your Team", UDim2.new(0, 16, 1, -100))
		local statsBox = Frame({ Parent = root, Color = C.Group, Radius = 14, Position = UDim2.new(0, 0, 1, -66), Size = UDim2.new(1, 0, 0, 66) })
		for i, tile in ipairs(tiles) do
			local cell = Frame({ Parent = statsBox, Position = UDim2.new((i - 1) / 5, 0, 0, 0), Size = UDim2.new(0.2, 0, 1, 0) })
			if i > 1 then
				Frame({ Parent = cell, Color = C.Separator, Position = UDim2.new(0, 0, 0.5, 0), Anchor = Vector2.new(0, 0.5), Size = UDim2.new(0, 1, 0, 34) })
			end
			Text({ Parent = cell, Text = tile[1], Font = F.Semi, TextSize = 19, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 6, 0, 12), Size = UDim2.new(1, -12, 0, 24) })
			Text({ Parent = cell, Text = tile[2], Style = "Caption", Color = C.Secondary, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 6, 0, 38), Size = UDim2.new(1, -12, 0, 16) })
		end
	end,
}

---------------------------------------------------------------------
-- Shop
---------------------------------------------------------------------
panels.Shop = {
	Title = "Shop",
	Subtitle = "Upgrades for your team. Yours forever.",
	Render = function(root)
		if not State then
			return
		end
		local group = Group(root)
		for _, pass in ipairs(Config.GamePasses) do
			local owned = State.Passes[pass.Key] == true
			local r = Row(group, 72)
			Text({ Parent = r, Text = pass.Name, Style = "Headline", Wrap = false, Position = UDim2.new(0, 18, 0, 14), Size = UDim2.new(1, -160, 0, 22) })
			Text({ Parent = r, Text = pass.Desc, Style = "Subhead", Color = C.Secondary, Wrap = false, Position = UDim2.new(0, 18, 0, 38), Size = UDim2.new(1, -160, 0, 20) })
			if owned then
				Text({ Parent = r, Text = "Owned", Font = F.Semi, TextSize = 15, Color = C.Secondary, AlignX = RIGHT, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -18, 0.5, 0), Size = UDim2.new(0, 100, 0, 20) })
			else
				Button({ Parent = r, Text = "Get", Kind = "get", Font = F.Bold, TextSize = 15, Anchor = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0, 76, 0, 30) }, function()
					act("PromptPass", pass.Key)
				end)
			end
		end
	end,
}

---------------------------------------------------------------------
-- Dock
---------------------------------------------------------------------
local DOCK = { "Lab", "Garage", "Compete", "Drive", "Season", "Shop" }
local DOCK_LABEL = { Lab = "Robot Lab", Garage = "Garage", Compete = "Compete", Drive = "Drive", Season = "Season", Shop = "Shop" }
local ITEM_W = 104

local dockHost = Frame({ Parent = mainGui, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.new(0, #DOCK * ITEM_W + 12, 0, 52) })
autoScale(dockHost)
local dock = Frame({ Parent = dockHost, Color = C.Sheet, Transparency = 0.08, Radius = "pill", Hairline = 0.9 })

for i, key in ipairs(DOCK) do
	local button = new("TextButton", { Parent = dock, AutoButtonColor = false, Text = "", BackgroundTransparency = 1, Position = UDim2.new(0, 6 + (i - 1) * ITEM_W, 0, 6), Size = UDim2.new(0, ITEM_W, 1, -12) })
	local pill = Frame({ Parent = button, Color = C.Fill, Transparency = 1, Radius = "pill" })
	local label = Text({ Parent = button, Text = DOCK_LABEL[key], Font = F.Semi, TextSize = 14, Color = C.Secondary, AlignX = CENTER, Wrap = false, Size = UDim2.fromScale(1, 1) })
	local dot = Frame({ Parent = button, Color = C.Accent, Radius = "pill", Anchor = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 7), Size = UDim2.new(0, 7, 0, 7), Visible = false })
	button.MouseEnter:Connect(function()
		if openName ~= key then
			label.TextColor3 = C.Label
		end
	end)
	button.MouseLeave:Connect(function()
		if openName ~= key then
			label.TextColor3 = C.Secondary
		end
	end)
	button.Activated:Connect(function()
		openSheet(key)
	end)
	dockItems[key] = { Pill = pill, Label = label, Dot = dot }
end

local function refreshDots()
	if not State then
		return
	end
	local money = cash()
	local robot = State.Garage[State.Active]
	local lab = false
	if State.Purchased.assembly then
		for _, slot in ipairs(Config.ModuleSlots) do
			for _, def in ipairs(Config.Modules[slot]) do
				if not State.Modules[def.Id] and (def.Season or 0) <= State.Season and money >= def.Cost then
					lab = true
				end
			end
		end
		if #State.Garage < State.GarageSlots and money >= Config.GetRobotStats(State.Loadout).BuildCost then
			lab = true
		end
	end
	local compete = false
	if robot then
		local rating = Config.GetRobotStats(robot).Rating
		for _, comp in ipairs(Config.Competitions) do
			if rating >= comp.MinRating and money >= comp.Fee and (cooldownEnds[comp.Id] or 0) <= os.clock() then
				compete = true
			end
		end
	end
	dockItems.Lab.Dot.Visible = lab
	dockItems.Compete.Dot.Visible = compete
	dockItems.Season.Dot.Visible = money >= Config.GetSeasonCost(State.Season)
	dockItems.Drive.Dot.Visible = robot ~= nil and (Remotes:GetAttribute("QueueSize") or 0) > 0 and not player:GetAttribute("InQueue")
end

---------------------------------------------------------------------
-- Match HUD
---------------------------------------------------------------------
local scoreHost = Frame({ Parent = mainGui, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 66), Size = UDim2.new(0, 420, 0, 60), Visible = false })
autoScale(scoreHost)
local scoreCapsule = Frame({ Parent = scoreHost, Color = C.Sheet, Transparency = 0.08, Radius = "pill", Hairline = 0.9 })

local function TeamSide(onRight, color)
	local side = Frame({ Parent = scoreCapsule, Position = UDim2.new(onRight and 0.62 or 0, 0, 0, 0), Size = UDim2.new(0.38, 0, 1, 0) })
	local align = onRight and RIGHT or LEFT
	Frame({ Parent = side, Color = color, Radius = "pill", Position = onRight and UDim2.new(1, -28, 0, 14) or UDim2.new(0, 22, 0, 14), Size = UDim2.new(0, 7, 0, 7) })
	local name = Text({ Parent = side, Style = "Caption", Color = C.Secondary, Wrap = false, AlignX = align, Position = onRight and UDim2.new(0, 8, 0, 8) or UDim2.new(0, 36, 0, 8), Size = UDim2.new(1, -44, 0, 18) })
	local score = Text({ Parent = side, Font = F.Bold, TextSize = 24, Wrap = false, AlignX = align, Position = onRight and UDim2.new(0, 8, 0, 26) or UDim2.new(0, 22, 0, 26), Size = UDim2.new(1, -30, 0, 28) })
	return side, name, score
end

local redSide, redName, redScore = TeamSide(false, C.TeamRed)
local blueSide, blueName, blueScore = TeamSide(true, C.TeamBlue)
local clock = Text({ Parent = scoreCapsule, Font = F.Semi, TextSize = 22, AlignX = CENTER, Wrap = false, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.new(0.24, 0, 0, 28) })
local clockSub = Text({ Parent = scoreCapsule, Style = "Caption", Color = C.Secondary, AlignX = CENTER, Wrap = false, Anchor = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 36), Size = UDim2.new(0.24, 0, 0, 14) })

local intakeHost = Frame({ Parent = mainGui, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.new(0, 520, 0, 80), Visible = false })
autoScale(intakeHost)
local hint = Text({ Parent = intakeHost, Style = "Footnote", Color = C.Secondary, AlignX = CENTER, Wrap = false, Size = UDim2.new(1, 0, 0, 18) })
local intakeCapsule = Frame({ Parent = intakeHost, Color = C.Sheet, Transparency = 0.08, Radius = "pill", Hairline = 0.9, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(0, 330, 0, 48) })
local dots = Frame({ Parent = intakeCapsule, Position = UDim2.new(0, 22, 0, 0), Size = UDim2.new(0, 120, 1, 0) })
new("UIListLayout", { Parent = dots, FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
local intakeText = Text({ Parent = intakeCapsule, Style = "Callout", Wrap = false, AlignX = RIGHT, Position = UDim2.new(0, 140, 0, 0), Size = UDim2.new(1, -162, 1, 0) })

local exitHost = Frame({ Parent = mainGui, Anchor = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -20), Size = UDim2.new(0, 140, 0, 40), Visible = false })
autoScale(exitHost)
Button({ Parent = exitHost, Text = "Exit Robot", Kind = "secondary", Size = UDim2.fromScale(1, 1) }, function()
	arena("Stop")
end)

local countdownHost = Frame({ Parent = modalGui, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.4), Size = UDim2.new(0, 400, 0, 180), Visible = false })
autoScale(countdownHost)
local countdownText = Text({ Parent = countdownHost, Font = F.Bold, TextSize = 132, AlignX = CENTER, Wrap = false, Size = UDim2.fromScale(1, 1) })

local matchHost = Frame({ Parent = modalGui, Anchor = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.new(0, 460, 0, 290), Visible = false })
autoScale(matchHost)
local matchSheet = Frame({ Parent = matchHost, Color = C.Sheet, Radius = 22, Hairline = 0.9 })
local matchTitle = Text({ Parent = matchSheet, Style = "Display", TextSize = 40, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 20, 0, 30), Size = UDim2.new(1, -40, 0, 48) })
local matchScore = Text({ Parent = matchSheet, Style = "Title2", AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 20, 0, 98), Size = UDim2.new(1, -40, 0, 30) })
local matchNames = Text({ Parent = matchSheet, Style = "Subhead", Color = C.Secondary, AlignX = CENTER, Wrap = false, Position = UDim2.new(0, 20, 0, 132), Size = UDim2.new(1, -40, 0, 20) })
Text({ Parent = matchSheet, Text = "Rewards have been added to your account.", Style = "Footnote", Color = C.Tertiary, AlignX = CENTER, Position = UDim2.new(0, 20, 0, 172), Size = UDim2.new(1, -40, 0, 18) })
Button({ Parent = matchSheet, Text = "Done", Kind = "primary", TextSize = 16, Anchor = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.new(0, 200, 0, 42) }, function()
	matchHost.Visible = false
	dim.Visible = false
end)

local lastCountdown, lastMatchState = nil, nil

local function flashCount(text)
	countdownHost.Visible = true
	countdownText.Text = text
	countdownText.TextTransparency = 0
	tween(countdownText, { TextTransparency = 1 }, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
end

local function buildDots(held, capacity)
	for _, child in ipairs(dots:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	for i = 1, capacity do
		Frame({ Parent = dots, Order = i, Color = i <= held and C.Label or C.Fill, Radius = "pill", Size = UDim2.new(0, 10, 0, 10) })
	end
end

local function renderArena()
	local mode = Arena.Mode
	local driving = isDriving()
	intakeHost.Visible = driving
	exitHost.Visible = driving
	scoreHost.Visible = driving
	dockHost.Visible = not driving
	if State then
		updateGoal(cash())
	end

	if driving then
		closeSheet()
		local held, capacity = Arena.Held or 0, Arena.Capacity or 1
		buildDots(held, capacity)
		intakeText.Text = held .. " of " .. capacity .. '  <font color="#98989F">·  ' .. (Arena.PointsPerBall or 1) .. " pts each</font>"
	end

	if mode == "Practice" then
		redSide.Visible, blueSide.Visible = true, false
		redName.Text = "PRACTICE"
		redScore.Text = tostring(Arena.Points or 0)
		clock.Text = "—"
		clockSub.Text = "POINTS"
		hint.Text = "W A S D  drive" .. (Arena.Strafe and "   ·   Q E  strafe" or "") .. "   ·   F  score   ·   Space  exit"
		countdownHost.Visible = false
	elseif mode == "Ranked" and Arena.Match then
		local m = Arena.Match
		redSide.Visible, blueSide.Visible = true, true
		redName.Text = string.upper(m.RedName) .. (m.Side == "Red" and "  ·  YOU" or "")
		blueName.Text = (m.Side == "Blue" and "YOU  ·  " or "") .. string.upper(m.BlueName)
		redScore.Text = tostring(m.Red)
		blueScore.Text = tostring(m.Blue)
		hint.Text = "Score in the " .. (m.Side == "Red" and "red" or "blue") .. " goal   ·   F  score   ·   Leaving forfeits"
		if m.State == "Countdown" then
			clock.Text = string.format("0:%02d", m.Countdown or 0)
			clockSub.Text = "STARTING"
			clock.TextColor3 = C.Label
			if m.Countdown ~= lastCountdown then
				flashCount(tostring(m.Countdown or ""))
			end
			lastCountdown = m.Countdown
		else
			local t = m.Time or 0
			clock.Text = string.format("%d:%02d", math.floor(t / 60), t % 60)
			clockSub.Text = "LIVE"
			clock.TextColor3 = t <= 10 and C.Accent or C.Label
			if lastMatchState == "Countdown" then
				flashCount("Go")
			end
		end
		lastMatchState = m.State
	else
		countdownHost.Visible = false
		lastMatchState, lastCountdown = nil, nil
	end

	if mode == "Result" then
		local titles = { Win = "Victory", Loss = "Defeat", Tie = "Tie", Forfeit = "Forfeit" }
		matchTitle.Text = titles[Arena.Result] or "Match Over"
		matchTitle.TextColor3 = Arena.Result == "Win" and C.Label or C.Secondary
		matchScore.Text = '<font color="#FF453A">' .. (Arena.Red or 0) .. "</font>  –  " .. '<font color="#0A84FF">' .. (Arena.Blue or 0) .. "</font>"
		matchNames.Text = (Arena.RedName or "Red") .. "  vs  " .. (Arena.BlueName or "Blue")
		dim.Visible = true
		matchHost.Visible = true
		matchSheet.BackgroundTransparency = 1
		tween(matchSheet, { BackgroundTransparency = 0 })
		Arena = { Mode = "None" }
	end
end

ArenaState.OnClientEvent:Connect(function(info)
	Arena = info or { Mode = "None" }
	renderArena()
end)

---------------------------------------------------------------------
-- Wiring
---------------------------------------------------------------------
DataUpdate.OnClientEvent:Connect(function(snapshot)
	State = snapshot
	for compId, remaining in pairs(snapshot.Cooldowns or {}) do
		cooldownEnds[compId] = os.clock() + remaining
	end
	updateStatus()
	refreshDots()
	renderOpen()
end)

OpenUIRemote.OnClientEvent:Connect(function(name)
	if panels[name] and not isDriving() and openName ~= name then
		openSheet(name)
	end
end)

task.spawn(function()
	local stats = player:WaitForChild("leaderstats")
	local cashValue = stats:WaitForChild("Cash")
	setCash(cashValue.Value)
	cashValue.Changed:Connect(function(value)
		setCash(value)
		for _, fn in ipairs(live.Cash) do
			fn(value)
		end
		if State then
			updateGoal(value)
		end
	end)
end)

local function rerenderDrive()
	refreshDots()
	if openName == "Drive" then
		renderOpen()
	end
end
player:GetAttributeChangedSignal("InQueue"):Connect(rerenderDrive)
player:GetAttributeChangedSignal("Driving"):Connect(rerenderDrive)
Remotes:GetAttributeChangedSignal("QueueSize"):Connect(rerenderDrive)

task.spawn(function()
	while true do
		task.wait(1)
		for _, fn in ipairs(live.Tick) do
			fn()
		end
		refreshDots()
	end
end)

local function hookCamera(cam)
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
	end
	updateScale()
end
hookCamera(workspace.CurrentCamera)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	hookCamera(workspace.CurrentCamera)
end)

task.spawn(function()
	for _ = 1, 20 do
		local ok, snapshot = pcall(RequestRemote.InvokeServer, RequestRemote, "GetData")
		if ok and type(snapshot) == "table" then
			if not State then
				State = snapshot
				updateStatus()
				refreshDots()
			end
			return
		end
		task.wait(1)
	end
end)
