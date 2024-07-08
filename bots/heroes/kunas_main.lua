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
object.bDebugUtility = true
 
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
 
BotEcho('loading thunderbringer_main...')

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 3, ShortSolo = 2, LongSolo = 2, ShortSupport = 5, LongSupport = 5, ShortCarry = 1, LongCarry = 1}
 
---------------------------------
--  	Constants   	   --
---------------------------------
 
-- Wretched Hag
object.heroName = 'Hero_Kunas'
 
-- Item buy order. internal names
behaviorLib.StartingItems = {"Item_Scarab", "2 Item_RunesOfTheBlight", "Item_ManaPotion"} -- Items: Scarab, 2 Runes Of The Blight, Mana Potion
behaviorLib.LaneItems = {"Item_Bottle", "Item_Marchers", "Item_Steamboots", "Item_PortalKey"} -- Items: Marchers, Steamboots, Portal Key
behaviorLib.MidItems = {"Item_SpellShards", "Item_HealthMana2" } -- Items: Spell Shards, Icon Of The Goddes
behaviorLib.LateItems = {"Item_GrimoireOfPower", "Item_Morph"} -- Items: Grimoire Of Power, Kuldra Sheepstick
 
-- Skillbuild table, 0 = q, 1 = w, 2 = e, 3 = r, 4 = attri
object.tSkills = {
	1, 2, 1, 2, 1,
	3, 1, 2, 2, 0,
	3, 0, 0, 0, 4,
	3, 4, 4, 4, 4,
	4, 4, 4, 4, 4
}
 
-- Bonus agression points if a skill/item is available for use
 
object.nChainUp = 7
object.nBlastUp = 16
object.nUltUp = 28
object.nHellflowerUp = 12
object.nSheepstickUp = 15
 
-- Bonus agression points that are applied to the bot upon successfully using a skill/item
 
object.nChainUse = 2
object.nBlastUse = 8
object.nUltUse = 28
object.nHellflowerUse = 15
object.nSheepstickUse = 18
 
-- Thresholds of aggression the bot must reach to use these abilities
 
object.nChainThreshold = 16
object.nBlastThreshold = 27
object.nHellflowerThreshold = 23
object.nSheepstickThreshold = 29

------------------------------
--  	Skills  	--
------------------------------
local bSkillsValid = false
function object:SkillBuild()
	local unitSelf = self.core.unitSelf
	if not bSkillsValid then
		skills.chainLightning		= unitSelf:GetAbility(0)
		skills.blastOfLightning		= unitSelf:GetAbility(1)
		skills.lightningRod			= unitSelf:GetAbility(2)
		skills.lightningStorm		= unitSelf:GetAbility(3)
		skills.abilAttributeBoost 	= unitSelf:GetAbility(4)
		
		if skills.chainLightning and skills.blastOfLightning and skills.lightningRod and skills.lightningStorm and skills.abilAttributeBoost then
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
		if EventData.InflictorName == "Ability_Kunas1" then
			nAddBonus = nAddBonus + self.nChainUse
		elseif EventData.InflictorName == "Ability_Kunas2" then
			nAddBonus = nAddBonus + self.nBlastUse
		elseif EventData.InflictorName == "Ability_Kunas4" then
			nAddBonus = nAddBonus + self.nUltUse
		end
	elseif EventData.Type == "Item" then
		if EventData.SourceUnit == core.unitSelf:GetUniqueID() then
			local sInflictorName = EventData.InflictorName
			local itemHellflower = core.GetItem("Item_Silence")
			local itemSheepstick = core.GetItem("Item_Morph")
			if itemHellflower ~= nil and sInflictorName == itemHellflower:GetName() then
				nAddBonus = nAddBonus + self.nHellflowerUse
			elseif itemSheepstick ~= nil and sInflictorName == itemSheepstick:GetName() then
				nAddBonus = nAddBonus + self.nSheepstickUse
			end
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
	local unitSelf = core.unitSelf
	local nUtility = 0
 
	if skills.chainLightning:CanActivate() then
		nUtility = nUtility + object.nChainUp
	end
 
	if skills.blastOfLightning:CanActivate() then
		nUtility = nUtility + object.nBlastUp
	end
 
	if skills.lightningStorm:CanActivate() then
		nUtility = nUtility + object.nUltUp
	end
	
	local itemHellflower = core.GetItem("Item_Silence")
	if itemHellflower and itemHellflower:CanActivate() then
		nUtility = nUtility + object.nHellflowerUp
	end
 
	local itemSheepstick = core.GetItem("Item_Morph")
	if itemSheepstick and itemSheepstick:CanActivate() then
		nUtility = nUtility + object.nSheepstickUp		
	end
	
	nUtility = nUtility + (unitSelf:GetManaPercent() * unitSelf:GetHealthPercent() * 100)
	
	return nUtility
