-----------------------------------------
--  _   _	    ______       _    --
-- | | | |	   | ___ \     | |   --
-- | |_| | __ _  __ _| |_/ / ___ | |_  --
-- |  _  |/ _` |/ _` | ___ \/ _ \| __| --
-- | | | | (_| | (_| | |_/ / (_) | |_  --
-- \_| |_/\__,_|\__, \____/ \___/ \__| --
--	       __/ |		 --
--	      |___/  -By: DarkFire   --
-----------------------------------------
 
------------------------------------------
--	  Bot Initialization	  --
------------------------------------------
 
local _G = getfenv(0)
local object = _G.object
 
object.myName = object:GetName()
 
object.bRunLogic = true
object.bRunBehaviors = true
object.bUpdates = true
object.bUseShop = true
 
object.bRunCommands = true
object.bMoveCommands = true
object.bAttackCommands = true
object.bAbilityCommands = true
object.bOtherCommands = true
 
object.bReportBehavior = false
object.bDebugUtility = false
 
object.logger = {}
object.logger.bWriteLog = true
object.logger.bVerboseLog = true
 
object.core = {}
object.eventsLib = {}
object.metadata = {}
object.behaviorLib = {}
object.skills = {}
 
runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"
 
local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills
 
local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
	= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, asin, max, random
	= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.asin, _G.math.max, _G.math.random
 
local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp
 
BotEcho('loading slither_main...')

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 4, ShortSolo = 3, LongSolo = 3, ShortSupport = 5, LongSupport = 5, ShortCarry = 2, LongCarry = 2}
 
---------------------------------
--  	Constants   	   --
---------------------------------
 
-- Wretched Hag
object.heroName = 'Hero_Ebulus'
 
-- Item buy order. internal names
behaviorLib.StartingItems = 
	{"Item_Soulscream", "2 Item_RunesOfTheBlight"}
behaviorLib.LaneItems = 
	{"Item_Marchers", "Item_Steamboots"} -- Items: Marchers, Upg Marchers to Steamboots
behaviorLib.MidItems = 
	{"Item_Lightbrand", "Item_Sicarius", "Item_Strength6", "Item_Intelligence7"} -- Items: Build Dawnbringer, Staff Of The Master
behaviorLib.LateItems = 
	{"Item_Evasion", "Item_BehemothsHeart", 'Item_Damage9'} -- Items: Wingbow, Behemoth's Heart, DoomBringer
-- Skillbuild table, 0 = q, 1 = w, 2 = e, 3 = r, 4 = attri
object.tSkills = {
	0, 1, 0, 2, 0,
	3, 0, 1, 1, 1,
	3, 2, 2, 2, 4,
	3, 4, 4, 4, 4,
	4, 4, 4, 4, 4
}
 
-- Bonus agression points if a skill/item is available for use
 
object.nPoisonSprayUp = 18
object.nToxinWardUp = 4
object.nPoisonBurstUp = 70
 
-- Bonus agression points that are applied to the bot upon successfully using a skill/item
 
object.nPoisonSprayUse = 11
object.nToxinWardUse = 2
object.nPoisonBurstUse = 33
 
-- Thresholds of aggression the bot must reach to use these abilities
 
object.nPoisonSprayThreshold = 37
object.nToxinWardThreshold = 5
object.nPoisonBurstThreshold = 106
 
------------------------------
--  	Skills  	--
------------------------------
local bSkillsValid = false
function object:SkillBuild()
	local unitSelf = self.core.unitSelf
	if not bSkillsValid then
		skills.poisonSpray		= unitSelf:GetAbility(0)
		skills.toxinWard		= unitSelf:GetAbility(1)
		skills.toxicity			= unitSelf:GetAbility(2)
		skills.poisonBurst		= unitSelf:GetAbility(3)
		skills.abilAttributeBoost = unitSelf:GetAbility(4)
		
		if skills.poisonSpray and skills.toxinWard and skills.toxicity and skills.poisonBurst and skills.abilAttributeBoost then
			bSkillsValid = true
		else
			return
		end
	end
 
	local nPoints = unitSelf:GetAbilityPointsAvailable()
	if nPoints <= 0 then
		return
	end
 
	local nLevel = unitSelf:GetLevel()
	for i = nLevel, (nLevel + nPoints) do
		unitSelf:GetAbility( self.tSkills[i] ):LevelUp()
	end
end
 
----------------------------------------------
--	  OnCombatEvent Override	  --
----------------------------------------------
 
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
 
	local nAddBonus = 0
 
	if EventData.Type == "Ability" then
		if EventData.InflictorName == "Ability_Ebulus1" then
			nAddBonus = nAddBonus + self.nPoisonSprayUse
		elseif EventData.InflictorName == "Ability_Ebulus2" then
			nAddBonus = nAddBonus + self.nToxinWardUse
		elseif EventData.InflictorName == "Ability_Ebulus4" then
			nAddBonus = nAddBonus + self.nPoisonBurstUse
		end
	end
 
	if nAddBonus > 0 then
		core.DecayBonus(self)
		core.nHarassBonus = core.nHarassBonus + nAddBonus
	end
end
 
object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride
 
----------------------------------------------------
--	  CustomHarassUtility Override	  --
----------------------------------------------------
 
local function CustomHarassUtilityFnOverride(hero)
	local nUtility = 0
 
	if skills.poisonSpray:CanActivate() then
		nUtility = nUtility + object.nPoisonSprayUp
	end
 
	if skills.toxinWard:CanActivate() then
		nUtility = nUtility + object.nToxinWardUp
	end
 
	if skills.poisonBurst:CanActivate() then
		nUtility = nUtility + object.nPoisonBurstUp
	end
 
	return nUtility
end
 
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride 
 
---------------------------------------
--	  Harass Behavior	  --
---------------------------------------
 
local function HarassHeroExecuteOverride(botBrain)
 
	local unitTarget = behaviorLib.heroTarget
	if unitTarget == nil then
		return object.harassExecuteOld(botBrain)
	end
 
	local nLastHarassUtility = behaviorLib.lastHarassUtil
	local bActionTaken = false
	   
	local unitSelf = core.unitSelf
	local vecMyPosition = unitSelf:GetPosition()
	local vecTargetPosition = unitTarget:GetPosition()
	local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)
 
	-- Poison Burst
	if not bActionTaken then
		local abilPoisonBurst = skills.poisonBurst
		if abilPoisonBurst:CanActivate() and (nLastHarassUtility > (object.nPoisonBurstThreshold / core.NumberElements(tLocalEnemyHeroes)) or unitTarget:GetHealthPercent() < 0.62) then
			local nRange = 950
			if nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderAbility(botBrain, abilPoisonBurst)
			end
		end   
	end
	   
	-- Poison Spray
	if not bActionTaken then
		local abilPoisonSpray = skills.poisonSpray
		if abilPoisonSpray:CanActivate() and (nLastHarassUtility > object.nPoisonSprayThreshold or unitTarget:GetHealthPercent() < 0.19) then
			local nRange = abilPoisonSpray:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderAbilityPosition(botBrain, abilPoisonSpray, vecTargetPosition)
			end
		end
	end
	   
	-- Toxin Wards
	if not bActionTaken then
		local abilWard = skills.toxinWard
		if abilWard:CanActivate() and nLastHarassUtility > object.nToxinWardThreshold and unitSelf:GetManaPercent() > 0.44 then
			local nRange = abilWard:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				local unitEnemyWell = core.enemyWell
				if unitEnemyWell then
					-- If possible blink behind the enemy (where behind is defined as the direction from the target to the enemy well)
					local vecTargetPointToWell = Vector3.Normalize(unitEnemyWell:GetPosition() - vecTargetPosition)
					if vecTargetPointToWell then
						bActionTaken = core.OrderAbilityPosition(botBrain, abilWard, vecTargetPosition + (vecTargetPointToWell * 150))
					end
				end
			end
		end
	end
	   
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
	   
	return bActionTaken
end
 
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

BotEcho(object:GetName()..' finished loading slither_main')
