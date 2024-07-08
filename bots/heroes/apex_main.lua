--ArachnaBot v1.0


local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic 		= true
object.bRunBehaviors	= true
object.bUpdates 		= true
object.bUseShop 		= true

object.bRunCommands 	= true
object.bMoveCommands 	= true
object.bAttackCommands 	= true
object.bAbilityCommands = true
object.bOtherCommands 	= true

object.bReportBehavior = false
object.bDebugUtility = false
object.bDebugExecute = false


object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core 		= {}
object.eventsLib 	= {}
object.metadata 	= {}
object.behaviorLib 	= {}
object.skills 		= {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
	= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
	= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

BotEcho('loading apex_main...')

object.heroName = 'Hero_Apex'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 4, ShortSolo = 5, LongSolo = 5, ShortSupport = 1, LongSupport = 1, ShortCarry = 4, LongCarry = 4}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
	local unitSelf = self.core.unitSelf

	if not bSkillsValid then
		skills.decimate = unitSelf:GetAbility(0)
		skills.fireSurge = unitSelf:GetAbility(1)
		skills.theBurningEmber = unitSelf:GetAbility(2)
		skills.armageddon = unitSelf:GetAbility(3)
		skills.attributeBoost = unitSelf:GetAbility(4)
		
		if skills.decimate and skills.fireSurge and skills.theBurningEmber and skills.armageddon and skills.attributeBoost then
			bSkillsValid = true
		else
			return
		end
	end
		
	if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
	end
	
	--speicific level ordering first {precision, web, web, harden}
	if not (skills.decimate:GetLevel() >= 1) then
		skills.decimate:LevelUp()
	elseif not (skills.fireSurge:GetLevel() >= 2) then
		skills.fireSurge:LevelUp()
	elseif not (skills.theBurningEmber:GetLevel() >= 1) then
		skills.theBurningEmber:LevelUp()
	--max in this order {ult, web, precision, carapace, stats}
	elseif skills.armageddon:CanLevelUp() then
		skills.armageddon:LevelUp()
	elseif skills.fireSurge:CanLevelUp() then
		skills.fireSurge:LevelUp()
	elseif skills.theBurningEmber:CanLevelUp() then
		skills.theBurningEmber:LevelUp()
	elseif skills.decimate:CanLevelUp() then
		skills.decimate:LevelUp()
	else
		skills.attributeBoost:LevelUp()
	end	
end

---------------------------------------------------
--                   Overrides                   --
---------------------------------------------------

----------------------------------
--	Arachna specific harass bonuses
--
--  Abilities off cd increase harass util
--  Ability use increases harass util for a time
----------------------------------

object.decimateUpBonus = 12
object.decimateUseBonus = 62
object.decimateUseThreshold = 28

object.fireSurgeUpBonus = 10
object.fireSurgeUseBonus = 22
object.fireSurgeUseThreshold = 25

object.theBurningEmberUpBonus = 60
object.theBurningEmberUseBonus = 260
object.theBurningEmberUseThreshold = 13 --per enemy and per enemy close

object.armageddonUpBonus = 120
object.armageddonUseBonus = 49
object.armageddonUseThreshold = 114 --has added bonuses to calculating whether use it or not

local function AbilitiesUpUtilityFn()
	local unitSelf = core.unitSelf
	local val = 0
	
	if skills.decimate:CanActivate() then
		val = val + object.decimateUpBonus
	end
	
	if skills.fireSurge:CanActivate() then
		val = val + object.fireSurgeUpBonus
	end
	
	if skills.theBurningEmber:CanActivate() then
		val = val + object.theBurningEmberUpBonus
	end
	
	if skills.armageddon:CanActivate() then
		val = val + object.armageddonUpBonus
	end
	
	return val
end

--Arachna ability use gives bonus to harass util for a while
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
	
	local addBonus = 0
	
	if EventData.Type == "Ability" then
		--BotEcho("ABILILTY EVENT!  InflictorName: "..EventData.InflictorName)		
		if EventData.InflictorName == "Ability_Apex1" then
			addBonus = addBonus + object.decimateUseBonus
		elseif EventData.InflictorName == "Ability_Apex2" then
			addBonus = addBonus + object.fireSurgeUseBonus
		--elseif EventData.InflictorName == "Ability_Apex3" then
		--	addBonus = addBonus + object.searUseBonus
		elseif EventData.InflictorName == "Ability_Apex4" then
			addBonus = addBonus + object.armageddonUseBonus
		end
	end
	
	if addBonus > 0 then
		--decay before we add
		core.DecayBonus(self)
	
		core.nHarassBonus = core.nHarassBonus + addBonus
	end
