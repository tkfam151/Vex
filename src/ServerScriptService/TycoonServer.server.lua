--[[
	TycoonServer (Script)  ->  ServerScriptService.TycoonServer

	Workshops, tycoon buttons, droppers, Robot Lab, robot bays (income),
	competitions, seasons (rebirth), game pass shop and leaderboard.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local DataManager = require(ServerScriptService:WaitForChild("DataManager"))
local RobotBuilder = require(ReplicatedStorage:WaitForChild("RobotBuilder"))
local WorldBuilder = require(ServerScriptService:WaitForChild("WorldBuilder"))

local Remotes = DataManager.Remotes
local World = WorldBuilder.GetWorld()

local playerPlot = {} -- [player] = plot

local function notify(player, text, kind)
	DataManager.Notify(player, text, kind)
end

---------------------------------------------------------------------
-- Data push (batched so many changes in one frame send one update)
---------------------------------------------------------------------
local pendingPush = {}
local function pushData(player)
	if pendingPush[player] then
		return
	end
	pendingPush[player] = true
	task.defer(function()
		pendingPush[player] = nil
		if player.Parent and DataManager.Get(player) then
			Remotes.DataUpdate:FireClient(player, DataManager.GetSnapshot(player))
		end
	end)
end

---------------------------------------------------------------------
-- Plot visuals
---------------------------------------------------------------------
local function updateStorageLabel(plot)
	plot.StorageLabel.Text = "Step here to collect\n" .. Config.Money(plot.Storage)
end

local function updateTrophyShelf(plot)
	local model = plot.Built.shelf
	local data = plot.Owner and DataManager.Get(plot.Owner)
	if model and data then
		local label = model:FindFirstChild("TrophyLabel", true)
		if label then
			label.Text = Config.Format(data.Trophies) .. " TROPHIES"
		end
	end
end

local function refreshDisplay(plot)
	local assembly = plot.Built.assembly
	if not assembly then
		return
	end
	local old = assembly:FindFirstChild("DesignRobot")
	if old then
		old:Destroy()
	end
	local data = plot.Owner and DataManager.Get(plot.Owner)
	local pad = assembly:FindFirstChild("DisplayPad")
	if not data or not pad then
		return
	end
	local robot, stats = RobotBuilder.Build(data.Loadout, {
		Name = "DesignRobot",
		TeamColor = plot.Color,
		Label = "Current Design",
	})
	robot:PivotTo(plot.CFrame * CFrame.new(-20, 1.4 + 1, 36) * CFrame.Angles(0, math.pi, 0))
	robot.Parent = assembly
	local sub = robot.Root:FindFirstChild("Sub", true)
	if sub then
		sub.Text = "Rating " .. stats.Rating
	end
end

local function refreshBays(plot)
	plot.Bays:ClearAllChildren()
	local player = plot.Owner
	local data = player and DataManager.Get(player)
	if not data then
		return
	end
	local mult = DataManager.GetMultiplier(player)
	local slots = DataManager.GetGarageSlots(player)
	for i = 1, slots do
		local pad = WorldBuilder.BuildBayPad(plot, i)
		local loadout = data.Garage[i]
		if loadout then
			local stats = Config.GetRobotStats(loadout)
			local label = "Robot " .. i .. (i == data.Active and "  ·  Active" or "")
			local robot = RobotBuilder.Build(loadout, {
				Name = "BayRobot" .. i,
				TeamColor = plot.Color,
				Label = label,
				SubLabel = "Rating " .. stats.Rating .. "  ·  +" .. Config.Money(stats.Income * mult) .. "/s",
			})
			robot:PivotTo(pad.CFrame * CFrame.new(0, 0.15 + 1, 0) * CFrame.Angles(0, math.pi, 0))
			robot.Parent = plot.Bays
		end
	end
end

local function updateButtonColors(plot)
	local data = plot.Owner and DataManager.Get(plot.Owner)
	if not data then
		return
	end
	for itemId, model in pairs(plot.ButtonModels) do
		local item = Config.ItemById[itemId]
		local pad = model.PrimaryPart
		if pad and item then
			pad.Color = data.Cash >= item.Cost and Color3.fromRGB(60, 220, 90) or Color3.fromRGB(220, 60, 60)
		end
	end
end

---------------------------------------------------------------------
-- Drops
---------------------------------------------------------------------
local function spawnDrop(plot, item, position)
	local drop = Instance.new("Part")
	drop.Name = "Drop"
	drop.Size = Vector3.new(1, 1, 1) * (0.8 + math.min(item.Slot, 6) * 0.08)
	drop.Color = item.DropColor
	drop.Material = Enum.Material.Metal
	drop.CFrame = CFrame.new(position) * CFrame.Angles(math.random() * 3, math.random() * 3, math.random() * 3)
	drop.TopSurface = Enum.SurfaceType.Smooth
	drop.BottomSurface = Enum.SurfaceType.Smooth
	drop.CanQuery = false
	drop:SetAttribute("Value", item.DropValue)
	drop.Parent = plot.Drops
	pcall(function()
		drop:SetNetworkOwner(nil)
	end)
	Debris:AddItem(drop, Config.DropLifetime)
end

local function startDropper(plot, item, model)
	local token = plot.Token
	task.spawn(function()
		local body = model.PrimaryPart
		local dropPoint = body and body:FindFirstChild("DropPoint")
		if not dropPoint then
			return
		end
		while plot.Token == token and model.Parent do
			local interval = item.Interval
			if plot.Built.overclock then
				interval *= Config.ItemById.overclock.Factor
			end
			task.wait(interval)
			if plot.Token ~= token or not model.Parent then
				break
			end
			if #plot.Drops:GetChildren() < Config.MaxDropsPerPlot then
				spawnDrop(plot, item, dropPoint.WorldPosition)
			end
		end
	end)
end

local function hookUpgrader(plot, item, model)
	local laser = model:FindFirstChild("Laser")
	if not laser then
		return
	end
	local flag = "Up_" .. item.Id
	laser.Touched:Connect(function(hit)
		if hit.Parent ~= plot.Drops or hit:GetAttribute(flag) then
			return
		end
		hit:SetAttribute(flag, true)
		hit:SetAttribute("Value", (hit:GetAttribute("Value") or 0) * item.Multiplier)
		hit.Color = item.Color
		hit.Material = Enum.Material.Neon
	end)
end

---------------------------------------------------------------------
-- Building items / buttons
---------------------------------------------------------------------
local tryPurchase -- forward declaration

local function buildItem(plot, item)
	if plot.Built[item.Id] then
		return
	end
	local model = WorldBuilder.BuildItem(plot, item)
	plot.Built[item.Id] = model
	if item.Type == "Dropper" then
		startDropper(plot, item, model)
	elseif item.Type == "Upgrader" then
		hookUpgrader(plot, item, model)
	elseif item.Type == "Assembly" then
		local labPrompt = model:FindFirstChild("LabPrompt", true)
		if labPrompt then
			labPrompt.Triggered:Connect(function(who)
				if who == plot.Owner then
					Remotes.OpenUI:FireClient(who, "Lab")
				else
					notify(who, "This is " .. (plot.OwnerName or "someone") .. "'s workshop.", "error")
				end
			end)
		end
		refreshDisplay(plot)
	elseif item.Type == "Shelf" then
		updateTrophyShelf(plot)
	end
end

local function refreshButtons(plot)
	local data = plot.Owner and DataManager.Get(plot.Owner)
	for _, item in ipairs(Config.Items) do
		local existing = plot.ButtonModels[item.Id]
		local show = data ~= nil
			and not data.Purchased[item.Id]
			and (item.Requires == nil or data.Purchased[item.Requires] == true)
		if show and not existing then
			local model = WorldBuilder.BuildButton(plot, item)
			plot.ButtonModels[item.Id] = model
			model.PrimaryPart.Touched:Connect(function(hit)
				local who = Players:GetPlayerFromCharacter(hit.Parent)
				if who and who == plot.Owner then
					tryPurchase(who, item)
				end
			end)
		elseif not show and existing then
			existing:Destroy()
			plot.ButtonModels[item.Id] = nil
		end
	end
	updateButtonColors(plot)
end

function tryPurchase(player, item)
	local data = DataManager.Get(player)
	local runtime = DataManager.Runtime[player]
	local plot = playerPlot[player]
	if not data or not runtime or not plot then
		return
	end
	if data.Purchased[item.Id] then
		return
	end
	if item.Requires and not data.Purchased[item.Requires] then
		return
	end
	if not DataManager.SpendCash(player, item.Cost) then
		if os.clock() - (runtime.LastBuyFail or 0) > 2 then
			runtime.LastBuyFail = os.clock()
			notify(player, "You need " .. Config.Money(item.Cost - data.Cash) .. " more for " .. item.Name, "error")
		end
		return
	end
	data.Purchased[item.Id] = true
	buildItem(plot, item)
	refreshButtons(plot)
	if item.Type == "Assembly" or item.Type == "Bay" then
		refreshBays(plot)
	end
	if item.Type == "Assembly" then
		notify(player, "Robot Lab unlocked! Open ROBOTS from the menu or use the workbench.", "success")
	else
		notify(player, "Built " .. item.Name .. "!", "success")
	end
	DataManager.MarkChanged(player)
end

---------------------------------------------------------------------
-- Claim / release plots
---------------------------------------------------------------------
local function teleportHome(player)
	local plot = playerPlot[player]
	local character = player.Character
	if not character then
		return
	end
	if plot then
		character:PivotTo(plot.SpawnCFrame)
	end
end

local function clearPlot(plot)
	plot.Token += 1
	plot.Items:ClearAllChildren()
	plot.Buttons:ClearAllChildren()
	plot.Drops:ClearAllChildren()
	plot.Bays:ClearAllChildren()
	plot.Built = {}
	plot.ButtonModels = {}
	plot.Storage = 0
	updateStorageLabel(plot)
end

local function loadPlot(plot)
	local data = plot.Owner and DataManager.Get(plot.Owner)
	if not data then
		return
	end
	for _, item in ipairs(Config.Items) do
		if data.Purchased[item.Id] then
			buildItem(plot, item)
		end
	end
	refreshButtons(plot)
	refreshBays(plot)
	refreshDisplay(plot)
end

local function claimPlot(player, plot)
	plot.Owner = player
	plot.OwnerName = player.DisplayName
	playerPlot[player] = plot
	DataManager.Runtime[player].Plot = plot
	plot.OwnerLabel.Text = player.DisplayName .. "'s Workshop"
	clearPlot(plot)
	loadPlot(plot)
	DataManager.FirePlotClaimed(player, plot)
end

local function releasePlot(plot)
	if plot.Owner then
		DataManager.FirePlotReleased(plot.Owner, plot)
	end
	clearPlot(plot)
	plot.Owner = nil
	plot.OwnerName = nil
	plot.OwnerLabel.Text = "Empty Workshop"
end

-- collectors & collect pads are permanent, hook them once
for _, plot in ipairs(World.Plots) do
	plot.Collector.Touched:Connect(function(hit)
		if hit.Parent ~= plot.Drops or hit:GetAttribute("Collected") then
			return
		end
		hit:SetAttribute("Collected", true)
		local value = hit:GetAttribute("Value") or 0
		hit:Destroy()
		local owner = plot.Owner
		if not owner or not DataManager.Get(owner) then
			return
		end
		local amount = value * DataManager.GetMultiplier(owner)
		if DataManager.HasPass(owner, "AutoCollect") then
			DataManager.AddCash(owner, amount, false)
		else
			plot.Storage += amount
			updateStorageLabel(plot)
		end
	end)

	local lastCollect = 0
	plot.CollectPad.Touched:Connect(function(hit)
		local who = Players:GetPlayerFromCharacter(hit.Parent)
		if not who or who ~= plot.Owner or plot.Storage < 1 then
			return
		end
		if os.clock() - lastCollect < 0.5 then
			return
		end
		lastCollect = os.clock()
		local amount = DataManager.AddCash(who, plot.Storage, false)
		plot.Storage = 0
		updateStorageLabel(plot)
		notify(who, "+" .. Config.Money(amount) .. " collected", "cash")
	end)
end

---------------------------------------------------------------------
-- Competitions
---------------------------------------------------------------------
local TEAM_LETTERS = { "A", "B", "C", "D", "E", "F", "G", "H", "K", "R", "X", "Y", "Z" }
local function randomTeam()
	return tostring(math.random(100, 99999)) .. TEAM_LETTERS[math.random(1, #TEAM_LETTERS)]
end

local ROUNDS = {
	{ Name = "Quarterfinals", Difficulty = 0.85 },
	{ Name = "Semifinals", Difficulty = 1.0 },
	{ Name = "Finals", Difficulty = 1.15 },
}

local function simulateTournament(rating, comp)
	local results = {}
	local reached = 0
	for i, round in ipairs(ROUNDS) do
		local you = rating * (0.8 + math.random() * 0.45)
		local opp = comp.Difficulty * round.Difficulty * (0.8 + math.random() * 0.4)
		local yourScore = math.floor(you * 1.5 + math.random(0, 8))
		local oppScore = math.floor(opp * 1.5 + math.random(0, 8))
		if yourScore == oppScore then
			yourScore += math.random(0, 1) == 0 and 1 or -1
		end
		local won = yourScore > oppScore
		table.insert(results, { Round = round.Name, You = yourScore, Opp = oppScore, OppTeam = randomTeam(), Won = won })
		if not won then
			break
		end
		reached = i
	end
	return results, reached
end

---------------------------------------------------------------------
-- Request handlers
---------------------------------------------------------------------
local Actions = {}

function Actions.GetData(player)
	return DataManager.GetSnapshot(player)
end

local function hasLab(data)
	return data.Purchased.assembly == true
end

function Actions.UnlockModule(player, data, moduleId)
	local def = Config.ModuleById[moduleId]
	if not def then
		return false, "Unknown part"
	end
	if not hasLab(data) then
		return false, "Buy the Robot Assembly Station first!"
	end
	if data.Modules[def.Id] then
		return false, "Already unlocked"
	end
	if (def.Season or 0) > data.Season then
		return false, "Requires Season " .. def.Season
	end
	if not DataManager.SpendCash(player, def.Cost) then
		return false, "Not enough cash"
	end
	data.Modules[def.Id] = true
	data.Loadout[def.Slot] = def.Id
	local plot = playerPlot[player]
	if plot then
		refreshDisplay(plot)
	end
	DataManager.MarkChanged(player)
	return true, "Unlocked & equipped " .. def.Name .. "!"
end

function Actions.EquipModule(player, data, moduleId)
	local def = Config.ModuleById[moduleId]
	if not def or not data.Modules[def.Id] then
		return false, "You don't own that part"
	end
	data.Loadout[def.Slot] = def.Id
	local plot = playerPlot[player]
	if plot then
		refreshDisplay(plot)
	end
	DataManager.MarkChanged(player)
	return true, "Equipped " .. def.Name
end

function Actions.BuildRobot(player, data)
	if not hasLab(data) then
		return false, "Buy the Robot Assembly Station first!"
	end
	local slots = DataManager.GetGarageSlots(player)
	if #data.Garage >= slots then
		return false, "All robot bays are full! Buy more bays or scrap a robot."
	end
	local stats = Config.GetRobotStats(data.Loadout)
	if not DataManager.SpendCash(player, stats.BuildCost) then
		return false, "Building costs " .. Config.Money(stats.BuildCost)
	end
	table.insert(data.Garage, DataManager.DeepCopy(data.Loadout))
	data.Stats.RobotsBuilt += 1
	if data.Active < 1 then
		data.Active = #data.Garage
	end
	local plot = playerPlot[player]
	if plot then
		refreshBays(plot)
	end
	DataManager.MarkChanged(player)
	return true, "Robot #" .. #data.Garage .. " built! (Rating " .. stats.Rating .. ")"
end

function Actions.ScrapRobot(player, data, index)
	index = tonumber(index)
	local robot = index and data.Garage[index]
	if not robot then
		return false, "No robot there"
	end
	if player:GetAttribute("Driving") then
		return false, "Stop driving first"
	end
	local stats = Config.GetRobotStats(robot)
	local refund = math.floor(stats.BuildCost * Config.ScrapRefund)
	table.remove(data.Garage, index)
	if data.Active == index then
		data.Active = #data.Garage > 0 and 1 or 0
	elseif data.Active > index then
		data.Active -= 1
	end
	DataManager.AddCash(player, refund, false)
	local plot = playerPlot[player]
	if plot then
		refreshBays(plot)
	end
	DataManager.MarkChanged(player)
	return true, "Scrapped robot for " .. Config.Money(refund)
end

function Actions.SetActive(player, data, index)
	index = tonumber(index)
	if not index or not data.Garage[index] then
		return false, "No robot there"
	end
	if player:GetAttribute("Driving") then
		return false, "Stop driving first"
	end
	data.Active = index
	local plot = playerPlot[player]
	if plot then
		refreshBays(plot)
	end
	DataManager.MarkChanged(player)
	return true, "Robot #" .. index .. " is now your competition robot"
end

function Actions.EnterCompetition(player, data, compId)
	local comp = Config.CompetitionById[compId]
	if not comp then
		return false, "Unknown competition"
	end
	local robot = data.Garage[data.Active]
	if not robot then
		return false, "Build a robot in the Robot Lab first!"
	end
	local stats = Config.GetRobotStats(robot)
	if stats.Rating < comp.MinRating then
		return false, "Your robot needs a rating of " .. comp.MinRating
	end
	local runtime = DataManager.Runtime[player]
	local readyAt = runtime.Cooldowns[comp.Id] or 0
	if os.time() < readyAt then
		return false, "Next event in " .. (readyAt - os.time()) .. "s"
	end
	if not DataManager.SpendCash(player, comp.Fee) then
		return false, "Entry fee is " .. Config.Money(comp.Fee)
	end
	runtime.Cooldowns[comp.Id] = os.time() + comp.Cooldown
	data.Stats.CompsEntered += 1

	local rounds, reached = simulateTournament(stats.Rating, comp)
	local prize = 0
	local trophies = 0
	local payout = Config.CompetitionPayout[reached] or 0
	if payout > 0 then
		prize = DataManager.AddCash(player, comp.Prize * payout, true)
	end
	if reached == 3 then
		trophies = comp.Trophies
		data.Stats.CompWins += 1
	elseif reached == 2 then
		trophies = math.max(1, math.floor(comp.Trophies / 3))
	end
	if trophies > 0 then
		DataManager.AddTrophies(player, trophies)
	end
	local plot = playerPlot[player]
	if plot then
		updateTrophyShelf(plot)
	end
	DataManager.MarkChanged(player)
	return true, {
		Competition = comp.Name,
		Rounds = rounds,
		Reached = reached,
		Prize = prize,
		Trophies = trophies,
		Champion = reached == 3,
	}
end

function Actions.Rebirth(player, data)
	local cost = Config.GetSeasonCost(data.Season)
	if data.Cash < cost then
		return false, "You need " .. Config.Money(cost) .. " to start a new season"
	end
	if player:GetAttribute("Driving") then
		return false, "Stop driving first"
	end
	local modules, loadout = DataManager.DefaultModules()
	data.Season += 1
	data.Cash = Config.StartingCash
	data.Purchased = {}
	data.Modules = modules
	data.Loadout = loadout
	data.Garage = {}
	data.Active = 0
	data.Seeds = DataManager.DeepCopy(Config.Garden.StartingSeeds)
	data.Garden = {}
	data.Backpack = {}
	data.Showcase = {}
	DataManager.UpdateLeaderstats(player)
	local plot = playerPlot[player]
	if plot then
		clearPlot(plot)
		loadPlot(plot)
	end
	DataManager.FireProgressReset(player)
	DataManager.MarkChanged(player)
	task.spawn(DataManager.Save, player)
	local mult = Config.GetMultiplier(data.Season, false)
	return true, "Season " .. data.Season .. " begins! Permanent x" .. mult .. " cash."
end

function Actions.PromptPass(player, _, key)
	for _, pass in ipairs(Config.GamePasses) do
		if pass.Key == key then
			if not pass.Id or pass.Id <= 0 then
				return false, "This pass isn't set up yet (add its ID in Config)."
			end
			MarketplaceService:PromptGamePassPurchase(player, pass.Id)
			return true
		end
	end
	return false, "Unknown pass"
end

Remotes.Request.OnServerInvoke = function(player, action, ...)
	local handler = Actions[action]
	local data = DataManager.Get(player)
	if not handler then
		return false, "Unknown action"
	end
	if not data then
		return false, "Your data is still loading..."
	end
	local runtime = DataManager.Runtime[player]
	if runtime.Busy then
		return false, "Slow down!"
	end
	runtime.Busy = true
	local ok, a, b = pcall(handler, player, data, ...)
	runtime.Busy = false
	if not ok then
		warn("[TycoonServer] Action", action, "failed:", a)
		return false, "Something went wrong"
	end
	return a, b
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if not purchased then
		return
	end
	for _, pass in ipairs(Config.GamePasses) do
		if pass.Id == passId then
			DataManager.GrantPass(player, pass.Key)
			notify(player, "Thanks for buying " .. pass.Name .. "!", "success")
			local plot = playerPlot[player]
			if plot and pass.Key == "ExtraBays" then
				refreshBays(plot)
			end
		end
	end
end)

World.Hub.CompetitionPrompt.Triggered:Connect(function(player)
	Remotes.OpenUI:FireClient(player, "Compete")
end)

---------------------------------------------------------------------
-- Players
---------------------------------------------------------------------
local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.25)
		teleportHome(player)
	end)

	local data = DataManager.Load(player)
	if not data then
		return
	end

	local plot = nil
	for _, candidate in ipairs(World.Plots) do
		if not candidate.Owner then
			plot = candidate
			break
		end
	end
	if plot then
		claimPlot(player, plot)
		teleportHome(player)
	else
		notify(player, "All workshops are full - you can still compete and drive!", "error")
	end
	pushData(player)
	task.delay(2, function()
		if player.Parent then
			notify(player, "Welcome to " .. Config.GameName .. "! Step on the green buttons to build your workshop.", "info")
		end
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	local plot = playerPlot[player]
	if plot then
		releasePlot(plot)
	end
	playerPlot[player] = nil
	pendingPush[player] = nil
end)

DataManager.Changed:Connect(function(player)
	pushData(player)
	local plot = playerPlot[player]
	if plot then
		updateTrophyShelf(plot)
	end
end)

---------------------------------------------------------------------
-- Loops: robot income + button colors, leaderboard
---------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(1)
		for player, plot in pairs(playerPlot) do
			if DataManager.Get(player) then
				local income = DataManager.GetRobotIncome(player)
				if income > 0 then
					DataManager.AddCash(player, income, true)
				end
				updateButtonColors(plot)
			end
		end
	end
end)

