--> Additional Comments <--
--> This script was used for one tower ability <--

--> Script <--
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local mobsFolder = workspace:WaitForChild("Mobs")

local HealthModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Health"))
local towerModule = require(script.Parent)

local multiHit = {
	["MultiSource"] = {
		["HeroCowboyTower"] = {"Gun1", "Gun2"}
	}
}

function multiHit.Attack(newTower, requirments, target, i, doAnim)
	if target:FindFirstChild("HumanoidRootPart") then
		local config = newTower.Config
		local TowerTurnToTargetRootPart = TweenService:Create(newTower.HumanoidRootPart, TweenInfo.new(0.01), {CFrame = CFrame.lookAt(newTower.HumanoidRootPart.Position, target.HumanoidRootPart.Position)})
		TowerTurnToTargetRootPart:Play()

		TowerTurnToTargetRootPart.Completed:Connect(function()
			for towerName, sources in pairs(multiHit.MultiSource) do
				if towerName == newTower.Name then
					local source = newTower:FindFirstChild(sources[i])
					if source then
						ReplicatedStorage.Remote.RemoteEvents.AnimateTower:FireAllClients(newTower, "Attack", "Gunshot", target, source, doAnim, delayAtStart)
					end
				end
			end
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
end

function multiHit.Ability(newTower, requirments)
	if requirments.AbilitiesFolder and requirments.AbilitiesFolder.MultiHit then
		local config = newTower.Config
		local target = towerModule.FindTarget(newTower, config.Range.Value, config.TargetMode.Value)
		local hitAmount = requirments.AbilitiesFolder.MultiHit.Amount.Value
		local waitTime = requirments.AbilitiesFolder.MultiHit.WaitTime.Value

		if not target then
			repeat
				target = towerModule.FindTarget(newTower, config.Range.Value, config.TargetMode.Value)
				task.wait(0.1)
			until target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 and target:FindFirstChild("HumanoidRootPart")
		end
		for i = 1, hitAmount do
			local doAnim = true
			if i == requirments.AbilitiesFolder.MultiHit.MultiAnim.Value then
				doAnim = false
			end
			if not target:FindFirstChild("HumanoidRootPart") then
				repeat
					target = towerModule.FindTarget(newTower, config.Range.Value, config.TargetMode.Value)
					task.wait(0.1)
				until target and target:FindFirstChild("Humanoid") and target.Humanoid.Health > 0 and target:FindFirstChild("HumanoidRootPart")
			end
			multiHit.Attack(newTower, requirments, target, i, doAnim)
			task.wait(waitTime)
		end
	end
end

return multiHit
