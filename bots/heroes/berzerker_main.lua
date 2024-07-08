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
object.logger.bWriteLog = true
object.logger.bVerboseLog = true

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

BotEcho('loading accursed_main...')

object.heroName = 'Hero_Berzerker'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 1, ShortSolo = 3, LongSolo = 3, ShortSupport = 1, LongSupport = 1, ShortCarry = 5, LongCarry = 4}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
	local unitSelf = self.core.unitSelf

	if not bSkillsValid then
		skills.chainSpike = unitSelf:GetAbility(0)
		skills.markForDeath = unitSelf:GetAbility(1)
		skills.strengthSap = unitSelf:GetAbility(2)
		skills.carnage = unitSelf:GetAbility(3)
		skills.attributeBoost = unitSelf:GetAbility(4)
		
		if skills.chainSpike and skills.markForDeath and skills.strengthSap and skills.carnage and skills.attributeBoost then
			bSkillsValid = true
		else
			return
		end
	end
		
	if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
	end
	
	--speicific level ordering first {precision, web, web, harden}
	if not (skills.chainSpike:GetLevel() >= 1) then
		skills.chainSpike:LevelUp()
	elseif not (skills.strengthSap:GetLevel() >= 2) then
		skills.strengthSap:LevelUp()
	elseif not (skills.markForDeath:GetLevel() >= 1) then
		skills.markForDeath:LevelUp()
	--max in this order {ult, web, precision, carapace, stats}
	elseif skills.carnage:CanLevelUp() then
		skills.carnage:LevelUp()
	elseif skills.chainSpike:CanLevelUp() then
		skills.chainSpike:LevelUp()
	elseif skills.markForDeath:CanLevelUp() then
		skills.markForDeath:LevelUp()
	elseif skills.strengthSap:CanLevelUp() then
		skills.strengthSap:LevelUp()
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

object.chainSpikeUpBonus = 14
object.chainSpikeUseBonus = 30
object.chainSpikeUseThreshold = 28

object.markForDeathUpBonus = 14
object.markForDeathUseBonus = 21
object.markForDeathUseThreshold = 19

object.strengthSapUpBonus = 17
object.strengthSapUseBonus = 14
object.strengthSapUseThreshold = 13

object.carnageUpBonus = 40
object.carnageUseBonus = 100
object.carnageUseThreshold = 100

local function AbilitiesUpUtilityFn()
	local unitSelf = core.unitSelf
	local val = 0
	
	if skills.chainSpike:CanActivate() then
		val = val + object.chainSpikeUpBonus
	end
	
	if skills.markForDeath:CanActivate() then
		val = val + object.markForDeathUpBonus
	end
	
	if skills.strengthSap:CanActivate() then
		val = val + object.strengthSapUpBonus
	end
	
	if skills.carnage:CanActivate() then
		val = val + object.carnageUpBonus
	end
	
	return val
end

--Arachna ability use gives bonus to harass util for a while
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
	
	local addBonus = 0
	
	if EventData.Type == "Ability" then
		--BotEcho("ABILILTY EVENT!  InflictorName: "..EventData.InflictorName)		
		if EventData.InflictorName == "Ability_Berzerker1" then
			addBonus = addBonus + object.chainSpikeUseBonus
		elseif EventData.InflictorName == "Ability_Berzerker2" then
			addBonus = addBonus + object.markForDeathUseBonus
		elseif EventData.InflictorName == "Ability_Berzerker3" then
			addBonus = addBonus + object.strengthSapUseBonus
		elseif EventData.InflictorName == "Ability_Berzerker4" then
			addBonus = addBonus + object.carnageUseBonus
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
	
	if unitSelf:HasState("State_Berzerker_Ability1_Self") then
		nUtility = nUtility + 10
	end
	
	if unitSelf:HasState("State_Berzerker_Ability2_Buff") then
		nUtility = nUtility + 7
	end
	
	if unitSelf:HasState("State_Berzerker_Ability3_Buff") then
		nUtility = nUtility + 14
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
		
		local abilChainSpike = skills.chainSpike
		local abilMarkForDeath = skills.markForDeath
		local abilStrengthSap = skills.strengthSap
		local abilCarnage = skills.carnage
		
		local isDisabled = 0
		if unitSelf:IsStunned() then isDisable = isDisabled + 10 end
		if unitSelf:IsSilenced() then isDisable = isDisabled + 10 end
		if unitSelf:IsPerplexed() then isDisable = isDisabled + 10 end
		if unitSelf:IsImmobilized() then isDisable = isDisabled + 10 end
		if unitSelf:IsDisarmed() then isDisable = isDisabled + 10 end
		
		if abilCarnage and abilCarnage:CanActivate() and not bActionTaken then
			if nLastHarassUtility + isDisabled > object.carnageUseThreshold then
				bActionTaken = core.OrderAbility(botBrain, abilCarnage)
			end
		end
		
		if abilStrengthSap and abilStrengthSap:CanActivate() and not bActionTaken then
			if ((nLastHarassUtility > object.strengthSapUseThreshold) or (nLastHarassUtility + 3 > object.strengthSapUseThreshold and unitSelf:GetHealthPercent() < .75)) and dist < 600 then
				bActionTaken = core.OrderAbility(botBrain, abilStrengthSap)
			end
		end
		
		if abilMarkForDeath and abilMarkForDeath:CanActivate() and not bActionTaken then
			if nLastHarassUtility > object.markForDeathUseThreshold then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilMarkForDeath, unitTarget)
			end
		end
		
		if abilChainSpike and abilChainSpike:CanActivate() and not bActionTaken then
			if nLastHarassUtility > botBrain.chainSpikeUseThreshold and not unitSelf:HasState("State_Berzerker_Ability1_Self") then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilChainSpike, unitTarget)
			elseif unitSelf:HasState("State_Berzerker_Ability1_Self") and ((dist > 750 and dist < 850) or unitTarget:GetHealthPercent() < 0.2) then
				bActionTaken = core.OrderAbility(botBrain, abilChainSpike)
			end
		end
	end
	
	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end
end

object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

behaviorLib.StartingItems = {"Item_LoggersHatchet", "Item_IronBuckler", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems = {"Item_Marchers", "Item_Strength5", "Item_Steamboots", "Item_ElderParasite", "Item_Insanitarius"} --Item_Strength6 is Frostbrand
behaviorLib.MidItems = {"Item_Strength6", "Item_Immunity", "Item_StrengthAgility" } --Immunity is Shrunken Head, Item_StrengthAgility is Frostburn
behaviorLib.LateItems = {"Item_SolsBulwark", "Item_DaemonicBreastplate", "Item_BehemothsHeart", "Item_Damage9"} --Item_Damage9 is doombringer

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

BotEcho('finished loading berzerker_main')
