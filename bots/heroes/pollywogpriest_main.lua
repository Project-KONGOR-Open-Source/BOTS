--WitchSlayerBot v1.0


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

BotEcho('loading pollywogpriest_main...')

object.heroName = 'Hero_PollywogPriest'

--------------------------------
-- Lanes
--------------------------------
core.tLanePreferences = {Jungle = 0, Mid = 2, ShortSolo = 2, LongSolo = 1, ShortSupport = 5, LongSupport = 5, ShortCarry = 2, LongCarry = 1}

--------------------------------
-- Skills
--------------------------------
local bSkillsValid = false
function object:SkillBuild()
	local unitSelf = self.core.unitSelf	
	
	if not bSkillsValid then
		skills.electricJolt			= unitSelf:GetAbility(0)
		skills.morph				= unitSelf:GetAbility(1)
		skills.tongueTied			= unitSelf:GetAbility(2)
		skills.voodooWards			= unitSelf:GetAbility(3)
		skills.abilAttributeBoost	= unitSelf:GetAbility(4)
		
		if skills.electricJolt and skills.morph and skills.tongueTied and skills.voodooWards and skills.abilAttributeBoost then
			bSkillsValid = true
		else
			return
		end
	end
	
	if unitSelf:GetAbilityPointsAvailable() <= 0 then
		return
	end
	
	if skills.voodooWards:CanLevelUp() then
		skills.voodooWards:LevelUp()
	elseif skills.tongueTied:CanLevelUp() then
		skills.tongueTied:LevelUp()
	elseif skills.electricJolt:GetLevel() < 1 then
		skills.electricJolt:LevelUp()
	elseif skills.morph:CanLevelUp() then
		skills.morph:LevelUp()
	elseif skills.electricJolt:CanLevelUp() then
		skills.electricJolt:LevelUp()
	else
		skills.abilAttributeBoost:LevelUp()
	end
end

---------------------------------------------------
--                   Overrides                   --
---------------------------------------------------

--[[for testing
function object:onthinkOverride(tGameVariables)
	self:onthinkOld(tGameVariables)
	
	core.unitSelf:TeamShare()
	
	-- Insert code here
end
object.onthinkOld = object.onthink
object.onthink 	= object.onthinkOverride
--]]


----------------------------------
--	Witch Slayer's specific harass bonuses
--
--  Abilities off cd increase harass util
--  Ability use increases harass util for a time
----------------------------------

object.nElectricJoltUp = 4
object.nMorphUp = 5
object.nTongueTiedUp = 6
object.nVoodooWardsUp = 40
object.nSheepstickUp = 12

object.nElectricJoltUse = 18
object.nMorphUse = 22
object.nTongueTiedUse = 18
object.nVoodooWardsUse = 48
object.nSheepstickUse = 12

object.nElectricJoltThreshold = 18
object.nMorphThreshold = 21
object.nTongueTiedThreshold = 18
object.nVoodooWardsThreshold = 47
object.nSheepstickThreshold = 12

local function AbilitiesUpUtility(hero)
	local bDebugLines = false
	local bDebugEchos = false
	
	local nUtility = 0
	
	if skills.electricJolt:CanActivate() then
		nUtility = nUtility + object.nElectricJoltUp
	end
	
	if skills.morph:CanActivate() then
		nUtility = nUtility + object.nMorphUp
	end
	
	if skills.voodooWards:CanActivate() then
		nUtility = nUtility + object.nTongueTiedUp
	end
	
	if skills.tongueTied:CanActivate() then
		nUtility = nUtility + object.nVoodooWardsUp
	end
	
	if object.itemSheepstick and object.itemSheepstick:CanActivate() then
		nUtility = nUtility + object.nSheepstickUp
	end
	
	if bDebugEchos then BotEcho(" HARASS - abilitiesUp: "..nUtility) end
	if bDebugLines then
		local lineLen = 150
		local myPos = core.unitSelf:GetPosition()
		local vTowards = Vector3.Normalize(hero:GetPosition() - myPos)
		local vOrtho = Vector3.Create(-vTowards.y, vTowards.x) --quick 90 rotate z
		core.DrawDebugArrow(myPos - vOrtho * lineLen * 1.4, (myPos - vOrtho * lineLen * 1.4 ) + vTowards * nUtility * (lineLen/100), 'cyan')
	end
	
	return nUtility
