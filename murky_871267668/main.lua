local mod = RegisterMod("The Binding of No. 7",1)
local name = "Murky"

local Pipbuck = Isaac.GetItemIdByName("Pipbuck")
local TaintedLung = Isaac.GetItemIdByName("Tainted Lung")
local LeatherCanteen = Isaac.GetItemIdByName("Leather Canteen")
local RadawayVariant = Isaac.GetEntityVariantByName("Radaway")
local SkeletonVariant = Isaac.GetEntityVariantByName("Pipbuck Skeleton")
local BrimVariant = Isaac.GetEntityVariantByName("Brimstone Blitz")

local CoughCooldown = 0
local TechXPos = Vector (0, 0)
local CanteenGulps = 2.0

local PipbuckEquiped=false
local SpawnRadaway=false

local PipbuckSpawned=false
local BrimSpawned=false

local RadawayPTS=0
local roll=0
local LungSpeedBonus=0

local head = Isaac.GetCostumeIdByPath("gfx/characters/character_murkyhead.anm2")
local body = Isaac.GetCostumeIdByPath("gfx/characters/character_murkybody.anm2")

local Pipbuck_costume = Isaac.GetCostumeIdByPath("gfx/characters/costume_pipbuck.anm2")
local Pipbuck_costumenb = Isaac.GetCostumeIdByPath("gfx/characters/costume_pipbucknb.anm2") --costume variant without body

local Radsores_25_50 = Isaac.GetCostumeIdByPath("gfx/characters/costume_radsores_25-50.anm2")
local Radsores_50_75 = Isaac.GetCostumeIdByPath("gfx/characters/costume_radsores_50-75.anm2")
local Radsores_75_100 = Isaac.GetCostumeIdByPath("gfx/characters/costume_radsores_75-100.anm2")
local Radsores_100 = Isaac.GetCostumeIdByPath("gfx/characters/costume_radsores_100.anm2")

local CoughChance = 0
local CoughChanceMax = 50

local TrackedLaser=nil

local Rads = 0.0
local RadsMax = 200.0
local RadTick=1
local RadTickTime=36
local FullRadsFrame=0
local RadsDamageTime=900

local RadsBar = Sprite()
local RadsPointer = Sprite()
local CanteenNumbers = Sprite()

local RadsRed=false
local RadsRedFrame=0

RadsBar:Load("gfx/ui/ui_rads.anm2", true)
RadsBar:Play("Rads", false)

RadsPointer:Load("gfx/ui/ui_rads_pointer.anm2", true)
RadsPointer:Play("Rads Pointer", false)

CanteenNumbers:Load("gfx/ui/ui_canteen_numbers.anm2", true)
CanteenNumbers:Play("1", true)

function mod:get_costume() --equip Murky costume
	local player = Isaac.GetPlayer(0)
	if player:GetName() == name and Game():GetFrameCount()<1 then
		player:AddNullCostume(head)
		player:AddNullCostume(body)
		player:AddCollectible(TaintedLung, 0, 0)
	end
	
	if Isaac.HasModData(mod) and Game():GetFrameCount()>1 then
		--Isaac.DebugString("Has data!")
		local SaveData=Isaac.LoadModData(mod)
		
		local _, i=string.find(SaveData, "Rads:")
		local j, _=string.find(SaveData, ";", i)
		Rads=tonumber(string.sub(SaveData, i+1, j-1))
		
		_, i=string.find(SaveData, "Gulps:")
		j, _=string.find(SaveData, ";", i)
		CanteenGulps=tonumber(string.sub(SaveData, i+1, j-1))
		
		_, i=string.find(SaveData, "PipbuckSpawned:")
		j, _=string.find(SaveData, ";", i)
		PipbuckSpawned=("true"==string.sub(SaveData, i+1, j-1))
		
		_, i=string.find(SaveData, "BrimSpawned:")
		j, _=string.find(SaveData, ";", i)
		BrimSpawned=("true"==string.sub(SaveData, i+1, j-1))
		
		_, i=string.find(SaveData, "PipbuckEquiped:")
		j, _=string.find(SaveData, ";", i)
		PipbuckEquiped=("true"==string.sub(SaveData, i+1, j-1))
		
		if Rads==RadsMax then
			CoughChance=CoughChanceMax
			_, i=string.find(SaveData, "FullRadsFrame:")
			j, _=string.find(SaveData, ";", i)
			FullRadsFrame=tonumber(string.sub(SaveData, i+1, j-1))
			player:AddCacheFlags(CacheFlag.CACHE_SPEED)
			player:EvaluateItems()
		end
		
		--Isaac.DebugString("Loaded?"..type(PipbuckSpawned).." "..type(BrimSpawned))
		
	end
