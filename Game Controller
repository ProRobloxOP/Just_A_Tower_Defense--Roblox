--> Additional Comments <--
--> The script was used as a way to show tower placements locally <--

--> Last updated: 11/4/2023 (mm, dd, yy) <--
--> Script <--
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = game.Players.LocalPlayer
local TowersFolderInRS = ReplicatedStorage:WaitForChild("Towers")
local camera = workspace.CurrentCamera

local gameStarted = false
local hoveredInstance = nil
local selectedTower = nil
local secondSelectedTower = nil
local towerToSpawn = nil
local touchingOtherSquareBarriers = 0
local canPlace = false
local rotation = 0
local lastTouch = tick()

local info = workspace:WaitForChild("Info")

local gui = script.Parent
local EquippedTowersFrame = gui:WaitForChild("EquippedTowersFrame")
local ErrorFrame = gui:WaitForChild("ErrorFrame")
local PlayerCashFrame = gui:WaitForChild("PlayerCash")
local InfoFrame = gui:WaitForChild("Info")

local PlayerEarnedCashFrame = PlayerCashFrame:WaitForChild("PlayerEarnedCash")
local InfoHealthFrame = InfoFrame:WaitForChild("Health")
local InfoStatsFrame = InfoFrame:WaitForChild("Stats")

local playerCashValue = player:WaitForChild("Cash")

local HealthModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Health"))
local TowersBarrierModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("TowerBarrier"))
local ViewportGuiModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ViewportGui"))
local PathArrowsModule = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("PathArrows"))

local function MouseRaycast(blacklist)
	local mousePosition = UserInputService:GetMouseLocation()
	local mouseRay = camera:ViewportPointToRay(mousePosition.X, mousePosition.Y)
	local raycastResult

	if blacklist then
		local raycastParams = RaycastParams.new()

		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = blacklist

		raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction*1000, raycastParams)
	else
		raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction*1000)
	end

	return raycastResult
end

local function CreateRangeCircle(tower, placeholder, transparency)
	if tower:FindFirstChild("Config") then
		local range = tower.Config.Range.Value
		local towerAltLeg = tower:FindFirstChild("AltLeg")
		local height
		if towerAltLeg then
			height = ((tower.HumanoidRootPart.Size.Y / 2) + (towerAltLeg.Size.Y/2))
		else
			height = ((tower.HumanoidRootPart.Size.Y / 2) + (tower:FindFirstChild("Left Leg").Size.Y)/2)
		end
		local offset = CFrame.new(0, -height, 0)

		local p = Instance.new("Part")
		local clynderMesh = Instance.new("CylinderMesh")
		p.Name = "Range"
		p.Shape = Enum.PartType.Cylinder
		p.Material = Enum.Material.Neon
		p.Transparency = transparency or 0.8
		p.Color = Color3.new(1, 1, 1)
		p.Size = Vector3.new(0.05, range*2, range*2)
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BackSurface = Enum.SurfaceType.Smooth
		p.CanCollide = false
		p.CanQuery = false
		p.CastShadow = false
		p.CollisionGroup = "Tower"
		p.CFrame = tower.HumanoidRootPart.CFrame * offset * CFrame.Angles(0, 0, math.rad(90))
		
		local TowerParentValue = Instance.new("ObjectValue")
		TowerParentValue.Name = "TowerParent"
		TowerParentValue.Value = tower
		TowerParentValue.Parent = p
		
		if placeholder then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = p
			weld.Part1 = tower.HumanoidRootPart
			weld.Parent = p
			p.Massless = true
			p.Anchored = false
		else
			p.Anchored = true
		end
		p.Parent = workspace.Effects
	end
end

local function ShowErrorMessage(msg)
	ErrorFrame.Transparency = 0
	ErrorFrame.Message.Text = msg
	ErrorFrame.Visible = true
	local ErrorFrameTween = TweenService:Create(ErrorFrame, TweenInfo.new(0.5), {Transparency = 1})
	ErrorFrameTween:Play()
	ErrorFrameTween.Completed:Connect(function()
		if ErrorFrame.Transparency == 1 then
			ErrorFrame.Visible = false
			ErrorFrame.Transparency = 0
		end
	end)
end

local function RemovePlaceHolderTower()
	if towerToSpawn then
		local Range = workspace.Effects:FindFirstChild("Range")
		if Range then
			local rangeHighlight = player.PlayerGui.Highlights:FindFirstChild("RangeHighlight")
			if rangeHighlight then
				rangeHighlight:Destroy()
			end
			Range:Destroy()
		end
		for i, Beam in pairs(workspace.Towers:GetDescendants()) do
			if Beam:IsA("Beam") then
				local towerOfBeam = Beam:FindFirstAncestorOfClass("Model")
				if towerOfBeam and towerOfBeam.Parent == workspace.Towers and towerOfBeam:FindFirstChild("Config") then
					if towerOfBeam.Config:FindFirstChild("Owner") and towerOfBeam.Config.Owner.Value ~= tostring(player.UserId) then
						Beam.Transparency = NumberSequence.new(1)
					else
						Beam.Color = ColorSequence.new(Color3.new(0.0124971, 0.942809, 1))
						Beam.Brightness = 10
					end
					for i2, SquareBarrier in pairs(workspace.Effects:GetChildren()) do
						if SquareBarrier.Name == "SquareBarrier" and SquareBarrier:FindFirstChild("TowerParent") and SquareBarrier.TowerParent.Value == towerOfBeam then
							SquareBarrier.Transparency = 1
						end
					end
				end
			end
		end
		
		for i, Highlight in pairs(player.PlayerGui.Highlights:GetChildren()) do
			if Highlight.Adornee == towerToSpawn then
				Highlight:Destroy()
			end
		end
		towerToSpawn:Destroy()
		towerToSpawn = nil
		rotation = 0
		
		gui.Controls.Place.Visible = false
		gui.Controls.Visible = false
		touchingOtherSquareBarriers = 0
	end
