--> Additional Comments <--
--> This module script in ServerScriptService was used primarley to handle tower upgrades, selling, attacking, etc. <--

--> Script <--
-- Getting variables required for script --
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local mobsFolder = workspace:WaitForChild("Mobs")

local HealthModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Health"))
local TowerBarrierModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TowerBarrier"))
 
local maxTowers = 20

local tower = {}

local function GetTowerDowngrade(newTower)
	if newTower then
		local towerExists = ReplicatedStorage.Towers:FindFirstChild(newTower.Name, true)
		if towerExists then
			for i, child in pairs(ReplicatedStorage.Towers:GetDescendants()) do
				local config = child:FindFirstChild("Config")
				if config and config:FindFirstChild("Upgrade") then
					if config.Upgrade.Value and config.Upgrade.Value == towerExists then
						return child
					end
				end
			end
		end
	end
	
	return false
end

function tower.FindTarget(newTower, range, mode)
	local bestTarget = nil
	local bestWaypoint = nil
	local bestDistance = nil
	local bestHealth = nil
	local map = workspace.Map:FindFirstChildOfClass("Model")
	
	for i, mob in pairs(mobsFolder:GetChildren()) do
		if mob:IsA("Model") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 and mob:FindFirstChild("HumanoidRootPart") and map.Waypoints:FindFirstChild(mob.Config.MovingTo.Value + 1) then
			local distanceToMob = ((mob.HumanoidRootPart.Position - newTower.HumanoidRootPart.Position).X^2 + (mob.HumanoidRootPart.Position - newTower.HumanoidRootPart.Position).Z^2)^0.5
			local distanceToWaypoint = ((mob.HumanoidRootPart.Position - map.Waypoints[mob.Config.MovingTo.Value + 1].Position).X^2 + (mob.HumanoidRootPart.Position - map.Waypoints[mob.Config.MovingTo.Value + 1].Position).Z^2)^0.5
			
			if distanceToMob <= range then
				if mode == "Closest" then
					range = distanceToMob
					bestTarget = mob
				elseif mode == "First" then
					if (not bestWaypoint) or mob.Config.MovingTo.Value >= bestWaypoint then
						bestWaypoint = mob.Config.MovingTo.Value
						
						if (not bestDistance) or distanceToWaypoint < bestDistance then
							bestDistance = distanceToWaypoint
							bestTarget = mob
						end
					end
				elseif mode == "Last" then
					if not bestWaypoint or mob.Config.MovingTo.Value <= bestWaypoint then
						bestWaypoint = mob.Config.MovingTo.Value

						if not bestDistance or distanceToWaypoint > bestDistance then
							bestDistance = distanceToWaypoint
							bestTarget = mob
						end
					end
				elseif mode == "Strongest" then
					if not bestHealth or mob.Humanoid.Health > bestHealth then
						bestHealth = mob.Humanoid.Health
						bestTarget = mob
					end
				elseif mode == "Weakest" then
					if not bestHealth or mob.Humanoid.Health < bestHealth then
						bestHealth = mob.Humanoid.Health
						bestTarget = mob
					end
				end
			end
		end
	end
	
	return bestTarget
end

function tower.UseAbility(newTower, name, requirments)
	local abilityModule = script:FindFirstChild(name)
	if abilityModule then
		require(abilityModule).Ability(newTower, requirments)
	end
end