end

function mod:rads_stuff () --increase Rads, determine CoughChance, equip Radsore costumes
	local player = Isaac.GetPlayer(0)
	
	if Game():GetFrameCount()<=1 then
		Rads=0.0
		CanteenGulps=2.0
		PipbuckSpawned=false
		BrimSpawned=false
		PipbuckEquiped=false
	end
	
	if player:HasCollectible(TaintedLung) then
		
		if Rads<RadsMax and Game():GetFrameCount()%RadTickTime==0 then --Rads Increase
			if Rads+RadTick<=RadsMax then
				Rads=Rads+RadTick
			else
				Rads=RadsMax
			end
			
		end
		
		if Rads<RadsMax/4 then --Set CoughChance, equip costumes
			if CoughChance~=0 then
				CoughChance=0
				player:AddCacheFlags(CacheFlag.CACHE_SPEED)
				player:EvaluateItems()
				
				player:TryRemoveNullCostume(head)
				player:TryRemoveNullCostume(Radsores_25_50)
				player:TryRemoveNullCostume(Radsores_50_75)
				player:TryRemoveNullCostume(Radsores_75_100)
				player:TryRemoveNullCostume(Radsores_100)
				player:AddNullCostume(head)
			end
		elseif Rads<RadsMax/2 then
			if CoughChance~=CoughChanceMax/4 then
				CoughChance=CoughChanceMax/4
				player:AddCacheFlags(CacheFlag.CACHE_SPEED)
				player:EvaluateItems()
				
				player:TryRemoveNullCostume(head)
				player:TryRemoveNullCostume(Radsores_50_75)
				player:TryRemoveNullCostume(Radsores_75_100)
				player:TryRemoveNullCostume(Radsores_100)
				player:AddNullCostume(Radsores_25_50)
			end
		elseif Rads<RadsMax*3/4 then
			if CoughChance~=CoughChanceMax/2 then
				CoughChance=CoughChanceMax/2
				player:AddCacheFlags(CacheFlag.CACHE_SPEED)
				player:EvaluateItems()
				
				player:TryRemoveNullCostume(head)
				player:TryRemoveNullCostume(Radsores_25_50)
				player:TryRemoveNullCostume(Radsores_75_100)
				player:TryRemoveNullCostume(Radsores_100)
				player:AddNullCostume(Radsores_50_75)
			end
		elseif Rads<RadsMax then
			if CoughChance~=CoughChanceMax*3/4 then
				CoughChance=CoughChanceMax*3/4
				player:AddCacheFlags(CacheFlag.CACHE_SPEED)
				player:EvaluateItems()
				
				player:TryRemoveNullCostume(head)
				player:TryRemoveNullCostume(Radsores_25_50)
				player:TryRemoveNullCostume(Radsores_50_75)
				player:TryRemoveNullCostume(Radsores_100)
				player:AddNullCostume(Radsores_75_100)
			end
		elseif CoughChance~=CoughChanceMax then
			CoughChance=CoughChanceMax
			FullRadsFrame=Game():GetFrameCount()
			player:AddCacheFlags(CacheFlag.CACHE_SPEED)
			player:EvaluateItems()
			
			player:TryRemoveNullCostume(head)
			player:TryRemoveNullCostume(Radsores_25_50)
			player:TryRemoveNullCostume(Radsores_50_75)
			player:TryRemoveNullCostume(Radsores_75_100)
			player:AddNullCostume(Radsores_100)
		end
		
	end
end