end

local function ColorPlaceholderTower(color, beamBrightness)
	for i, Highlight in pairs(player.PlayerGui.Highlights:GetChildren()) do
		if Highlight.Adornee == towerToSpawn then
			Highlight.OutlineColor = color
		end
	end
	
	for i, v in pairs(towerToSpawn:GetDescendants()) do
		if v.Name == "SquareBarrier" then
			v.Color = color
		end
	end
end

local function toggleTowerInfo(doNotTween)
	gui.Selection.TowerSelection.TowerIcon:ClearAllChildren()
	secondSelectedTower = nil	
	
	if selectedTower and selectedTower.Parent then
		secondSelectedTower = selectedTower
		local Range = workspace.Effects:FindFirstChild("Range")
		if Range then
			local rangeHighlight = player.PlayerGui.Highlights:FindFirstChild("RangeHighlight")
			if rangeHighlight then
				rangeHighlight:Destroy()
			end
			Range:Destroy()
		end
		CreateRangeCircle(selectedTower)

		local humanoid = selectedTower:WaitForChild("Humanoid")
		local config = selectedTower.Config
		local TowerSelectionFrame = gui.Selection.TowerSelection
		
		TowerSelectionFrame.TitleAndStats.Owner.Text = "Owner: "..(game.Players:GetPlayerByUserId(config.Owner.Value).Name)
		
		if config.Owner.Value == tostring(player.UserId) then
			TowerSelectionFrame.ActionButtons.Upgrade.BackgroundColor3 = Color3.fromRGB(33, 255, 6)
			TowerSelectionFrame.ActionButtons.Sell.BackgroundColor3 = Color3.fromRGB(252, 1, 7)
			TowerSelectionFrame.ActionButtons.Target.BackgroundColor3 = Color3.fromRGB(102, 204, 255)
		else
			TowerSelectionFrame.ActionButtons.Upgrade.BackgroundColor3 = Color3.new(0.500008, 0.500008, 0.500008)
			TowerSelectionFrame.ActionButtons.Sell.BackgroundColor3 = Color3.new(0.500008, 0.500008, 0.500008)
			TowerSelectionFrame.ActionButtons.Target.BackgroundColor3 = Color3.new(0.500008, 0.500008, 0.500008)
		end
		
		local upgradeTower = config:FindFirstChild("Upgrade")
		if upgradeTower and upgradeTower.Value then
			TowerSelectionFrame.UpgradeStats.Settings.Damage.Text = "Damage: "..config.Damage.Value.." > "..upgradeTower.Value.Config.Damage.Value
			TowerSelectionFrame.UpgradeStats.Settings.Cooldown.Text = "Cooldown: "..config.Cooldown.Value.." > "..upgradeTower.Value.Config.Cooldown.Value
			TowerSelectionFrame.UpgradeStats.Settings.Range.Text = "Range: "..config.Range.Value.." > "..upgradeTower.Value.Config.Range.Value
			TowerSelectionFrame.ActionButtons.Upgrade.Text = "Upgrade: $"..(upgradeTower.Value.Config.Price.Value - upgradeTower.Value.Config.PreviousPrice.Value).." (E)"
		else
			TowerSelectionFrame.UpgradeStats.Settings.Damage.Text = "Damage: "..config.Damage.Value
			TowerSelectionFrame.UpgradeStats.Settings.Cooldown.Text = "Cooldown: "..config.Cooldown.Value
			TowerSelectionFrame.UpgradeStats.Settings.Range.Text = "Range: "..config.Range.Value
			gui.Selection.TowerSelection.ActionButtons.Target.Text = "Target: "..config.TargetMode.Value
			TowerSelectionFrame.ActionButtons.Upgrade.Text = "Upgrade: MAX"
		end
		TowerSelectionFrame.ActionButtons.Sell.Text = "Sell: $"..(math.round(config.Price.Value / 3)).." (Delete)"
		
		if config:FindFirstChild("UpgradeNumber") then
			TowerSelectionFrame.TitleAndStats.Title.Text = selectedTower.Humanoid.DisplayName.." (Upgrade: "..config.UpgradeNumber.Value..")"
		else
			TowerSelectionFrame.TitleAndStats.Title.Text = selectedTower.Humanoid.DisplayName.." (Upgrade: 0)"
		end
		
		local viewportModel = ReplicatedStorage.Towers:FindFirstChild(selectedTower.Name, true):Clone()
		local worldModelHolder = Instance.new("WorldModel")
		worldModelHolder.PrimaryPart = viewportModel.PrimaryPart
		for i, child in pairs(viewportModel:GetChildren()) do
			child.Parent = worldModelHolder
		end
		viewportModel:Destroy()
		viewportModel = worldModelHolder
		worldModelHolder = nil
		viewportModel.Parent = TowerSelectionFrame.TowerIcon
		
		ViewportGuiModule.CreateCamera(TowerSelectionFrame.TowerIcon, viewportModel, -50)
		ReplicatedStorage.Bindable.BindableEvents.AnimateModel:Fire(viewportModel, "Idle", "Tower")
		
		
		gui.Selection.Position = UDim2.new(1, 0, gui.Selection.Position.Y.Scale, 0)
		gui.Selection.Visible = true
		
		if config:FindFirstChild("Target") then
			local Highlight
			for i, choosenHighlight in pairs(player.PlayerGui.Highlights:GetChildren()) do
				if choosenHighlight:FindFirstChild("Owner") and choosenHighlight.Owner.Value == selectedTower then
					Highlight = choosenHighlight
				end
			end
			if Highlight then
				Highlight.Enabled = true
			else
				local target = config.Target.Value
				local oldTraget = target
				Highlight = Instance.new("Highlight")
				Highlight.Name = "TowerTargetOutlineHighlight"
				Highlight.Adornee = target
				Highlight.FillTransparency = 0.5
				Highlight.FillColor = Color3.new(1, 0.200717, 0.141924)
				Highlight.OutlineColor = Color3.new(1, 0.200717, 0.141924)
				Highlight.Parent = player.PlayerGui.Highlights

				local HighlightOwner = Instance.new("ObjectValue")
				HighlightOwner.Name = "Owner"
				HighlightOwner.Value = selectedTower
				HighlightOwner.Parent = Highlight

				config.Target.Changed:Connect(function(newTarget)
					Highlight.Adornee = newTarget
				end)
			end
		end
		
		if not doNotTween then
			local ShowGuiTween = TweenService:Create(gui.Selection, TweenInfo.new(0.3), {Position = UDim2.new(0.609, 0, gui.Selection.Position.Y.Scale, 0)})
			ShowGuiTween:Play()
		else
			gui.Selection.Position = UDim2.new(0.609, 0, gui.Selection.Position.Y.Scale, 0)
		end
	elseif not towerToSpawn then
		local Range = workspace.Effects:FindFirstChild("Range")
		if Range then
			local rangeHighlight = player.PlayerGui.Highlights:FindFirstChild("RangeHighlight")
			if rangeHighlight then
				rangeHighlight:Destroy()
			end
			Range:Destroy()
		end
		for i, Highlight in pairs(player.PlayerGui.Highlights:GetChildren()) do
			if Highlight.Name == "TowerTargetOutlineHighlight" then
				Highlight.Enabled = false
			end
		end
		selectedTower = nil
		gui.Selection.Visible = false
	end
