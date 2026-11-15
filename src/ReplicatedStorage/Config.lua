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
	Color3.fromRGB(215, 45, 55), -- red
	Color3.fromRGB(40, 110, 220), -- blue
	Color3.fromRGB(50, 175, 80), -- green
	Color3.fromRGB(240, 190, 40), -- yellow
	Color3.fromRGB(150, 70, 210), -- purple
	Color3.fromRGB(240, 120, 30), -- orange
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
	Drivetrain = { Icon = "⚙️", Desc = "Speed & pushing power. Holonomic drives can strafe (Q/E)." },
	Intake = { Icon = "🧲", Desc = "How many balls you can hold and how easily you grab them." },
	Lift = { Icon = "🏗️", Desc = "Points per ball scored." },
	Brain = { Icon = "🧠", Desc = "Control + free Autonomous points at match start." },
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
	{ Key = "DoubleCash", Name = "2x Cash", Id = 0, Icon = "💰", Desc = "Double all cash you earn, forever." },
	{ Key = "AutoCollect", Name = "Auto Collect", Id = 0, Icon = "🧺", Desc = "Workshop cash goes straight to your wallet." },
	{ Key = "ExtraBays", Name = "+2 Robot Bays", Id = 0, Icon = "🏠", Desc = "Two extra robot bays (needs Assembly Station)." },
	{ Key = "Turbo", Name = "Turbo Motors", Id = 0, Icon = "⚡", Desc = "+15% drive speed in practice & ranked." },
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
