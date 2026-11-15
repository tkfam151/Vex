--[[
	DataManager (ModuleScript)  ->  ServerScriptService.DataManager

	Loads/saves player data, owns leaderstats, cash helpers, game pass
	checks, and creates all RemoteEvents/RemoteFunctions.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local DataManager = {}
DataManager.Profiles = {} -- [player] = saved data table
DataManager.Passes = {} -- [player] = { [passKey] = true }
DataManager.Runtime = {} -- [player] = non-saved state (cooldowns, debounces)

local changedEvent = Instance.new("BindableEvent")
DataManager.Changed = changedEvent.Event

-- fired by TycoonServer so other systems (garden, market) can react
local plotClaimed = Instance.new("BindableEvent")
local plotReleased = Instance.new("BindableEvent")
local progressReset = Instance.new("BindableEvent")
DataManager.PlotClaimed = plotClaimed.Event -- (player, plot)
DataManager.PlotReleased = plotReleased.Event -- (player, plot)
DataManager.ProgressReset = progressReset.Event -- (player) after a new season
function DataManager.FirePlotClaimed(player, plot)
	plotClaimed:Fire(player, plot)
end
function DataManager.FirePlotReleased(player, plot)
	plotReleased:Fire(player, plot)
end
function DataManager.FireProgressReset(player)
	progressReset:Fire(player)
end

---------------------------------------------------------------------
-- Remotes (created once, shared by every server script)
---------------------------------------------------------------------
local remoteFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remoteFolder then
	remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "Remotes"
	remoteFolder.Parent = ReplicatedStorage
end

local function getRemote(className, name)
	local remote = remoteFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new(className)
		remote.Name = name
		remote.Parent = remoteFolder
	end
	return remote
end

DataManager.Remotes = {
	Folder = remoteFolder,
	Request = getRemote("RemoteFunction", "Request"), -- workshop / lab / competitions
	ArenaRequest = getRemote("RemoteFunction", "ArenaRequest"), -- driving / ranked
	SimRequest = getRemote("RemoteFunction", "SimRequest"), -- garden / market
	DataUpdate = getRemote("RemoteEvent", "DataUpdate"),
	Notify = getRemote("RemoteEvent", "Notify"),
	OpenUI = getRemote("RemoteEvent", "OpenUI"),
	ArenaState = getRemote("RemoteEvent", "ArenaState"),
	Score = getRemote("RemoteEvent", "Score"),
}

---------------------------------------------------------------------
-- DataStore
---------------------------------------------------------------------
local store = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataManager] DataStore unavailable (publish the place & enable Studio API access to save):", result)
	end
end

local warnedSaveFailure = false

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end
	return copy
end
DataManager.DeepCopy = deepCopy

local function reconcile(data, template)
	for key, value in pairs(template) do
		if data[key] == nil then
			data[key] = deepCopy(value)
		elseif type(value) == "table" and type(data[key]) == "table" and key ~= "Garage" and key ~= "Seeds" then
			reconcile(data[key], value)
		end
	end
end

function DataManager.DefaultModules()
	local modules, loadout = {}, {}
	for _, slot in ipairs(Config.ModuleSlots) do
		local starter = Config.Modules[slot][1]
		modules[starter.Id] = true
		loadout[slot] = starter.Id
	end
	return modules, loadout
end

local function defaultData()
	local modules, loadout = DataManager.DefaultModules()
	return {
		Cash = Config.StartingCash,
		Trophies = 0,
		Season = 0,
		Purchased = {},
		Modules = modules,
		Loadout = loadout,
		Garage = {},
		Active = 0,
		Seeds = deepCopy(Config.Garden.StartingSeeds),
		Garden = {}, -- ["t1"] = { S = seedId, T = plantedAt, M = mutation }
		Backpack = {}, -- { { S = seedId, M = mutation, V = value } }
		Showcase = {}, -- ["p1"] = { S = speciesId, M = mutation }
		Stats = {
			CompWins = 0,
			CompsEntered = 0,
			MatchesPlayed = 0,
			MatchesWon = 0,
			BallsScored = 0,
			RobotsBuilt = 0,
			TotalEarned = 0,
			Harvests = 0,
			Steals = 0,
		},
	}
end

local function keyFor(player)
	return "Player_" .. player.UserId
end

local function sanitize(data)
	-- make sure the loadout only references real, owned modules
	for _, slot in ipairs(Config.ModuleSlots) do
		local def = Config.ModuleById[data.Loadout[slot]]
		if not def or def.Slot ~= slot or not data.Modules[def.Id] then
			data.Loadout[slot] = Config.Modules[slot][1].Id
		end
	end
	-- remove garage robots that reference unknown parts
	local cleanGarage = {}
	for _, robot in ipairs(data.Garage) do
		if type(robot) == "table" then
			table.insert(cleanGarage, robot)
		end
	end
	data.Garage = cleanGarage
	if data.Active > #data.Garage then
		data.Active = #data.Garage
	end
	if data.Active < 1 and #data.Garage > 0 then
		data.Active = 1
	end
	data.Cash = math.max(0, math.floor(tonumber(data.Cash) or 0))
end

---------------------------------------------------------------------
-- Leaderstats
---------------------------------------------------------------------
local function updateLeaderstats(player)
	local data = DataManager.Profiles[player]
	local stats = player:FindFirstChild("leaderstats")
	if not data or not stats then
		return
	end
	stats.Cash.Value = data.Cash
	stats.Trophies.Value = data.Trophies
	stats.Season.Value = data.Season
end
DataManager.UpdateLeaderstats = updateLeaderstats

local function createLeaderstats(player, data)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = data.Cash
	cash.Parent = folder
	local trophies = Instance.new("IntValue")
	trophies.Name = "Trophies"
	trophies.Value = data.Trophies
	trophies.Parent = folder
	local season = Instance.new("IntValue")
	season.Name = "Season"
	season.Value = data.Season
	season.Parent = folder
	folder.Parent = player
end

---------------------------------------------------------------------
-- Load / Save
---------------------------------------------------------------------
function DataManager.Load(player)
	local data = nil
	if store then
		for attempt = 1, 3 do
			local ok, result = pcall(function()
				return store:GetAsync(keyFor(player))
			end)
			if ok then
				data = result
				break
			end
			warn("[DataManager] Load attempt", attempt, "failed for", player.Name, result)
			task.wait(1.5)
		end
	end

	if type(data) ~= "table" then
		data = defaultData()
	else
		reconcile(data, defaultData())
	end
	sanitize(data)

	if not player.Parent then
		return nil -- left while loading
	end

	DataManager.Profiles[player] = data
	DataManager.Runtime[player] = { Cooldowns = {} }
	DataManager.Passes[player] = {}
	createLeaderstats(player, data)

	for _, pass in ipairs(Config.GamePasses) do
		if pass.Id and pass.Id > 0 then
			task.spawn(function()
				local ok, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
				end)
				if ok and owns and DataManager.Passes[player] then
					DataManager.Passes[player][pass.Key] = true
					DataManager.MarkChanged(player)
				end
			end)
		end
	end

	return data