end

local function AddPlaceHolderTower(name)
	local towerExists = TowersFolderInRS:FindFirstChild(name, true)

	if towerExists then
		selectedTower = nil
		toggleTowerInfo()
		RemovePlaceHolderTower()
		ReplicatedStorage.Remote.RemoteEvents.DevEnableMouseLock:FireServer(false)

		towerToSpawn = towerExists:Clone()
		towerToSpawn.Parent = workspace

		CreateRangeCircle(towerToSpawn, true)

		local ReturnedSquareBarrier = TowersBarrierModule.Create(towerToSpawn, false)
		
		for i, descendant in pairs(towerToSpawn:GetDescendants()) do
			if descendant:IsA("Beam") then
				descendant.Transparency = NumberSequence.new(0)
			elseif descendant:IsA("Part") or descendant:IsA("BasePart") or descendant:IsA("MeshPart") then
				descendant.CollisionGroup = "Tower"
			end
		end
		
		for i, Beam in pairs(workspace.Towers:GetDescendants()) do
			if Beam:IsA("Beam") then
				Beam.Transparency = NumberSequence.new(0)
				Beam.Brightness = 1
				Beam.Color = ColorSequence.new(Color3.new(1, 0.131823, 0.000335698))
			end
		end
		
		if ReturnedSquareBarrier then
			ReturnedSquareBarrier.Transparency = 0.7
			for i, SquareBarrier in pairs(workspace.Effects:GetChildren()) do
				if SquareBarrier.Name == "SquareBarrier" and SquareBarrier ~= ReturnedSquareBarrier then
					SquareBarrier.Transparency = 0.7
				end
			end
			
			ReturnedSquareBarrier.Touched:Connect(function(part)
				if part.Name == "SquareBarrier" and part.Parent == workspace.Effects then
					canPlace = false
					ColorPlaceholderTower(Color3.new(1, 0.18175, 0.140917), 1)
					touchingOtherSquareBarriers += 1
				end
			end)
			ReturnedSquareBarrier.TouchEnded:Connect(function(part)
				if part.Name == "SquareBarrier" and part.Parent == workspace.Effects and touchingOtherSquareBarriers > 0 then
					touchingOtherSquareBarriers -= 1
					if touchingOtherSquareBarriers == 0 then
						local blacklistTable = workspace.Effects:GetChildren()
						table.insert(blacklistTable, towerToSpawn)
						local result = MouseRaycast(blacklistTable)
						if result and result.Instance then
							if result.Instance:FindFirstAncestor("TowerArea") and touchingOtherSquareBarriers == 0 then
								canPlace = true
								ColorPlaceholderTower(Color3.new(0.0864271, 1, 0), 10)
							end
						end
					end
				end
			end)
		end
		
		if not UserInputService.MouseEnabled and not UserInputService.KeyboardEnabled then
			gui.Controls.Place.Visible = true

			local blacklistTable = workspace.Effects:GetChildren()
			table.insert(blacklistTable, towerToSpawn)
			local result = MouseRaycast(blacklistTable)

			if result and result.Instance then
				if towerToSpawn then
					table.insert(blacklistTable, player.Character)
					local result = MouseRaycast(blacklistTable)
					hoveredInstance = nil
					if result.Instance:FindFirstAncestor("TowerArea") and touchingOtherSquareBarriers == 0 then
						canPlace = true
						ColorPlaceholderTower(Color3.new(0.0864271, 1, 0), 10)
					else
						canPlace = false
						ColorPlaceholderTower(Color3.new(1, 0.18175, 0.140917), 1)
					end
					local x = result.Position.X
					local y = result.Position.Y + towerToSpawn["Left Leg"].Size.Y + (towerToSpawn.PrimaryPart.Size.Y / 2)
					local z = result.Position.Z

					local cframe = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(rotation), 0)

					if not towerToSpawn.PrimaryPart then
						towerToSpawn.HumanoidRootPart = towerToSpawn.PrimaryPart
					end
					towerToSpawn:SetPrimaryPartCFrame(cframe)
				end
			end
		end

		gui.Controls.Visible = true
	end