local leaderboardStore = nil
pcall(function()
	leaderboardStore = DataStoreService:GetOrderedDataStore(Config.LeaderboardStoreName)
end)
local nameCache = {}

local function showOnlineLeaderboard(rows)
	-- no datastore (e.g. unpublished place in Studio): rank online players instead
	local list = {}
	for player, data in pairs(DataManager.Profiles) do
		table.insert(list, { Name = player.DisplayName, Value = data.Trophies })
	end
	table.sort(list, function(a, b)
		return a.Value > b.Value
	end)
	for i, row in ipairs(rows) do
		local entry = list[i]
		row.Text = entry and string.format("  %d    %s    %s", i, entry.Name, Config.Format(entry.Value)) or string.format("  %d    —", i)
	end
end

local function refreshLeaderboard()
	local rows = World.Hub.LeaderboardRows
	if not leaderboardStore then
		showOnlineLeaderboard(rows)
		return
	end
	for player, data in pairs(DataManager.Profiles) do
		pcall(function()
			leaderboardStore:SetAsync(tostring(player.UserId), data.Trophies)
		end)
	end
	local ok, pages = pcall(function()
		return leaderboardStore:GetSortedAsync(false, 10)
	end)
	if not ok then
		showOnlineLeaderboard(rows)
		return
	end
	local entries = pages:GetCurrentPage()
	for i, row in ipairs(rows) do
		local entry = entries[i]
		if entry then
			local userId = tonumber(entry.key)
			local name = nameCache[userId]
			if not name then
				local success, result = pcall(function()
					return Players:GetNameFromUserIdAsync(userId)
				end)
				name = success and result or ("User " .. tostring(userId))
				nameCache[userId] = name
			end
			row.Text = string.format("  %d    %s    %s", i, name, Config.Format(entry.value))
		else
			row.Text = string.format("  %d    —", i)
		end
	end
end

task.spawn(function()
	task.wait(10)
	while true do
		refreshLeaderboard()
		task.wait(60)
	end
end)