end

function DataManager.Save(player)
	local data = DataManager.Profiles[player]
	if not data or not store then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync(keyFor(player), data)
	end)
	if not ok and not warnedSaveFailure then
		warnedSaveFailure = true
		warn("[DataManager] Save failed (further save warnings hidden):", err)
	end
end

function DataManager.Release(player)
	DataManager.Save(player)
	DataManager.Profiles[player] = nil
	DataManager.Runtime[player] = nil
	DataManager.Passes[player] = nil
end

task.spawn(function()
	while true do
		task.wait(Config.AutoSaveInterval)
		for player in pairs(DataManager.Profiles) do
			task.spawn(DataManager.Save, player)
		end
	end
end)

game:BindToClose(function()
	local pending = 0
	for player in pairs(DataManager.Profiles) do
		pending += 1
		task.spawn(function()
			DataManager.Save(player)
			pending -= 1
		end)
	end
	local start = os.clock()
	while pending > 0 and os.clock() - start < 25 do
		task.wait(0.1)
	end
end)

---------------------------------------------------------------------
-- Helpers used by every server script
---------------------------------------------------------------------
function DataManager.Get(player)
	return DataManager.Profiles[player]
end

function DataManager.HasPass(player, key)
	local passes = DataManager.Passes[player]
	return passes ~= nil and passes[key] == true
end