end

local function SpawnNewTower()
	local RequestTower = ReplicatedStorage.Remote.RemoteFunctions.RequestTower:InvokeServer(towerToSpawn.Name)
	if RequestTower == true and ReplicatedStorage.Towers[towerToSpawn.Name].Config.Limit.Value > 0 then
		local placeHolder =  ReplicatedStorage.Remote.RemoteFunctions.SpawnTower:InvokeServer(towerToSpawn.Name, towerToSpawn.PrimaryPart.CFrame)
		if placeHolder and placeHolder:IsA("Model") then
			RemovePlaceHolderTower()

			for i, descendant in pairs(placeHolder:GetDescendants()) do
				if descendant:IsA("Beam") then
					descendant.Transparency = NumberSequence.new(0)
				end
			end

			selectedTower = placeHolder
			toggleTowerInfo()
		elseif placeHolder then
			if placeHolder == "In Other Tower Radius" then
				ShowErrorMessage("⚠️ Tower In Other Tower's Radius ⚠️")
			elseif placeHolder == "Tower Does Not Exist" then
				ShowErrorMessage("⚠️ Tower Does Not Exist ⚠️")
			else
				ShowErrorMessage("⚠️ "..placeHolder.." ⚠️")
			end
		end
	elseif RequestTower ~= false then
		ShowErrorMessage("⚠️ "..RequestTower.." ⚠️")
	end
end

gui.Controls.Rotate.Frame.TextButton.Activated:Connect(function()
	rotation += 90
end)

gui.Controls.Place.Frame.TextButton.Activated:Connect(function()
	if towerToSpawn and canPlace then
		SpawnNewTower()
	end
end)

gui.Controls.Cancel.Frame.TextButton.Activated:Connect(RemovePlaceHolderTower)

gui.Selection.TowerSelection.ActionButtons.Target.Activated:Connect(function()
	if selectedTower and selectedTower:FindFirstChild("Humanoid") then
		local modeChangeSuccess = ReplicatedStorage.Remote.RemoteFunctions.ChangeTowerMode:InvokeServer(selectedTower)
		if modeChangeSuccess then
			toggleTowerInfo()
		end
	end
end)

local function UpgradeSelectedTower()
	if selectedTower and selectedTower:FindFirstChild("Humanoid") and selectedTower:FindFirstChild("Config") and selectedTower.Config:FindFirstChild("Upgrade") then
		local upgradeTower = selectedTower.Config.Upgrade.Value
		if upgradeTower then
			local allowedToUpgrade = ReplicatedStorage.Remote.RemoteFunctions.RequestTower:InvokeServer(upgradeTower.Name, selectedTower)

			if allowedToUpgrade then
				for i, effect in pairs(workspace.Effects:GetChildren()) do
					if effect.Name == "SquareBarrier" then
						if effect:FindFirstChild("TowerParent") and effect.TowerParent.Value == selectedTower then
							effect:Destroy()
						end
					elseif effect.Name == "Range" then
						effect:Destroy()
						local rangeHighlight = player.PlayerGui.Highlights:FindFirstChild("RangeHighlight")
						if rangeHighlight then
							rangeHighlight:Destroy()
						end
					end
				end
				for i, Highlight in pairs(player.PlayerGui.Highlights:GetChildren()) do
					if Highlight.Name == "TowerTargetOutlineHighlight" and Highlight:FindFirstChild("Owner") and Highlight.Owner.Value == selectedTower then
						Highlight:Destroy()
					end
				end
				pcall(function()
					local newSelectedTower = ReplicatedStorage.Remote.RemoteFunctions.SpawnTower:InvokeServer(upgradeTower.Name, selectedTower.PrimaryPart.CFrame, selectedTower)
					if newSelectedTower and newSelectedTower.Humanoid then
						selectedTower = newSelectedTower
						for i, descendant in pairs(selectedTower:GetDescendants()) do
							if descendant:IsA("Beam") then
								descendant.Transparency = NumberSequence.new(0)
							end
						end
					else
						if newSelectedTower then
							ShowErrorMessage("⚠️ "..newSelectedTower.." ⚠️")
						end
					end
				end)
				toggleTowerInfo(true)
				task.wait(0.1)
				if towerToSpawn then
					for i, Beam in pairs(workspace.Towers:GetDescendants()) do
						if Beam.Name == "SquareBarrier" then
							if Beam.Parent and Beam.Parent:FindFirstChild("Owner") and Beam.Parent.Owner.Value == selectedTower then
								Beam.Transparency = NumberSequence.new(0)
							end
						end
					end
				end
			end
		end
	end
end

gui.Selection.TowerSelection.ActionButtons.Upgrade.Activated:Connect(function()
	UpgradeSelectedTower()
end)

local function SellSelectedTower()
	if selectedTower and selectedTower:FindFirstChild("Humanoid") then
		for i, effect in pairs(workspace.Effects:GetChildren()) do
			if effect.Name == "SquareBarrier" then
				if effect:FindFirstChild("TowerParent") and effect.TowerParent.Value == selectedTower then
					effect:Destroy()
				end
			elseif effect.Name == "Range" then
				effect:Destroy()
				local rangeHighlight = player.PlayerGui.Highlights:FindFirstChild("RangeHighlight")
				if rangeHighlight then
					rangeHighlight:Destroy()
				end
			end
		end
		for i, Highlight in  pairs(player.PlayerGui.Highlights:GetChildren()) do
			if Highlight.Name == "TowerTargetOutlineHighligh" and Highlight:FindFirstChild("Owner") and Highlight.Owner.Value == selectedTower then
				Highlight:Destroy()
			end
		end
		local soldTower = ReplicatedStorage.Remote.RemoteFunctions.SellTower:InvokeServer(selectedTower)
		if soldTower then
			selectedTower = nil
			toggleTowerInfo()
		else
			CreateRangeCircle(selectedTower)
			TowersBarrierModule.SquareBarrier(selectedTower, true, selectedTower.TowersBarrier, selectedTower.TowersBarrier.Attachment1, selectedTower.TowersBarrier.Attachment2)
		end
	end
