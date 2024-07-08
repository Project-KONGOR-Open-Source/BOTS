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
object.logger.bWriteLog = false
object.logger.bVerboseLog = false
 
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
 
BotEcho('loading corrupted_disciple_main...')

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 5, ShortSolo = 4, LongSolo = 4, ShortSupport = 1, LongSupport = 1, ShortCarry = 4, LongCarry = 4}
 
---------------------------------
--  	Constants   	   --
---------------------------------
 
-- Wretched Hag
object.heroName = 'Hero_CorruptedDisciple'
 
-- Item buy order. internal names
behaviorLib.StartingItems  = {"2 Item_DuckBoots", "2 Item_MinorTotem", "Item_HealthPotion", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems  = {"Item_Marchers", "Item_HelmOfTheVictim", "Item_Steamboots"}
behaviorLib.MidItems  = {"Item_Sicarius", "Item_WhisperingHelm", "Item_Immunity"}
behaviorLib.LateItems  = {"Item_ManaBurn2", "Item_LifeSteal4", "Item_Evasion"}
 
-- Skillbuild table, 0 = q, 1 = w, 2 = e, 3 = r, 4 = attri
object.tSkills = {
	1, 2, 1, 2, 2,
	3, 2, 0, 0, 0,
	3, 0, 1, 1, 4,
	3, 4, 4, 4, 4,
	4, 4, 4, 4, 4
}
 
-- Bonus agression points if a skill/item is available for use
 
object.nPlasmaFieldUp = 15
object.nStaticLinkUp = 16
object.nEyeOfTheStormUp = 29
 
-- Bonus agression points that are applied to the bot upon successfully using a skill/item
 
object.nPlasmaFieldUse = 11
object.nStaticLinkUse = 4
object.nEyeOfTheStormUse = 9
 
-- Thresholds of aggression the bot must reach to use these abilities
 
object.nPlasmaFieldThreshold = 49
object.nStaticLinkThreshold = 34
object.nEyeOfTheStormThreshold = 89

------------------------------
--  	Skills  	--
------------------------------
local bSkillsValid = false
function object:SkillBuild()
	local unitSelf = self.core.unitSelf
	if not bSkillsValid then
		skills.electricTide			= unitSelf:GetAbility(0)
		skills.corruptedConduit		= unitSelf:GetAbility(1)
		skills.staticDischarge		= unitSelf:GetAbility(2)
		skills.overload				= unitSelf:GetAbility(3)
		skills.abilAttributeBoost 	= unitSelf:GetAbility(4)
		
		if skills.electricTide and skills.corruptedConduit and skills.staticDischarge and skills.overload and skills.abilAttributeBoost then
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
		if EventData.InflictorName == "Ability_CorruptedDisciple1" then
			nAddBonus = nAddBonus + self.nPlasmaFieldUse
		elseif EventData.InflictorName == "Ability_CorruptedDisciple2" then
			nAddBonus = nAddBonus + self.nStaticLinkUse
		elseif EventData.InflictorName == "Ability_CorruptedDisciple4" then
			nAddBonus = nAddBonus + self.nEyeOfTheStormUse
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
 
	if skills.electricTide:CanActivate() then
		nUtility = nUtility + object.nPlasmaFieldUp
	end
 
	if skills.corruptedConduit:CanActivate() then
		nUtility = nUtility + object.nStaticLinkUp
	end
 
	if skills.staticDischarge:CanActivate() then
		nUtility = nUtility + object.nEyeOfTheStormUp
	end
	
	if unitSelf:GetHealthPercent() > .93 then
		nUtility = nUtility + 4
	end
	
	if unitSelf:GetManaPercent() > .93 then
		nUtility = nUtility + 8
	end
	
	if unitSelf:HasState("State_CorruptedDisciple_Ability1_Self") then
		nUtility = nUtility + object.nPlasmaFieldUse
	end
	
	if unitSelf:HasState("State_CorruptedDisciple_Ability2_Self") then
		nUtility = nUtility + object.nStaticLinkUse
	end
	
	if unitSelf:HasState("State_CorruptedDisciple_Ability2_Self_Damage") then
		nUtility = nUtility + object.nStaticLinkUse
	end
	
	if unitSelf:HasState("State_CorruptedDisciple_Ability4_Self") then
		nUtility = nUtility + object.nEyeOfTheStormUse
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
	local healthSelf = unitSelf:GetHealthPercent()
	local healthTarget = unitTarget:GetHealthPercent()
	local vecMyPosition = unitSelf:GetPosition()
	local vecTargetPosition = unitTarget:GetPosition()
	local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)
	local bTargetDisabled = unitTarget:IsStunned() or unitTarget:IsSilenced()
	local bCanSeeTarget = core.CanSeeUnit(botBrain, unitTarget)
	
	-- Overload
	if not bActionTaken then
		local abilOverload = skills.overload
		if abilOverload:CanActivate() and nLastHarassUtility > object.nEyeOfTheStormThreshold and (healthSelf > 0.67 or healthSelf > healthTarget) and nTargetDistanceSq < 525 then
			bActionTaken = core.OrderAbility(botBrain, abilOverload)
		end   
	end
	   
	-- Corrupted Conduit
	if not bActionTaken then
		local abilConduit = skills.corruptedConduit
		if abilConduit:CanActivate() and nLastHarassUtility > object.nStaticLinkThreshold and (healthSelf > 0.77 or healthSelf > healthTarget) then
			bActionTaken = core.OrderAbilityEntity(botBrain, abilConduit, unitTarget)
		end   
	end
	   
	-- Electric Tide
	if not bActionTaken then
		local abilTide = skills.electricTide
		if abilTide:CanActivate() and nLastHarassUtility > object.nPlasmaFieldThreshold and ((nTargetDistanceSq < 600 and nTargetDistanceSq > 400) or (healthTarget < 0.17 and nTargetDistanceSq < 800)) then
			bActionTaken = core.OrderAbility(botBrain, abilTide)
		end   
	end
	 
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
	   
	return bActionTaken
end
 
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
 
-------------------------------------------
--	  	 Pushing				 --
-------------------------------------------
 
-- These are modified from fane_maciuca's Rhapsody Bot
function behaviorLib.customPushExecute(botBrain)
	local bSuccess = false
	local abilTide = skills.electricTide
	local unitSelf = core.unitSelf
	local nMinimumCreeps = 3
       
	-- Stop the bot from trying to farm creeps if the creeps approach the spot where the bot died
	if not unitSelf:IsAlive() then
		return bSuccess
	end
       
	--Don't use Scream if it would put mana too low
	if abilTide:CanActivate() and unitSelf:GetManaPercent() > .49 then
		local tLocalEnemyCreeps = core.localUnits["EnemyCreeps"]
		if core.NumberElements(tLocalEnemyCreeps) > nMinimumCreeps then
			local vecCenter = core.GetGroupCenter(tLocalEnemyCreeps)
			if vecCenter then
				local vecCenterDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), vecCenter)
				if vecCenterDistanceSq then
					if vecCenterDistanceSq < (90 * 90) then
						bSuccess = core.OrderAbility(botBrain, abilTide)
					else
						bSuccess = core.OrderMoveToPos(botBrain, unitSelf, vecCenter)
					end
				end
			end
		end
	end
       
	return bSuccess
end
BotEcho(object:GetName()..' finished loading corrupted_disciple_main')