end
object.oncombateventOld = object.oncombatevent
object.oncombatevent 	= object.oncombateventOverride

--Util override
local function CustomHarassUtilityOverride(hero)
	local unitSelf = core.unitSelf
	local nUtility = AbilitiesUpUtilityFn()
	
	if unitSelf:GetHealthPercent() > .93 then
		nUtility = nUtility + 4
	end
	
	if unitSelf:GetManaPercent() > .93 then
		nUtility = nUtility + 8
	end
	
	return nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityOverride   

----------------------------------
--	Arachna specific push strength
----------------------------------
local function PushingStrengthUtilOverride(myHero)
	local myDamage = core.GetFinalAttackDamageAverage(myHero)
	local myAttackDuration = myHero:GetAdjustedAttackDuration()
	local myDPS = myDamage * 1000 / (myAttackDuration) --ms to s
	
	local vTop = Vector3.Create(300, 100)
	local vBot = Vector3.Create(100, 0)
	local m = ((vTop.y - vBot.y)/(vTop.x - vBot.x))
	local b = vBot.y - m * vBot.x 
	
	local util = m * myDPS + b
	util = Clamp(util, 0, 100)
	
	--BotEcho(format("MyDPS: %g  util: %g  myMin: %g  myMax: %g  myAttackAverageL %g", 
	--	myDPS, util, myHero:GetFinalAttackDamageMin(), myHero:GetFinalAttackDamageMax(), myDamage))

	return util
end
behaviorLib.PushingStrengthUtilFn = PushingStrengthUtilOverride

--This function returns the position of the enemy hero.
--If he is not shown on map it returns the last visible spot
--as long as it is not older than 10s
object.tEnemyPosition = {}
object.tEnemyPositionTimestamp = {}
local function funcGetEnemyPosition(unitEnemy)

	if not unitEnemy then 
		--TODO: change this to nil and fix the rest of the code to recognize it as the failure case
		return Vector3.Create(20000, 20000) 
	end
	
	local tEnemyPosition = object.tEnemyPosition
	local tEnemyPositionTimestamp = object.tEnemyPositionTimestamp

	if core.IsTableEmpty(tEnemyPosition) then	
		local tEnemyTeam = HoN.GetHeroes(core.enemyTeam)
		
		--vector beyond map
		for x, hero in pairs(tEnemyTeam) do
			--TODO: Also here
			tEnemyPosition[hero:GetUniqueID()] = Vector3.Create(20000, 20000)
			tEnemyPositionTimestamp[hero:GetUniqueID()] = HoN.GetGameTime()
		end
	end

	local nUniqueID = unitEnemy:GetUniqueID()
	
	--enemy visible?
	if core.CanSeeUnit(object, unitEnemy) then
		--update table
		tEnemyPosition[nUniqueID] = unitEnemy:GetPosition()
		tEnemyPositionTimestamp[nUniqueID] = HoN.GetGameTime()
	end

	--return position, 10s memory
	if tEnemyPositionTimestamp[nUniqueID] <= HoN.GetGameTime() + 10000 then
		return tEnemyPosition[nUniqueID]
	else	
		--TODO: Also here
		return Vector3.Create(20000, 20000)
	end