end

gui.Selection.TowerSelection.ActionButtons.Sell.Activated:Connect(function()
	SellSelectedTower()
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	
	if towerToSpawn then
		if input.UserInputType == Enum.UserInputType.MouseButton1 and canPlace then
			SpawnNewTower()
		elseif input.UserInputType == Enum.UserInputType.Touch and canPlace then
			local timeSinceLastTouch = tick() - lastTouch
			if timeSinceLastTouch <= 0.25 then
				SpawnNewTower()
			end
			lastTouch = tick()
		elseif input.KeyCode == Enum.KeyCode.R then
			rotation += 90
		elseif (input.KeyCode == Enum.KeyCode.Q) and towerToSpawn then
			RemovePlaceHolderTower()
		end
	elseif hoveredInstance then
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local model = hoveredInstance:FindFirstAncestorOfClass("Model")

			if model and model.Parent == workspace.Towers then
				selectedTower = model
			else
				selectedTower = nil
			end

			toggleTowerInfo()
		elseif selectedTower then
			if input.KeyCode == Enum.KeyCode.E then
				UpgradeSelectedTower()
			elseif input.KeyCode == Enum.KeyCode.Backspace then
				SellSelectedTower()
			end
		end
	end
end)

UserInputService.TouchTap:Connect(function(touchPositions, processed)
	if processed then
		return
	end

	if not UserInputService.MouseEnabled and not UserInputService.KeyboardEnabled then
		local blacklistTable = workspace.Effects:GetChildren()
		table.insert(blacklistTable, towerToSpawn)
		
		for i, SquareBarrier in pairs(workspace.Effects:GetChildren()) do
			if SquareBarrier.Name == "SquareBarrier" then
				table.insert(blacklistTable, SquareBarrier)
			end
		end
		
		local result = MouseRaycast(blacklistTable)

		if result and result.Instance then
			if towerToSpawn then
				table.insert(blacklistTable, player.Character)
				local result = MouseRaycast(blacklistTable)
				hoveredInstance = nil
				if result and result.Instance then
					if result.Instance:FindFirstAncestor("TowerArea") and touchingOtherSquareBarriers == 0 then
						canPlace = true
						ColorPlaceholderTower(Color3.new(0.0864271, 1, 0), 10)
					else
						canPlace = false
						ColorPlaceholderTower(Color3.new(1, 0.18175, 0.140917), 1)
					end
					local x = result.Position.X
					local y = result.Position.Y + towerToSpawn["Left Leg"].Size.Y + (towerToSpawn.PrimaryPart.Size.Y / 2)
					local z = result.Position.Z

					local cframe = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(rotation), 0)

					if not towerToSpawn.PrimaryPart then
						towerToSpawn.PrimaryPart = towerToSpawn.HumanoidRootPart
					end
					towerToSpawn:SetPrimaryPartCFrame(cframe)
				end
			end
		end
		
		local model = nil
		local GuisMouseOn = player.PlayerGui:GetGuiObjectsAtPosition(touchPositions[1].X, touchPositions[1].Y)
		
		if not table.find(GuisMouseOn, EquippedTowersFrame) then
			if hoveredInstance then
				model = hoveredInstance:FindFirstAncestorOfClass("Model")
			end

			if model and model.Parent == workspace.Towers then
				if selectedTower ~= model then
					selectedTower = model
					toggleTowerInfo()
				end
			else
				selectedTower = nil
				toggleTowerInfo()
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	for i, child in pairs(workspace.Effects:GetChildren()) do
		if child.Name == "Range" and (not towerToSpawn) then
			if child.TowerParent.Value ~= secondSelectedTower then
				child:Destroy()
			end
		end
	end
	
	local blacklistTable = workspace.Effects:GetChildren()
	table.insert(blacklistTable, towerToSpawn)
	local result = MouseRaycast(blacklistTable)
	if result and result.Instance then
		if towerToSpawn then
			if UserInputService.MouseEnabled and UserInputService.KeyboardEnabled then
				table.insert(blacklistTable, player.Character)
				
				for i, SquareBarrier in pairs(workspace.Effects:GetChildren()) do
					if SquareBarrier.Name == "SquareBarrier" then
						table.insert(blacklistTable, SquareBarrier)
					end
				end
				
				local result = MouseRaycast(blacklistTable)
				hoveredInstance = nil
				if result and result.Instance then
					if result.Instance:FindFirstAncestor("TowerArea") and touchingOtherSquareBarriers == 0 then
						canPlace = true
						ColorPlaceholderTower(Color3.new(0.0864271, 1, 0), 10)
					else
						canPlace = false
						ColorPlaceholderTower(Color3.new(1, 0.18175, 0.140917), 1)
					end
					local x = result.Position.X
					local y = result.Position.Y + towerToSpawn["Left Leg"].Size.Y + (towerToSpawn.PrimaryPart.Size.Y / 2)
					local z = result.Position.Z

					local cframe = CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(rotation), 0)

					if not towerToSpawn.PrimaryPart then
						towerToSpawn.PrimaryPart = towerToSpawn.HumanoidRootPart
					end
					towerToSpawn:SetPrimaryPartCFrame(cframe)
				end
			end
		else
			hoveredInstance = result.Instance
			local result = MouseRaycast(workspace.Effects:GetChildren())
			if result and result.Instance then
				local model = result.Instance:FindFirstAncestorOfClass("Model")
				if model and model.Parent == workspace.Mobs then
					for i2, HealthGui in pairs(player.PlayerGui.Billboards:GetChildren()) do
						if HealthGui.Adornee == model.Head then
							HealthGui.Enabled = true
						elseif HealthGui.Adornee and HealthGui.Adornee:IsDescendantOf(workspace.Mobs) then
							HealthGui.Enabled = false
						end
					end
				elseif UserInputService.MouseEnabled then
					if result.Instance:IsDescendantOf(workspace.Towers) then
						local model = result.Instance:FindFirstAncestorOfClass("Model")
						if model ~= selectedTower then
							CreateRangeCircle(model, false, 0.96)
						end
					end
					for i, HealthGui in pairs(player.PlayerGui.Billboards:GetChildren()) do
						if HealthGui.Adornee and HealthGui.Adornee.Parent and HealthGui.Adornee.Parent.Name ~= "Base" then
							HealthGui.Enabled = false
						end
					end
				end
			end
		end
	else
		hoveredInstance = nil
	end
	
	local result = MouseRaycast(workspace.Effects:GetChildren())
	if result and result.Instance then
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		
		if model and (model.Parent == workspace.Towers or model.Parent == workspace.Mobs) then
			for i, child in pairs(model.Parent:GetChildren()) do
				if child == model then
					local CreateNewHighlight = true
					for i2, Highlight in pairs(player.PlayerGui.Highlights:GetChildren()) do
						if Highlight.Adornee == child then
							CreateNewHighlight = false
						end
					end

					if CreateNewHighlight == true then
						if child.Parent == workspace.Towers then
							if child.Config.Owner.Value == tostring(player.UserId) then
								local towerHighlight = Instance.new("Highlight")
								towerHighlight.Name = "TowerOutlineHighlight"
								towerHighlight.Parent = player.PlayerGui.Highlights
								towerHighlight.FillTransparency = 0.8
								towerHighlight.OutlineColor = Color3.new(0.0124971, 0.942809, 1)
								towerHighlight.FillColor = Color3.new(0.0124971, 0.942809, 1)
								towerHighlight.Adornee = child
							else
								local towerHighlight = Instance.new("Highlight")
								towerHighlight.Name = "TowerOutlineHighlight"
								towerHighlight.Parent = player.PlayerGui.Highlights
								towerHighlight.FillTransparency = 0.6
								towerHighlight.OutlineColor = Color3.new(255, 255, 255)
								towerHighlight.FillColor = Color3.new(255, 255, 255)
								towerHighlight.Adornee = child
							end
						elseif child.Parent == workspace.Mobs then
							local mobHighlight = Instance.new("Highlight")
							mobHighlight.Name = "TowerOutlineHighlight"
							mobHighlight.Parent = player.PlayerGui.Highlights
							mobHighlight.FillTransparency = 0.5
							mobHighlight.OutlineColor = Color3.new(1, 0.200717, 0.141924)
							mobHighlight.FillColor = Color3.new(1, 0.200717, 0.141924)
							mobHighlight.Adornee = child
						end
					end
				else
					for i2, Highlight in pairs(player.PlayerGui.Highlights:GetChildren()) do
						if Highlight.Name == "TowerOutlineHighlight" and Highlight.Adornee == child then
							Highlight:Destroy()
						end
					end
				end
			end
		else
			for i2, Highlight in pairs(player.PlayerGui.Highlights:GetChildren()) do
				if Highlight.Name == "TowerOutlineHighlight" and Highlight.Adornee and (Highlight.Adornee:IsDescendantOf(workspace.Towers) or Highlight.Adornee:IsDescendantOf(workspace.Mobs)) then
					Highlight:Destroy()
				end
			end
		end
	end
