writefile("PLEAD.mp3", game:HttpGet("https://github.com/ian49972/smth/raw/refs/heads/main/PLEAD.mp3"))

local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local head = character:WaitForChild("Head")

-- Record original position
local originalPivot = character:GetPivot()

-- Set to night time
Lighting.TimeOfDay = "00:00:00"

-- Face system setup
local faceDecal = head:FindFirstChildOfClass("Decal") or Instance.new("Decal", head)
faceDecal.Name = "FaceDecal"
faceDecal.Texture = "http://www.roblox.com/asset/?id=126025407205354" -- Neutral face
local faceStates = {
	Neutral = "http://www.roblox.com/asset/?id=126025407205354",
	Hurt = "http://www.roblox.com/asset/?id=77826599197600",
	Injured = "http://www.roblox.com/asset/?id=77826599197600",
	Dead = "http://www.roblox.com/asset/?id=89760806612988"
}
local lastHitTimeForFace = 0
local hurtFaceDuration = 2 -- Seconds to show Hurt face

-- Load random map
local mapIds = {128853636451228, 81453459261707, 115147376541455, 113945634909660, 88149930290101}
local randomId = mapIds[math.random(1, #mapIds)]
local map = game:GetObjects("rbxassetid://" .. randomId)[1]
map.Parent = workspace

-- Function to get model bounds
local function getModelBounds(model)
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local cf = part.CFrame
			local size = part.Size / 2
			for i = -1, 1, 2 do
				for j = -1, 1, 2 do
					for k = -1, 1, 2 do
						local corner = cf * Vector3.new(i * size.X, j * size.Y, k * size.Z)
						minV = Vector3.new(math.min(minV.X, corner.X), math.min(minV.Y, corner.Y), minV.Z)
						maxV = Vector3.new(math.max(maxV.X, corner.X), math.max(maxV.Y, corner.Y), maxV.Z)
					end
				end
			end
		end
	end
	return minV, maxV
end

-- Safe spawn function
local function safePlayerSpawn(map, character, humanoid, ignoreList)
	if not map or not map.Parent then
		warn("safePlayerSpawn: map is nil or not parented")
		return false
	end
	ignoreList = ignoreList or {character}
	local parts = map:GetDescendants()
	local candidates = {}
	for _, v in ipairs(parts) do
		if v and v:IsA("BasePart") and v.CanCollide and v.Size.Magnitude > 2 and not v:IsDescendantOf(character) then
			table.insert(candidates, v)
		end
	end
	if #candidates == 0 then
		local prim = map.PrimaryPart or map:FindFirstChildWhichIsA("BasePart")
		if prim then table.insert(candidates, prim) end
	end
	if #candidates == 0 then
		warn("safePlayerSpawn: no candidate parts found in map")
		return false
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = ignoreList

	for attempt = 1, 30 do
		local part = candidates[math.random(1, #candidates)]
		if part and part:IsA("BasePart") then
			local origin = part.Position + Vector3.new(0, 50, 0)
			local res = workspace:Raycast(origin, Vector3.new(0, -500, 0), params)
			if res and res.Position and res.Instance and res.Instance:IsDescendantOf(map) then
				if res.Normal and res.Normal.Y >= 0.7 then
					local footPos = res.Position + Vector3.new(0, humanoid.HipHeight + 0.1, 0)
					local upCheck = workspace:Raycast(footPos, Vector3.new(0, 2.5, 0), params)
					if not (upCheck and upCheck.Instance and upCheck.Instance:IsDescendantOf(map)) then
						local safeCFrame = CFrame.new(res.Position + Vector3.new(0, humanoid.HipHeight + 0.1, 0))
						task.spawn(function()
							if character and character.PrimaryPart then
								pcall(function() character:PivotTo(safeCFrame) end)
							else
								local hrp = character:FindFirstChild("HumanoidRootPart")
								if hrp then pcall(function() hrp.CFrame = safeCFrame end) end
							end
						end)
						return true
					end
				end
			end
		end
		task.wait(0.01)
	end

	local minV, maxV = getModelBounds(map)
	local cx = (minV.X + maxV.X) / 2
	local cz = (minV.Z + maxV.Z) / 2
	for y = maxV.Y + 50, minV.Y - 50, -10 do
		local origin = Vector3.new(cx, y, cz)
		local res = workspace:Raycast(origin, Vector3.new(0, -300, 0), params)
		if res and res.Instance and res.Instance:IsDescendantOf(map) and res.Normal and res.Normal.Y >= 0.7 then
			local safeCFrame = CFrame.new(res.Position + Vector3.new(0, humanoid.HipHeight + 0.1, 0))
			task.spawn(function()
				pcall(function() character:PivotTo(safeCFrame) end)
			end)
			return true
		end
		task.wait(0.01)
	end

	local fallbackPart = map.PrimaryPart or map:FindFirstChildWhichIsA("BasePart")
	if fallbackPart then
		local pos = fallbackPart.Position + Vector3.new(0, 10 + humanoid.HipHeight, 0)
		task.spawn(function() pcall(function() character:PivotTo(CFrame.new(pos)) end) end)
		return true
	end

	warn("safePlayerSpawn: all methods failed")
	return false
end

-- Teleport player
task.spawn(function()
	safePlayerSpawn(map, character, humanoid, {character})
end)

-- Play sound
local sound = Instance.new("Sound")
sound.SoundId = getcustomasset("PLEAD.mp3")
sound.Volume = 1
sound.Parent = workspace
sound.Looped = false
sound:Play()

-- Remove default Animator
local animator = humanoid:FindFirstChildOfClass("Animator")
if animator then animator:Destroy() end

-- Load Survivor rig for player animations
local survivorModel = game:GetObjects("rbxassetid://102046170699445")[1]
survivorModel.Parent = workspace
survivorModel:PivotTo(character:GetPivot())
local survivorRig = survivorModel:WaitForChild("RigSurvivor")
local animFolder = survivorRig:WaitForChild("AnimSaves")

local safeFolder = Instance.new("Folder")
safeFolder.Name = "SafeSurvivorKF"
safeFolder.Parent = player:WaitForChild("PlayerGui")

local KF = {}
for _, name in pairs({"survidle", "survwalk", "survrun", "survinjuredidle", "survinjuredwalk", "survinjuredrun"}) do
	local kf = animFolder:FindFirstChild(name)
	if kf and kf:IsA("KeyframeSequence") then
		KF[name] = kf:Clone()
		KF[name].Parent = safeFolder
	else
		warn("Missing or invalid Survivor animation: " .. name)
	end
end
survivorModel:Destroy()

-- Load CoolKid animations
local coolKidModel = game:GetObjects("rbxassetid://102046170699445")[1]
coolKidModel.Parent = workspace
local coolKidRig = coolKidModel:WaitForChild("RigCOOLKID")
local coolKidAnimFolder = coolKidRig:WaitForChild("AnimSaves")

local coolKidKF = {}
for _, name in pairs({"walk", "run", "attack", "kill007", "kill007victim"}) do
	local kf = coolKidAnimFolder:FindFirstChild(name)
	if kf and kf:IsA("KeyframeSequence") then
		coolKidKF[name] = kf:Clone()
		local keyframes = kf:GetKeyframes()
		if #keyframes > 0 then
			warn("Loaded animation " .. name .. " with " .. #keyframes .. " keyframes, duration: " .. keyframes[#keyframes].Time)
		else
			warn("Animation " .. name .. " has no keyframes")
		end
	else
		warn("Missing or invalid CoolKid animation: " .. name)
	end
end
coolKidModel:Destroy()

-- Animation cache and style mappings
local animationCache = {}
local tStyle = {
	[Enum.PoseEasingStyle.Linear] = Enum.EasingStyle.Linear,
	[Enum.PoseEasingStyle.Bounce] = Enum.EasingStyle.Bounce,
	[Enum.PoseEasingStyle.Cubic] = Enum.EasingStyle.Cubic,
	[Enum.PoseEasingStyle.Elastic] = Enum.EasingStyle.Elastic,
	[Enum.PoseEasingStyle.Constant] = Enum.EasingStyle.Linear,
}
local tDirection = {
	[Enum.PoseEasingDirection.In] = Enum.EasingDirection.In,
	[Enum.PoseEasingDirection.Out] = Enum.EasingDirection.Out,
	[Enum.PoseEasingDirection.InOut] = Enum.EasingDirection.InOut,
}

-- Optimized PlayKeyframeSequence
local function PlayKeyframeSequence(Model, KeyFrameSequence, Speed, Loop)
	Speed = Speed or 1
	Loop = Loop == nil and true or Loop

	if not Model or not KeyFrameSequence or not KeyFrameSequence:IsA("KeyframeSequence") then
		warn("PlayKeyframeSequence: Invalid Model or KeyFrameSequence - " .. (KeyFrameSequence and KeyFrameSequence.Name or "nil"))
		return function() end
	end

	-- Cache animation data
	local cacheKey = Model:GetFullName() .. KeyFrameSequence.Name
	if not animationCache[cacheKey] then
		local frames = {}
		for _, kf in ipairs(KeyFrameSequence:GetKeyframes()) do
			if kf and kf:IsA("Keyframe") then
				table.insert(frames, {Time = kf.Time, Keyframe = kf})
			else
				warn("Invalid keyframe in " .. KeyFrameSequence.Name)
			end
		end
		if #frames == 0 then
			warn("No valid keyframes in " .. KeyFrameSequence.Name)
			return function() end
		end
		table.sort(frames, function(a, b) return a.Time < b.Time end)

		local motors, motorValues, keyPoses = {}, {}, {}
		local function GetMotorFromPose(pose)
			for _, v in pairs(Model:GetDescendants()) do
				if v:IsA("Motor6D") and v.Part0 and v.Part1 then
					if v.Part0.Name == pose.Parent.Name and v.Part1.Name == pose.Name then
						return v
					end
				end
			end
		end

		for i, frame in ipairs(frames) do
			keyPoses[i] = {Time = frame.Time, Poses = {}}
			for _, pose in ipairs(frame.Keyframe:GetDescendants()) do
				if pose:IsA("Pose") and pose.Weight > 0 then
					local motor = motors[pose.Name] or GetMotorFromPose(pose)
					if motor then
						motors[pose.Name] = motor
						if not motorValues[pose.Name] then
							local cv = Instance.new("CFrameValue")
							cv.Value = motor.Transform
							cv.Parent = motor
							motorValues[pose.Name] = cv
						end
						keyPoses[i].Poses[pose.Name] = {Motor = motor, Pose = pose}
					else
						warn("No motor found for pose " .. pose.Name .. " in " .. KeyFrameSequence.Name)
					end
				end
			end
		end

		local tweens = {}
		for i = 1, #keyPoses - 1 do
			local k1, k2 = keyPoses[i], keyPoses[i + 1]
			local t = (k2.Time - k1.Time) / Speed
			tweens[i] = {Time = t, Tweens = {}}
			for name, data in pairs(k2.Poses) do
				local easingStyle = data.Pose.EasingStyle
				local easingDirection = data.Pose.EasingDirection
				if easingStyle and easingDirection then
					local info = TweenInfo.new(t, tStyle[easingStyle] or Enum.EasingStyle.Linear, tDirection[easingDirection] or Enum.EasingDirection.InOut)
					tweens[i].Tweens[name] = TS:Create(motorValues[name], info, {Value = data.Pose.CFrame})
				else
					warn("Invalid EasingStyle or EasingDirection for pose " .. name .. " in " .. KeyFrameSequence.Name)
				end
			end
		end

		if #tweens == 0 then
			warn("No valid tweens created for " .. KeyFrameSequence.Name)
			return function() end
		end

		animationCache[cacheKey] = {Motors = motors, MotorValues = motorValues, Tweens = tweens}
	end

	local motors = animationCache[cacheKey].Motors
	local motorValues = animationCache[cacheKey].MotorValues
	local tweens = animationCache[cacheKey].Tweens

	local stopped = false
	local hb = RS.Heartbeat:Connect(function()
		if stopped then hb:Disconnect() return end
		for name, motor in pairs(motors) do
			if motor and motorValues[name] then
				motor.Transform = motorValues[name].Value
			end
		end
	end)

	local function loopFunc()
		repeat
			for _, seg in ipairs(tweens) do
				if stopped then break end
				for _, tw in pairs(seg.Tweens) do
					if tw then tw:Play() end
				end
				task.wait(seg.Time)
			end
		until stopped or not Loop
		if hb then hb:Disconnect() end
	end
	task.spawn(loopFunc)

	return function() stopped = true end
end

-- Survivor Animation Logic
local defaultSpeed, sprintSpeed = 16, 28
humanoid.WalkSpeed = defaultSpeed
local sprinting = false
local currentAnimStopper = nil

RS.RenderStepped:Connect(function()
	if currentAnimStopper and currentAnimStopper.Mode == "Attack" then return end
	local speed = humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed
	local hpPct = humanoid.Health / humanoid.MaxHealth
	local kf

	if hpPct <= 0.5 then
		if speed < defaultSpeed * 0.1 then
			kf = KF["survinjuredidle"]
		elseif speed < defaultSpeed * 1.5 then
			kf = KF["survinjuredwalk"]
		else
			kf = KF["survinjuredrun"]
		end
	else
		if speed < defaultSpeed * 0.1 then
			kf = KF["survidle"]
		elseif speed < defaultSpeed * 1.5 then
			kf = KF["survwalk"]
		else
			kf = KF["survrun"]
		end
	end

	if kf then
		if not currentAnimStopper or currentAnimStopper.Key ~= kf then
			if currentAnimStopper then currentAnimStopper.Stop() end
			currentAnimStopper = {Stop = PlayKeyframeSequence(character, kf, 1, true), Key = kf, Mode = "Move"}
		end
	end
end)

-- Sprint system for player
local maxStamina = 100
local stamina = maxStamina
local staminaDepleteRate = 10
local staminaRegenRate = 20

-- Sprint system for killer
local killerMaxStamina = 110
local killerStamina = killerMaxStamina
local killerDepleteRate = 9.5
local killerRegenRate = 21
local killerSprinting = false

-- Timer
local timeLeft = 93
local gameActive = true

-- Screen GUI for player
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))

-- Timer GUI
local timerLabel = Instance.new("TextLabel", screenGui)
timerLabel.Size = UDim2.new(0, 100, 0, 50)
timerLabel.Position = UDim2.new(0.5, -50, 0, 10)
timerLabel.BackgroundTransparency = 1
timerLabel.TextColor3 = Color3.new(1, 1, 1)
timerLabel.TextSize = 30
timerLabel.Text = "01:30"

-- Player stamina bar
local playerStaminaBar = Instance.new("Frame", screenGui)
playerStaminaBar.Size = UDim2.new(0, 200, 0, 20)
playerStaminaBar.Position = UDim2.new(0.5, -100, 1, -100)
playerStaminaBar.BackgroundColor3 = Color3.new(0, 0, 0)
playerStaminaBar.BorderSizePixel = 0

local playerFill = Instance.new("Frame", playerStaminaBar)
playerFill.Size = UDim2.new(1, 0, 1, 0)
playerFill.BackgroundColor3 = Color3.new(0, 1, 0)
playerFill.BorderSizePixel = 0

-- Sprint toggle button
local sprintBtn = Instance.new("TextButton", screenGui)
sprintBtn.Size = UDim2.new(0, 160, 0, 50)
sprintBtn.Position = UDim2.new(0.5, -80, 1, -60)
sprintBtn.Text = "Sprint"
sprintBtn.MouseButton1Click:Connect(function()
	sprinting = not sprinting
	sprintBtn.Text = sprinting and "Sprinting..." or "Sprint"
end)

-- Load CoolKid NPC
local coolKidFolder = game:GetObjects("rbxassetid://136862019193370")[1]
coolKidFolder.Parent = workspace
local coolKidModel = coolKidFolder:FindFirstChildWhichIsA("Model")
if not coolKidModel then
	warn("CoolKid model not found in asset")
	return
end
coolKidModel.Parent = workspace
coolKidFolder:Destroy()

-- Teleport NPC
local playerHRP = character:WaitForChild("HumanoidRootPart")
local offset = Vector3.new(5, 0, 5)
local npcSpawnCFrame = CFrame.new(playerHRP.Position + offset)
coolKidModel:PivotTo(npcSpawnCFrame)

local coolKidHRP = coolKidModel:WaitForChild("HumanoidRootPart")
if not coolKidHRP then
	warn("CoolKid model missing HumanoidRootPart")
	return
end
coolKidHRP.Anchored = false
local coolKidHumanoid = coolKidModel:WaitForChild("Humanoid")
if not coolKidHumanoid then
	warn("CoolKid model missing Humanoid")
	return
end

-- Killer stamina billboard
local billboard = Instance.new("BillboardGui", coolKidModel)
billboard.Name = "StaminaBillboard"
billboard.Adornee = coolKidModel:FindFirstChild("Head") or coolKidHRP
billboard.Size = UDim2.new(0, 100, 0, 10)
billboard.StudsOffset = Vector3.new(0, 3, 0)
billboard.AlwaysOnTop = true
billboard.Enabled = true

local killerBg = Instance.new("Frame", billboard)
killerBg.Size = UDim2.new(1, 0, 1, 0)
killerBg.BackgroundColor3 = Color3.new(0, 0, 0)
killerBg.BorderSizePixel = 0

local killerFill = Instance.new("Frame", killerBg)
killerFill.Size = UDim2.new(1, 0, 1, 0)
killerFill.BackgroundColor3 = Color3.new(1, 0, 0)
killerFill.BorderSizePixel = 0

-- Larger Hitbox for single-hit
local hitbox = Instance.new("Part")
hitbox.Size = Vector3.new(10, 6, 10)
hitbox.Transparency = 1
hitbox.CanCollide = false
hitbox.Anchored = false
hitbox.Parent = coolKidModel
hitbox.CFrame = coolKidHRP.CFrame

-- Weld hitbox to NPC
local weld = Instance.new("WeldConstraint")
weld.Part0 = coolKidHRP
weld.Part1 = hitbox
weld.Parent = coolKidHRP

local lastHitTime = 0
local hitCooldown = 2
local isExecuting = false
local isAttacking = false

hitbox.Touched:Connect(function(part)
	if part:IsDescendantOf(character) then
		warn("Hitbox.Touched fired for part: " .. part.Name)
		if tick() - lastHitTime < hitCooldown then
			warn("Hit rejected: Cooldown active, time since last hit: " .. (tick() - lastHitTime))
			return
		end
		if not gameActive then
			warn("Hit rejected: gameActive is false")
			return
		end
		if isExecuting then
			warn("Hit rejected: isExecuting is true")
			return
		end
		if isAttacking then
			warn("Hit rejected: isAttacking is true")
			return
		end
		lastHitTime = tick()
		lastHitTimeForFace = tick()
		faceDecal.Texture = faceStates.Hurt
		warn("Hit accepted, attempting to play attack animation")
		if coolKidKF["attack"] and coolKidKF["attack"]:IsA("KeyframeSequence") then
			local keyframes = coolKidKF["attack"]:GetKeyframes()
			if #keyframes == 0 then
				warn("Attack animation has no keyframes")
				return
			end
			-- Stop any existing animation
			if coolKidStopper and coolKidStopper.Stop then
				coolKidStopper.Stop()
				coolKidStopper = nil
				warn("Stopped previous animation")
			end
			-- Set attacking flag
			isAttacking = true
			-- Play attack animation without optimization
			coolKidStopper = {Stop = PlayKeyframeSequence(coolKidModel, coolKidKF["attack"], 1, false), Key = "attack", Mode = "Attack"}
			humanoid:TakeDamage(20)
			local attackDuration = keyframes[#keyframes].Time
			warn("Playing attack animation with duration: " .. attackDuration)
			task.spawn(function()
				task.wait(attackDuration + 0.1) -- Small buffer
				if coolKidStopper and coolKidStopper.Key == "attack" and coolKidStopper.Mode == "Attack" then
					coolKidStopper.Stop()
					coolKidStopper = nil
					isAttacking = false
					warn("Attack animation completed and stopped")
				end
			end)
			if humanoid.Health <= 0 then
				isExecuting = true
				isAttacking = false
				humanoid.Health = 1
				faceDecal.Texture = faceStates.Dead
				local playerHRP = character:FindFirstChild("HumanoidRootPart")
				if playerHRP and coolKidHRP then
					coolKidHumanoid.WalkSpeed = 0
					playerHRP.CFrame = coolKidHRP.CFrame * CFrame.new(0, 0, 0)
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = coolKidHRP
					weld.Part1 = playerHRP
					weld.Parent = coolKidHRP
					if coolKidStopper and coolKidStopper.Stop then
						coolKidStopper.Stop()
						coolKidStopper = nil
					end
					coolKidStopper = {Stop = PlayKeyframeSequence(coolKidModel, coolKidKF["kill007"], 1, false), Key = "kill007", Mode = "Attack"}
					local playerStopper = PlayKeyframeSequence(character, coolKidKF["kill007victim"], 1, false)
					local executionDuration = math.max(
						coolKidKF["kill007"]:GetKeyframes()[#coolKidKF["kill007"]:GetKeyframes()].Time,
						coolKidKF["kill007victim"]:GetKeyframes()[#coolKidKF["kill007victim"]:GetKeyframes()].Time
					)
					task.delay(executionDuration, function()
						weld:Destroy()
						if playerStopper then playerStopper() end
						if coolKidStopper and coolKidStopper.Key == "kill007" then
							coolKidStopper.Stop()
							coolKidStopper = nil
						end
						humanoid.Health = 0
						isExecuting = false
					end)
				else
					isExecuting = false
				end
			end
		else
			warn("Attack animation missing or invalid for CoolKid")
			isAttacking = false
		end
	end
end)

local coolKidStopper = nil
local coolKidMoveSpeedRun = 28
local coolKidMoveSpeedWalk = 12
local lastSprintingState = false
local lastDistance = math.huge

-- Function to end the game
local function endGame()
	if not gameActive then return end
	gameActive = false
	Lighting.TimeOfDay = "14:00:00"
	if screenGui then screenGui:Destroy() end
	if coolKidModel then coolKidModel:Destroy() end
	if map then map:Destroy() end
	if hbConn then hbConn:Disconnect() end
	if sound then sound:Stop() sound:Destroy() end
	if faceDecal then faceDecal:Destroy() end
	character:PivotTo(originalPivot)
	if not humanoid:FindFirstChildOfClass("Animator") then
		Instance.new("Animator", humanoid)
	end
end

-- Stamina and movement update loop
local hbConn = RS.Heartbeat:Connect(function(dt)
	if not gameActive then return end
	
	-- Timer update
	timeLeft -= dt
	if timeLeft <= 0 then
		endGame()
		return
	end
	-- Update timer GUI
	local minutes = math.floor(timeLeft / 60)
	local seconds = math.floor(timeLeft % 60)
	timerLabel.Text = string.format("%02d:%02d", minutes, seconds)
	
	-- Player stamina update
	if sprinting then
		if stamina > 0 then
			humanoid.WalkSpeed = sprintSpeed
			stamina = math.max(0, stamina - staminaDepleteRate * dt)
		else
			sprinting = false
			sprintBtn.Text = "Sprint"
			humanoid.WalkSpeed = defaultSpeed
		end
	else
		humanoid.WalkSpeed = defaultSpeed
		stamina = math.min(maxStamina, stamina + staminaRegenRate * dt)
	end
	-- Update player stamina bar
	playerFill.Size = UDim2.new(stamina / maxStamina, 0, 1, 0)

	-- Killer stamina update
	if killerSprinting then
		killerStamina = math.max(0, killerStamina - killerDepleteRate * dt)
		if killerStamina <= 0 then
			killerSprinting = false
		end
	else
		killerStamina = math.min(killerMaxStamina, killerStamina + killerRegenRate * dt)
		if killerStamina >= killerMaxStamina then
			killerSprinting = true
		end
	end
	-- Update killer stamina bar
	killerFill.Size = UDim2.new(killerStamina / killerMaxStamina, 0, 1, 0)

	-- Face system update
	if humanoid.Health > 0 then
		if tick() - lastHitTimeForFace < hurtFaceDuration then
			-- Keep Hurt face during duration
		elseif humanoid.Health / humanoid.MaxHealth <= 0.5 then
			faceDecal.Texture = faceStates.Injured
		else
			faceDecal.Texture = faceStates.Neutral
		end
	end
end)

spawn(function()
	while coolKidHumanoid.Health > 0 and gameActive do
		hitbox.CFrame = coolKidHRP.CFrame
		if (coolKidStopper and coolKidStopper.Mode == "Attack") or isAttacking then
			task.wait(0.1)
			continue
		end
		local targetPos = character.HumanoidRootPart.Position
		local dist = (coolKidHRP.Position - targetPos).Magnitude
		local shouldUpdateAnim = lastSprintingState ~= killerSprinting or math.abs(lastDistance - dist) > 2
		if dist > 2 then
			coolKidHumanoid:MoveTo(targetPos)
			if killerSprinting and coolKidKF["run"] then
				coolKidHumanoid.WalkSpeed = coolKidMoveSpeedRun
				if shouldUpdateAnim and (not coolKidStopper or coolKidStopper.Key ~= "run") then
					if coolKidStopper and coolKidStopper.Stop then
						coolKidStopper.Stop()
						coolKidStopper = nil
					end
					coolKidStopper = {Stop = PlayKeyframeSequence(coolKidModel, coolKidKF["run"], 1.5, true), Key = "run", Mode = "Move"}
				end
			elseif coolKidKF["walk"] then
				coolKidHumanoid.WalkSpeed = coolKidMoveSpeedWalk
				if shouldUpdateAnim and (not coolKidStopper or coolKidStopper.Key ~= "walk") then
					if coolKidStopper and coolKidStopper.Stop then
						coolKidStopper.Stop()
						coolKidStopper = nil
					end
					coolKidStopper = {Stop = PlayKeyframeSequence(coolKidModel, coolKidKF["walk"], 1, true), Key = "walk", Mode = "Move"}
				end
			else
				warn("No valid walk or run animation for CoolKid")
			end
		else
			coolKidHumanoid.WalkSpeed = 0
			if coolKidStopper and coolKidStopper.Stop and coolKidStopper.Mode == "Move" then
				coolKidStopper.Stop()
				coolKidStopper = nil
			end
		end
		lastSprintingState = killerSprinting
		lastDistance = dist
		task.wait(0.1)
	end
end)

humanoid.Died:Connect(function()
	endGame()
end)