function mod:on_update()
	local player = Isaac.GetPlayer(0)
	
	if player:HasCollectible(TaintedLung) then
	
		for _, entity in pairs(Isaac.GetRoomEntities()) do
			
			if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == BrimVariant then -- spawn canteen and remove Brim, after animation is finished
			
				if entity:GetSprite():IsPlaying("Appear") then
					if entity:GetSprite():GetFrame() == 5 then --Brim touches the ground
						SFXManager():Play(SoundEffect.SOUND_FORESTBOSS_STOMPS, 1.0, 0, false, 1)
					elseif entity:GetSprite():GetFrame() == 9 then --last frame of Appear animation
						Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, LeatherCanteen, Vector (entity.Position.X+20, entity.Position.Y+20), Vector (0, 0), nil)
					end
				elseif entity:GetSprite():IsPlaying("Idle") and (player.Position - entity.Position):Length() < 100 then --player gets close enough
					entity:GetSprite():Play("Jump", false)
				elseif entity:GetSprite():IsPlaying("Jump") then
					if entity:GetSprite():GetFrame() == 3 then --Brim jumps
						SFXManager():Play(SoundEffect.SOUND_FETUS_JUMP, 1.0, 0, false, 0.5)
					elseif entity:GetSprite():GetFrame() == 8 then --last frame of Jump animation
						entity:Die()
					end
				end
				
			end
			
			if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == RadawayVariant then --if the entity is radaway or radaway (half)
			
				if entity:GetSprite():IsPlaying("Idle") and Rads>0 then
					if (player.Position - entity.Position):Length() < player.Size + entity.Size and not entity:IsDead() then
					
						entity.EntityCollisionClass=EntityCollisionClass.ENTCOLL_NONE
						
						RadawayPTS=RadsMax*0.25/entity.SubType --how much points will this radaway restore
					
						SFXManager():Play(SoundEffect.SOUND_BOSS2_BUBBLES , 1.0, 0, false, 1)
						entity:GetSprite():Play("Collect", false)
						entity:Die()
						
						if player:HasCollectible(LeatherCanteen) and CanteenGulps<7 then
							CanteenGulps=CanteenGulps+RadawayPTS/(RadsMax/8)
						elseif CanteenGulps==7 then
							CanteenGulps=8.0
						else
							if Rads >= RadawayPTS then
								Rads = Rads-RadawayPTS
							else
								Rads = 0.0
							end
						end
					end
					
				elseif (entity.FrameCount == 7) then
					SFXManager():Play(SoundEffect.SOUND_FETUS_LAND , 1.0, 0, false, 1)
				end
			end
			
			if entity.Type == EntityType.ENTITY_PICKUP and ( --spawn Radaway on chest open
				entity.Variant == PickupVariant.PICKUP_CHEST
				or entity.Variant == PickupVariant.PICKUP_BOMBCHEST
				or entity.Variant == PickupVariant.PICKUP_SPIKEDCHEST
				or entity.Variant == PickupVariant.PICKUP_ETERNALCHEST
				or entity.Variant == PickupVariant.PICKUP_LOCKEDCHEST
				or entity.Variant == PickupVariant.PICKUP_REDCHEST) then
			
				local ChestData=entity:GetData()
				if ChestData.Checked==nil and entity.SubType==0 then --if chest is unchecked and open (subtype==0)
					ChestData.Checked=true
					
					roll = player:GetCollectibleRNG(TaintedLung):RandomInt(100)
					
					local DropChanceHalf=80
					local DropChanceFull=40
					
					if entity.Variant == PickupVariant.PICKUP_LOCKEDCHEST or entity.Variant == PickupVariant.PICKUP_ETERNALCHEST then
						DropChanceFull=100
					end
					
					if roll<DropChanceHalf then
						Isaac.Spawn(EntityType.ENTITY_PICKUP, RadawayVariant, 2, entity.Position, Vector(math.random()*4,math.random()*4), player)
					end
					
					roll = player:GetCollectibleRNG(TaintedLung):RandomInt(100)
					
					if roll<DropChanceFull then
						Isaac.Spawn(EntityType.ENTITY_PICKUP, RadawayVariant, 1, entity.Position, Vector(math.random()*4,math.random()*4), player)
					end
					
				end
				
				if entity.Variant == PickupVariant.PICKUP_ETERNALCHEST and entity.SubType==1 then --radaway will spawn on each eternal chest opening
					ChestData.Checked=nil
				end
			end
			
			if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_GRAB_BAG then --Spawn Radaway from Grab Bag
			
				if entity:GetSprite():IsPlaying("Collect") then
					if (player.Position - entity.Position):Length() < player.Size + entity.Size and entity:GetData().Checked==nil then
						
						entity:GetData().Checked=true
						
						roll = player:GetCollectibleRNG(TaintedLung):RandomInt(100)
					
						if roll<80 then
							Isaac.Spawn(EntityType.ENTITY_PICKUP, RadawayVariant, 2, entity.Position, Vector(math.random()*4,math.random()*4), player)
						end
						
						roll = player:GetCollectibleRNG(TaintedLung):RandomInt(100)
						
						if roll<40 then
							Isaac.Spawn(EntityType.ENTITY_PICKUP, RadawayVariant, 1, entity.Position, Vector(math.random()*4,math.random()*4), player)
						end
					
					end
				end
				
			end
			
			
			--lasers
			if entity.Type == EntityType.ENTITY_LASER and entity.SpawnerType==player.Type and entity.Variant~=7 then --Change Lasers if spawned by player and not tractor beam
				local LaserData = entity:GetData()
				local Laser = entity:ToLaser()
				
				local LaserRange=40+(-23.75-player.TearHeight)*10
				if LaserRange<25 then
					LaserRange=25
				end
				
				if player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) and Laser:IsCircleLaser() and not player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then --excludes ludovico lasers
					LaserData.Checked=true
				end
				
				if CoughCooldown==1 and LaserData.Checked == nil then
					
					--Laser:SetColor(Color (1, 0, 0, 1, 0, 0, 0), 0, 0, false, false)
					
					Laser.MaxDistance=LaserRange
				end	
				
				if CoughCooldown>0 then
					LaserData.Checked=true
				end
				
				if LaserData.Trim==true and (TechXPos - Laser.Position):Length() > LaserRange then --remove Tech X Lasers if the cough happened they if the are far enough
					LaserData.Trim=false
					Laser:Remove()
				end
				
				if LaserData.Track==true then
					if TrackedLaser:Exists() then --if the original brimstone laser was cut off then the cough ones will be cut off as well.
						Laser.Angle=TrackedLaser.Angle+LaserData.TrackAngle
					else
						Laser:Remove()
					end
				end
				
				if LaserData.Checked == nil then
					LaserData.Checked=true
					local roll=math.random(100)
					if roll<=CoughChance then
						
						--Laser:SetColor(Color (1, 0, 0, 1, 0, 0, 0), 0, 0, false, false)
						
						if not Laser:IsCircleLaser() then --if it is not a tech x laser
						
							Laser.MaxDistance=LaserRange
						
							for i=1, 1+math.random(2), 1 do
								
								local A=math.random()*45
								local NLMod=1-math.random()*0.25
		
								local NewLaserL=EntityLaser.ShootAngle(Laser.Variant, Laser.Position, Laser.Angle+A, Laser.Timeout, Vector (0, -25), player)
								--local NewLaserL=player:FireBrimstone(Laser:GetEndPoint():Rotated(Laser.Angle+A))
								
								A=360-math.random()*45
								--A=-math.random()*45
								
								local NewLaserR=EntityLaser.ShootAngle(Laser.Variant, Laser.Position, Laser.Angle+A, Laser.Timeout, Vector (0, -25), player)
								--local NewLaserR=player:FireBrimstone(Laser:GetEndPoint():Rotated(Laser.Angle+A))
								
								NewLaserR.MaxDistance=NLMod*Laser.MaxDistance
								NewLaserL.MaxDistance=NLMod*Laser.MaxDistance
								
								
								NewLaserR.Color=Laser.Color
								NewLaserL.Color=Laser.Color
								
								NewLaserR.TearFlags=Laser.TearFlags
								NewLaserL.TearFlags=Laser.TearFlags
								
								NewLaserR.CollisionDamage=Laser.CollisionDamage
								NewLaserL.CollisionDamage=Laser.CollisionDamage
								
								NewLaserR:GetData().Track=true
								NewLaserL:GetData().Track=true
								
								NewLaserR:GetData().TrackAngle=NewLaserR.Angle-Laser.Angle
								NewLaserL:GetData().TrackAngle=NewLaserL.Angle-Laser.Angle
								
								NewLaserR:GetData().Checked=true
								NewLaserL:GetData().Checked=true
								
								
								--NewLaserR.HomingLaser=Laser.HomingLaser
								--NewLaserL.HomingLaser=Laser.HomingLaser
							
							end
							
							TrackedLaser=Laser
							
						else --if it is a tech x laser
							
							LaserData.Trim=true
							TechXPos=Laser.Position
						
							for i=1, 1+math.random(2), 1 do
						
								local NewLaserL=player:FireTechXLaser(Laser.Position, Laser.Position, Laser.Radius*(0.9+0.2*math.random()))
								
								local NewLaserR=player:FireTechXLaser(Laser.Position, Laser.Position, Laser.Radius*(0.9+0.2*math.random()))
								
								local A=math.random()*45
								local NLMod=1-math.random()*0.5
								
								NewLaserR.Velocity=Vector(Laser.Velocity:Rotated(A).X*NLMod, Laser.Velocity:Rotated(A).Y*NLMod)
								
								local A=-math.random()*45
								local NLMod=1-math.random()*0.5
								
								NewLaserL.Velocity=Vector(Laser.Velocity:Rotated(A).X*NLMod, Laser.Velocity:Rotated(A).Y*NLMod)
								
								NewLaserR:GetData().Trim=true
								NewLaserL:GetData().Trim=true
								
								NewLaserR:GetData().Checked=true
								NewLaserL:GetData().Checked=true
							
							end
						end
						
						SFXManager():Play(SoundEffect.SOUND_LITTLE_HORN_COUGH , 1.0, 0, false, 1.15+math.random()*0.2) --414 is a Littlehorn cough sound
						
						CoughCooldown=1 --cooldown for the rest of this call back AND for the next one
						
					else
						CoughCooldown=2
					end
				end
			end
			--lasers
			
			
			
			if entity.Type == EntityType.ENTITY_TEAR and (entity.SpawnerType==player.Type or (entity.SpawnerType==EntityType.ENTITY_FAMILIAR and entity.SpawnerVariant==FamiliarVariant.INCUBUS)) then --Change Tears
				local TearData = entity:GetData()
				local Tear = entity:ToTear()
				
				if Tear.Variant==21 then --excludes multidimensional baby tears
					TearData.Checked=true
				end
				
				if player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) and entity.SpawnerType==player.Type then --excludes Ludovico tears (and other player created tears)
					TearData.Checked=true
				end
				
				if CoughCooldown==1 and TearData.Checked == nil then
					if Tear.Variant == 0 then --If tear variant is Blue
						Tear:ChangeVariant(TearVariant.BLOOD)
					end
					
					Tear:SetColor(Color (1, 0, 0, 1, 0, 0, 0), 0, 0, false, false)
					
					if Tear.Height*0.25 <= -5 then
						Tear.Height=Tear.Height*0.25
					else
						Tear.Height=-5
					end
				end	
				
				if CoughCooldown>0 then
					TearData.Checked=true
				end				
				
				if TearData.Checked == nil then
					TearData.Checked=true
					local roll=math.random(100)
					
					if roll<=CoughChance then
						if Tear.Variant == 0 then --If tear variant is Blue
							Tear:ChangeVariant(TearVariant.BLOOD)
						end
						
						Tear:SetColor(Color (1, 0, 0, 1, 0, 0, 0), 0, 0, false, false)
						
						if Tear.Height*0.25 <= -5 then
							Tear.Height=Tear.Height*0.25
						else
							Tear.Height=-5
						end
						--Isaac.DebugString(Tear.Height)
						
						for i=1, 1+math.random(2), 1 do
						
						local A=math.random()*45
						local NTMod=1-math.random()*0.5
						
						local NewTearR=player:FireTear(Tear.Position, Vector(Tear.Velocity:Rotated(A).X*NTMod, Tear.Velocity:Rotated(A).Y*NTMod), false, false, false)
						
						local A=-math.random()*45
						local NTMod=1-math.random()*0.5
						
						local NewTearL=player:FireTear(Tear.Position, Vector(Tear.Velocity:Rotated(A).X*NTMod, Tear.Velocity:Rotated(A).Y*NTMod), false, false, false)
						
						--Isaac.DebugString(Tear.Velocity:GetAngleDegrees().." "..Tear.Velocity.X.." "..Tear.Velocity.Y.." "..NewTearR.Velocity:GetAngleDegrees().." "..NewTearRVelocityX.." "..NewTearRVelocityY)
						
						NewTearR:ChangeVariant(Tear.Variant)
						NewTearL:ChangeVariant(Tear.Variant)
						
						NewTearR:GetData().Checked=true
						NewTearL:GetData().Checked=true
						
						
						
						NewTearR.FallingSpeed=Tear.FallingSpeed
						NewTearL.FallingSpeed=Tear.FallingSpeed
						
						NewTearR.FallingAcceleration=Tear.FallingAcceleration
						NewTearL.FallingAcceleration=Tear.FallingAcceleration
						
						NewTearR.Color=Tear.Color
						NewTearL.Color=Tear.Color
						
						NewTearR.Scale=Tear.Scale*(0.9+0.2*math.random())
						NewTearL.Scale=Tear.Scale*(0.9+0.2*math.random())
						
						NewTearR.Height=Tear.Height
						NewTearL.Height=Tear.Height
						
						NewTearR.TearFlags=Tear.TearFlags
						NewTearL.TearFlags=Tear.TearFlags
						
						NewTearR.Rotation=Tear.Rotation
						NewTearL.Rotation=Tear.Rotation
						
						NewTearR.HomingFriction=Tear.HomingFriction
						NewTearL.HomingFriction=Tear.HomingFriction
						
						NewTearR.WaitFrames=Tear.WaitFrames
						NewTearL.WaitFrames=Tear.WaitFrames
						
						NewTearR.ContinueVelocity=Tear.ContinueVelocity
						NewTearL.ContinueVelocity=Tear.ContinueVelocity
						
						NewTearR.KnockbackMultiplier=Tear.KnockbackMultiplier
						NewTearL.KnockbackMultiplier=Tear.KnockbackMultiplier
						
						NewTearR.StickTarget=Tear.StickTarget
						NewTearL.StickTarget=Tear.StickTarget
						
						NewTearR.StickDiff=Tear.StickDiff
						NewTearL.StickDiff=Tear.StickDiff
						
						NewTearR.StickTimer=Tear.StickTimer
						NewTearL.StickTimer=Tear.StickTimer
						
						NewTearR.ParentOffset=Tear.ParentOffset
						NewTearL.ParentOffset=Tear.ParentOffset
						
						NewTearR.CollisionDamage=Tear.CollisionDamage
						NewTearL.CollisionDamage=Tear.CollisionDamage
						
						end
						
						if SFXManager():IsPlaying(SoundEffect.SOUND_TEARS_FIRE) then --153 is firing a tear sound
							SFXManager():Stop(SoundEffect.SOUND_TEARS_FIRE)
						end
						SFXManager():Play(SoundEffect.SOUND_LITTLE_HORN_COUGH , 1.0, 0, false, 1.15+math.random()*0.2) --414 is a Littlehorn cough sound
						
						CoughCooldown=1 --cooldown for the rest of this callback with range and color change
						
					else
						CoughCooldown=2 --cooldown for the rest of the callback
					end
				end
			end
		end
		
		CoughCooldown=0
	end