end
 
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride 

--HarassHeroUtility override
local function HarassHeroUtilityOverride(botBrain)
	--Flint's ult has a larger range than the default "local units" target gathering range of 1250 (or 
	--	whatever core.localCreepRange is). This means we have to temporarally override that table so 
	--	we consider all units that are in his (extended) range
	
	local oldHeroes = core.localUnits["EnemyHeroes"]
		
	local abilUlt = skills.lightningStorm
	local nRange = 99999
	
	if nRange > core.localCreepRange and abilUlt:CanActivate() then
		local vecMyPosition = core.unitSelf:GetPosition()		
		local tAllHeroes = HoN.GetUnitsInRadius(vecMyPosition, nRange, core.UNIT_MASK_ALIVE + core.UNIT_MASK_HERO)
		local tEnemyHeroes = {}
		local nEnemyTeam = core.enemyTeam
		for key, hero in pairs(tAllHeroes) do
			if hero:GetTeam() == nEnemyTeam then
				tinsert(tEnemyHeroes, hero)
			end
		end
		
		core.teamBotBrain:AddMemoryUnitsToTable(tEnemyHeroes, nEnemyTeam, vecMyPosition, nRange)
		core.localUnits["EnemyHeroes"] = tEnemyHeroes
	end
	
	local nUtility = object.HarassHeroUtilityOld(botBrain)	
	
	core.localUnits["EnemyHeroes"] = oldHeroes
	return nUtility
end
object.HarassHeroUtilityOld = behaviorLib.HarassHeroBehavior["Utility"] 
behaviorLib.HarassHeroBehavior["Utility"]  = HarassHeroUtilityOverride 

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
	local bTargetDisabled = unitTarget:IsStunned() or unitTarget:IsSilenced()
	local bCanSeeTarget = core.CanSeeUnit(botBrain, unitTarget)
	   
	-- Hellflower
	local itemHellflower = core.GetItem("Item_Silence")
	if itemHellflower and itemHellflower:CanActivate() and not bTargetDisabled and bCanSeeTarget and nLastHarassUtility > object.nHellflowerThreshold then
		local nRange = itemHellflower:GetRange()
		if nTargetDistanceSq < (nRange * nRange) then
			bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, itemHellflower, unitTarget)
		end
	end
 
	-- Ult
	if not bActionTaken then
		local abilUlt = skills.lightningStorm
		if abilUlt:CanActivate() then
			local nLevel = abilUlt:GetLevel()
			local nUltDamage = 270
			if nLevel == 2 then
				nUltDamage = 460
			elseif nLevel == 3 then
				nUltDamage = 650
			end
			local nHealth = unitTarget:GetHealth()
			local nDamageMultiplier = 1 - unitTarget:GetMagicArmor()
			local nTrueDamage = nUltDamage * nDamageMultiplier
			if abilUlt:CanActivate() and unitTarget:GetHealth() < nTrueDamage then
				bActionTaken = core.OrderAbility(botBrain, abilUlt)
			end
		end   
	end
	   
	-- Blast of Lightning
	if not bActionTaken then
		local abilBlast = skills.blastOfLightning
		if abilBlast:CanActivate() and bCanSeeTarget and nLastHarassUtility > object.nBlastThreshold then
			local nRange = abilBlast:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilBlast, unitTarget)
			end
		end
	end
	   
	-- Chain Lightning
	if not bActionTaken then
		local abilChain = skills.chainLightning
		if abilChain:CanActivate() and bCanSeeTarget and nLastHarassUtility > object.nChainThreshold then
			local nRange = abilChain:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilChain, unitTarget)
			end
		end
	end
	   
	-- Sheepstick
	if not bActionTaken then
		local itemSheepstick = core.GetItem("Item_Morph")
		if itemSheepstick and itemSheepstick:CanActivate() and (nMyMana - itemSheepstick:GetManaCost()) >= 60  and not bTargetDisabled and bCanSeeTarget and nLastHarassUtility > object.nSheepstickThreshold then
			local nRange = itemSheepstick:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, itemSheepstick, unitTarget)
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

BotEcho(object:GetName()..' finished loading thunderbringer_main')