function tower.Attack(newTower)
	local config = newTower.Config
	local target = tower.FindTarget(newTower, config.Range.Value, config.TargetMode.Value)
	if target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0  and (not config:FindFirstChild("Numb")) then
		if config:FindFirstChild("AttackAbilities") then
			for i, folder in pairs(config.AttackAbilities:GetChildren()) do
				local requirements = {
					["AbilitiesFolder"] = config.AttackAbilities
				}
				tower.UseAbility(newTower, folder.Name, requirements)
			end
		else
			local TowerTurnToTargetRootPart = TweenService:Create(newTower.HumanoidRootPart, TweenInfo.new(0.01), {CFrame = CFrame.lookAt(newTower.HumanoidRootPart.Position, target.HumanoidRootPart.Position)})
			TowerTurnToTargetRootPart:Play()

			TowerTurnToTargetRootPart.Completed:Connect(function()
				ReplicatedStorage.Remote.RemoteEvents.AnimateTower:FireAllClients(newTower, "Attack", "Gunshot", target)
				if config:FindFirstChild("Damage") then
					local defensiveValue = {}
					local targetHasDefensiveObject = false
					for defensiveObjectName, color3Represenitive in pairs(HealthModule.DefensiveObjects) do
						if target.Config and target.Config:FindFirstChild(defensiveObjectName) then
							targetHasDefensiveObject = true
							defensiveValue[defensiveObjectName] = HealthModule.GetDefensiveValue(defensiveObjectName, target)[defensiveObjectName]
						end
					end
					if targetHasDefensiveObject then
						local leastImportant
						local firstDefensiveValueObjectName = nil
						local firstDefensiveValue = nil
						for defensiveObjectName, healthSettings in pairs(defensiveValue) do
							if healthSettings and (healthSettings[3] == 1  or (not firstDefensiveValue) or healthSettings[3] > leastImportant) then
								leastImportant = healthSettings[3]
								firstDefensiveValueObjectName = defensiveObjectName
								firstDefensiveValue = healthSettings
							end
						end
						if firstDefensiveValue and firstDefensiveValueObjectName and firstDefensiveValue[1] and firstDefensiveValue[2] then
							firstDefensiveValue[1].Value -= config.Damage.Value

							if firstDefensiveValue[1].Value <= 0 then
								firstDefensiveValue[1].Value = 0
							end
							for i, player in pairs(game.Players:GetPlayers()) do
								player.Cash.Value += math.round((target.Config.CashDrop.Value * (1-(firstDefensiveValue[1].Value/firstDefensiveValue[2].Value)) / (#game.Players:GetPlayers()/0.8)))	
							end
							if firstDefensiveValue[1].Value <= 0 then
								target.Config[firstDefensiveValueObjectName]:Destroy()
							end
						else
							target.Humanoid:TakeDamage(config.Damage.Value)

							for i, player in pairs(game.Players:GetPlayers()) do
								if target.Humanoid.Health <= 0 then
									player.Cash.Value += math.round(target.Config.CashDrop.Value / (#game.Players:GetPlayers()/0.8))
								else
									player.Cash.Value += math.round((target.Config.CashDrop.Value * (1-(target.Humanoid.Health/target.Humanoid.MaxHealth)) / (#game.Players:GetPlayers()/0.8)))
									target.Config.CashDrop.Value -= math.round((target.Config.CashDrop.Value * (1-(target.Humanoid.Health/target.Humanoid.MaxHealth)) / (#game.Players:GetPlayers()/0.8)))
								end
							end
						end
					else
						target.Humanoid:TakeDamage(config.Damage.Value)

						for i, player in pairs(game.Players:GetPlayers()) do
							if target.Humanoid.Health <= 0 then
								player.Cash.Value += math.round(target.Config.CashDrop.Value / (#game.Players:GetPlayers()/0.8))
							else
								player.Cash.Value += math.round((target.Config.CashDrop.Value * (1-(target.Humanoid.Health/target.Humanoid.MaxHealth)) / (#game.Players:GetPlayers()/0.8)))
								target.Config.CashDrop.Value -= math.round((target.Config.CashDrop.Value * (1-(target.Humanoid.Health/target.Humanoid.MaxHealth)) / (#game.Players:GetPlayers()/0.8)))
							end
						end
					end
				end
			end)
		end

		task.wait(config.Cooldown.Value)
	end
	task.wait(0.01)

	if newTower and newTower.Parent then
		tower.Attack(newTower)
	end
end

function tower.CheckForATarget(newTower)
	local heartBeatConnection
	
	heartBeatConnection = RunService.Heartbeat:Connect(function()
		if newTower and newTower.Parent then
			local config = newTower.Config
			local target = tower.FindTarget(newTower, config.Range.Value, config.TargetMode.Value)

			if target then
				config.Target.Value = target
			else
				config.Target.Value = nil
			end
		else
			heartBeatConnection:Disconnect()
		end
	end)
end

function tower.ChangeMode(player, model)
	if model and model:FindFirstChild("Config") then
		local targetMode = model.Config.TargetMode
		local modes = {"First", "Last", "Closest", "Strongest", "Weakest"}
		local modeIndex = table.find(modes, targetMode.Value)
		
		if modeIndex < #modes then
			targetMode.Value = modes[modeIndex + 1]
		else
			targetMode.Value = modes[1]
		end
		
		return targetMode.Value
	else
		warn("⚠️ Unable To Change Tower Mode ⚠️")
		return false
	end
end
ReplicatedStorage.Remote.RemoteFunctions.ChangeTowerMode.OnServerInvoke = tower.ChangeMode

function tower.Sell(player, model)
	if model and model:FindFirstChild("Config") then
		if model.Config.Owner.Value == tostring(player.UserId) then
			player.PlacedTowers.Value -= 1
			player.Cash.Value += math.round(model.Config.Price.Value / 3)
			model:Destroy()
			return true
		end
	end
	warn("⚠️ Unable To Sell This Tower ⚠️")
	return false
end
ReplicatedStorage.Remote.RemoteFunctions.SellTower.OnServerInvoke = tower.Sell

function tower.WorkspaceRaycast(blacklist, cframe)
	local camera = workspace.CurrentCamera
	local workspaceRay = camera:ViewportPointToRay(cframe.X, CFrame.Y)
	local raycastResult

	if blacklist then
		local raycastParams = RaycastParams.new()

		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = blacklist

		raycastResult = workspace:Raycast(workspaceRay.Origin, workspaceRay.Direction*1000, raycastParams)
	else
		raycastResult = workspace:Raycast(workspaceRay.Origin, workspaceRay.Direction*1000)
	end

	return raycastResult
end

function tower.Spawn(player, name, cframe, previous)
	local allowedToSpawn = tower.CheckSpawn(player, name, previous) -- checks if tower exists

	if allowedToSpawn == true then
		local newTower = ReplicatedStorage.Towers:FindFirstChild(name, true):Clone()
		local oldMode = nil
		
		-- Set Collision Group model "tower" to Collision Group "Tower" --
		for i, object in pairs(newTower:GetDescendants()) do
			if object:IsA("BasePart") or object:IsA("Part") or object:IsA("MeshPart") then
				object.CollisionGroup = "Tower"
			end
		end
		
		-- Creates A Value Named Upgrade Number --
		if previous then
			local UpgradeValue = previous.Config:FindFirstChild("UpgradeNumber") or Instance.new("IntValue")
			local newDowngradedTower = GetTowerDowngrade(previous)
			local latestDowngradedTower = newDowngradedTower
			local count = 1
			repeat
				count += 1
				newDowngradedTower = GetTowerDowngrade(latestDowngradedTower)
				if newDowngradedTower then
					latestDowngradedTower = newDowngradedTower
				end
			until not newDowngradedTower
			if latestDowngradedTower then
				UpgradeValue.Value = count
			else
				UpgradeValue.Value = 1
			end
			UpgradeValue.Name = "UpgradeNumber"
			UpgradeValue.Parent = newTower.Config
			oldMode = previous.Config.TargetMode.Value
			for i, SquareBarrier in pairs(workspace.Effects:GetChildren()) do
				if SquareBarrier.Name == "SquareBarrier" and SquareBarrier:FindFirstChild("TowerParent") and SquareBarrier.TowerParent.Value == previous then
					SquareBarrier:Destroy()
				end
			end
		else
			player.PlacedTowers.Value += 1
		end
		
		-- Create Tower Owner Value --
		local ownerValue = Instance.new("StringValue")
		ownerValue.Name = "Owner"
		ownerValue.Value = player.UserId
		ownerValue.Parent = newTower.Config
		
		-- Create Tower Mode Value --
		local targetMode = Instance.new("StringValue")
		targetMode.Name = "TargetMode"
		targetMode.Value = oldMode or "First"
		targetMode.Parent = newTower.Config
		
		-- Create Tower Target Value --
		local target = Instance.new("ObjectValue")
		target.Name = "Target"
		target.Parent = newTower.Config
		
		-- Spawn tower into workspace with correct location --
		newTower.HumanoidRootPart.CFrame = cframe
		newTower.Parent = workspace.Towers
		newTower.HumanoidRootPart:SetNetworkOwner(nil)
		
		local ReturnedSquareBarrier = TowerBarrierModule.Create(newTower, true)
		if ReturnedSquareBarrier then
			local filter = OverlapParams.new()
			filter.FilterDescendantsInstances = {workspace.Effects}
			filter.FilterType = Enum.RaycastFilterType.Include
			local foundParts = workspace:GetPartsInPart(ReturnedSquareBarrier, filter)
			for i, otherSquareBarriers in pairs(foundParts) do
				if otherSquareBarriers.Name == "SquareBarrier" then
					ReturnedSquareBarrier:Destroy()
					newTower:Destroy()
					warn("⚠️ Tower Can't Be Placed In Other Tower Radius ⚠️")
					return
				end
			end
			if previous then
				previous:Destroy()
			end
		else
			newTower:Destroy()
			return
		end
		local TouchingOtherTowers = false
		local newFilter = OverlapParams.new()
		newFilter.FilterDescendantsInstances = {newTower}
		newFilter.FilterType = Enum.RaycastFilterType.Exclude
		for i, part in pairs(newTower:GetDescendants()) do
			if part:IsA("Part") or part:IsA("BasePart") or part:IsA("MeshPart") then
				for i2, part2 in pairs(workspace.Towers:GetDescendants()) do
					if part2:IsA("Part") or part2:IsA("BasePart") or part2:IsA("MeshPart") then
						local foundParts = workspace:GetPartsInPart(part, newFilter)
						if table.find(foundParts, part2) then
							TouchingOtherTowers = true
						end
					end
				end
			end
		end
		if TouchingOtherTowers then
			newTower:Destroy()
			return
		end
		
		if newTower.Config:FindFirstChild("PreviousPrice") then
			player.Cash.Value -= newTower.Config.Price.Value - newTower.Config.PreviousPrice.Value
		else
			player.Cash.Value -= newTower.Config.Price.Value
		end
		
		coroutine.wrap(tower.Attack)(newTower) -- creates a coroutine function for the function "tower.Attack()", given the required models that can run the function "tower.Spawn" again
		coroutine.wrap(tower.CheckForATarget)(newTower)
		
		return newTower
	else
		warn(allowedToSpawn or "⚠️ Requested Tower Does Not Exist: ".. name .. "⚠️") -- a warning in Dev Console if mob does not exist
		return allowedToSpawn
	end
end

ReplicatedStorage.Remote.RemoteFunctions.SpawnTower.OnServerInvoke = tower.Spawn

function tower.CheckSpawn(player, name, previous)
	local towerExists = ReplicatedStorage:WaitForChild("Towers"):FindFirstChild(name, true)
	
	if towerExists then
		if previous and previous:FindFirstChild("Config") then
			if previous.Config.Owner.Value ~= tostring(player.UserId) then
				return "Player Isn't Owner"
			end
		elseif previous and not previous:FindFirstChild("Config") then
			return
		elseif not previous then
			local numberOfTowerModel = 0
			for i, playerTowers in pairs(workspace.Towers:GetChildren()) do
				local newDowngradedTower = GetTowerDowngrade(playerTowers)
				local latestDowngradedTower = newDowngradedTower
				local count = 1
				repeat
					count += 1
					newDowngradedTower = GetTowerDowngrade(latestDowngradedTower)
					if newDowngradedTower then
						latestDowngradedTower = newDowngradedTower
					end
				until not newDowngradedTower
				
				if not latestDowngradedTower then
					latestDowngradedTower = playerTowers
				end
				
				if latestDowngradedTower.Name == towerExists.Name and playerTowers.Config:FindFirstChild("Owner") and playerTowers.Config.Owner.Value == tostring(player.UserId) then
					numberOfTowerModel += 1
				end
			end
			if numberOfTowerModel == towerExists.Config.Limit.Value then
				return towerExists.Humanoid.DisplayName.." Has A Placement Limit Of "..towerExists.Config.Limit.Value
			end
		end
		
		local PriceNeeded
		if towerExists.Config:FindFirstChild("PreviousPrice") then
			PriceNeeded = towerExists.Config.Price.Value - towerExists.Config.PreviousPrice.Value
		else
			PriceNeeded = towerExists.Config.Price.Value
		end
		if PriceNeeded <= player.Cash.Value then
			if previous or player.PlacedTowers.Value < maxTowers then
				return true
			else
				return "Max Tower Placement"
			end
		elseif PriceNeeded > player.Cash.Value then
			return "Cannot Afford"
		end
	end
	
	return
end

ReplicatedStorage.Remote.RemoteFunctions.RequestTower.OnServerInvoke = tower.CheckSpawn

game.Players.PlayerAdded:Connect(function()
	maxTowers = math.round(20/(math.round(#game.Players:GetPlayers()*0.8)))
end)

return tower