end
----------------------------------
--	Arachna harass actions
----------------------------------
local function HarassHeroExecuteOverride(botBrain)
	local unitTarget = behaviorLib.heroTarget
	if unitTarget == nil or not unitTarget:IsValid() then
		return false --can not execute, move on to the next behavior
	end
	
	local unitSelf = core.unitSelf
	
	local bActionTaken = false
	
	local nLastHarassUtility = behaviorLib.lastHarassUtil
	
	--since we are using an old pointer, ensure we can still see the target for entity targeting
	if core.CanSeeUnit(botBrain, unitTarget) then
		local vecMyPosition = unitSelf:GetPosition()
		local vecTargetPosition = unitTarget:GetPosition()
		
		local attkRange = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
		
		local dist = Vector3.Distance2D(vecMyPosition, vecTargetPosition)
		
		local abilDecimate = skills.decimate
		local abilFireSurge = skills.fireSurge
		local abilTheBurningEmber = skills.theBurningEmber
		local abilArmageddon = skills.armageddon
		local abilDecimateRange = abilDecimate and abilDecimate:GetRange() or 0
		local abilArmageddonRange = 1200
		
		local numEnemies = 0
		local numEnemiesClose = 0
		local tEnemyTeam = HoN.GetHeroes(core.enemyTeam)
		
		local nEnemyDPS = 0

		--units close to unitTarget
		for id, enemy in pairs(tEnemyTeam) do
			if id ~= unitTarget:GetUniqueID() then
				if Vector3.Distance2DSq(unitTarget:GetPosition(), funcGetEnemyPosition(enemy)) < 1200*1200 then
					numEnemies = numEnemies + 1
					
					local enemyDamage = core.GetFinalAttackDamageAverage(enemy)
					local enemyAttackDuration = enemy:GetAdjustedAttackDuration() or 1449
					nEnemyDPS = nEnemyDPS + (enemyDamage * 1000 / (enemyAttackDuration)) --ms to s
					if Vector3.Distance2DSq(unitTarget:GetPosition(), funcGetEnemyPosition(enemy)) < 500*500 then
						numEnemiesClose = numEnemiesClose + 1
					end
				end
			end
		end
		
		if abilDecimate and abilDecimate:CanActivate() and not bActionTaken then
			if unitSelf:GetHealthPercent() > unitTarget:GetHealthPercent() and nLastHarassUtility > botBrain.decimateUseThreshold then
				bActionTaken = core.OrderAbilityPosition(botBrain, abilDecimate, vecTargetPosition)
			end
		end
		
		if abilFireSurge and abilFireSurge:CanActivate() and not bActionTaken then
			if object.fireSurgeUseThreshold > object.fireSurgeUseThreshold then
				bActionTaken = core.OrderAbility(botBrain, abilFireSurge)
			end
		end
		
		if abilArmageddon and abilArmageddon:CanActivate() and not bActionTaken then
			if (nLastHarassUtility + (numEnemies * 5.7) + (numEnemiesClose * 11.4)) > object.armageddonUseThreshold then
				bActionTaken = core.OrderAbility(botBrain, abilArmageddon)
			end
		end
		
		if abilTheBurningEmber and abilTheBurningEmber:CanActivate() and not bActionTaken then
			local enduranceThreshold = 0
			local nSkillLevel = abilTheBurningEmber:GetLevel()
			if nSkillLevel == 1 then
				enduranceThreshold = 70
			elseif nSkillLevel == 2 then
				enduranceThreshold = 109
			elseif nSkillLevel == 3 then
				enduranceThreshold = 147
			elseif nSkillLevel == 4 then
				enduranceThreshold = 186
			end
			if ((unitSelf:GetHealthPercent() < 0.53 or unitSelf:GetHealth() < 233) and nEnemyDPS < enduranceThreshold) then
				bActionTaken = core.OrderAbility(botBrain, abilTheBurningEmber)
			end
		end
	end
	
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
end

object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

-- Item buy order. internal names
behaviorLib.StartingItems =
	{"2 Item_IronBuckler", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems =
	{"Item_Lifetube", "Item_Marchers", "Item_Shield2", "Item_MysticVestments"} -- Shield2 is HotBL
behaviorLib.MidItems =
	{"Item_EnhancedMarchers", "Item_PortalKey"} 
behaviorLib.LateItems =
	{"Item_Excruciator", "Item_SolsBulwark", "Item_DaemonicBreastplate", "Item_Intelligence7", "Item_HealthMana2", "Item_BehemothsHeart"} --Excruciator is Barbed Armor, Item_Intelligence7 is staff, Item_HealthMana2 is icon
	
--[[ colors:
	red
	aqua == cyan
	gray
	navy
	teal
	blue
	lime
	black
	brown
	green
	olive
	white
	silver
	purple
	maroon
	yellow
	orange
	fuchsia == magenta
	invisible
--]]

BotEcho('finished loading apex_main')