end

--Witch Slayer ability use gives bonus to harass util for a while
function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)
	
	local bDebugEchos = false
	local nAddBonus = 0
	
	if EventData.Type == "Ability" then
		if bDebugEchos then BotEcho("  ABILILTY EVENT!  InflictorName: "..EventData.InflictorName) end
		if EventData.InflictorName == "Ability_PollywogPriest1" then
			nAddBonus = nAddBonus + object.nElectricJoltUse
		elseif EventData.InflictorName == "Ability_PollywogPriest2" then
			nAddBonus = nAddBonus + object.nMorphUse
		elseif EventData.InflictorName == "Ability_PollywogPriest3" then
			nAddBonus = nAddBonus + object.nTongueTiedUse
		elseif EventData.InflictorName == "Ability_PollywogPriest4" then
			nAddBonus = nAddBonus + object.nVoodooWardsUse
		end
	elseif EventData.Type == "Item" then
		if core.itemSheepstick ~= nil and EventData.SourceUnit == core.unitSelf:GetUniqueID() and EventData.InflictorName == core.itemSheepstick:GetName() then
			nAddBonus = nAddBonus + self.nSheepstickUse
		end
	end
	
	if nAddBonus > 0 then
		--decay before we add
		core.DecayBonus(self)
	
		core.nHarassBonus = core.nHarassBonus + nAddBonus
	end
end
object.oncombateventOld = object.oncombatevent
object.oncombatevent 	= object.oncombateventOverride

--Util calc override
local function CustomHarassUtilityFnOverride(hero)
	local nUtility = AbilitiesUpUtility(hero)
	local unitSelf = core.unitSelf
	
	if unitSelf:GetHealthPercent() > .93 then
		nUtility = nUtility + 4
	end
	
	if unitSelf:GetManaPercent() > .93 then
		nUtility = nUtility + 8
	end
	
	if unitSelf:HasState("State_PollywogPriest_Ability3_Self") then
		nUtility = nUtility + 16
	end
	
	return nUtility
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride   

----------------------------------
--	Witch Slayer harass actions
----------------------------------

