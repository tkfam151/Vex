--[[
	SimServer (Script)  ->  ServerScriptService.SimServer

	Garden:  buy seeds at the Seed Shop (restocks every few minutes), plant
	         them in the beds at your workshop, harvest when ripe, sell your
	         backpack at the Sell Stand. Crops keep growing while you're away.
	Market:  robots ride the Robot Market conveyor in the hub. Buy one and it
	         stands on a showcase pad at your base, filling it with cash.
	Steal:   hold the prompt on someone else's robot, then carry it back to
	         your own base. The owner gets it back by catching you. Step on
	         your lock pad to raise laser walls for a minute.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local RobotBuilder = require(ReplicatedStorage:WaitForChild("RobotBuilder"))
local DataManager = require(ServerScriptService:WaitForChild("DataManager"))
local WorldBuilder = require(ServerScriptService:WaitForChild("WorldBuilder"))

local Remotes = DataManager.Remotes
local World = WorldBuilder.GetWorld()
local Hub = World.Hub
local Garden = Config.Garden
local Market = Config.Market

local function notify(player, text, kind)
	DataManager.Notify(player, text, kind)
end

local function plotOf(player)
	for _, plot in ipairs(World.Plots) do
		if plot.Owner == player then
			return plot
		end
	end
	return nil
end

local function rarityColor(rarity)
	local r = Config.Rarities[rarity]
	return r and r.Color or Color3.new(1, 1, 1)
end

local function rootOf(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and humanoid.Health > 0 and root then
		return root, humanoid, character
	end
	return nil, nil, nil
end

-- true if a world position is inside a plot's square
local function insidePlot(plot, position)
	local localPos = plot.CFrame:PointToObjectSpace(position)
	local half = Config.PlotSize / 2
	return math.abs(localPos.X) <= half and math.abs(localPos.Z) <= half
end

---------------------------------------------------------------------
-- Seed shop stock
---------------------------------------------------------------------
local globalStock = {}

local function rollStock()
	local stock = {}
	for _, seed in ipairs(Config.Seeds) do
		local rule = Garden.Stock[seed.Rarity]
		if rule and math.random() <= rule.Chance then
			stock[seed.Id] = math.random(rule.Min, rule.Max)
		end
	end
	return stock
end

local function restock()
	globalStock = rollStock()
	Remotes.Folder:SetAttribute("RestockAt", os.time() + Garden.RestockInterval)
	for player, runtime in pairs(DataManager.Runtime) do
		runtime.Stock = DataManager.DeepCopy(globalStock)
		if player.Parent then
			DataManager.MarkChanged(player)
		end
	end
end

task.spawn(function()
	restock()
	while true do
		task.wait(Garden.RestockInterval)
		restock()
		for _, player in ipairs(Players:GetPlayers()) do
			notify(player, "The Seed Shop has restocked!", "info")
		end
	end
end)

---------------------------------------------------------------------
-- Garden beds
---------------------------------------------------------------------
local function rollGardenMutation()
	for _, m in ipairs(Garden.Mutations) do
		if math.random() < m.Chance then
			return m.Name
		end
	end
	return nil
end

local function growthOf(entry)
	local seed = Config.SeedById[entry.S]
	if not seed then
		return 1, 0
	end
	local elapsed = os.time() - entry.T
	return math.clamp(elapsed / seed.GrowTime, 0, 1), math.max(0, seed.GrowTime - elapsed)
end

local function renderTile(plot, tile)
	local data = plot.Owner and DataManager.Get(plot.Owner)
	local entry = data and data.Garden[tile.Key]
	local model = tile.Model
	if not entry then
		if model then
			model:Destroy()
			tile.Model = nil
		end
		tile.Prompt.ActionText = "Plant"
		tile.Prompt.ObjectText = "Empty Bed"
		return
	end
	local seed = Config.SeedById[entry.S]
	if not seed then
		data.Garden[tile.Key] = nil
		return
	end
	local mutation = entry.M and Config.GetMutation(entry.M)
	local progress, remaining = growthOf(entry)
	local top = tile.Part.CFrame * CFrame.new(0, tile.Part.Size.Y / 2, 0)

	if not model then
		model = Instance.new("Model")
		model.Name = "Plant"
		local stem = Instance.new("Part")
		stem.Name = "Stem"
		stem.Anchored = true
		stem.CanCollide = false
		stem.CanQuery = false
		stem.Color = Color3.fromRGB(70, 170, 60)
		stem.Material = Enum.Material.SmoothPlastic
		stem.Parent = model
		local fruit = Instance.new("Part")
		fruit.Name = "Fruit"
		fruit.Shape = Enum.PartType.Ball
		fruit.Anchored = true
		fruit.CanCollide = false
		fruit.CanQuery = false
		fruit.Material = Enum.Material.SmoothPlastic
		fruit.Parent = model
		for _, side in ipairs({ -1, 1 }) do
			local leaf = Instance.new("Part")
			leaf.Name = "Leaf"
			leaf.Anchored = true
			leaf.CanCollide = false
			leaf.CanQuery = false
			leaf.Color = Color3.fromRGB(90, 200, 70)
			leaf.Material = Enum.Material.SmoothPlastic
			leaf:SetAttribute("Side", side)
			leaf.Parent = model
		end
		local gui = Instance.new("BillboardGui")
		gui.Name = "Tag"
		gui.Size = UDim2.new(7, 0, 2, 0)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 7.5, 0)
		gui.MaxDistance = 60
		gui.LightInfluence = 0
		gui.Adornee = tile.Part
		gui.Parent = model
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.FontFace = Font.fromEnum(Enum.Font.FredokaOne)
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Parent = label
		model.Parent = plot.Items.Parent
		tile.Model = model
	end

	local stemHeight = 0.8 + 3.2 * progress
	local fruitSize = 0.6 + 2.6 * progress
	model.Stem.Size = Vector3.new(0.5, stemHeight, 0.5)
	model.Stem.CFrame = top * CFrame.new(0, stemHeight / 2, 0)
	for _, leaf in ipairs(model:GetChildren()) do
		if leaf.Name == "Leaf" then
			local side = leaf:GetAttribute("Side")
			leaf.Size = Vector3.new(0.6 + 1.6 * progress, 0.2, 0.8 + 0.8 * progress)
			leaf.CFrame = top * CFrame.new(side * (0.4 + 0.8 * progress), stemHeight * 0.45, 0) * CFrame.Angles(0, 0, math.rad(side * 20))
		end
	end
	model.Fruit.Size = Vector3.one * fruitSize
	model.Fruit.CFrame = top * CFrame.new(0, stemHeight + fruitSize * 0.35, 0)
	model.Fruit.Color = mutation and mutation.Color or seed.Color
	model.Fruit.Material = mutation and Enum.Material.Neon or Enum.Material.SmoothPlastic

	local label = model.Tag.Label
	local name = (mutation and (mutation.Name .. " ") or "") .. seed.Name
	if progress >= 1 then
		label.Text = name .. "\nREADY!"
		label.TextColor3 = Color3.fromRGB(120, 255, 100)
		tile.Prompt.ActionText = "Harvest"
	else
		label.Text = name .. "\n" .. (remaining >= 60 and string.format("%dm %ds", remaining // 60, remaining % 60) or (remaining .. "s"))
		label.TextColor3 = Color3.new(1, 1, 1)
		tile.Prompt.ActionText = "Growing..."
	end
	tile.Prompt.ObjectText = name
end

local function renderGarden(plot)
	for _, tile in ipairs(plot.GardenTiles) do
		renderTile(plot, tile)
	end
end

local function clearGarden(plot)
	for _, tile in ipairs(plot.GardenTiles) do
		if tile.Model then
			tile.Model:Destroy()
			tile.Model = nil
		end
		tile.Prompt.Enabled = false
	end
end

local function onBedTriggered(plot, tile, player)
	if player ~= plot.Owner then
		notify(player, "That's someone else's garden!", "error")
		return
	end
	local data = DataManager.Get(player)
	local runtime = DataManager.Runtime[player]
	if not data or not runtime then
		return
	end
	local entry = data.Garden[tile.Key]
	if entry then
		local progress, remaining = growthOf(entry)
		if progress < 1 then
			notify(player, "Still growing. Ready in " .. remaining .. "s", "info")
			return
		end
		if #data.Backpack >= Garden.MaxBackpack then
			notify(player, "Your backpack is full! Sell at the Sell Stand.", "error")
			return
		end
		local seed = Config.SeedById[entry.S]
		local mutation = entry.M and Config.GetMutation(entry.M)
		local value = math.floor(seed.Value * (mutation and mutation.Multiplier or 1))
		table.insert(data.Backpack, { S = entry.S, M = entry.M, V = value })
		data.Garden[tile.Key] = nil
		data.Stats.Harvests += 1
		notify(player, "Harvested " .. (entry.M and (entry.M .. " ") or "") .. seed.Name .. " (" .. Config.Money(value) .. ")", "success")
		renderTile(plot, tile)
		DataManager.MarkChanged(player)
		return
	end

	-- plant: use the selected seed, otherwise the first one you own
	local seedId = runtime.SelectedSeed
	if not seedId or (data.Seeds[seedId] or 0) <= 0 then
		seedId = nil
		for _, seed in ipairs(Config.Seeds) do
			if (data.Seeds[seed.Id] or 0) > 0 then
				seedId = seed.Id
				break
			end
		end
	end
	if not seedId then
		notify(player, "You have no seeds. Buy some at the Seed Shop!", "error")
		return
	end
	data.Seeds[seedId] -= 1
	if data.Seeds[seedId] <= 0 then
		data.Seeds[seedId] = nil
	end
	local mutation = rollGardenMutation()
	data.Garden[tile.Key] = { S = seedId, T = os.time(), M = mutation }
	if mutation then
		notify(player, "Lucky! Your " .. Config.SeedById[seedId].Name .. " is growing " .. mutation .. "!", "success")
	end
	renderTile(plot, tile)
	DataManager.MarkChanged(player)
end

for _, plot in ipairs(World.Plots) do
	for _, tile in ipairs(plot.GardenTiles) do
		tile.Prompt.Triggered:Connect(function(player)
			onBedTriggered(plot, tile, player)
		end)
	end
end

local function sellBackpack(player)
	local data = DataManager.Get(player)
	if not data then
		return false, "Data still loading"
	end
	if #data.Backpack == 0 then
		return false, "Your backpack is empty. Harvest some crops first!"
	end
	local total = 0
	for _, item in ipairs(data.Backpack) do
		total += item.V or 0
	end
	local count = #data.Backpack
	data.Backpack = {}
	local earned = DataManager.AddCash(player, total, true)
	DataManager.MarkChanged(player)
	return true, "Sold " .. count .. " crops for " .. Config.Money(earned) .. "!"
end

Hub.SellPrompt.Triggered:Connect(function(player)
	local ok, msg = sellBackpack(player)
	notify(player, msg, ok and "cash" or "error")
end)

Hub.SeedPrompt.Triggered:Connect(function(player)
	Remotes.OpenUI:FireClient(player, "Seeds")
end)

---------------------------------------------------------------------
-- Showcase pads (market robots at your base)
---------------------------------------------------------------------
local carries = {} -- [thief] = carry
local stealingPads = {} -- [plot][key] = true while a pad's robot is being carried

local startSteal -- forward

local function buildShowcaseRobot(entry, label, sub)
	local species = Config.SpeciesById[entry.S]
	local mutation = entry.M and Config.GetMarketMutation(entry.M)
	local model = RobotBuilder.Build(species.Loadout, {
		Label = (entry.M and (entry.M .. " ") or "") .. (label or species.Name),
		SubLabel = sub,
		TitleColor = rarityColor(species.Rarity),
		Tint = mutation and mutation.Tint or nil,
	})
	model:ScaleTo(species.Scale)
	return model, species
end

local function renderPad(plot, pad)
	if pad.Model then
		pad.Model:Destroy()
		pad.Model = nil
	end
	local data = plot.Owner and DataManager.Get(plot.Owner)
	local entry = data and data.Showcase[pad.Key]
	pad.Stored = pad.Stored or 0
	if not entry or not Config.SpeciesById[entry.S] then
		pad.Label.Text = ""
		pad.Part.Color = Color3.fromRGB(240, 240, 245)
		return
	end
	if stealingPads[plot] and stealingPads[plot][pad.Key] then
		pad.Label.Text = "BEING STOLEN!"
		pad.Label.TextColor3 = Color3.fromRGB(255, 90, 90)
		return
	end
	local species = Config.SpeciesById[entry.S]
	local mult = DataManager.GetMultiplier(plot.Owner)
	local model = buildShowcaseRobot(entry, nil, species.Rarity .. "  +" .. Config.Money(Config.ShowcaseIncome(entry) * mult) .. "/s")
	local scale = species.Scale
	model:PivotTo(pad.Part.CFrame * CFrame.new(0, pad.Part.Size.Y / 2 + scale, 0) * CFrame.Angles(0, math.pi, 0))
	model.Parent = plot.Bays.Parent
	pad.Model = model
	pad.Part.Color = rarityColor(species.Rarity)

	local stealPrompt = Instance.new("ProximityPrompt")
	stealPrompt.ActionText = "Steal"
	stealPrompt.ObjectText = species.Name
	stealPrompt.HoldDuration = Market.StealHold
	stealPrompt.MaxActivationDistance = 10
	stealPrompt.RequiresLineOfSight = false
	stealPrompt.Parent = model.PrimaryPart
	stealPrompt.Triggered:Connect(function(thief)
		startSteal(thief, plot, pad)
	end)
	pad.Label.TextColor3 = Color3.fromRGB(120, 255, 100)
	pad.Label.Text = pad.Stored >= 1 and Config.Money(pad.Stored) or ""
end

local function renderShowcase(plot)
	for _, pad in ipairs(plot.ShowcasePads) do
		renderPad(plot, pad)
	end
end

local function clearShowcase(plot)
	for _, pad in ipairs(plot.ShowcasePads) do
		if pad.Model then
			pad.Model:Destroy()
			pad.Model = nil
		end
		pad.Stored = 0
		pad.Label.Text = ""
		pad.Part.Color = Color3.fromRGB(240, 240, 245)
	end
end

local function freePadKey(data)
	for i = 1, #Market.PadRows * #Market.PadColumns do
		local key = "p" .. i
		if not data.Showcase[key] then
			return key
		end
	end
	return nil
end

local function padByKey(plot, key)
	for _, pad in ipairs(plot.ShowcasePads) do
		if pad.Key == key then
			return pad
		end
	end
	return nil
end

-- collect stored cash by stepping on a pad
for _, plot in ipairs(World.Plots) do
	for _, pad in ipairs(plot.ShowcasePads) do
		pad.Stored = 0
		local last = 0
		pad.Part.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player or player ~= plot.Owner or (pad.Stored or 0) < 1 or os.clock() - last < 0.4 then
				return
			end
			last = os.clock()
			local amount = DataManager.AddCash(player, pad.Stored, false)
			pad.Stored = 0
			pad.Label.Text = ""
			notify(player, "+" .. Config.Money(amount) .. " collected", "cash")
		end)
	end
end

-- income tick
task.spawn(function()
	while true do
		task.wait(1)
		for _, plot in ipairs(World.Plots) do
			local owner = plot.Owner
			local data = owner and DataManager.Get(owner)
			if data then
				local mult = DataManager.GetMultiplier(owner)
				local auto = DataManager.HasPass(owner, "AutoCollect")
				for _, pad in ipairs(plot.ShowcasePads) do
					local entry = data.Showcase[pad.Key]
					if entry and not (stealingPads[plot] and stealingPads[plot][pad.Key]) then
						local income = Config.ShowcaseIncome(entry) * mult
						if auto then
							DataManager.AddCash(owner, income, false)
						else
							pad.Stored = (pad.Stored or 0) + income
							pad.Label.Text = Config.Money(pad.Stored)
						end
					end
				end
			end
		end
	end
end)

---------------------------------------------------------------------
-- Robot Market conveyor
---------------------------------------------------------------------
local runway = {} -- list of { Model, Species, Mutation, Distance }
local direction = (Market.End - Market.Start).Unit
local runwayLength = (Market.End - Market.Start).Magnitude

local function pickSpecies()
	local total = 0
	for _, rarity in ipairs(Config.RarityOrder) do
		total += Config.Rarities[rarity].Weight
	end
	local roll = math.random() * total
	local chosen = "Common"
	for _, rarity in ipairs(Config.RarityOrder) do
		roll -= Config.Rarities[rarity].Weight
		if roll <= 0 then
			chosen = rarity
			break
		end
	end
	local pool = {}
	for _, sp in ipairs(Config.Species) do
		if sp.Rarity == chosen then
			table.insert(pool, sp)
		end
	end
	if #pool == 0 then
		return Config.Species[1]
	end
	return pool[math.random(1, #pool)]
end

local function rollMarketMutation()
	for _, m in ipairs(Market.Mutations) do
		if math.random() < m.Chance then
			return m.Name
		end
	end
	return nil
end

local function runwayCFrame(item)
	local pos = Market.Start + direction * item.Distance
	return CFrame.lookAt(pos, pos + direction) * CFrame.new(0, item.Species.Scale, 0)
end

local function buyFromRunway(player, item)
	if not item.Model.Parent then
		return
	end
	local data = DataManager.Get(player)
	local plot = plotOf(player)
	if not data or not plot then
		notify(player, "You need a workshop to buy robots.", "error")
		return
	end
	local key = freePadKey(data)
	if not key then
		notify(player, "All your showcase pads are full!", "error")
		return
	end
	local price = item.Species.Price
	if not DataManager.SpendCash(player, price) then
		notify(player, "You need " .. Config.Money(price - data.Cash) .. " more!", "error")
		return
	end
	for i, other in ipairs(runway) do
		if other == item then
			table.remove(runway, i)
			break
		end
	end
	item.Model:Destroy()
	data.Showcase[key] = { S = item.Species.Id, M = item.Mutation }
	local pad = padByKey(plot, key)
	if pad then
		renderPad(plot, pad)
	end
	notify(player, "You bought " .. (item.Mutation and (item.Mutation .. " ") or "") .. item.Species.Name .. "! It's at your base.", "success")
	DataManager.MarkChanged(player)
end

local function spawnRunwayRobot()
	local species = pickSpecies()
	local mutation = rollMarketMutation()
	local entry = { S = species.Id, M = mutation }
	local model = buildShowcaseRobot(entry, nil, Config.Money(species.Price) .. "  ·  +" .. Config.Money(Config.ShowcaseIncome(entry)) .. "/s")
	local item = { Model = model, Species = species, Mutation = mutation, Distance = 0 }
	model:PivotTo(runwayCFrame(item))
	model.Parent = Hub.MarketFolder
	local buyPrompt = Instance.new("ProximityPrompt")
	buyPrompt.ActionText = "Buy " .. Config.Money(species.Price)
	buyPrompt.ObjectText = (mutation and (mutation .. " ") or "") .. species.Name .. " (" .. species.Rarity .. ")"
	buyPrompt.HoldDuration = 0.25
	buyPrompt.MaxActivationDistance = 12
	buyPrompt.RequiresLineOfSight = false
	buyPrompt.Parent = model.PrimaryPart
	buyPrompt.Triggered:Connect(function(player)
		buyFromRunway(player, item)
	end)
	table.insert(runway, item)
	if Config.RarityOrder[5] == species.Rarity or Config.RarityOrder[6] == species.Rarity then
		for _, player in ipairs(Players:GetPlayers()) do
			notify(player, "A " .. species.Rarity .. " " .. species.Name .. " is on the Robot Market!", "info")
		end
	end
end

task.spawn(function()
	while true do
		spawnRunwayRobot()
		task.wait(Market.SpawnInterval)
	end
end)

RunService.Heartbeat:Connect(function(dt)
	for i = #runway, 1, -1 do
		local item = runway[i]
		item.Distance += Market.Speed * dt
		if item.Distance >= runwayLength or not item.Model.Parent then
			item.Model:Destroy()
			table.remove(runway, i)
		else
			item.Model:PivotTo(runwayCFrame(item))
		end
	end
end)

---------------------------------------------------------------------
-- Stealing
---------------------------------------------------------------------
local function isLocked(plot)
	return os.time() < (plot.LockedUntil or 0)
end

local function endCarry(carry, success, reason)
	carries[carry.Thief] = nil
	if stealingPads[carry.Plot] then
		stealingPads[carry.Plot][carry.Key] = nil
	end
	if carry.Visual then
		carry.Visual:Destroy()
	end
	local _, humanoid = rootOf(carry.Thief)
	if humanoid then
		humanoid.WalkSpeed = carry.OldSpeed or 16
	end
	carry.Thief:SetAttribute("Carrying", nil)

	local ownerData = carry.Owner.Parent and DataManager.Get(carry.Owner)
	if success and ownerData and ownerData.Showcase[carry.Key] then
		local thiefData = DataManager.Get(carry.Thief)
		local thiefPlot = plotOf(carry.Thief)
		local key = thiefData and freePadKey(thiefData)
		if thiefData and thiefPlot and key then
			local entry = ownerData.Showcase[carry.Key]
			ownerData.Showcase[carry.Key] = nil
			thiefData.Showcase[key] = entry
			thiefData.Stats.Steals += 1
			local name = Config.SpeciesById[entry.S].Name
			notify(carry.Thief, "You stole " .. name .. "!", "success")
			notify(carry.Owner, carry.Thief.DisplayName .. " stole your " .. name .. "!", "error")
			local pad = padByKey(thiefPlot, key)
			if pad then
				renderPad(thiefPlot, pad)
			end
			DataManager.MarkChanged(carry.Thief)
			DataManager.MarkChanged(carry.Owner)
		else
			success = false
			reason = "You have no free pads!"
		end
	end
	if not success then
		if reason then
			notify(carry.Thief, reason, "error")
		end
		if carry.Owner.Parent and reason == "Caught!" then
			notify(carry.Owner, "You got your robot back!", "success")
		end
	end
	if carry.Plot.Owner == carry.Owner then
		local pad = padByKey(carry.Plot, carry.Key)
		if pad then
			renderPad(carry.Plot, pad)
		end
	end
end

function startSteal(thief, plot, pad)
	local owner = plot.Owner
	if not owner or thief == owner then
		if thief == owner then
			notify(thief, "That's your robot! Step on its pad to collect cash.", "info")
		end
		return
	end
	if carries[thief] then
		notify(thief, "You're already carrying a robot!", "error")
		return
	end
	if isLocked(plot) then
		notify(thief, "This base is locked!", "error")
		return
	end
	local ownerData = DataManager.Get(owner)
	local thiefData = DataManager.Get(thief)
	local entry = ownerData and ownerData.Showcase[pad.Key]
	if not entry or not thiefData then
		return
	end
	if not plotOf(thief) then
		notify(thief, "You need a workshop to steal robots.", "error")
		return
	end
	if not freePadKey(thiefData) then
		notify(thief, "Your showcase pads are full!", "error")
		return
	end
	local root, humanoid, character = rootOf(thief)
	if not root then
		return
	end
	if stealingPads[plot] and stealingPads[plot][pad.Key] then
		return
	end

	stealingPads[plot] = stealingPads[plot] or {}
	stealingPads[plot][pad.Key] = true

	-- carried copy above the thief's head
	local visual = buildShowcaseRobot(entry, nil, "STOLEN")
	visual:ScaleTo(0.4 * Config.SpeciesById[entry.S].Scale)
	for _, d in ipairs(visual:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
			d.Massless = true
		end
	end
	visual:PivotTo(root.CFrame * CFrame.new(0, 4.5, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = visual.PrimaryPart
	weld.Parent = visual.PrimaryPart
	visual.Parent = character

	local carry = {
		Thief = thief,
		Owner = owner,
		Plot = plot,
		Key = pad.Key,
		Visual = visual,
		Started = os.clock(),
		OldSpeed = humanoid.WalkSpeed,
	}
	carries[thief] = carry
	humanoid.WalkSpeed = Market.CarrySpeed
	thief:SetAttribute("Carrying", true)
	renderPad(plot, pad)
	notify(thief, "Run back to your base!", "info")
	notify(owner, thief.DisplayName .. " is stealing your " .. Config.SpeciesById[entry.S].Name .. "! Catch them!", "error")
end

task.spawn(function()
	while true do
		task.wait(0.15)
		for thief, carry in pairs(carries) do
			local root = rootOf(thief)
			if not thief.Parent or not root then
				endCarry(carry, false, nil)
			elseif not carry.Owner.Parent or carry.Plot.Owner ~= carry.Owner then
				endCarry(carry, false, "The owner left.")
			elseif os.clock() - carry.Started > Market.StealTimeout then
				endCarry(carry, false, "You took too long!")
			else
				local ownerRoot = rootOf(carry.Owner)
				local thiefPlot = plotOf(thief)
				if ownerRoot and (ownerRoot.Position - root.Position).Magnitude <= Market.RecoverDistance then
					endCarry(carry, false, "Caught!")
				elseif thiefPlot and insidePlot(thiefPlot, root.Position) then
					endCarry(carry, true, nil)
				end
			end
		end
	end
end)

---------------------------------------------------------------------
-- Base lock
---------------------------------------------------------------------
local function setLasers(plot, on)
	for _, laser in ipairs(plot.Lasers) do
		laser.Transparency = on and 0.55 or 1
	end
end

for _, plot in ipairs(World.Plots) do
	local last = 0
	plot.LockPad.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player or player ~= plot.Owner or os.clock() - last < 1 then
			return
		end
		last = os.clock()
		local now = os.time()
		if isLocked(plot) then
			return
		end
		if now < (plot.LockReadyAt or 0) then
			notify(player, "Lock recharging: " .. (plot.LockReadyAt - now) .. "s", "error")
			return
		end
		plot.LockedUntil = now + Market.LockDuration
		plot.LockReadyAt = plot.LockedUntil + Market.LockCooldown
		setLasers(plot, true)
		notify(player, "Base locked for " .. Market.LockDuration .. " seconds!", "success")
		DataManager.MarkChanged(player)
	end)
	for _, laser in ipairs(plot.Lasers) do
		laser.Touched:Connect(function(hit)
			if not isLocked(plot) then
				return
			end
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player or player == plot.Owner then
				return
			end
			local root = hit.Parent:FindFirstChild("HumanoidRootPart")
			if root then
				local localPos = plot.CFrame:PointToObjectSpace(root.Position)
				local outward = plot.CFrame:VectorToWorldSpace(Vector3.new(localPos.X, 0, localPos.Z).Unit)
				root.CFrame = root.CFrame + outward * 8
				root.AssemblyLinearVelocity = outward * 60 + Vector3.new(0, 30, 0)
			end
		end)
	end
end

task.spawn(function()
	while true do
		task.wait(1)
		local now = os.time()
		for _, plot in ipairs(World.Plots) do
			if plot.Owner then
				if isLocked(plot) then
					plot.LockLabel.Text = "LOCKED  " .. (plot.LockedUntil - now) .. "s"
				else
					if plot.Lasers[1].Transparency < 1 then
						setLasers(plot, false)
					end
					local wait = (plot.LockReadyAt or 0) - now
					plot.LockLabel.Text = wait > 0 and ("RECHARGING  " .. wait .. "s") or "LOCK BASE"
				end
				renderGarden(plot)
			end
		end
	end
end)

---------------------------------------------------------------------
-- Plot lifecycle
---------------------------------------------------------------------
local function setupPlot(player, plot)
	plot.LockedUntil = 0
	plot.LockReadyAt = 0
	setLasers(plot, false)
	for _, tile in ipairs(plot.GardenTiles) do
		tile.Prompt.Enabled = true
	end
	renderGarden(plot)
	renderShowcase(plot)
	local runtime = DataManager.Runtime[player]
	if runtime then
		runtime.Stock = runtime.Stock or DataManager.DeepCopy(globalStock)
	end
end

local function teardownPlot(player, plot)
	-- bank any uncollected pad cash
	local total = 0
	for _, pad in ipairs(plot.ShowcasePads) do
		total += pad.Stored or 0
	end
	if total > 0 and DataManager.Get(player) then
		DataManager.AddCash(player, total, false)
	end
	for thief, carry in pairs(carries) do
		if carry.Plot == plot or thief == player then
			endCarry(carry, false, "The steal was cancelled.")
		end
	end
	stealingPads[plot] = nil
	clearGarden(plot)
	clearShowcase(plot)
	setLasers(plot, false)
	plot.LockedUntil = 0
	plot.LockReadyAt = 0
end

DataManager.PlotClaimed:Connect(setupPlot)
DataManager.PlotReleased:Connect(teardownPlot)
DataManager.ProgressReset:Connect(function(player)
	local plot = plotOf(player)
	if plot then
		teardownPlot(player, plot)
		setupPlot(player, plot)
	end
end)

for _, plot in ipairs(World.Plots) do
	if plot.Owner then
		setupPlot(plot.Owner, plot)
	end
end

Players.PlayerAdded:Connect(function(player)
	-- stock for players who join between restocks
	task.spawn(function()
		for _ = 1, 30 do
			local runtime = DataManager.Runtime[player]
			if runtime then
				runtime.Stock = runtime.Stock or DataManager.DeepCopy(globalStock)
				DataManager.MarkChanged(player)
				return
			end
			task.wait(1)
		end
	end)
end)

---------------------------------------------------------------------
-- Requests from the UI
---------------------------------------------------------------------
local Actions = {}

function Actions.BuySeed(player, data, runtime, seedId)
	local seed = Config.SeedById[seedId]
	if not seed then
		return false, "Unknown seed"
	end
	runtime.Stock = runtime.Stock or {}
	if (runtime.Stock[seedId] or 0) <= 0 then
		return false, seed.Name .. " is sold out. Wait for the restock!"
	end
	if not DataManager.SpendCash(player, seed.Price) then
		return false, "You need " .. Config.Money(seed.Price - data.Cash) .. " more"
	end
	runtime.Stock[seedId] -= 1
	data.Seeds[seedId] = (data.Seeds[seedId] or 0) + 1
	runtime.SelectedSeed = runtime.SelectedSeed or seedId
	DataManager.MarkChanged(player)
	return true, "Bought " .. seed.Name .. " seed"
end

function Actions.SelectSeed(player, data, runtime, seedId)
	if not Config.SeedById[seedId] or (data.Seeds[seedId] or 0) <= 0 then
		return false, "You don't have that seed"
	end
	runtime.SelectedSeed = seedId
	DataManager.MarkChanged(player)
	return true, Config.SeedById[seedId].Name .. " selected. Plant it in a garden bed!"
end

function Actions.SellAll(player)
	local root = rootOf(player)
	if not root or (root.Position - Hub.SellPosition).Magnitude > Garden.SellDistance then
		return false, "Go to the Sell Stand in the hub to sell!"
	end
	return sellBackpack(player)
end

Remotes.SimRequest.OnServerInvoke = function(player, action, ...)
	local handler = Actions[action]
	local data = DataManager.Get(player)
	local runtime = DataManager.Runtime[player]
	if not handler then
		return false, "Unknown action"
	end
	if not data or not runtime then
		return false, "Your data is still loading..."
	end
	local ok, a, b = pcall(handler, player, data, runtime, ...)
	if not ok then
		warn("[SimServer] " .. tostring(action) .. " failed: " .. tostring(a))
		return false, "Something went wrong"
	end
	return a, b
end