end

function mod:save_data()
	if Game():GetFrameCount()%60==0 then
		Isaac.SaveModData(mod, "Rads:"..Rads..";"
							.."Gulps:"..CanteenGulps..";"
							.."FullRadsFrame:"..tostring(FullRadsFrame)..";"
							.."PipbuckSpawned:"..tostring(PipbuckSpawned)..";"
							.."BrimSpawned:"..tostring(BrimSpawned)..";"
							.."PipbuckEquiped:"..tostring(PipbuckEquiped)..";")
	end
end

function mod:spawn_radaway()
	local player = Isaac.GetPlayer(0)
	
	if player:HasCollectible(TaintedLung) then
	
		local room = Game():GetLevel():GetCurrentRoom()
	
		if not Game():IsGreedMode() then--not Greed mode
			if room:IsFirstVisit() and room:GetFrameCount() == 1 then
				SpawnRadaway=true
			end
			
			if Game():GetFrameCount() <= 1 then
				SpawnRadaway=false
			end
			
			if room:IsFirstVisit() and room:IsClear() and SpawnRadaway then
			
				SpawnRadaway=false
				roll = player:GetCollectibleRNG(TaintedLung):RandomInt(100)
				--Isaac.DebugString ("Full radaway roll: "..roll)
				
				if roll<15 then
					Isaac.Spawn(EntityType.ENTITY_PICKUP, RadawayVariant, 1, room:FindFreePickupSpawnPosition(Vector (320, 300), 50, true), Vector(0,0), player)
				end
				
				roll = player:GetCollectibleRNG(TaintedLung):RandomInt(100)
				--Isaac.DebugString ("Half radaway roll: "..roll)
				
				if roll<30 then
					Isaac.Spawn(EntityType.ENTITY_PICKUP, RadawayVariant, 2, room:FindFreePickupSpawnPosition(Vector (320, 300), 50, true), Vector(0,0), player)
				end
				
			end
			
		
		else--Greed mode
			if not room:IsClear() and not SpawnRadaway then
				SpawnRadaway=true
			end
			
			if Game():GetFrameCount() <= 1 then
				SpawnRadaway=false
			end
			
			if room:IsClear() and SpawnRadaway then
				SpawnRadaway=false
				Isaac.Spawn(EntityType.ENTITY_PICKUP, RadawayVariant, 1, room:FindFreePickupSpawnPosition(Vector (320, 300), 50, true), Vector(0,0), player)
				Isaac.Spawn(EntityType.ENTITY_PICKUP, RadawayVariant, 1, room:FindFreePickupSpawnPosition(Vector (320, 300), 50, true), Vector(0,0), player)
			end
		end
		
	end