function DataManager.GrantPass(player, key)
	local passes = DataManager.Passes[player]
	if passes then
		passes[key] = true
		DataManager.MarkChanged(player)
	end
end

function DataManager.GetMultiplier(player)
	local data = DataManager.Profiles[player]
	if not data then
		return 1
	end
	return Config.GetMultiplier(data.Season, DataManager.HasPass(player, "DoubleCash"))
end

-- Adds cash. If applyMultiplier is true the season/pass multiplier is used.
function DataManager.AddCash(player, amount, applyMultiplier)
	local data = DataManager.Profiles[player]
	if not data then
		return 0
	end
	if applyMultiplier then
		amount *= DataManager.GetMultiplier(player)
	end
	amount = math.floor(amount)
	data.Cash += amount
	if amount > 0 then
		data.Stats.TotalEarned += amount
	end
	updateLeaderstats(player)
	return amount
end

function DataManager.SpendCash(player, amount)
	local data = DataManager.Profiles[player]
	if not data or amount < 0 or data.Cash < amount then
		return false
	end
	data.Cash -= amount
	updateLeaderstats(player)
	return true
end

function DataManager.AddTrophies(player, amount)
	local data = DataManager.Profiles[player]
	if not data then
		return
	end
	data.Trophies += amount
	updateLeaderstats(player)
	DataManager.MarkChanged(player)
end

function DataManager.GetGarageSlots(player)
	local data = DataManager.Profiles[player]
	if not data then
		return 0
	end
	local slots = 0
	for _, item in ipairs(Config.Items) do
		if (item.Type == "Assembly" or item.Type == "Bay") and data.Purchased[item.Id] then
			slots += 1
		end
	end
	if slots > 0 and DataManager.HasPass(player, "ExtraBays") then
		slots += 2
	end
	return math.min(slots, #Config.Layout.BayPositions)
end

function DataManager.GetActiveRobot(player)
	local data = DataManager.Profiles[player]
	if not data then
		return nil
	end
	return data.Garage[data.Active]
end

function DataManager.GetRobotIncome(player)
	local data = DataManager.Profiles[player]
	if not data then
		return 0
	end
	local total = 0
	for _, robot in ipairs(data.Garage) do
		local stats = Config.GetRobotStats(robot)
		total += stats.Income
	end
	return total
end

function DataManager.Notify(player, text, kind)
	DataManager.Remotes.Notify:FireClient(player, text, kind or "info")
end

function DataManager.MarkChanged(player)
	changedEvent:Fire(player)
end

function DataManager.GetSnapshot(player)
	local data = DataManager.Profiles[player]
	if not data then
		return nil
	end
	local runtime = DataManager.Runtime[player]
	local cooldowns = {}
	if runtime then
		for compId, readyAt in pairs(runtime.Cooldowns) do
			local remaining = readyAt - os.time()
			if remaining > 0 then
				cooldowns[compId] = remaining
			end
		end
	end
	return {
		Cash = data.Cash,
		Trophies = data.Trophies,
		Season = data.Season,
		Purchased = data.Purchased,
		Modules = data.Modules,
		Loadout = data.Loadout,
		Garage = data.Garage,
		Active = data.Active,
		Stats = data.Stats,
		Passes = DataManager.Passes[player] or {},
		Multiplier = DataManager.GetMultiplier(player),
		GarageSlots = DataManager.GetGarageSlots(player),
		RobotIncome = DataManager.GetRobotIncome(player) * DataManager.GetMultiplier(player),
		Cooldowns = cooldowns,
		HasPlot = runtime ~= nil and runtime.Plot ~= nil,
		Seeds = data.Seeds,
		Garden = data.Garden,
		Backpack = data.Backpack,
		Showcase = data.Showcase,
		Stock = runtime and runtime.Stock or {},
		SelectedSeed = runtime and runtime.SelectedSeed or nil,
		LockedUntil = runtime and runtime.Plot and runtime.Plot.LockedUntil or 0,
		LockReadyAt = runtime and runtime.Plot and runtime.Plot.LockReadyAt or 0,
	}
end

Players.PlayerRemoving:Connect(function(player)
	-- deferred so other scripts' PlayerRemoving handlers can still read the data first
	task.defer(function()
		if DataManager.Profiles[player] then
			DataManager.Release(player)
		end
	end)
end)

return DataManager