local function HarassHeroExecuteOverride(botBrain)
	local bDebugEchos = false
	
	local unitTarget = behaviorLib.heroTarget
	if unitTarget == nil or not unitTarget:IsValid() then
		return false --can not execute, move on to the next behavior
	end
	
	local unitSelf = core.unitSelf
	
	local vecMyPosition = unitSelf:GetPosition()
	local nAttackRangeSq = core.GetAbsoluteAttackRangeToUnit(unitSelf, unitTarget)
	nAttackRangeSq = nAttackRangeSq * nAttackRangeSq
	local nMyExtraRange = core.GetExtraRange(unitSelf)
	
	local vecTargetPosition = unitTarget:GetPosition()
	local nTargetExtraRange = core.GetExtraRange(unitTarget)
	local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)
	local bTargetRooted = unitTarget:IsStunned() or unitTarget:IsImmobilized() or unitTarget:GetMoveSpeed() < 300
	
	local nLastHarassUtility = behaviorLib.lastHarassUtil
	local bCanSee = core.CanSeeUnit(botBrain, unitTarget)	
	
	if bDebugEchos then BotEcho("Witch Slayer HarassHero at "..nLastHarassUtility) end
	local bActionTaken = false

	--since we are using an old pointer, ensure we can still see the target for entity targeting
	if core.CanSeeUnit(botBrain, unitTarget) then
		local bTargetVuln = unitTarget:IsStunned() or unitTarget:IsImmobilized()

		--Sheepstick
		if not bActionTaken and not bTargetVuln then
			local itemSheepstick = core.itemSheepstick
			if itemSheepstick then
				local nRange = itemSheepstick:GetRange()
				if itemSheepstick:CanActivate() and nLastHarassUtility > botBrain.nSheepstickThreshold then
					if nTargetDistanceSq < (nRange * nRange) then
						bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, itemSheepstick, unitTarget)
					end
				end
			end
		end
	end
	
	--Voodoo Wards
	if not bActionTaken and not unitSelf:HasState("State_PollywogPriest_Ability3_Self") and((nLastHarassUtility > object.nVoodooWardsThreshold * 0.7 and bTargetRooted) or nLastHarassUtility > object.nVoodooWardsThreshold) then
		local abilVoodoo = skills.voodooWards
		if abilVoodoo:CanActivate() then
			local nRange = abilVoodoo:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderAbilityPosition(botBrain, abilVoodoo, vecTargetPosition)
			end
		end
	end
	
	--Electric Jolt
	if not bActionTaken and not unitSelf:HasState("State_PollywogPriest_Ability3_Self") and nLastHarassUtility > object.nElectricJoltThreshold then
		local abilJolt = skills.electricJolt
		if abilJolt:CanActivate() then
			local nRange = abilJolt:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilJolt, unitTarget)
			end
		end
	end
	
	--Tongue Tied
	if not bActionTaken and not unitSelf:HasState("State_PollywogPriest_Ability3_Self") and nLastHarassUtility > object.nTongueTiedThreshold then
		local abilTongue = skills.tongueTied
		if abilTongue:CanActivate() then
			local nRange = abilTongue:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilTongue, unitTarget)
			end
		end
	end
	
	--Morph
	if not bActionTaken and not unitSelf:HasState("State_PollywogPriest_Ability3_Self") and nLastHarassUtility > object.nMorphThreshold then
		local abilMorph = skills.morph
		if abilMorph:CanActivate() then
			local nRange = abilMorph:GetRange()
			if nTargetDistanceSq < (nRange * nRange) then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilMorph, unitTarget)
			end
		end
	end
	
	if not bActionTaken then
		if bDebugEchos then BotEcho("  No action yet, proceeding with normal harass execute.") end
		return object.harassExecuteOld(botBrain)
	end
end
object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

----------------------------------
--  FindItems Override
----------------------------------
local function funcFindItemsOverride(botBrain)
	object.FindItemsOld(botBrain)

	core.ValidateItem(core.itemSheepstick)
	
	--only update if we need to
	if core.itemSheepstick then
		return
	end

	local inventory = core.unitSelf:GetInventory(false)
	for slot = 1, 6, 1 do
		local curItem = inventory[slot]
		if curItem and not curItem:IsRecipe() then
			if core.itemSheepstick == nil and curItem:GetName() == "Item_Morph" then
				core.itemSheepstick = core.WrapInTable(curItem)
			end
		end
	end
end
object.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride

----------------------------------
--	Witch Slayer items
----------------------------------
--[[ list code:
	"# Item" is "get # of these"
	"Item #" is "get this level of the item" --]]
behaviorLib.StartingItems = 
	{"Item_GuardianRing", "Item_PretendersCrown", "Item_MinorTotem", "Item_HealthPotion", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems = 
	{"Item_ManaRegen3", "Item_Marchers", "Item_Striders", "Item_GraveLocket"} --ManaRegen3 is Ring of the Teacher
behaviorLib.MidItems = 
	{"Item_SacrificialStone", "Item_NomesWisdom", "Item_Astrolabe", "Item_Intelligence7"} --Intelligence7 is Staff of the Master
behaviorLib.LateItems = 
	{"Item_Morph", "Item_BehemothsHeart", 'Item_Damage9'} --Morph is Sheepstick. Item_Damage9 is Doombringer


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

BotEcho('finished loading witchslayer_main')