end

function is_boss_loading ()
	local room = Game():GetRoom()
	
		if room:GetType() == RoomType.ROOM_BOSS and room:IsFirstVisit() and room:GetFrameCount() < 1 then
			return true
		else
			return false
		end
end

function mod:render_rads()
	local player = Isaac.GetPlayer(0)

	if not (Game():GetLevel():GetCurses() == LevelCurse.CURSE_OF_THE_UNKNOWN) and player:HasCollectible(Pipbuck) and not (is_boss_loading()) then
		if Rads<RadsMax then
			RadsRed=false
		elseif RadsRed==false then
			RadsRedFrame=0
			RadsRed=true
		end
		
		RadsBar:Render(Vector (45, 33), Vector (0, 0), Vector (0, 0))
		RadsPointer:Render(Vector (45+Rads*40/RadsMax, 33), Vector (0, 0), Vector (0, 0))
		
		if RadsRed==true then
			RadsBar:SetFrame("Rads", RadsRedFrame%120)
			RadsPointer:SetFrame("Rads Pointer", RadsRedFrame%120)
			RadsRedFrame=RadsRedFrame+1
		else
			RadsBar:SetFrame("Rads", 0)
			RadsPointer:SetFrame("Rads Pointer", 0)
		end
	end
end

function mod:render_canteen_number()
	local player = Isaac.GetPlayer(0)
	
	if player:HasCollectible(LeatherCanteen) and CanteenGulps>0 and not (is_boss_loading()) then
		CanteenNumbers:Play(string.sub(tostring(CanteenGulps), -3, -3), true)
		CanteenNumbers:Render(Vector (8, 8), Vector (0, 0), Vector (0, 0))
	end