end)

ReplicatedStorage.Bindable.BindableEvents.SendTowerIcon.Event:Connect(function(TowerIcon)
	UserInputService.InputBegan:Connect(function(input, gameProccessed)
		if gameProccessed then
			return
		end
		
		if tostring((input.KeyCode.Value) - 48) == TowerIcon.Name then
			for i, TextButton in pairs(TowerIcon:GetChildren()) do
				if TextButton:IsA("TextButton") and TextButton.Name ~= "TowerIcon" then
					for i, towers in pairs(TowersFolderInRS:GetDescendants()) do
						if towers.Name == TextButton.Name then
							RemovePlaceHolderTower()
							AddPlaceHolderTower(TextButton.Name)
						end
					end
				end
			end
		end
	end)
	
	for i, TextButton in pairs(TowerIcon:GetChildren()) do
		if TextButton:IsA("TextButton") then
			if TextButton.Name ~= "TowerIcon" then
				TowerIcon.Cost.Visible = true
				TowerIcon.Cost.Text = "$"..ReplicatedStorage.Towers:FindFirstChild(TextButton.Name, true).Config.Price.Value
			end
			TextButton.Activated:Connect(function()
				if not towerToSpawn then
					if TextButton.Name ~= "TowerIcon" then
						for i, towers in pairs(TowersFolderInRS:GetDescendants()) do
							if towers.Name == TextButton.Name then
								AddPlaceHolderTower(TextButton.Name)
							end
						end
					end
				else
					RemovePlaceHolderTower()
				end
			end)
		end
	end
end)

