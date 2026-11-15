-- VEX Robotics Tycoon installer
-- Paste ALL of this into Roblox Studio > View > Command Bar and press Enter.
-- It creates (or replaces) every game script. Undo with Ctrl+Z.
local ChangeHistoryService = game:GetService("ChangeHistoryService")
ChangeHistoryService:SetWaypoint("Before VEX Tycoon install")
-- remove scripts from older versions that moved
local oldBuilder = game:GetService("ServerScriptService"):FindFirstChild("RobotBuilder")
if oldBuilder then
	oldBuilder:Destroy()
end
local files = {}
table.insert(files, { Class = "ModuleScript", Service = "ReplicatedStorage", Sub = nil, Name = "Config", Source = [=[
--[[
	Config (ModuleScript)  ->  ReplicatedStorage.Config

	Every number in the game lives here. Tweak prices, robot parts,
	competitions and rewards without touching any other script.
]]

local Config = {}

---------------------------------------------------------------------
-- General
---------------------------------------------------------------------
Config.GameName = "VEX Robotics Tycoon"
Config.DataStoreName = "VexRoboticsTycoon_v1"
Config.LeaderboardStoreName = "VexRoboticsTycoon_Trophies_v1"
Config.AutoSaveInterval = 120 -- seconds
Config.StartingCash = 0

---------------------------------------------------------------------
-- World layout
---------------------------------------------------------------------
Config.MaxPlots = 6
Config.PlotRadius = 220 -- distance from hub center to each workshop
Config.PlotSize = 110
Config.HubRadius = 130
Config.ConveyorSpeed = 10
Config.DropLifetime = 25
Config.MaxDropsPerPlot = 80

Config.PlotColors = {
	Color3.fromRGB(196, 38, 46), -- VEX red
	Color3.fromRGB(28, 92, 178), -- alliance blue
	Color3.fromRGB(46, 130, 84), -- green
	Color3.fromRGB(204, 150, 40), -- amber
	Color3.fromRGB(104, 72, 160), -- violet
	Color3.fromRGB(196, 96, 40), -- orange
}

-- Local positions inside a workshop plot (plot faces the hub on -Z)
Config.Layout = {
	DropperX = { -40, -31, -22, -13, -4, 5 },
	UpgraderX = { 14, 21, 28 },
	ConveyorZ = 10,
	ButtonColumns = { -46, -36, -26, -16, -6 },
	ButtonRows = { -46, -37, -28, -19, -10 },
	BayPositions = {
		Vector3.new(5, 0, 27),
		Vector3.new(17, 0, 27),
		Vector3.new(29, 0, 27),
		Vector3.new(41, 0, 27),
		Vector3.new(5, 0, 44),
		Vector3.new(17, 0, 44),
		Vector3.new(29, 0, 44),
		Vector3.new(41, 0, 44),
	},
}

---------------------------------------------------------------------
-- Seasons (rebirth)
---------------------------------------------------------------------
Config.Season = {
	BaseCost = 250000,
	CostGrowth = 2.5, -- cost = BaseCost * CostGrowth ^ currentSeason
	MultiplierPerSeason = 0.5, -- +50% cash per season
}

function Config.GetSeasonCost(season)
	return math.floor(Config.Season.BaseCost * Config.Season.CostGrowth ^ season)
end

function Config.GetMultiplier(season, hasDoubleCash)
	local m = 1 + (season or 0) * Config.Season.MultiplierPerSeason
	if hasDoubleCash then
		m *= 2
	end
	return m
end

---------------------------------------------------------------------
-- Robot economy
---------------------------------------------------------------------
Config.RobotIncomePerRating = 0.5 -- cash / second per rating point for each robot in a bay
Config.BuildCostBase = 50
Config.BuildCostPerRating = 25
Config.ScrapRefund = 0.5

---------------------------------------------------------------------
-- Workshop items (tycoon buttons). Bought in order via "Requires".
-- Types: Dropper, Upgrader, Walls, Assembly, Bay, Tiles, Banner,
--        Shelf, Overclock, Hall
---------------------------------------------------------------------
Config.Items = {
	{ Id = "dropper1", Name = "Parts Bin", Cost = 0, Type = "Dropper", Slot = 1, DropValue = 1, Interval = 2, DropColor = Color3.fromRGB(170, 170, 180), Desc = "Drops screws and nuts." },
	{ Id = "dropper2", Name = "Screw Sorter", Cost = 40, Requires = "dropper1", Type = "Dropper", Slot = 2, DropValue = 2, Interval = 2, DropColor = Color3.fromRGB(120, 120, 130), Desc = "Sorts hardware faster." },
	{ Id = "walls", Name = "Workshop Walls", Cost = 100, Requires = "dropper2", Type = "Walls", Desc = "A real team workshop!" },
	{ Id = "upgrader1", Name = "Deburring Station", Cost = 200, Requires = "dropper2", Type = "Upgrader", Slot = 1, Multiplier = 1.5, Color = Color3.fromRGB(60, 200, 255), Desc = "x1.5 part value." },
	{ Id = "dropper3", Name = "Metal Cutter", Cost = 450, Requires = "upgrader1", Type = "Dropper", Slot = 3, DropValue = 5, Interval = 2.5, DropColor = Color3.fromRGB(200, 200, 210), Desc = "Cuts aluminum C-channel." },
	{ Id = "assembly", Name = "Robot Assembly Station", Cost = 700, Requires = "dropper3", Type = "Assembly", Desc = "Unlocks the Robot Lab + Robot Bay #1." },
	{ Id = "tiles", Name = "Practice Field Tiles", Cost = 900, Requires = "assembly", Type = "Tiles", Desc = "Foam tiles for your robot bays." },
	{ Id = "bay2", Name = "Robot Bay #2", Cost = 1500, Requires = "assembly", Type = "Bay", Desc = "Hold one more robot." },
	{ Id = "dropper4", Name = "3D Printer", Cost = 2500, Requires = "dropper3", Type = "Dropper", Slot = 4, DropValue = 12, Interval = 2.5, DropColor = Color3.fromRGB(240, 120, 30), Desc = "Prints custom parts." },
	{ Id = "banner", Name = "Team Banner & Lights", Cost = 4000, Requires = "walls", Type = "Banner", Desc = "Show off your team." },
	{ Id = "upgrader2", Name = "Quality Inspection", Cost = 6000, Requires = "dropper4", Type = "Upgrader", Slot = 2, Multiplier = 1.75, Color = Color3.fromRGB(80, 255, 120), Desc = "x1.75 part value." },
	{ Id = "bay3", Name = "Robot Bay #3", Cost = 9000, Requires = "bay2", Type = "Bay", Desc = "Hold one more robot." },
	{ Id = "dropper5", Name = "CNC Mill", Cost = 15000, Requires = "upgrader2", Type = "Dropper", Slot = 5, DropValue = 35, Interval = 3, DropColor = Color3.fromRGB(90, 160, 255), Desc = "Precision machined parts." },
	{ Id = "shelf", Name = "Trophy Shelf", Cost = 22000, Requires = "banner", Type = "Shelf", Desc = "Displays your trophies." },
	{ Id = "bay4", Name = "Robot Bay #4", Cost = 35000, Requires = "bay3", Type = "Bay", Desc = "Hold one more robot." },
	{ Id = "dropper6", Name = "Laser Cutter", Cost = 60000, Requires = "dropper5", Type = "Dropper", Slot = 6, DropValue = 90, Interval = 3, DropColor = Color3.fromRGB(255, 70, 70), Desc = "Laser-cut polycarbonate." },
	{ Id = "upgrader3", Name = "Precision Polisher", Cost = 100000, Requires = "dropper6", Type = "Upgrader", Slot = 3, Multiplier = 2, Color = Color3.fromRGB(255, 220, 60), Desc = "x2 part value." },
	{ Id = "bay5", Name = "Robot Bay #5", Cost = 150000, Requires = "bay4", Type = "Bay", Desc = "Hold one more robot." },
	{ Id = "overclock", Name = "Factory Overclock", Cost = 250000, Requires = "upgrader3", Type = "Overclock", Factor = 0.6, Desc = "All machines run 40% faster." },
	{ Id = "bay6", Name = "Robot Bay #6", Cost = 400000, Requires = "bay5", Type = "Bay", Desc = "Hold one more robot." },
	{ Id = "hall", Name = "Championship Hall", Cost = 750000, Requires = "overclock", Type = "Hall", Desc = "A golden entrance for champions." },
}

Config.ItemById = {}
for index, item in ipairs(Config.Items) do
	item.Index = index
	Config.ItemById[item.Id] = item
end

---------------------------------------------------------------------
-- Robot modules. First entry in each slot is the free starter part.
-- Stats: Speed, Power, Control, Scoring  -> Rating = sum of all
-- Season = minimum season (rebirths) needed to unlock
---------------------------------------------------------------------
Config.ModuleSlots = { "Drivetrain", "Intake", "Lift", "Brain" }

Config.SlotInfo = {
	Drivetrain = { Desc = "Speed and pushing power. Holonomic drives can strafe with Q and E." },
	Intake = { Desc = "How many balls you can hold, and how easily you pick them up." },
	Lift = { Desc = "How many points each scored ball is worth." },
	Brain = { Desc = "Driver control, plus autonomous points at the start of every match." },
}

Config.Modules = {
	Drivetrain = {
		{ Id = "dt_basic", Name = "2-Motor Tank Drive", Cost = 0, Speed = 2, Power = 2, Control = 1, Wheels = 4, WheelSize = 2.4, WheelColor = Color3.fromRGB(45, 45, 50), Accent = Color3.fromRGB(150, 150, 155), Desc = "The classic Clawbot base." },
		{ Id = "dt_4m", Name = "4-Motor Tank Drive", Cost = 300, Speed = 4, Power = 4, Control = 2, Wheels = 4, WheelSize = 2.6, WheelColor = Color3.fromRGB(45, 45, 50), Accent = Color3.fromRGB(220, 50, 50), Desc = "Twice the motors, twice the push." },
		{ Id = "dt_omni", Name = "6-Wheel Omni Drive", Cost = 2500, Speed = 7, Power = 6, Control = 4, Wheels = 6, WheelSize = 2.6, WheelColor = Color3.fromRGB(110, 110, 120), Accent = Color3.fromRGB(60, 200, 90), Desc = "Smooth turns, great traction." },
		{ Id = "dt_mecanum", Name = "Mecanum Drive", Cost = 15000, Speed = 8, Power = 5, Control = 8, Strafe = true, Wheels = 4, WheelSize = 2.8, WheelColor = Color3.fromRGB(230, 190, 60), Accent = Color3.fromRGB(60, 140, 230), Desc = "Strafe sideways with Q/E!" },
		{ Id = "dt_xdrive", Name = "X-Drive", Cost = 60000, Speed = 13, Power = 7, Control = 10, Strafe = true, Wheels = 4, WheelSize = 2.8, Diagonal = true, WheelColor = Color3.fromRGB(200, 200, 210), Accent = Color3.fromRGB(150, 70, 210), Desc = "Fast holonomic drive, strafes." },
		{ Id = "dt_blue", Name = "600 RPM Blue-Cartridge Drive", Cost = 250000, Speed = 18, Power = 12, Control = 12, Wheels = 6, WheelSize = 2.8, WheelColor = Color3.fromRGB(40, 40, 45), Accent = Color3.fromRGB(40, 120, 255), Season = 1, Desc = "Blazing fast. Season 1+." },
		{ Id = "dt_worlds", Name = "Worlds Holonomic Drive", Cost = 1200000, Speed = 25, Power = 18, Control = 18, Strafe = true, Wheels = 4, WheelSize = 3, Diagonal = true, WheelColor = Color3.fromRGB(255, 205, 60), Accent = Color3.fromRGB(255, 205, 60), Season = 2, Desc = "Championship-grade. Season 2+." },
	},
	Intake = {
		{ Id = "in_claw", Name = "Clawbot Claw", Cost = 0, Scoring = 1, Capacity = 1, Radius = 4, Style = "Claw", Color = Color3.fromRGB(160, 160, 165), Desc = "Holds 1 ball." },
		{ Id = "in_flex", Name = "Flex Wheel Intake", Cost = 400, Scoring = 3, Capacity = 2, Radius = 5, Style = "Rollers", Rollers = 1, Color = Color3.fromRGB(60, 200, 90), Desc = "Holds 2 balls." },
		{ Id = "in_roller", Name = "Roller Intake", Cost = 3000, Scoring = 6, Capacity = 3, Radius = 6, Style = "Rollers", Rollers = 2, Color = Color3.fromRGB(60, 140, 230), Desc = "Holds 3 balls." },
		{ Id = "in_chain", Name = "Hooked Chain Conveyor", Cost = 20000, Scoring = 10, Power = 1, Capacity = 4, Radius = 7, Style = "Rollers", Rollers = 3, Color = Color3.fromRGB(230, 120, 40), Desc = "Holds 4 balls." },
		{ Id = "in_dual", Name = "Dual Stage Intake", Cost = 90000, Scoring = 15, Power = 2, Capacity = 5, Radius = 7.5, Style = "Rollers", Rollers = 4, Color = Color3.fromRGB(220, 50, 50), Desc = "Holds 5 balls." },
		{ Id = "in_pro", Name = "Worlds Intake", Cost = 500000, Scoring = 24, Power = 3, Capacity = 7, Radius = 9, Style = "Rollers", Rollers = 4, Color = Color3.fromRGB(255, 205, 60), Season = 1, Desc = "Holds 7 balls. Season 1+." },
	},
	Lift = {
		{ Id = "lf_none", Name = "No Lift", Cost = 0, Points = 1, Style = "None", Color = Color3.fromRGB(150, 150, 155), Desc = "1 point per ball." },
		{ Id = "lf_4bar", Name = "4-Bar Lift", Cost = 800, Scoring = 2, Power = 1, Points = 2, Style = "FourBar", Color = Color3.fromRGB(200, 200, 210), Desc = "2 points per ball." },
		{ Id = "lf_dr4b", Name = "Double Reverse 4-Bar", Cost = 6000, Scoring = 5, Power = 1, Points = 3, Style = "DR4B", Color = Color3.fromRGB(60, 140, 230), Desc = "3 points per ball." },
		{ Id = "lf_cascade", Name = "Cascade Lift", Cost = 35000, Scoring = 9, Power = 2, Points = 4, Style = "Cascade", Color = Color3.fromRGB(60, 200, 90), Desc = "4 points per ball." },
		{ Id = "lf_cata", Name = "Pneumatic Catapult", Cost = 150000, Scoring = 14, Power = 3, Points = 5, Style = "Catapult", Color = Color3.fromRGB(220, 50, 50), Desc = "5 points per ball." },
		{ Id = "lf_fly", Name = "Flywheel Launcher", Cost = 700000, Scoring = 20, Power = 5, Points = 7, Style = "Flywheel", Color = Color3.fromRGB(255, 205, 60), Season = 1, Desc = "7 points per ball. Season 1+." },
	},
	Brain = {
		{ Id = "br_basic", Name = "Basic Controller", Cost = 0, Control = 1, Auton = 0, ScreenColor = Color3.fromRGB(120, 120, 120), Desc = "Driver control only." },
		{ Id = "br_v5", Name = "V5 Brain + Driver Code", Cost = 1000, Control = 3, Auton = 1, ScreenColor = Color3.fromRGB(80, 160, 255), Desc = "+1 auton point." },
		{ Id = "br_pid", Name = "PID Autonomous", Cost = 8000, Control = 6, Auton = 3, ScreenColor = Color3.fromRGB(80, 255, 140), Desc = "+3 auton points." },
		{ Id = "br_odom", Name = "Odometry + Pure Pursuit", Cost = 45000, Control = 10, Auton = 5, ScreenColor = Color3.fromRGB(255, 200, 60), Desc = "+5 auton points." },
		{ Id = "br_vision", Name = "Vision Sensor AI", Cost = 200000, Control = 15, Auton = 8, ScreenColor = Color3.fromRGB(255, 90, 200), Desc = "+8 auton points." },
		{ Id = "br_worlds", Name = "Worlds Skills Code", Cost = 900000, Control = 22, Auton = 12, ScreenColor = Color3.fromRGB(255, 60, 60), Season = 2, Desc = "+12 auton points. Season 2+." },
	},
}

Config.ModuleById = {}
for _, slot in ipairs(Config.ModuleSlots) do
	for index, def in ipairs(Config.Modules[slot]) do
		def.Slot = slot
		def.Index = index
		Config.ModuleById[def.Id] = def
	end
end

-- Returns computed stats for a loadout {Drivetrain=id, Intake=id, Lift=id, Brain=id}
function Config.GetRobotStats(loadout)
	local stats = { Speed = 0, Power = 0, Control = 0, Scoring = 0 }
	local defs = {}
	for _, slot in ipairs(Config.ModuleSlots) do
		local id = loadout and loadout[slot]
		local def = id and Config.ModuleById[id]
		if not def or def.Slot ~= slot then
			def = Config.Modules[slot][1]
		end
		defs[slot] = def
		stats.Speed += def.Speed or 0
		stats.Power += def.Power or 0
		stats.Control += def.Control or 0
		stats.Scoring += def.Scoring or 0
	end
	stats.Rating = stats.Speed + stats.Power + stats.Control + stats.Scoring
	stats.Capacity = defs.Intake.Capacity or 1
	stats.IntakeRadius = defs.Intake.Radius or 4
	stats.PointsPerBall = defs.Lift.Points or 1
	stats.Auton = defs.Brain.Auton or 0
	stats.Strafe = defs.Drivetrain.Strafe == true
	stats.MaxSpeed = 14 + stats.Speed * 0.7
	stats.TurnSpeed = 2.4 + stats.Control * 0.05
	stats.Force = 5000 + stats.Power * 900
	stats.Income = stats.Rating * Config.RobotIncomePerRating
	stats.BuildCost = math.floor(Config.BuildCostBase + stats.Rating * Config.BuildCostPerRating)
	return stats, defs
end

---------------------------------------------------------------------
-- Competitions (auto-simulated tournaments, uses your ACTIVE robot)
---------------------------------------------------------------------
Config.Competitions = {
	{ Id = "scrim", Name = "Club Scrimmage", MinRating = 0, Fee = 0, Difficulty = 6, Prize = 120, Trophies = 1, Cooldown = 45 },
	{ Id = "league", Name = "League Night", MinRating = 12, Fee = 60, Difficulty = 14, Prize = 700, Trophies = 2, Cooldown = 60 },
	{ Id = "qualifier", Name = "Local Qualifier", MinRating = 22, Fee = 300, Difficulty = 24, Prize = 3500, Trophies = 4, Cooldown = 90 },
	{ Id = "regional", Name = "Regional Championship", MinRating = 35, Fee = 2000, Difficulty = 38, Prize = 22000, Trophies = 8, Cooldown = 120 },
	{ Id = "state", Name = "State Championship", MinRating = 55, Fee = 12000, Difficulty = 58, Prize = 130000, Trophies = 15, Cooldown = 150 },
	{ Id = "nationals", Name = "Nationals", MinRating = 80, Fee = 60000, Difficulty = 84, Prize = 650000, Trophies = 30, Cooldown = 180 },
	{ Id = "worlds", Name = "World Championship", MinRating = 110, Fee = 300000, Difficulty = 112, Prize = 3500000, Trophies = 75, Cooldown = 240 },
}

Config.CompetitionById = {}
for _, comp in ipairs(Config.Competitions) do
	Config.CompetitionById[comp.Id] = comp
end

-- Payout fraction of the prize based on how far you got (0 = lost QF, 3 = champion)
Config.CompetitionPayout = { [0] = 0, [1] = 0.25, [2] = 0.5, [3] = 1 }

---------------------------------------------------------------------
-- Driving: practice field + ranked 1v1 matches
---------------------------------------------------------------------
Config.Field = {
	Size = 96,
	GoalRadius = 13,
	BallSize = 2.5,
	BallColor = Color3.fromRGB(80, 220, 90),
}

Config.Practice = {
	Balls = 14,
	CashPerPoint = 15, -- multiplied by season multiplier
}

Config.Match = {
	Duration = 90,
	Countdown = 5,
	Balls = 18,
	WinTrophies = 5,
	TieTrophies = 2,
	LoseTrophies = 1,
	WinCashBase = 500,
	WinCashPerRating = 40,
	LoseCash = 100,
}

---------------------------------------------------------------------
-- Game passes: put your real Game Pass IDs here (0 = disabled)
---------------------------------------------------------------------
Config.GamePasses = {
	{ Key = "DoubleCash", Name = "2x Cash", Id = 0, Desc = "Double all cash you earn, forever." },
	{ Key = "AutoCollect", Name = "Auto Collect", Id = 0, Desc = "Workshop cash goes straight to your wallet." },
	{ Key = "ExtraBays", Name = "+2 Robot Bays", Id = 0, Desc = "Two extra robot bays (needs Assembly Station)." },
	{ Key = "Turbo", Name = "Turbo Motors", Id = 0, Desc = "+15% drive speed in practice & ranked." },
}

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" }

function Config.Format(n)
	n = math.floor(tonumber(n) or 0)
	local negative = n < 0
	n = math.abs(n)
	local text
	if n < 1000 then
		text = tostring(n)
	else
		local index = 1
		local value = n
		while value >= 1000 and index < #SUFFIXES do
			value /= 1000
			index += 1
		end
		local fmt = value >= 100 and "%.0f%s" or (value >= 10 and "%.1f%s" or "%.2f%s")
		text = string.format(fmt, value, SUFFIXES[index])
	end
	return (negative and "-" or "") .. text
end

function Config.Money(n)
	return "$" .. Config.Format(n)
end

return Config
]=] })
table.insert(files, { Class = "ModuleScript", Service = "ServerScriptService", Sub = nil, Name = "DataManager", Source = [=[
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
		elseif type(value) == "table" and type(data[key]) == "table" and key ~= "Garage" then
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
		Stats = {
			CompWins = 0,
			CompsEntered = 0,
			MatchesPlayed = 0,
			MatchesWon = 0,
			BallsScored = 0,
			RobotsBuilt = 0,
			TotalEarned = 0,
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
]=] })
table.insert(files, { Class = "ModuleScript", Service = "ReplicatedStorage", Sub = nil, Name = "RobotBuilder", Source = [=[
--[[
	RobotBuilder (ModuleScript)  ->  ReplicatedStorage.RobotBuilder
	Shared so the UI can show live 3D robot previews.

	Builds a 3D VEX-style robot Model out of the chosen modules.
	  RobotBuilder.Build(loadout, options) -> model, stats
	options:
	  Drive      = true  -> unanchored, has a VehicleSeat + drive constraints
	  TeamColor  = Color3 accent color
	  Label      = text shown above the robot
	  SubLabel   = second line of text
	  NoNameplate = true -> skip the floating name tag (UI previews)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local RobotBuilder = {}

local FONT_BOLD = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
local FONT_SEMI = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold)

local METAL = Color3.fromRGB(196, 198, 204)
local DARK = Color3.fromRGB(35, 35, 40)
local MOTOR = Color3.fromRGB(55, 30, 30)

local function makeBillboard(root, label, subLabel, accent)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Nameplate"
	gui.Size = UDim2.new(9, 0, 2.2, 0)
	gui.StudsOffset = Vector3.new(0, 6.5, 0)
	gui.MaxDistance = 110
	gui.LightInfluence = 0
	gui.Parent = root

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(16, 16, 18)
	card.BackgroundTransparency = 0.2
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 1
	stroke.Transparency = 0.85
	stroke.Parent = card

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0.1, 0, 0.1, 0)
	title.Size = UDim2.new(0.8, 0, 0.46, 0)
	title.FontFace = FONT_BOLD
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = label or "Robot"
	title.Parent = card

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.new(0.1, 0, 0.56, 0)
	sub.Size = UDim2.new(0.8, 0, 0.3, 0)
	sub.FontFace = FONT_SEMI
	sub.TextScaled = true
	sub.TextColor3 = Color3.fromRGB(170, 170, 178)
	sub.Text = subLabel or ""
	sub.Parent = card
end

function RobotBuilder.Build(loadout, options)
	options = options or {}
	local stats, defs = Config.GetRobotStats(loadout)
	local drivetrain, intake, lift, brain = defs.Drivetrain, defs.Intake, defs.Lift, defs.Brain
	local accent = options.TeamColor or drivetrain.Accent

	local model = Instance.new("Model")
	model.Name = options.Name or "VexRobot"

	-- Invisible collision box. Everything else is decoration welded to it.
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(7.4, 2, 8.4)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = true
	root.CFrame = CFrame.new()
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.25, 0, 1, 1)
	root.Parent = model
	model.PrimaryPart = root

	local function add(name, size, cf, color, material, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		if shape then
			p.Shape = shape
		end
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	-------------------------------------------------------------- drivetrain
	local wheelD = drivetrain.WheelSize or 2.5
	local wy = -1 + wheelD / 2 -- axle height (root bottom is the floor)

	add("Chassis", Vector3.new(6, 0.3, 8), CFrame.new(0, wy, 0), METAL, Enum.Material.Metal)
	add("RailL", Vector3.new(0.5, 1, 8.2), CFrame.new(-3, wy + 0.35, 0), METAL, Enum.Material.Metal)
	add("RailR", Vector3.new(0.5, 1, 8.2), CFrame.new(3, wy + 0.35, 0), METAL, Enum.Material.Metal)
	add("CrossF", Vector3.new(6, 0.6, 0.5), CFrame.new(0, wy + 0.35, -3.8), accent, Enum.Material.Metal)
	add("CrossB", Vector3.new(6, 0.6, 0.5), CFrame.new(0, wy + 0.35, 3.8), accent, Enum.Material.Metal)

	local wheelZ = drivetrain.Wheels == 6 and { -3, 0, 3 } or { -3, 3 }
	for _, z in ipairs(wheelZ) do
		for _, side in ipairs({ -1, 1 }) do
			local cf = CFrame.new(side * 3.65, wy, z)
			if drivetrain.Diagonal then
				local angle = (z < 0) == (side < 0) and 45 or -45
				cf = cf * CFrame.Angles(0, math.rad(angle), 0)
			end
			add("Wheel", Vector3.new(0.8, wheelD, wheelD), cf, drivetrain.WheelColor, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
			add("Hub", Vector3.new(0.85, wheelD * 0.4, wheelD * 0.4), cf, accent, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
			add("Motor", Vector3.new(0.9, 0.9, 1.2), CFrame.new(side * 2.2, wy + 0.35, z), MOTOR, Enum.Material.SmoothPlastic)
		end
	end

	-------------------------------------------------------------- intake (front = -Z)
	if intake.Style == "Claw" then
		add("ClawBase", Vector3.new(3, 0.4, 0.6), CFrame.new(0, wy + 1.2, -4.3), intake.Color, Enum.Material.Metal)
		add("ClawL", Vector3.new(0.3, 0.6, 1.8), CFrame.new(-1.2, wy + 1.2, -5.2), intake.Color, Enum.Material.Metal)
		add("ClawR", Vector3.new(0.3, 0.6, 1.8), CFrame.new(1.2, wy + 1.2, -5.2), intake.Color, Enum.Material.Metal)
		add("ClawPost", Vector3.new(0.4, 1.6, 0.4), CFrame.new(0, wy + 0.6, -4), METAL, Enum.Material.Metal)
	else
		local count = intake.Rollers or 1
		add("IntakePlateL", Vector3.new(0.25, 0.8 + count * 0.9, 2.2), CFrame.new(-2.9, wy + 0.4 + count * 0.45, -4.6), METAL, Enum.Material.Metal)
		add("IntakePlateR", Vector3.new(0.25, 0.8 + count * 0.9, 2.2), CFrame.new(2.9, wy + 0.4 + count * 0.45, -4.6), METAL, Enum.Material.Metal)
		for i = 1, count do
			local y = wy - 0.1 + i * 0.9
			local z = -4.9 + (i % 2) * 0.5
			add("Roller", Vector3.new(5.5, 0.85, 0.85), CFrame.new(0, y, z), intake.Color, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		end
	end

	-------------------------------------------------------------- lift (back = +Z)
	local liftColor = lift.Color
	if lift.Style == "FourBar" or lift.Style == "DR4B" then
		local towerH = lift.Style == "DR4B" and 4.5 or 3.5
		for _, side in ipairs({ -1, 1 }) do
			add("Tower", Vector3.new(0.4, towerH, 0.4), CFrame.new(side * 2.6, wy + towerH / 2, 3), METAL, Enum.Material.Metal)
			add("Arm", Vector3.new(0.3, 0.3, 5.5), CFrame.new(side * 2.6, wy + towerH - 0.4, 0.6) * CFrame.Angles(math.rad(-18), 0, 0), liftColor, Enum.Material.Metal)
			add("Arm2", Vector3.new(0.3, 0.3, 5.5), CFrame.new(side * 2.6, wy + towerH - 1.4, 0.6) * CFrame.Angles(math.rad(-18), 0, 0), liftColor, Enum.Material.Metal)
			if lift.Style == "DR4B" then
				add("UpperArm", Vector3.new(0.3, 0.3, 4.5), CFrame.new(side * 2.6, wy + towerH + 1, 1.2) * CFrame.Angles(math.rad(20), 0, 0), liftColor, Enum.Material.Metal)
			end
		end
	elseif lift.Style == "Cascade" then
		for _, side in ipairs({ -1, 1 }) do
			add("Stage1", Vector3.new(0.5, 5, 0.5), CFrame.new(side * 2.4, wy + 2.5, 3), METAL, Enum.Material.Metal)
			add("Stage2", Vector3.new(0.35, 4.5, 0.35), CFrame.new(side * 2.0, wy + 4.2, 3), liftColor, Enum.Material.Metal)
		end
		add("Carriage", Vector3.new(4.8, 0.4, 1.2), CFrame.new(0, wy + 6.3, 2.6), liftColor, Enum.Material.Metal)
	elseif lift.Style == "Catapult" then
		add("CataBase", Vector3.new(4, 0.8, 1), CFrame.new(0, wy + 0.8, 2.6), METAL, Enum.Material.Metal)
		add("CataArm", Vector3.new(0.5, 0.5, 5.5), CFrame.new(0, wy + 2.6, 1.5) * CFrame.Angles(math.rad(35), 0, 0), liftColor, Enum.Material.Metal)
		add("CataCup", Vector3.new(1.8, 0.4, 1.8), CFrame.new(0, wy + 4.2, -0.6), liftColor, Enum.Material.SmoothPlastic)
		add("Piston", Vector3.new(0.3, 2, 0.3), CFrame.new(1.3, wy + 1.6, 2.4), Color3.fromRGB(230, 230, 230), Enum.Material.Glass)
	elseif lift.Style == "Flywheel" then
		add("FlyFrame", Vector3.new(0.3, 3.5, 3.5), CFrame.new(-1.8, wy + 2.5, 2.3), METAL, Enum.Material.Metal)
		add("FlyFrame2", Vector3.new(0.3, 3.5, 3.5), CFrame.new(1.8, wy + 2.5, 2.3), METAL, Enum.Material.Metal)
		add("Flywheel", Vector3.new(0.7, 3.2, 3.2), CFrame.new(0, wy + 2.8, 2.3), liftColor, Enum.Material.Metal, Enum.PartType.Cylinder)
		add("Hood", Vector3.new(3.4, 0.25, 3), CFrame.new(0, wy + 4.5, 1.8) * CFrame.Angles(math.rad(-15), 0, 0), Color3.fromRGB(240, 240, 240), Enum.Material.Glass)
	end

	-------------------------------------------------------------- brain + battery
	add("Brain", Vector3.new(2, 0.5, 1.6), CFrame.new(0, wy + 0.75, -1.6), DARK, Enum.Material.SmoothPlastic)
	add("Screen", Vector3.new(1.6, 0.05, 1.1), CFrame.new(0, wy + 1.03, -1.6), brain.ScreenColor, Enum.Material.Neon)
	add("Battery", Vector3.new(1.4, 0.6, 2), CFrame.new(-1.4, wy + 0.8, 1.4), Color3.fromRGB(30, 30, 35), Enum.Material.SmoothPlastic)
	if (brain.Auton or 0) >= 5 then
		add("Antenna", Vector3.new(1.8, 0.15, 0.15), CFrame.new(1.4, wy + 1.8, -1.6) * CFrame.Angles(0, 0, math.rad(90)), DARK, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		add("AntennaTip", Vector3.new(0.35, 0.35, 0.35), CFrame.new(1.4, wy + 2.7, -1.6), brain.ScreenColor, Enum.Material.Neon, Enum.PartType.Ball)
	end
	if brain.Id ~= "br_basic" then
		add("Sensor", Vector3.new(0.8, 0.5, 0.4), CFrame.new(0, wy + 0.5, -4.15), Color3.fromRGB(40, 40, 45), Enum.Material.SmoothPlastic)
	end

	-------------------------------------------------------------- seat
	if options.Drive then
		local seat = Instance.new("VehicleSeat")
		seat.Name = "DriverSeat"
		seat.Size = Vector3.new(2.4, 0.4, 2.4)
		seat.CFrame = CFrame.new(0, wy + 1.1, 1.2)
		seat.Color = accent
		seat.Material = Enum.Material.SmoothPlastic
		seat.MaxSpeed = 0
		seat.Torque = 0
		seat.TurnSpeed = 0
		seat.HeadsUpDisplay = false
		seat.CanCollide = false
		seat.CanTouch = false -- only the server can seat someone
		seat.Massless = true
		seat.Anchored = true
		seat:SetAttribute("VexRobot", true)
		seat.Parent = model
	end

	if not options.NoNameplate then
		makeBillboard(root, options.Label, options.SubLabel, accent)
	end

	-------------------------------------------------------------- weld everything to root
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = d
			weld.Parent = d
		end
	end

	if options.Drive then
		local attachment = Instance.new("Attachment")
		attachment.Name = "DriveAttachment"
		attachment.Parent = root

		local lv = Instance.new("LinearVelocity")
		lv.Name = "DriveLV"
		lv.Attachment0 = attachment
		lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
		lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
		lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
		lv.PlaneVelocity = Vector2.new(0, 0)
		lv.MaxForce = stats.Force
		lv.Parent = root

		local av = Instance.new("AngularVelocity")
		av.Name = "DriveAV"
		av.Attachment0 = attachment
		av.RelativeTo = Enum.ActuatorRelativeTo.World
		av.AngularVelocity = Vector3.zero
		av.MaxTorque = stats.Force * 5
		av.Parent = root

		model:SetAttribute("MaxSpeed", stats.MaxSpeed)
		model:SetAttribute("TurnSpeed", stats.TurnSpeed)
		model:SetAttribute("Strafe", stats.Strafe)
	end

	model:SetAttribute("Rating", stats.Rating)
	return model, stats
end

function RobotBuilder.SetAnchored(model, anchored)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = anchored
		end
	end
end

return RobotBuilder
]=] })
table.insert(files, { Class = "ModuleScript", Service = "ServerScriptService", Sub = nil, Name = "WorldBuilder", Source = [=[
--[[
	WorldBuilder (ModuleScript)  ->  ServerScriptService.WorldBuilder

	Generates the whole map from code so you don't need to model anything:
	  * Hub plaza with leaderboard + competition kiosk
	  * Practice field and Ranked field (VEX-style 1v1 arena)
	  * 6 team workshops (tycoon plots) with conveyor + collector
	Also builds every purchasable workshop item.

	WorldBuilder.GetWorld() builds once and returns the same table to
	every script that asks.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local WorldBuilder = {}
local world = nil

local SMOOTH = Enum.SurfaceType.Smooth
local FONT_BOLD = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)
local FONT_SEMI = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.SemiBold)
local SIGN_BLACK = Color3.fromRGB(16, 16, 18)
local VEX_RED = Color3.fromRGB(226, 35, 42)
local METAL = Color3.fromRGB(196, 198, 204)
local WHITE = Color3.fromRGB(240, 240, 240)

---------------------------------------------------------------------
-- Small helpers
---------------------------------------------------------------------
local function newPart(parent, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = SMOOTH
	p.BottomSurface = SMOOTH
	p.Material = Enum.Material.SmoothPlastic
	for key, value in pairs(props) do
		p[key] = value
	end
	p.Parent = parent
	return p
end

-- a part placed in plot-local coordinates
local function plotPart(plot, parent, size, pos, color, material, extra)
	local props = {
		Size = size,
		CFrame = plot.CFrame * CFrame.new(pos),
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	}
	if extra then
		for k, v in pairs(extra) do
			props[k] = v
		end
	end
	return newPart(parent, props)
end

local function surfaceText(part, face, text, textColor, bgColor, font)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = bgColor and 0 or 1
	label.BackgroundColor3 = bgColor or Color3.new(0, 0, 0)
	label.TextScaled = true
	label.FontFace = font or FONT_BOLD
	label.TextColor3 = textColor or Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0.04, 0)
	pad.PaddingRight = UDim.new(0.04, 0)
	pad.PaddingTop = UDim.new(0.08, 0)
	pad.PaddingBottom = UDim.new(0.08, 0)
	pad.Parent = label
	return label
end

local function billboard(adornee, text, studsWidth, studsHeight, offset, color)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(studsWidth, 0, studsHeight, 0)
	gui.StudsOffset = offset or Vector3.new(0, 3, 0)
	gui.MaxDistance = 90
	gui.LightInfluence = 0
	gui.Parent = adornee
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = SIGN_BLACK
	card.BackgroundTransparency = 0.2
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = 1
	stroke.Transparency = 0.85
	stroke.Parent = card
	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromScale(0.05, 0.1)
	label.Size = UDim2.fromScale(0.9, 0.8)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.FontFace = FONT_SEMI
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = card
	return label
end

-- two-line "shop tag" used above tycoon buttons
local function priceTag(adornee, name, price)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(8, 0, 2.2, 0)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	gui.Parent = adornee
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = SIGN_BLACK
	card.BackgroundTransparency = 0.15
	card.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = card
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Position = UDim2.fromScale(0.06, 0.1)
	nameLabel.Size = UDim2.fromScale(0.88, 0.48)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextScaled = true
	nameLabel.FontFace = FONT_BOLD
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.Text = name
	nameLabel.Parent = card
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "Price"
	priceLabel.Position = UDim2.fromScale(0.06, 0.58)
	priceLabel.Size = UDim2.fromScale(0.88, 0.32)
	priceLabel.BackgroundTransparency = 1
	priceLabel.TextScaled = true
	priceLabel.FontFace = FONT_SEMI
	priceLabel.TextColor3 = Color3.fromRGB(170, 170, 178)
	priceLabel.Text = price
	priceLabel.Parent = card
	return card
end

-- black VEX-style sign with a red accent bar along the bottom
local function vexSign(parent, size, cf, text)
	local sign = newPart(parent, { Size = size, CFrame = cf, Color = SIGN_BLACK })
	newPart(parent, { Size = Vector3.new(size.X, 0.4, size.Z + 0.1), CFrame = cf * CFrame.new(0, -size.Y / 2 + 0.2, 0), Color = VEX_RED })
	surfaceText(sign, Enum.NormalId.Front, text, Color3.new(1, 1, 1))
	return sign
end

local function setupLighting()
	local Lighting = game:GetService("Lighting")
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.2
	Lighting.GlobalShadows = true
	Lighting.OutdoorAmbient = Color3.fromRGB(135, 135, 150)
	Lighting.Ambient = Color3.fromRGB(60, 60, 75)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	local function ensure(className, props)
		local effect = Lighting:FindFirstChildOfClass(className)
		if not effect then
			effect = Instance.new(className)
			for k, v in pairs(props) do
				effect[k] = v
			end
			effect.Parent = Lighting
		end
	end
	ensure("Atmosphere", { Density = 0.28, Offset = 0.2, Color = Color3.fromRGB(200, 215, 235), Decay = Color3.fromRGB(110, 120, 150), Glare = 0.1, Haze = 1 })
	ensure("BloomEffect", { Intensity = 0.2, Size = 20, Threshold = 2 })
	ensure("ColorCorrectionEffect", { Saturation = 0.03, Contrast = 0.04, Brightness = 0 })
	ensure("SunRaysEffect", { Intensity = 0.03, Spread = 0.5 })
end

local function prompt(parent, actionText, objectText, holdTime)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = actionText
	p.ObjectText = objectText or ""
	p.HoldDuration = holdTime or 0
	p.MaxActivationDistance = 12
	p.RequiresLineOfSight = false
	p.Parent = parent
	return p
end

local function folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

---------------------------------------------------------------------
-- Hub
---------------------------------------------------------------------
local function buildHub(root)
	local hub = { }
	local hubFolder = folder("Hub", root)

	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Color = Color3.fromRGB(80, 140, 70)
		baseplate.Material = Enum.Material.Grass
		for _, child in ipairs(baseplate:GetChildren()) do
			if child:IsA("Texture") then
				child:Destroy()
			end
		end
	else
		newPart(hubFolder, {
			Name = "Ground",
			Size = Vector3.new(1200, 2, 1200),
			CFrame = CFrame.new(0, -1, 0),
			Color = Color3.fromRGB(80, 140, 70),
			Material = Enum.Material.Grass,
		})
	end

	newPart(hubFolder, {
		Name = "Plaza",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, Config.HubRadius * 2, Config.HubRadius * 2),
		CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(205, 205, 210),
		Material = Enum.Material.Concrete,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.CFrame = CFrame.new(0, 0.5, 72)
	spawn.Color = Color3.fromRGB(40, 40, 44)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Duration = 0
	spawn.TopSurface = SMOOTH
	spawn.Parent = hubFolder

	-- floating title
	local title = newPart(hubFolder, {
		Name = "Title",
		Size = Vector3.new(60, 10, 1),
		CFrame = CFrame.new(0, 30, 0),
		Color = SIGN_BLACK,
	})
	newPart(hubFolder, { Size = Vector3.new(60, 0.6, 1.1), CFrame = CFrame.new(0, 25.3, 0), Color = VEX_RED })
	surfaceText(title, Enum.NormalId.Front, string.upper(Config.GameName), Color3.new(1, 1, 1))
	surfaceText(title, Enum.NormalId.Back, string.upper(Config.GameName), Color3.new(1, 1, 1))

	-- leaderboard (faces the center)
	local board = newPart(hubFolder, {
		Name = "Leaderboard",
		Size = Vector3.new(18, 22, 1),
		CFrame = CFrame.new(0, 12, -100),
		Color = SIGN_BLACK,
	})
	newPart(hubFolder, { Size = Vector3.new(1, 12, 1), CFrame = CFrame.new(-7, 0.5, -100), Color = METAL, Material = Enum.Material.Metal })
	newPart(hubFolder, { Size = Vector3.new(1, 12, 1), CFrame = CFrame.new(7, 0.5, -100), Color = METAL, Material = Enum.Material.Metal })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 25
	gui.LightInfluence = 0
	gui.Parent = board
	local list = Instance.new("Frame")
	list.Size = UDim2.fromScale(1, 1)
	list.BackgroundTransparency = 1
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 60)
	header.BackgroundColor3 = VEX_RED
	header.FontFace = FONT_BOLD
	header.TextScaled = true
	header.TextColor3 = Color3.new(1, 1, 1)
	header.Text = "TOP TEAMS  ·  TROPHIES"
	header.Parent = list
	hub.LeaderboardRows = {}
	for i = 1, 10 do
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, 0, 0, 40)
		row.BackgroundTransparency = 1
		row.FontFace = FONT_SEMI
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = i <= 3 and Color3.new(1, 1, 1) or Color3.fromRGB(170, 170, 178)
		row.Text = string.format("  %d    —", i)
		row.Parent = list
		hub.LeaderboardRows[i] = row
	end

	-- competition kiosk
	local kiosk = newPart(hubFolder, {
		Name = "CompetitionKiosk",
		Size = Vector3.new(14, 6, 4),
		CFrame = CFrame.new(0, 3.3, 100),
		Color = SIGN_BLACK,
	})
	vexSign(hubFolder, Vector3.new(18, 5, 1), CFrame.new(0, 10, 100), "COMPETITIONS")
	hub.CompetitionPrompt = prompt(kiosk, "Enter Competitions", "Tournament Desk")

	-- lamp posts
	for i = 0, 11 do
		local angle = math.rad(i * 30 + 15)
		local pos = Vector3.new(math.sin(angle), 0, math.cos(angle)) * (Config.HubRadius - 6)
		newPart(hubFolder, { Size = Vector3.new(0.8, 12, 0.8), CFrame = CFrame.new(pos + Vector3.new(0, 6, 0)), Color = Color3.fromRGB(50, 50, 55), Material = Enum.Material.Metal })
		local bulb = newPart(hubFolder, { Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(pos + Vector3.new(0, 12.5, 0)), Color = Color3.fromRGB(255, 240, 200), Material = Enum.Material.Neon })
		local light = Instance.new("PointLight")
		light.Range = 24
		light.Brightness = 1.5
		light.Parent = bulb
	end

	return hub
end

---------------------------------------------------------------------
-- Driving fields
---------------------------------------------------------------------
local function buildField(root, name, center, accentText)
	local size = Config.Field.Size
	local half = size / 2
	local field = {
		Name = name,
		CFrame = CFrame.new(center),
		Size = size,
		Goals = {},
		Spawns = {},
	}
	local f = folder(name .. "Field", root)
	field.Folder = f
	field.Balls = folder("Balls", f)
	field.Robots = folder("Robots", f)

	local function at(x, y, z)
		return field.CFrame * CFrame.new(x, y, z)
	end

	-- foam tiles (6x6 grid like a real field)
	local tile = size / 6
	for ix = 0, 5 do
		for iz = 0, 5 do
			newPart(f, {
				Name = "Tile",
				Size = Vector3.new(tile, 0.5, tile),
				CFrame = at(-half + tile * (ix + 0.5), 0.35, -half + tile * (iz + 0.5)),
				Color = ((ix + iz) % 2 == 0) and Color3.fromRGB(105, 105, 112) or Color3.fromRGB(92, 92, 100),
				Material = Enum.Material.Fabric,
			})
		end
	end
	newPart(f, { Name = "CenterLine", Size = Vector3.new(0.4, 0.05, size), CFrame = at(0, 0.62, 0), Color = WHITE })

	-- perimeter walls (clear polycarbonate + aluminum rail)
	local wallH = 7
	local walls = {
		{ Vector3.new(size + 2, wallH, 1), Vector3.new(0, wallH / 2 + 0.6, -half - 0.5) },
		{ Vector3.new(size + 2, wallH, 1), Vector3.new(0, wallH / 2 + 0.6, half + 0.5) },
		{ Vector3.new(1, wallH, size), Vector3.new(-half - 0.5, wallH / 2 + 0.6, 0) },
		{ Vector3.new(1, wallH, size), Vector3.new(half + 0.5, wallH / 2 + 0.6, 0) },
	}
	for _, w in ipairs(walls) do
		newPart(f, { Name = "Wall", Size = w[1], CFrame = at(w[2].X, w[2].Y, w[2].Z), Color = Color3.fromRGB(200, 230, 255), Material = Enum.Material.Glass, Transparency = 0.6 })
		newPart(f, { Name = "Rail", Size = Vector3.new(w[1].X, 0.4, w[1].Z), CFrame = at(w[2].X, wallH + 0.8, w[2].Z), Color = METAL, Material = Enum.Material.Metal })
	end

	-- goals
	for _, info in ipairs({ { "Red", -1, Color3.fromRGB(220, 45, 50) }, { "Blue", 1, Color3.fromRGB(40, 110, 230) } }) do
		local side, sign, color = info[1], info[2], info[3]
		local gx = sign * (half - 4)
		local pad = newPart(f, { Name = side .. "GoalPad", Size = Vector3.new(8, 0.1, 12), CFrame = at(gx, 0.65, 0), Color = color, Material = Enum.Material.SmoothPlastic })
		newPart(f, { Size = Vector3.new(0.6, 8, 0.6), CFrame = at(gx + sign * 3.5, 4.6, -5.5), Color = color, Material = Enum.Material.Metal })
		newPart(f, { Size = Vector3.new(0.6, 8, 0.6), CFrame = at(gx + sign * 3.5, 4.6, 5.5), Color = color, Material = Enum.Material.Metal })
		newPart(f, { Size = Vector3.new(0.6, 0.6, 11.6), CFrame = at(gx + sign * 3.5, 8.6, 0), Color = color, Material = Enum.Material.Metal })
		newPart(f, { Name = "Net", Size = Vector3.new(0.2, 7.5, 11), CFrame = at(gx + sign * 3.7, 4.6, 0), Color = Color3.new(1, 1, 1), Material = Enum.Material.ForceField, Transparency = 0.3, CanCollide = false })
		local ring = newPart(f, {
			Name = side .. "ScoreZone",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.05, Config.Field.GoalRadius * 2, Config.Field.GoalRadius * 2),
			CFrame = at(gx, 0.62, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = color,
			Material = Enum.Material.Neon,
			Transparency = 0.75,
			CanCollide = false,
			CanTouch = false,
			CanQuery = false,
		})
		field.Goals[side] = { Position = at(gx, 0.6, 0).Position, Pad = pad, Zone = ring, Color = color }
	end

	-- spawns
	field.Spawns.Red = CFrame.lookAt(at(-30, 0.6, -30).Position, at(0, 0.6, -30).Position)
	field.Spawns.Blue = CFrame.lookAt(at(30, 0.6, 30).Position, at(0, 0.6, 30).Position)
	field.Spawns.List = {}
	for _, p in ipairs({ { -20, -34 }, { 20, -34 }, { -20, 34 }, { 20, 34 }, { 0, -20 }, { 0, 20 }, { -28, 0 }, { 28, 0 } }) do
		local pos = at(p[1], 0.6, p[2]).Position
		table.insert(field.Spawns.List, CFrame.lookAt(pos, at(0, 0.6, 0).Position))
	end

	-- entrance kiosk
	local kiosk = newPart(f, { Name = "Kiosk", Size = Vector3.new(10, 4, 3), CFrame = at(0, 2.3, -half - 10), Color = SIGN_BLACK })
	vexSign(f, Vector3.new(28, 5, 1), at(0, 13, -half - 1.5), accentText)
	field.Kiosk = kiosk
	field.ExitCFrame = at(0, 3.5, -half - 16)

	return field
end

local function buildScoreboard(field)
	local half = field.Size / 2
	local board = newPart(field.Folder, {
		Name = "Scoreboard",
		Size = Vector3.new(40, 12, 1),
		CFrame = field.CFrame * CFrame.new(0, 17, half + 3),
		Color = SIGN_BLACK,
	})
	local labels = {}
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 20
		gui.LightInfluence = 0
		gui.Parent = board
		local function make(text, x, w, color)
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Position = UDim2.fromScale(x, 0)
			l.Size = UDim2.fromScale(w, 1)
			l.FontFace = FONT_BOLD
			l.TextScaled = true
			l.TextColor3 = color
			l.Text = text
			l.Parent = gui
			return l
		end
		table.insert(labels, {
			Red = make("0", 0, 0.3, Color3.fromRGB(255, 80, 80)),
			Status = make("WAITING FOR PLAYERS", 0.3, 0.4, Color3.new(1, 1, 1)),
			Blue = make("0", 0.7, 0.3, Color3.fromRGB(90, 160, 255)),
		})
	end
	field.Scoreboard = labels
end

---------------------------------------------------------------------
-- Workshop plots
---------------------------------------------------------------------
local function buildPlot(root, index)
	local angle = math.rad((index - 1) * (360 / Config.MaxPlots))
	local center = Vector3.new(math.sin(angle), 0, math.cos(angle)) * Config.PlotRadius
	local cf = CFrame.lookAt(center, Vector3.new(0, 0, 0))
	local color = Config.PlotColors[((index - 1) % #Config.PlotColors) + 1]
	local half = Config.PlotSize / 2

	local plot = {
		Id = index,
		CFrame = cf,
		Color = color,
		Owner = nil,
		Storage = 0,
		Built = {},
		ButtonModels = {},
		Token = 0,
	}
	local model = Instance.new("Model")
	model.Name = "Plot" .. index
	model.Parent = root
	plot.Folder = model
	plot.Base = folder("Base", model)
	plot.Items = folder("Items", model)
	plot.Buttons = folder("Buttons", model)
	plot.Drops = folder("Drops", model)
	plot.Bays = folder("Bays", model)

	local base = plot.Base
	plotPart(plot, base, Vector3.new(Config.PlotSize, 1, Config.PlotSize), Vector3.new(0, 0.5, 0), Color3.fromRGB(175, 175, 180), Enum.Material.Concrete, { Name = "Floor" })
	-- colored border
	plotPart(plot, base, Vector3.new(Config.PlotSize, 1.2, 1), Vector3.new(0, 0.6, -half + 0.5), color, Enum.Material.SmoothPlastic)
	plotPart(plot, base, Vector3.new(Config.PlotSize, 1.2, 1), Vector3.new(0, 0.6, half - 0.5), color, Enum.Material.SmoothPlastic)
	plotPart(plot, base, Vector3.new(1, 1.2, Config.PlotSize), Vector3.new(-half + 0.5, 0.6, 0), color, Enum.Material.SmoothPlastic)
	plotPart(plot, base, Vector3.new(1, 1.2, Config.PlotSize), Vector3.new(half - 0.5, 0.6, 0), color, Enum.Material.SmoothPlastic)

	-- path to hub
	local pathLength = Config.PlotRadius - half - Config.HubRadius + 6
	plotPart(plot, base, Vector3.new(16, 0.4, pathLength), Vector3.new(0, 0.1, -half - pathLength / 2 + 2), Color3.fromRGB(150, 150, 155), Enum.Material.Concrete)

	-- owner sign
	local sign = plotPart(plot, base, Vector3.new(26, 6, 1), Vector3.new(-30, 6, -half + 1), SIGN_BLACK)
	plotPart(plot, base, Vector3.new(1, 3, 1), Vector3.new(-40, 2, -half + 1), METAL, Enum.Material.Metal)
	plotPart(plot, base, Vector3.new(1, 3, 1), Vector3.new(-20, 2, -half + 1), METAL, Enum.Material.Metal)
	plotPart(plot, base, Vector3.new(26, 0.4, 1.1), Vector3.new(-30, 3.2, -half + 1), color, Enum.Material.SmoothPlastic)
	plot.OwnerLabel = surfaceText(sign, Enum.NormalId.Front, "Empty Workshop", Color3.new(1, 1, 1))

	-- spawn pad
	plotPart(plot, base, Vector3.new(8, 0.2, 8), Vector3.new(30, 1.1, -42), color, Enum.Material.SmoothPlastic, { CanCollide = false })
	plot.SpawnCFrame = cf * CFrame.new(30, 4, -42) * CFrame.Angles(0, math.pi, 0)

	-- conveyor
	local z = Config.Layout.ConveyorZ
	local conveyor = plotPart(plot, base, Vector3.new(79, 1, 6), Vector3.new(-5.5, 3, z), Color3.fromRGB(40, 40, 45), Enum.Material.DiamondPlate, { Name = "Conveyor" })
	conveyor.AssemblyLinearVelocity = cf.RightVector * Config.ConveyorSpeed
	plotPart(plot, base, Vector3.new(79, 1.2, 0.5), Vector3.new(-5.5, 4.1, z - 3.25), METAL, Enum.Material.Metal)
	plotPart(plot, base, Vector3.new(79, 1.2, 0.5), Vector3.new(-5.5, 4.1, z + 3.25), METAL, Enum.Material.Metal)
	for x = -40, 30, 14 do
		plotPart(plot, base, Vector3.new(1, 2, 5), Vector3.new(x, 1.5, z), Color3.fromRGB(60, 60, 65), Enum.Material.Metal)
	end
	plotPart(plot, base, Vector3.new(1, 3, 6), Vector3.new(-45.5, 4, z), METAL, Enum.Material.Metal) -- end stop

	-- collector
	local collector = plotPart(plot, base, Vector3.new(11, 1, 10), Vector3.new(39.5, 1.5, z), Color3.fromRGB(40, 40, 44), Enum.Material.DiamondPlate, { Name = "Collector" })
	plotPart(plot, base, Vector3.new(11, 3, 0.5), Vector3.new(39.5, 3, z - 5), METAL, Enum.Material.Metal)
	plotPart(plot, base, Vector3.new(11, 3, 0.5), Vector3.new(39.5, 3, z + 5), METAL, Enum.Material.Metal)
	plotPart(plot, base, Vector3.new(0.5, 3, 10), Vector3.new(45.25, 3, z), METAL, Enum.Material.Metal)
	plot.Collector = collector
	billboard(collector, "PART COLLECTOR", 10, 1.5, Vector3.new(0, 4, 0), Color3.fromRGB(255, 255, 255))

	-- collect pad
	local collectPad = plotPart(plot, base, Vector3.new(7, 0.4, 7), Vector3.new(40, 1.2, -4), Color3.fromRGB(52, 199, 89), Enum.Material.SmoothPlastic, { Name = "CollectPad" })
	plot.CollectPad = collectPad
	plot.StorageLabel = billboard(collectPad, "Collect\n$0", 9, 3, Vector3.new(0, 4, 0), Color3.fromRGB(120, 255, 140))

	return plot
end

---------------------------------------------------------------------
-- Tycoon buttons
---------------------------------------------------------------------
function WorldBuilder.BuildButton(plot, item)
	local cols = Config.Layout.ButtonColumns
	local rows = Config.Layout.ButtonRows
	local i = item.Index - 1
	local x = cols[(i % #cols) + 1]
	local z = rows[(math.floor(i / #cols) % #rows) + 1]

	local model = Instance.new("Model")
	model.Name = "Button_" .. item.Id
	local pad = plotPart(plot, model, Vector3.new(0.6, 5, 5), Vector3.new(x, 1.3, z), Color3.fromRGB(60, 220, 90), Enum.Material.Neon, {
		Name = "Pad",
		Shape = Enum.PartType.Cylinder,
		CanCollide = false,
	})
	pad.CFrame = pad.CFrame * CFrame.Angles(0, 0, math.rad(90))
	plotPart(plot, model, Vector3.new(0.4, 6, 6), Vector3.new(x, 1.1, z), Color3.fromRGB(40, 40, 45), Enum.Material.Metal, {
		Shape = Enum.PartType.Cylinder,
		CFrame = plot.CFrame * CFrame.new(x, 1.1, z) * CFrame.Angles(0, 0, math.rad(90)),
	})
	local priceText = item.Cost == 0 and "FREE" or Config.Money(item.Cost)
	priceTag(pad, item.Name, priceText)
	model.PrimaryPart = pad
	model.Parent = plot.Buttons
	return model
end

---------------------------------------------------------------------
-- Robot bays
---------------------------------------------------------------------
function WorldBuilder.BuildBayPad(plot, index)
	local pos = Config.Layout.BayPositions[index]
	local pad = plotPart(plot, plot.Bays, Vector3.new(10, 0.3, 11), pos + Vector3.new(0, 1.15, 0), Color3.fromRGB(45, 48, 60), Enum.Material.Metal, { Name = "BayPad" .. index })
	plotPart(plot, plot.Bays, Vector3.new(10, 0.32, 0.4), pos + Vector3.new(0, 1.16, -5.3), VEX_RED, Enum.Material.SmoothPlastic)
	return pad
end

---------------------------------------------------------------------
-- Items
---------------------------------------------------------------------
local itemBuilders = {}

function itemBuilders.Dropper(plot, item, model)
	local x = Config.Layout.DropperX[item.Slot]
	local z = Config.Layout.ConveyorZ
	plotPart(plot, model, Vector3.new(1.2, 12, 1.2), Vector3.new(x, 7, z + 5.5), METAL, Enum.Material.Metal)
	plotPart(plot, model, Vector3.new(1, 1, 5), Vector3.new(x, 12.5, z + 3), METAL, Enum.Material.Metal)
	local body = plotPart(plot, model, Vector3.new(4.5, 4, 4.5), Vector3.new(x, 11, z), item.DropColor, Enum.Material.Metal, { Name = "Body" })
	plotPart(plot, model, Vector3.new(4.7, 0.6, 4.7), Vector3.new(x, 13.2, z), SIGN_BLACK, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(2, 1.5, 2), Vector3.new(x, 8.3, z), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
	local dropPoint = Instance.new("Attachment")
	dropPoint.Name = "DropPoint"
	dropPoint.Parent = body
	dropPoint.WorldPosition = (plot.CFrame * CFrame.new(x, 6.6, z)).Position
	billboard(body, item.Name, 8, 1.4, Vector3.new(0, 4.5, 0), Color3.new(1, 1, 1))
	model.PrimaryPart = body
end

function itemBuilders.Upgrader(plot, item, model)
	local x = Config.Layout.UpgraderX[item.Slot]
	local z = Config.Layout.ConveyorZ
	plotPart(plot, model, Vector3.new(1, 8, 1), Vector3.new(x, 5, z - 4), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
	plotPart(plot, model, Vector3.new(1, 8, 1), Vector3.new(x, 5, z + 4), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
	local top = plotPart(plot, model, Vector3.new(1.4, 1.4, 9), Vector3.new(x, 9.5, z), SIGN_BLACK, Enum.Material.Metal)
	local laser = plotPart(plot, model, Vector3.new(0.4, 3.5, 6), Vector3.new(x, 5.25, z), item.Color, Enum.Material.Neon, {
		Name = "Laser",
		Transparency = 0.45,
		CanCollide = false,
	})
	billboard(top, item.Name .. "  ·  " .. item.Multiplier .. "×", 8, 1.4, Vector3.new(0, 2, 0), item.Color)
	model.PrimaryPart = laser
end

function itemBuilders.Walls(plot, _, model)
	local half = Config.PlotSize / 2
	local wallColor = Color3.fromRGB(230, 230, 235)
	plotPart(plot, model, Vector3.new(Config.PlotSize, 14, 1), Vector3.new(0, 8, half - 0.5), wallColor, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(1, 14, 75), Vector3.new(-half + 0.5, 8, 17.5), wallColor, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(1, 14, 75), Vector3.new(half - 0.5, 8, 17.5), wallColor, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(Config.PlotSize, 1.5, 1.2), Vector3.new(0, 6, half - 0.6), VEX_RED, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(1.2, 1.5, 75), Vector3.new(-half + 0.6, 6, 17.5), VEX_RED, Enum.Material.SmoothPlastic)
	plotPart(plot, model, Vector3.new(1.2, 1.5, 75), Vector3.new(half - 0.6, 6, 17.5), VEX_RED, Enum.Material.SmoothPlastic)
end

function itemBuilders.Assembly(plot, _, model)
	local tableTop = plotPart(plot, model, Vector3.new(12, 0.6, 6), Vector3.new(-38, 4, 36), Color3.fromRGB(120, 85, 55), Enum.Material.WoodPlanks, { Name = "Workbench" })
	for _, p in ipairs({ { -43, 33.5 }, { -33, 33.5 }, { -43, 38.5 }, { -33, 38.5 } }) do
		plotPart(plot, model, Vector3.new(0.6, 3, 0.6), Vector3.new(p[1], 2.5, p[2]), METAL, Enum.Material.Metal)
	end
	local monitor = plotPart(plot, model, Vector3.new(5, 3.2, 0.3), Vector3.new(-38, 6.3, 38.5), Color3.fromRGB(20, 20, 25))
	surfaceText(monitor, Enum.NormalId.Front, "ROBOT LAB", Color3.new(1, 1, 1), SIGN_BLACK)
	-- tool rack
	plotPart(plot, model, Vector3.new(0.6, 6, 0.6), Vector3.new(-47, 4, 36), METAL, Enum.Material.Metal)
	plotPart(plot, model, Vector3.new(0.4, 0.4, 4), Vector3.new(-46, 6.5, 35) , Color3.fromRGB(240, 120, 30), Enum.Material.Metal)
	local p = prompt(tableTop, "Open Robot Lab", "Assembly Station")
	p.Name = "LabPrompt"
	-- display pad for the current design
	local display = plotPart(plot, model, Vector3.new(0.4, 12, 12), Vector3.new(-20, 1.2, 36), Color3.fromRGB(45, 48, 60), Enum.Material.Metal, {
		Name = "DisplayPad",
		Shape = Enum.PartType.Cylinder,
		CFrame = plot.CFrame * CFrame.new(-20, 1.2, 36) * CFrame.Angles(0, 0, math.rad(90)),
	})
	billboard(display, "CURRENT DESIGN", 10, 1.5, Vector3.new(0, 1.5, -7), plot.Color)
	model.PrimaryPart = tableTop
end

function itemBuilders.Bay()
	-- bays are drawn by TycoonServer.refreshBays
end

function itemBuilders.Tiles(plot, _, model)
	for ix = 0, 9 do
		for iz = 0, 2 do
			plotPart(plot, model, Vector3.new(10, 0.1, 10), Vector3.new(-50 + ix * 10 + 5, 1.04, 21 + iz * 10 + 5), ((ix + iz) % 2 == 0) and Color3.fromRGB(105, 105, 112) or Color3.fromRGB(92, 92, 100), Enum.Material.Fabric, { CanCollide = false })
		end
	end
end

function itemBuilders.Banner(plot, _, model)
	local half = Config.PlotSize / 2
	local banner = plotPart(plot, model, Vector3.new(34, 10, 0.3), Vector3.new(0, 17, half - 1.4), plot.Color, Enum.Material.Fabric)
	surfaceText(banner, Enum.NormalId.Front, "TEAM " .. string.upper(plot.OwnerName or "ROBOTICS"), Color3.new(1, 1, 1))
	for _, x in ipairs({ -45, -15, 15, 45 }) do
		plotPart(plot, model, Vector3.new(0.6, 22, 0.6), Vector3.new(x, 11, half - 3), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
		local lamp = plotPart(plot, model, Vector3.new(2.5, 1, 2.5), Vector3.new(x, 22, half - 4.5), Color3.fromRGB(255, 245, 220), Enum.Material.Neon)
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Bottom
		light.Range = 40
		light.Angle = 80
		light.Brightness = 2
		light.Parent = lamp
	end
end

function itemBuilders.Shelf(plot, _, model)
	local half = Config.PlotSize / 2
	for i, y in ipairs({ 4, 8 }) do
		plotPart(plot, model, Vector3.new(2, 0.4, 20), Vector3.new(-half + 2, y, 0 - i * 2), Color3.fromRGB(120, 85, 55), Enum.Material.WoodPlanks)
		for k = 0, 3 do
			local tz = -i * 2 - 8 + k * 5
			plotPart(plot, model, Vector3.new(1.2, 0.4, 1.2), Vector3.new(-half + 2, y + 0.4, tz), Color3.fromRGB(80, 60, 30), Enum.Material.Wood)
			plotPart(plot, model, Vector3.new(0.4, 1.2, 0.4), Vector3.new(-half + 2, y + 1.1, tz), Color3.fromRGB(255, 200, 60), Enum.Material.Metal)
			plotPart(plot, model, Vector3.new(1.2, 1.2, 1.2), Vector3.new(-half + 2, y + 2.1, tz), Color3.fromRGB(255, 200, 60), Enum.Material.Metal, { Shape = Enum.PartType.Ball })
		end
	end
	local sign = plotPart(plot, model, Vector3.new(0.4, 3, 14), Vector3.new(-half + 1.5, 12.5, -3), Color3.fromRGB(25, 28, 40))
	local label = surfaceText(sign, Enum.NormalId.Right, "0 TROPHIES", Color3.new(1, 1, 1))
	label.Name = "TrophyLabel"
end

function itemBuilders.Overclock(plot, _, model)
	local z = Config.Layout.ConveyorZ
	local core = plotPart(plot, model, Vector3.new(5, 7, 5), Vector3.new(-50, 4.5, z - 9), Color3.fromRGB(40, 40, 50), Enum.Material.Metal)
	for i = 0, 2 do
		plotPart(plot, model, Vector3.new(5.2, 0.5, 5.2), Vector3.new(-50, 2.5 + i * 2, z - 9), Color3.fromRGB(80, 200, 255), Enum.Material.Neon)
	end
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(80, 200, 255)
	light.Range = 20
	light.Brightness = 3
	light.Parent = core
	billboard(core, "Factory Overclock", 8, 1.5, Vector3.new(0, 5, 0), Color3.fromRGB(80, 200, 255))
end

function itemBuilders.Hall(plot, _, model)
	local half = Config.PlotSize / 2
	local gold = Color3.fromRGB(255, 200, 60)
	plotPart(plot, model, Vector3.new(2, 18, 2), Vector3.new(-10, 10, -half + 2), gold, Enum.Material.Metal)
	plotPart(plot, model, Vector3.new(2, 18, 2), Vector3.new(10, 10, -half + 2), gold, Enum.Material.Metal)
	local top = plotPart(plot, model, Vector3.new(24, 4, 2), Vector3.new(0, 20, -half + 2), gold, Enum.Material.Metal)
	surfaceText(top, Enum.NormalId.Front, "CHAMPIONS", Color3.fromRGB(40, 30, 0))
	plotPart(plot, model, Vector3.new(16, 0.2, 30), Vector3.new(0, 1.02, -half + 16), SIGN_BLACK, Enum.Material.SmoothPlastic, { CanCollide = false })
end

function WorldBuilder.BuildItem(plot, item)
	local model = Instance.new("Model")
	model.Name = item.Id
	model.Parent = plot.Items
	local builder = itemBuilders[item.Type]
	if builder then
		builder(plot, item, model)
	end
	return model
end

---------------------------------------------------------------------
-- Entry point
---------------------------------------------------------------------
function WorldBuilder.GetWorld()
	if world then
		return world
	end
	local existing = workspace:FindFirstChild("VexWorld")
	if existing then
		existing:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "VexWorld"
	root.Parent = workspace

	setupLighting()
	world = {}
	world.Root = root
	world.Hub = buildHub(root)
	world.Fields = {
		Practice = buildField(root, "Practice", Vector3.new(-62, 0, 0), "PRACTICE FIELD"),
		Ranked = buildField(root, "Ranked", Vector3.new(62, 0, 0), "RANKED  ·  1 V 1"),
	}
	buildScoreboard(world.Fields.Ranked)
	world.Fields.Practice.Prompt = prompt(world.Fields.Practice.Kiosk, "Drive Your Robot", "Practice Field")
	world.Fields.Ranked.Prompt = prompt(world.Fields.Ranked.Kiosk, "Join / Leave Queue", "Ranked 1v1")

	world.Plots = {}
	local plotsFolder = folder("Plots", root)
	for i = 1, Config.MaxPlots do
		world.Plots[i] = buildPlot(plotsFolder, i)
	end
	return world
end

return WorldBuilder
]=] })
table.insert(files, { Class = "Script", Service = "ServerScriptService", Sub = nil, Name = "TycoonServer", Source = [=[
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
		notify(player, "Robot Lab unlocked. Open Lab from the dock or use the workbench.", "success")
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
end

local function releasePlot(plot)
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
	DataManager.UpdateLeaderstats(player)
	local plot = playerPlot[player]
	if plot then
		clearPlot(plot)
		loadPlot(plot)
	end
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
]=] })
table.insert(files, { Class = "Script", Service = "ServerScriptService", Sub = nil, Name = "ArenaServer", Source = [=[
--[[
	ArenaServer (Script)  ->  ServerScriptService.ArenaServer

	Driving your ACTIVE robot:
	  * Practice field: free drive, score balls for cash
	  * Ranked 1v1: queue up, auton bonus, 90s match, trophies + cash
	Balls are collected automatically by your intake; press F (or the
	SCORE button) near a goal to score everything you're holding.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local DataManager = require(ServerScriptService:WaitForChild("DataManager"))
local RobotBuilder = require(ReplicatedStorage:WaitForChild("RobotBuilder"))
local WorldBuilder = require(ServerScriptService:WaitForChild("WorldBuilder"))

local Remotes = DataManager.Remotes
local World = WorldBuilder.GetWorld()
local Practice = World.Fields.Practice
local Ranked = World.Fields.Ranked

local TEAM_COLORS = {
	Red = Color3.fromRGB(220, 45, 50),
	Blue = Color3.fromRGB(40, 110, 230),
}

local sessions = {} -- [player] = session
local queue = {} -- array of players waiting for ranked
local match = nil -- current ranked match

local finishMatch, tryStartMatch -- forward declarations

local function notify(player, text, kind)
	DataManager.Notify(player, text, kind)
end

---------------------------------------------------------------------
-- Balls
---------------------------------------------------------------------
local function spawnBall(field)
	local half = field.Size / 2 - 6
	local pos = Vector3.new(0, 0, 0)
	for _ = 1, 15 do
		local x = (math.random() * 2 - 1) * half
		local z = (math.random() * 2 - 1) * half
		-- keep balls out of the goal zones
		if math.abs(x) < field.Size / 2 - 18 or math.abs(z) > 16 then
			pos = Vector3.new(x, 0, z)
			break
		end
	end
	local ball = Instance.new("Part")
	ball.Name = "Ball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * Config.Field.BallSize
	ball.Color = Config.Field.BallColor
	ball.Material = Enum.Material.SmoothPlastic
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.5, 0.3, 1, 1)
	ball.CFrame = field.CFrame * CFrame.new(pos + Vector3.new(0, 3, 0))
	ball.Parent = field.Balls
end

local function fillBalls(field, count)
	local current = #field.Balls:GetChildren()
	for _ = current + 1, count do
		spawnBall(field)
	end
end

local function clearBalls(field)
	field.Balls:ClearAllChildren()
end

local function ballTarget(field)
	return field == Ranked and Config.Match.Balls or Config.Practice.Balls
end

---------------------------------------------------------------------
-- State pushed to the driving player's HUD
---------------------------------------------------------------------
local function matchInfo(forPlayer)
	if not match then
		return nil
	end
	return {
		State = match.State,
		Countdown = match.Countdown,
		Time = match.TimeLeft,
		Red = match.Scores.Red,
		Blue = match.Scores.Blue,
		RedName = match.Red and match.Red.DisplayName or "?",
		BlueName = match.Blue and match.Blue.DisplayName or "?",
		Side = (forPlayer == match.Red and "Red") or (forPlayer == match.Blue and "Blue") or nil,
	}
end

local function sendState(player)
	local s = sessions[player]
	if not s then
		Remotes.ArenaState:FireClient(player, { Mode = "None" })
		return
	end
	Remotes.ArenaState:FireClient(player, {
		Mode = s.Mode,
		Held = s.Held,
		Capacity = s.Stats.Capacity,
		Points = s.Points,
		PointsPerBall = s.Stats.PointsPerBall,
		Strafe = s.Stats.Strafe,
		Side = s.Side,
		Match = s.Mode == "Ranked" and matchInfo(player) or nil,
	})
end

local function updateQueueAttributes()
	Remotes.Folder:SetAttribute("QueueSize", #queue)
	Remotes.Folder:SetAttribute("MatchLive", match ~= nil)
	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("InQueue", table.find(queue, player) ~= nil)
	end
end

local function updateScoreboard()
	for _, labels in ipairs(Ranked.Scoreboard) do
		if match then
			labels.Red.Text = tostring(match.Scores.Red)
			labels.Blue.Text = tostring(match.Scores.Blue)
			if match.State == "Countdown" then
				labels.Status.Text = string.format("%s vs %s\nStarting in %d", match.Red.DisplayName, match.Blue.DisplayName, match.Countdown or 0)
			else
				labels.Status.Text = string.format("%s vs %s\n%d:%02d", match.Red.DisplayName, match.Blue.DisplayName, math.floor(match.TimeLeft / 60), match.TimeLeft % 60)
			end
		else
			labels.Red.Text = "0"
			labels.Blue.Text = "0"
			labels.Status.Text = #queue > 0 and (#queue .. " in queue...") or "WAITING FOR PLAYERS"
		end
	end
end

---------------------------------------------------------------------
-- Sessions (a player driving a robot)
---------------------------------------------------------------------
local function getHumanoid(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 and character.PrimaryPart then
		return humanoid, character
	end
	return nil, nil
end

local function playerPlot(player)
	for _, plot in ipairs(World.Plots) do
		if plot.Owner == player then
			return plot
		end
	end
	return nil
end

local function sendHome(player, field)
	local _, character = getHumanoid(player)
	if not character then
		return
	end
	local plot = playerPlot(player)
	if plot then
		character:PivotTo(plot.SpawnCFrame)
	else
		character:PivotTo(field.ExitCFrame)
	end
end

local function endSession(player, teleport)
	local s = sessions[player]
	if not s then
		return
	end
	sessions[player] = nil
	s.Ended = true
	player:SetAttribute("Driving", false)
	for _, conn in ipairs(s.Connections) do
		conn:Disconnect()
	end
	local humanoid = getHumanoid(player)
	if humanoid then
		humanoid.Sit = false
	end
	if s.Model then
		s.Model:Destroy()
	end
	if teleport then
		task.delay(0.1, function()
			if player.Parent then
				sendHome(player, s.Field)
			end
		end)
	end
	sendState(player)
	task.delay(2, function()
		fillBalls(s.Field, ballTarget(s.Field))
	end)
end

local function releaseRobot(s)
	if s.Ended or not s.Model.Parent then
		return
	end
	s.Frozen = false
	RobotBuilder.SetAnchored(s.Model, false)
	pcall(function()
		s.Root:SetNetworkOwner(s.Player)
	end)
end

local function onLeftRobot(s)
	if s.Ended then
		return
	end
	local player = s.Player
	if s.Mode == "Ranked" and match and (match.Red == player or match.Blue == player) then
		notify(player, "You left your robot - match forfeited!", "error")
		finishMatch(match, s.Side)
	else
		notify(player, "Practice over! You scored " .. s.Points .. " points.", "info")
		endSession(player, true)
	end
end

-- Spawns the player's active robot on a field and seats them in it.
local function startSession(player, field, mode, spawnCF, side)
	if sessions[player] then
		return false, "You're already driving!"
	end
	local data = DataManager.Get(player)
	local loadout = DataManager.GetActiveRobot(player)
	if not data or not loadout then
		return false, "Build a robot in the Robot Lab first!"
	end
	local humanoid, character = getHumanoid(player)
	if not humanoid then
		return false, "Respawn first!"
	end
	if humanoid.SeatPart then
		humanoid.Sit = false
	end

	local model, stats = RobotBuilder.Build(loadout, {
		Drive = true,
		TeamColor = side and TEAM_COLORS[side] or nil,
		Label = player.DisplayName,
		SubLabel = "Rating " .. Config.GetRobotStats(loadout).Rating,
	})
	model.Name = "Robot_" .. player.Name
	if DataManager.HasPass(player, "Turbo") then
		model:SetAttribute("MaxSpeed", stats.MaxSpeed * 1.15)
	end
	model:PivotTo(spawnCF * CFrame.new(0, 1.2, 0))
	model.Parent = field.Robots

	local seat = model:FindFirstChild("DriverSeat")
	local s = {
		Player = player,
		Model = model,
		Root = model.PrimaryPart,
		Seat = seat,
		Stats = stats,
		Field = field,
		Mode = mode,
		Side = side,
		Held = 0,
		Points = 0,
		Frozen = true,
		Connections = {},
	}
	sessions[player] = s
	player:SetAttribute("Driving", true)

	character:PivotTo(seat.CFrame * CFrame.new(0, 3, 0))
	seat:Sit(humanoid)

	task.delay(0.6, function()
		if s.Ended then
			return
		end
		if seat.Occupant ~= humanoid then
			seat:Sit(humanoid) -- retry once
		end
		table.insert(s.Connections, seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if seat.Occupant == nil then
				onLeftRobot(s)
			end
		end))
	end)
	table.insert(s.Connections, humanoid.Died:Connect(function()
		onLeftRobot(s)
	end))

	sendState(player)
	return true
end

---------------------------------------------------------------------
-- Practice
---------------------------------------------------------------------
local function startPractice(player)
	if match and (match.Red == player or match.Blue == player) then
		return false, "You're in a ranked match!"
	end
	local spawns = Practice.Spawns.List
	local spawnCF = spawns[math.random(1, #spawns)]
	local ok, err = startSession(player, Practice, "Practice", spawnCF, nil)
	if not ok then
		return false, err
	end
	fillBalls(Practice, Config.Practice.Balls)
	task.delay(0.8, function()
		local s = sessions[player]
		if s then
			releaseRobot(s)
		end
	end)
	return true, "Drive with WASD, Q/E strafe (holonomic), F to score near a goal. Jump to exit."
end

---------------------------------------------------------------------
-- Ranked matches
---------------------------------------------------------------------
local function broadcastMatch()
	if not match then
		return
	end
	for _, player in ipairs({ match.Red, match.Blue }) do
		if player and player.Parent then
			sendState(player)
		end
	end
	updateScoreboard()
end

local function giveRewards(player, result, opponentRating)
	local data = DataManager.Get(player)
	if not data then
		return
	end
	data.Stats.MatchesPlayed += 1
	if result == "Win" then
		data.Stats.MatchesWon += 1
		local cash = DataManager.AddCash(player, Config.Match.WinCashBase + opponentRating * Config.Match.WinCashPerRating, true)
		DataManager.AddTrophies(player, Config.Match.WinTrophies)
		notify(player, "Victory. +" .. Config.Money(cash) .. " and +" .. Config.Match.WinTrophies .. " trophies", "success")
	elseif result == "Tie" then
		local cash = DataManager.AddCash(player, Config.Match.LoseCash * 2, true)
		DataManager.AddTrophies(player, Config.Match.TieTrophies)
		notify(player, "Tie game! +" .. Config.Money(cash) .. " and +" .. Config.Match.TieTrophies .. " trophies", "info")
	elseif result == "Loss" then
		local cash = DataManager.AddCash(player, Config.Match.LoseCash, true)
		DataManager.AddTrophies(player, Config.Match.LoseTrophies)
		notify(player, "Defeat - good effort! +" .. Config.Money(cash) .. " and +" .. Config.Match.LoseTrophies .. " trophy", "info")
	end
	DataManager.MarkChanged(player)
end

function finishMatch(m, forfeitSide)
	if match ~= m then
		return
	end
	match = nil
	m.State = "Ended"

	local winner
	if forfeitSide then
		winner = forfeitSide == "Red" and "Blue" or "Red"
	elseif m.Scores.Red > m.Scores.Blue then
		winner = "Red"
	elseif m.Scores.Blue > m.Scores.Red then
		winner = "Blue"
	else
		winner = "Tie"
	end

	local ratings = {
		Red = m.Ratings.Red or 0,
		Blue = m.Ratings.Blue or 0,
	}
	for _, side in ipairs({ "Red", "Blue" }) do
		local player = m[side]
		local other = side == "Red" and "Blue" or "Red"
		if player and player.Parent then
			local result
			if winner == "Tie" then
				result = "Tie"
			elseif winner == side then
				result = "Win"
			elseif forfeitSide == side then
				result = "Forfeit"
			else
				result = "Loss"
			end
			giveRewards(player, result, ratings[other])
			Remotes.ArenaState:FireClient(player, {
				Mode = "Result",
				Result = result,
				Red = m.Scores.Red,
				Blue = m.Scores.Blue,
				RedName = m.Red.DisplayName,
				BlueName = m.Blue.DisplayName,
			})
			endSession(player, true)
		end
	end

	for _, labels in ipairs(Ranked.Scoreboard) do
		labels.Status.Text = winner == "Tie" and "TIE GAME!" or (string.upper(winner) .. " WINS!")
	end
	clearBalls(Ranked)
	updateQueueAttributes()
	task.delay(4, function()
		updateScoreboard()
	end)
	task.delay(5, function()
		-- try to start the next match
		if not match then
			tryStartMatch()
		end
	end)
end

local function runMatch(m)
	for i = Config.Match.Countdown, 1, -1 do
		if match ~= m then
			return
		end
		m.Countdown = i
		broadcastMatch()
		task.wait(1)
	end
	if match ~= m then
		return
	end

	-- autonomous bonus from each robot's Brain
	for _, side in ipairs({ "Red", "Blue" }) do
		local s = sessions[m[side]]
		if s then
			m.Scores[side] += s.Stats.Auton
			if s.Stats.Auton > 0 then
				notify(m[side], "Autonomous bonus: +" .. s.Stats.Auton .. " points", "success")
			end
			releaseRobot(s)
		end
	end
	m.State = "Live"
	broadcastMatch()

	while match == m and m.TimeLeft > 0 do
		task.wait(1)
		if match ~= m then
			return
		end
		m.TimeLeft -= 1
		broadcastMatch()
	end
	if match == m then
		finishMatch(m, nil)
	end
end

function tryStartMatch()
	if match then
		return
	end
	-- drop anyone who can't play
	for i = #queue, 1, -1 do
		local p = queue[i]
		if not p.Parent or not DataManager.GetActiveRobot(p) or not getHumanoid(p) then
			table.remove(queue, i)
		end
	end
	if #queue < 2 then
		updateQueueAttributes()
		updateScoreboard()
		return
	end
	local red = table.remove(queue, 1)
	local blue = table.remove(queue, 1)
	for _, p in ipairs({ red, blue }) do
		if sessions[p] then
			endSession(p, false)
		end
	end

	local m = {
		Red = red,
		Blue = blue,
		Scores = { Red = 0, Blue = 0 },
		Ratings = {
			Red = Config.GetRobotStats(DataManager.GetActiveRobot(red)).Rating,
			Blue = Config.GetRobotStats(DataManager.GetActiveRobot(blue)).Rating,
		},
		State = "Countdown",
		Countdown = Config.Match.Countdown,
		TimeLeft = Config.Match.Duration,
	}
	match = m
	clearBalls(Ranked)
	fillBalls(Ranked, Config.Match.Balls)

	local okRed, errRed = startSession(red, Ranked, "Ranked", Ranked.Spawns.Red, "Red")
	local okBlue, errBlue = startSession(blue, Ranked, "Ranked", Ranked.Spawns.Blue, "Blue")
	if not okRed or not okBlue then
		match = nil
		for _, p in ipairs({ red, blue }) do
			endSession(p, true)
			notify(p, "Match cancelled: " .. tostring(errRed or errBlue), "error")
		end
		updateQueueAttributes()
		updateScoreboard()
		return
	end

	for _, p in ipairs({ red, blue }) do
		notify(p, "Ranked match. Score in your " .. (p == red and "RED" or "BLUE") .. " goal. Leaving your robot forfeits.", "info")
	end
	updateQueueAttributes()
	task.spawn(runMatch, m)
end

local function joinQueue(player)
	if table.find(queue, player) then
		table.remove(queue, table.find(queue, player))
		updateQueueAttributes()
		updateScoreboard()
		return true, "Left the ranked queue"
	end
	if match and (match.Red == player or match.Blue == player) then
		return false, "You're already in a match!"
	end
	if not DataManager.GetActiveRobot(player) then
		return false, "Build a robot in the Robot Lab first!"
	end
	table.insert(queue, player)
	updateQueueAttributes()
	updateScoreboard()
	task.defer(tryStartMatch)
	if #queue < 2 and not match then
		return true, "Joined the ranked queue! Waiting for an opponent..."
	end
	return true, "Joined the ranked queue!"
end

---------------------------------------------------------------------
-- Intake loop: robots automatically grab nearby balls
---------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(0.15)
		for player, s in pairs(sessions) do
			if not s.Frozen and s.Root and s.Root.Parent and s.Held < s.Stats.Capacity then
				local intakePos = (s.Root.CFrame * CFrame.new(0, 0, -4.5)).Position
				local grabbed = false
				for _, ball in ipairs(s.Field.Balls:GetChildren()) do
					if (ball.Position - intakePos).Magnitude <= s.Stats.IntakeRadius then
						ball:Destroy()
						s.Held += 1
						grabbed = true
						if s.Held >= s.Stats.Capacity then
							break
						end
					end
				end
				if grabbed then
					sendState(player)
					local field = s.Field
					task.delay(2.5, function()
						fillBalls(field, ballTarget(field))
					end)
				end
			end
		end
	end
end)

---------------------------------------------------------------------
-- Scoring (client presses F / SCORE)
---------------------------------------------------------------------
local function flashGoal(goal)
	local pad = goal.Pad
	local original = pad.Transparency
	pad.Transparency = 0
	pad.Size += Vector3.new(0, 0.5, 0)
	task.delay(0.3, function()
		pad.Transparency = original
		pad.Size -= Vector3.new(0, 0.5, 0)
	end)
end

Remotes.Score.OnServerEvent:Connect(function(player)
	local s = sessions[player]
	if not s or s.Frozen or s.Held <= 0 or not s.Root.Parent then
		return
	end
	if os.clock() - (s.LastScore or 0) < 0.3 then
		return
	end
	s.LastScore = os.clock()

	local goals
	if s.Mode == "Ranked" then
		goals = { s.Field.Goals[s.Side] }
	else
		goals = { s.Field.Goals.Red, s.Field.Goals.Blue }
	end
	local pos = s.Root.Position
	for _, goal in ipairs(goals) do
		local offset = Vector3.new(pos.X - goal.Position.X, 0, pos.Z - goal.Position.Z)
		if offset.Magnitude <= Config.Field.GoalRadius then
			local points = s.Held * s.Stats.PointsPerBall
			local data = DataManager.Get(player)
			if data then
				data.Stats.BallsScored += s.Held
			end
			s.Held = 0
			s.Points += points
			flashGoal(goal)
			if s.Mode == "Ranked" and match and s.Side then
				match.Scores[s.Side] += points
				broadcastMatch()
			else
				local cash = DataManager.AddCash(player, points * Config.Practice.CashPerPoint, true)
				notify(player, "+" .. points .. " points  (+" .. Config.Money(cash) .. ")", "cash")
				sendState(player)
			end
			return
		end
	end
	notify(player, s.Mode == "Ranked" and ("Drive into your " .. string.upper(s.Side) .. " goal zone to score!") or "Drive into a goal zone to score!", "error")
end)

---------------------------------------------------------------------
-- Requests from the UI
---------------------------------------------------------------------
Remotes.ArenaRequest.OnServerInvoke = function(player, action)
	if not DataManager.Get(player) then
		return false, "Your data is still loading..."
	end
	if action == "Practice" then
		return startPractice(player)
	elseif action == "Queue" then
		return joinQueue(player)
	elseif action == "Stop" then
		local s = sessions[player]
		if not s then
			return false, "You're not driving"
		end
		onLeftRobot(s)
		return true
	end
	return false, "Unknown action"
end

Practice.Prompt.Triggered:Connect(function(player)
	local ok, msg = startPractice(player)
	if msg then
		notify(player, msg, ok and "info" or "error")
	end
end)

Ranked.Prompt.Triggered:Connect(function(player)
	local ok, msg = joinQueue(player)
	if msg then
		notify(player, msg, ok and "info" or "error")
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local index = table.find(queue, player)
	if index then
		table.remove(queue, index)
	end
	if match and (match.Red == player or match.Blue == player) then
		finishMatch(match, match.Red == player and "Red" or "Blue")
	end
	endSession(player, false)
	updateQueueAttributes()
	updateScoreboard()
end)

fillBalls(Practice, Config.Practice.Balls)
updateQueueAttributes()
updateScoreboard()
]=] })
table.insert(files, { Class = "LocalScript", Service = "StarterPlayer", Sub = "StarterPlayerScripts", Name = "MainUI", Source = [=[
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
]=] })
table.insert(files, { Class = "LocalScript", Service = "StarterPlayer", Sub = "StarterPlayerScripts", Name = "DriveClient", Source = [=[
--[[
	DriveClient (LocalScript)  ->  StarterPlayer.StarterPlayerScripts.DriveClient

	Drives your robot when you're seated in it. The server gives you
	network ownership of the robot, so setting the constraints here is
	smooth and lag-free.

	Controls:  W/S or thumbstick = drive, A/D = turn,
	           Q/E = strafe (Mecanum / X-Drive only), F = score
	           Jump = leave robot
	Mobile & gamepad get on-screen / button bindings automatically.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ScoreRemote = Remotes:WaitForChild("Score")

local player = Players.LocalPlayer

local current = nil -- { Seat, Model, LV, AV }
local strafeLeft, strafeRight = false, false

local function onStrafe(actionName, inputState)
	local down = inputState == Enum.UserInputState.Begin
	if inputState == Enum.UserInputState.Begin or inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		if actionName == "VexStrafeLeft" then
			strafeLeft = down
		else
			strafeRight = down
		end
	end
	return Enum.ContextActionResult.Sink
end

local function onScore(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		ScoreRemote:FireServer()
	end
	return Enum.ContextActionResult.Sink
end

local function bindControls(model)
	ContextActionService:BindAction("VexScore", onScore, true, Enum.KeyCode.F, Enum.KeyCode.ButtonX)
	ContextActionService:SetTitle("VexScore", "Score")
	ContextActionService:SetPosition("VexScore", UDim2.new(1, -200, 1, -140))
	if model:GetAttribute("Strafe") then
		ContextActionService:BindAction("VexStrafeLeft", onStrafe, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonL1)
		ContextActionService:BindAction("VexStrafeRight", onStrafe, true, Enum.KeyCode.E, Enum.KeyCode.ButtonR1)
		ContextActionService:SetTitle("VexStrafeLeft", "Left")
		ContextActionService:SetTitle("VexStrafeRight", "Right")
		ContextActionService:SetPosition("VexStrafeLeft", UDim2.new(1, -270, 1, -80))
		ContextActionService:SetPosition("VexStrafeRight", UDim2.new(1, -200, 1, -60))
	end
end

local function unbindControls()
	ContextActionService:UnbindAction("VexScore")
	ContextActionService:UnbindAction("VexStrafeLeft")
	ContextActionService:UnbindAction("VexStrafeRight")
	strafeLeft, strafeRight = false, false
end

local function onSeated(active, seatPart)
	if active and seatPart and seatPart:GetAttribute("VexRobot") then
		local model = seatPart.Parent
		local root = model and model.PrimaryPart
		if not root then
			return
		end
		current = {
			Seat = seatPart,
			Model = model,
			LV = root:WaitForChild("DriveLV", 5),
			AV = root:WaitForChild("DriveAV", 5),
		}
		bindControls(model)
	elseif current then
		unbindControls()
		current = nil
	end
end

local function hookCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Seated:Connect(onSeated)
end

player.CharacterAdded:Connect(hookCharacter)
if player.Character then
	task.spawn(hookCharacter, player.Character)
end

local function key(code)
	return UserInputService:IsKeyDown(code)
end

RunService.Heartbeat:Connect(function()
	if not current then
		return
	end
	if not current.Model.Parent or not current.LV or not current.AV then
		unbindControls()
		current = nil
		return
	end

	local throttle = current.Seat.ThrottleFloat
	local steer = current.Seat.SteerFloat

	-- keyboard fallback (works even if the default vehicle controller is off)
	if throttle == 0 and steer == 0 and not UserInputService:GetFocusedTextBox() then
		if key(Enum.KeyCode.W) or key(Enum.KeyCode.Up) then
			throttle += 1
		end
		if key(Enum.KeyCode.S) or key(Enum.KeyCode.Down) then
			throttle -= 1
		end
		if key(Enum.KeyCode.D) or key(Enum.KeyCode.Right) then
			steer += 1
		end
		if key(Enum.KeyCode.A) or key(Enum.KeyCode.Left) then
			steer -= 1
		end
	end

	local maxSpeed = current.Model:GetAttribute("MaxSpeed") or 16
	local turnSpeed = current.Model:GetAttribute("TurnSpeed") or 3
	local strafe = 0
	if current.Model:GetAttribute("Strafe") then
		strafe = (strafeRight and 1 or 0) - (strafeLeft and 1 or 0)
	end

	current.LV.PlaneVelocity = Vector2.new(strafe * maxSpeed * 0.85, -throttle * maxSpeed)
	current.AV.AngularVelocity = Vector3.new(0, -steer * turnSpeed, 0)
end)
]=] })
for _, f in ipairs(files) do
	local parent = game:GetService(f.Service)
	if f.Sub then
		parent = parent:WaitForChild(f.Sub)
	end
	local old = parent:FindFirstChild(f.Name)
	if old then
		old:Destroy()
	end
	local s = Instance.new(f.Class)
	s.Name = f.Name
	s.Source = f.Source
	s.Parent = parent
end
ChangeHistoryService:SetWaypoint("Installed VEX Tycoon")
print("VEX Robotics Tycoon installed! " .. #files .. " scripts created. Press Play to test.")