end

function mod:use_canteen()
	local player = Isaac.GetPlayer(0)

	if CanteenGulps>0 then
		SFXManager():Play(SoundEffect.SOUND_VAMP_GULP , 1.0, 0, false, 1)
		if Rads>RadsMax/8 then
			Rads=Rads-RadsMax/8
		else
			Rads= 0.0
		end
		player:AnimateCollectible (LeatherCanteen, "UseItem", "PlayerPickup") --UseItem is an animation from player.anm2, PlayerPickup is an animation from 005.100_collectible.anm2
		CanteenGulps=CanteenGulps-1.0
	end
end

function mod:change_speed(player, cacheFlag)
	local player=Isaac.GetPlayer(0)
	
	if player:HasCollectible(TaintedLung) then
		if cacheFlag==CacheFlag.CACHE_SPEED then
			player.MoveSpeed=player.MoveSpeed-0.9*CoughChance/CoughChanceMax
		end
	end
end

function mod:rads_damage ()
	local player=Isaac.GetPlayer(0)
	
	if player:HasCollectible(TaintedLung) and Rads==RadsMax and (Game():GetFrameCount()-FullRadsFrame)%RadsDamageTime==0 and Game():GetFrameCount()-FullRadsFrame~=0 then
		player:TakeDamage(1, DamageFlag.DAMAGE_INVINCIBLE, EntityRef(player), 0)
	end