local function DisplayEndScreen(status)
	local screen = gui.EndScreen
	local ChooseButton = screen.LobbyFrameFrame.MapsFrame.ChooseButtonFrame.LeaveButton

	local LeavingColor = nil
	local LeavingMapText = ""
	
	if status == "Victory" then
		screen.Victory:Play()
		LeavingColor = Color3.new(0.131304, 0.999695, 0.0235904)
		LeavingMapText = workspace.Map:FindFirstChildOfClass("Model").NextMap.Value
		screen.LobbyFrameFrame.Title.Text = "End Screen: You Won!"
	elseif status == "Game Over" then
		LeavingColor = Color3.new(0.986252, 0.00723278, 0.0274205)
		LeavingMapText = "Locked"
		screen.LobbyFrameFrame.Title.Text = "End Screen: Game Over..."
	end
	
	local rewards = ReplicatedStorage.Remote.RemoteFunctions.GetPlayerMapRewards:InvokeServer()
	for rewardName, value in pairs(rewards) do
		if rewardName == "Coins" then
			screen.LobbyFrameFrame.MapsFrame.MapsChooseFrame.MapSection2.RewardsFrame.CoinsFrame.CoinsEarned.Text = value
		end
	end
	
	screen.BackgroundColor3 = LeavingColor
	screen.LobbyFrameFrame.MapsFrame.ChooseButtonFrame.LeaveButton.BackgroundColor3 = LeavingColor
	screen.LobbyFrameFrame.MapsFrame.ChooseButtonFrame.LeaveButton.Title.TextColor3 = LeavingColor
	screen.LobbyFrameFrame.MapsFrame.MapsChooseFrame.MapSection1.NextMap.Text = "Next Map: "..LeavingMapText
	screen.Visible = true
	screen.Size = UDim2.new(0, 0, 0, 0)

	local tweenStyle = TweenInfo.new(2, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0)
	local zoomTween = TweenService:Create(screen, tweenStyle, {Size = UDim2.new(0.6, 0,0.6, 0)})
	zoomTween:Play()
	
	local clicked
	clicked = ChooseButton.Activated:Connect(function()
		clicked:Disconnect()
		ReplicatedStorage.Remote.RemoteEvents.ExitGame:FireServer()
		ChooseButton.BackgroundColor3 = Color3.new(0.501961, 0.00155642, 0.998505)
		ChooseButton.Title.TextColor3 = Color3.new(0.501961, 0.00155642, 0.998505)
		ChooseButton.Title.Text = "Teleporting"
		wait(2)
		if not game:GetService("RunService"):IsStudio() then
			ReplicatedStorage.Remote.RemoteEvents.ExitGame:FireServer()
		else
			game.Players.LocalPlayer:Kick("\nYou Are In Studio...")
		end
	end)

	ChooseButton.MouseEnter:Connect(function()
		if ChooseButton.Size ~= UDim2.new(0.3, 5, 0.156, 5) then
			ChooseButton.Size = UDim2.new(0.3, 5, 1, 5)
		end
	end)

	ChooseButton.MouseLeave:Connect(function()
		if ChooseButton.Size ~= UDim2.new(0.3, 0, 0.156, 0) then
			ChooseButton.Size = UDim2.new(0.3, 0, 1, 0)
		end
	end)
end