end

function mod:equip_pipbuck()
	local player=Isaac.GetPlayer(0)
	
	if player:HasCollectible(Pipbuck) and not PipbuckEquiped then
		PipbuckEquiped=true
		if player:GetName()==name then
			player:TryRemoveNullCostume(body)
			player:AddNullCostume(Pipbuck_costume)
		else
			player:AddNullCostume(Pipbuck_costumenb)
		end
		player:AddCollectible(CollectibleType.COLLECTIBLE_COMPASS, 0, 0)
	end
end

function mod:spawn_pipbuck()
	local player=Isaac.GetPlayer(0)
	local level=Game():GetLevel()
	local room=Game():GetRoom()
	
	if level:GetStage() == LevelStage.STAGE1_1 and room:GetType() == RoomType.ROOM_TREASURE and room:IsFirstVisit() and room:GetFrameCount()==1 and player:GetName() == name and not PipbuckSpawned then
		PipbuckSpawned=true
		local PipbuckItem=Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, Pipbuck, room:FindFreePickupSpawnPosition(Vector (320, 300), 50, true), Vector (0, 0), nil)
		Isaac.Spawn(EntityType.ENTITY_SHOPKEEPER, SkeletonVariant, 0, Vector (PipbuckItem.Position.X, PipbuckItem.Position.Y+20), Vector (0, 0), nil)
	end
	
end

function mod:spawn_canteen()
	local player=Isaac.GetPlayer(0)
	local level=Game():GetLevel()
	local room=Game():GetRoom()
	
	if (level:GetStage() == LevelStage.STAGE1_2 or level:GetStage() == LevelStage.STAGE2_1) and room:IsFirstVisit() and room:GetFrameCount()==1 and player:GetName() == name and not BrimSpawned then
		BrimSpawned=true
		Isaac.Spawn(EntityType.ENTITY_PICKUP, BrimVariant, 0, Vector (100, 380), Vector (0, 0), nil)
	end
end

function debug_text()
	local player = Isaac.GetPlayer(0)
	--text=Rads.." "..CoughChance.." "..CanteenGulps.." "..Game():GetFrameCount().." "..FullRadsFrame.." PS:"..tostring(PipbuckSpawned).." BS:"..tostring(BrimSpawned).." PE:"..tostring(PipbuckEquiped)
	Isaac.RenderText(tostring(text), 100, 100, 255, 0, 0, 255)
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.get_costume)

mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.equip_pipbuck)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.rads_stuff)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.on_update)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.rads_damage)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.save_data)

mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.render_rads)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.render_canteen_number)

mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.use_canteen, LeatherCanteen )
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.change_speed)

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.spawn_pipbuck)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.spawn_canteen)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.spawn_radaway)

--mod:AddCallback(ModCallbacks.MC_POST_RENDER, debug_text)