local function SetupGameGui(gameRunning)
	if gameRunning ~= true then
		local map = workspace.Map:FindFirstChildOfClass("Model")
		if map then
			HealthModule.Setup(map:WaitForChild("Base"), {screenGui = InfoHealthFrame})
			coroutine.wrap(PathArrowsModule.LoopArrows)(map)
		else
			workspace.Map.ChildAdded:Connect(function(newMap)
				HealthModule.Setup(newMap:WaitForChild("Base"), {screenGui = InfoHealthFrame})
				coroutine.wrap(PathArrowsModule.LoopArrows)(newMap)
			end)
		end

		workspace.Mobs.ChildAdded:Connect(function(mob)
			if mob:IsA("Model") then
				HealthModule.Setup(mob)
			end
		end)
		info.Wave.Changed:Connect(function(change)
			InfoStatsFrame.Wave.Text = change
		end)
		info.Time.Changed:Connect(function(change)
			if tonumber(change) then
				change = tonumber(change)
				local originalChange = change
				local Minutes = (change - change%60)/60
				change = change - Minutes*60
				local Hours = (Minutes - Minutes%60)/60
				Minutes = Minutes - Hours*60
				if originalChange > 3600 then
					InfoStatsFrame.Timer.Text = "⏱️ "..string.format("%01i", Hours)..":"..string.format("%01i", Minutes)..":"..string.format("%02i", change)
				elseif originalChange > 60 then
					InfoStatsFrame.Timer.Text = "⏱️ "..string.format("%01i", Minutes)..":"..string.format("%02i", change)
				else
					InfoStatsFrame.Timer.Text = "⏱️ 0:"..string.format("%02i", change)
				end
			else
				InfoStatsFrame.Timer.Text = "⏱️ ".. change
			end
		end)
		playerCashValue.Changed:Connect(function(change)
			local abPlayerCash = tostring(math.floor(change))
			abPlayerCash = string.sub(abPlayerCash, 1, ((#abPlayerCash - 1) % 3) + 1)..({"", "K", "M", "B", "T", "QA", "QI", "SX", "SP", "OC", "NO", "DC", "UD", "DD", "TD", "QAD", "QID", "SXD", "SPD", "OCD", "NOD", "VG", "UVG"})[math.floor((#abPlayerCash - 1) / 3) + 1]
			if change < 0 then
				PlayerCashFrame.CashLabel.Text = "Cash: -$"..abPlayerCash
			else
				PlayerCashFrame.CashLabel.Text = "Cash: $"..abPlayerCash
			end
			local EarnedCashLabel = PlayerEarnedCashFrame.Template:Clone()

			if change < PlayerEarnedCashFrame.CashBefore.Value then
				EarnedCashLabel.Text = "-$"..(PlayerEarnedCashFrame.CashBefore.Value - change)
				EarnedCashLabel.TextColor3 = Color3.new(1, 0.131823, 0.000335698)
			else
				EarnedCashLabel.Text = "+$"..(change - PlayerEarnedCashFrame.CashBefore.Value)
			end

			EarnedCashLabel.Visible = true
			EarnedCashLabel.Parent = PlayerEarnedCashFrame
			EarnedCashLabel.LocalScript.Disabled = false
			PlayerEarnedCashFrame.CashBefore.Value = change
		end)

		for i, mob in pairs(workspace.Mobs:GetDescendants()) do
			if mob:IsA("Model") and mob:FindFirstChild("Humanoid") then
				ReplicatedStorage.Bindable.BindableEvents.AnimateModel:Fire(mob, "Walk")
				HealthModule.Setup(mob)
			end
		end

		for i, tower in pairs(workspace.Towers:GetChildren()) do
			if tower:IsA("Model") and ReplicatedStorage.Towers:FindFirstChild(tower.Name, true) then
				ReplicatedStorage.Bindable.BindableEvents.AnimateModel:Fire(tower, "Idle", "Tower")
			end
		end

		if tonumber(info.Time.Value) then
			local change = tonumber(info.Time.Value)
			local Minutes = (change - change%60)/60
			change = change - Minutes*60
			local Hours = (Minutes - Minutes%60)/60
			Minutes = Minutes - Hours*60
			if change > 3600 then
				InfoStatsFrame.Timer.Text = "⏱️ "..string.format("%01i", Hours)..":"..string.format("%01i", Minutes)..":"..string.format("%02i", change)
			elseif change > 60 then
				InfoStatsFrame.Timer.Text = "⏱️ "..string.format("%01i", Minutes)..":"..string.format("%02i", change)
			else
				InfoStatsFrame.Timer.Text = "⏱️ 0:"..string.format("%02i", change)
			end
		else
			InfoStatsFrame.Timer.Text = "⏱️ "..info.Time.Value
		end
	end
end

local function LoadGui()
	info.Message.Changed:Connect(function(change)
		if change == "Victory" or change == "Game Over" then
			DisplayEndScreen(change)
		end
	end)
	
	SetupGameGui()
	
	info.GameRunning.Changed:Connect(SetupGameGui)
end

local function SetupSkipWaveGui()
	local StartWaveFrameGui = gui.StartWaveFrame
	StartWaveFrameGui.Yes.Title.Text = "Start"
	StartWaveFrameGui.No.Title.Text = "Wait"

	StartWaveFrameGui.Yes.Activated:Connect(function()
		StartWaveFrameGui.Yes.Visible = false
		StartWaveFrameGui.No.Visible = false
		if gameStarted == false then
			ReplicatedStorage.Remote.RemoteEvents.PlayerVotedToSkipWave:FireServer("Start Game", "Skip")
		else
			ReplicatedStorage.Remote.RemoteEvents.PlayerVotedToSkipWave:FireServer("Wave Skip", "Skip")
		end
	end)
	StartWaveFrameGui.No.Activated:Connect(function()
		StartWaveFrameGui.Yes.Visible = false
		StartWaveFrameGui.No.Visible = false
		if gameStarted == false then
			ReplicatedStorage.Remote.RemoteEvents.PlayerVotedToSkipWave:FireServer("Start Game", "Continue")
		else
			ReplicatedStorage.Remote.RemoteEvents.PlayerVotedToSkipWave:FireServer("Wave Skip", "Continue")
		end
	end)

	ReplicatedStorage.Remote.RemoteEvents.ShowSkipWaveFrame.OnClientEvent:Connect(function(playersThatWantToSkipEvent, canShowSkipEventFrame)
		if gameStarted == false then
			StartWaveFrameGui.VoteToSkip.Text = "Start Game: ("..playersThatWantToSkipEvent.."/"..game.Players.NumPlayers..")"
		else
			StartWaveFrameGui.VoteToSkip.Text = "Skip Wave: ("..playersThatWantToSkipEvent.."/"..game.Players.NumPlayers..")"
		end

		StartWaveFrameGui.Yes.Visible = true
		StartWaveFrameGui.No.Visible = true
		
		if StartWaveFrameGui.Visible == false and canShowSkipEventFrame then
			StartWaveFrameGui.Position = UDim2.new(0.5, 0, 0, 0)
			StartWaveFrameGui.Visible = true
			local newTween = TweenService:Create(StartWaveFrameGui, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0), {Position = UDim2.new(0.5, 0,0.133, 0)})
			newTween:Play()
		end
	end)

	ReplicatedStorage.Remote.RemoteEvents.PlayerVotedToSkipWave.OnClientEvent:Connect(function(playersThatWantToSkipEvent)
		if gameStarted == false then
			StartWaveFrameGui.VoteToSkip.Text = "Start Game: ("..playersThatWantToSkipEvent.."/"..game.Players.NumPlayers..")"
		else
			StartWaveFrameGui.VoteToSkip.Text = "Skip Wave: ("..playersThatWantToSkipEvent.."/"..game.Players.NumPlayers..")"
		end
		if playersThatWantToSkipEvent == #game.Players:GetPlayers() then
			StartWaveFrameGui.Visible = false
		end
	end)

	ReplicatedStorage.Remote.RemoteEvents.RemoveSkipEventGui.OnClientEvent:Connect(function()
			if gameStarted == false then
				gameStarted = true
				StartWaveFrameGui.Yes.Title.Text = "Skip"
				StartWaveFrameGui.No.Title.Text = "Continue"
			end
		StartWaveFrameGui.Visible = false
	end)
end

LoadGui()
SetupSkipWaveGui()
