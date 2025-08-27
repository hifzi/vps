--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

--// Refs
local Plr = Players.LocalPlayer
local Character = Plr.Character or Plr.CharacterAdded:Wait()
local Humanoid = Character:FindFirstChildOfClass("Humanoid") or Character:WaitForChild("Humanoid")

--// State
local ClipOn, JumpOn, SpeedOn, FlyOn = false, false, false, false
local BaseWalkSpeed = Humanoid.WalkSpeed
local FlySpeed = 50

-- Connections
local ConStepped, ConJump, ConCharAdded, ConFly

--// GUI - Floating Buttons
local Gui = Instance.new("ScreenGui")
Gui.Name = "PlayerMods"
Gui.ResetOnSpawn = false
Gui.Parent = CoreGui

-- Util tombol toggle (floating style + draggable)
local function makeFloatingToggle(parent, position, label)
	local btn = Instance.new("TextButton")
	btn.Parent = parent
	btn.BackgroundColor3 = Color3.fromRGB(100,100,100) -- abu-abu = off
	btn.BorderColor3 = Color3.fromRGB(60,60,60)
	btn.BorderSizePixel = 2
	btn.Position = position
	btn.Size = UDim2.new(0, 50, 0, 50)
	btn.Font = Enum.Font.SourceSansBold
	btn.Text = label
	btn.TextColor3 = Color3.new(1,1,1)
	btn.TextSize = 14
	btn.TextStrokeTransparency = 0
	btn.TextStrokeColor3 = Color3.new(0,0,0)
	btn.Active = true
	btn.Draggable = true
	
	-- Rounded corners effect
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn
	
	return btn
end

-- Horizontal layout
local BtnNoclip = makeFloatingToggle(Gui, UDim2.new(0.35, 0, 0.05, 0), "NC")
local BtnJump   = makeFloatingToggle(Gui, UDim2.new(0.45, 0, 0.05, 0), "UJ")
local BtnSpeed  = makeFloatingToggle(Gui, UDim2.new(0.55, 0, 0.05, 0), "3S")
local BtnFly    = makeFloatingToggle(Gui, UDim2.new(0.65, 0, 0.05, 0), "FLY")

-- Helper untuk mengubah warna button (improved)
local function setButtonColor(btn, on)
	btn.BackgroundColor3 = on and Color3.fromRGB(0,200,0) or Color3.fromRGB(100,100,100)
	-- Add glow effect when active
	if on then
		btn.BorderColor3 = Color3.fromRGB(0,255,0)
	else
		btn.BorderColor3 = Color3.fromRGB(60,60,60)
	end
end

-- Character reattach
local function attachCharacter(char)
	Character = char
	Humanoid = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid")
	BaseWalkSpeed = Humanoid.WalkSpeed
end

-- Noclip loop
local function ensureStepped()
	if ConStepped then return end
	ConStepped = RunService.Stepped:Connect(function()
		if not ClipOn then return end
		local char = Plr.Character
		if not char then return end
		for _, v in ipairs(char:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end
	end)
end
local function stopStepped()
	if ConStepped then ConStepped:Disconnect() ConStepped=nil end
end

-- Mobile-friendly Fly system (Based on coolcapidog reference)
local function getCameraRelativeMovement()
	if Humanoid.MoveDirection == Vector3.new(0, 0, 0) then
		return Humanoid.MoveDirection
	end
	local cam = workspace.CurrentCamera
	local v12 = (cam.CFrame * CFrame.new((CFrame.new(cam.CFrame.Position, cam.CFrame.Position + Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)):VectorToObjectSpace(Humanoid.MoveDirection)))).Position - cam.CFrame.Position
	if v12 == Vector3.new() then
		return v12
	end
	return v12.Unit
end

local function startFly()
	if ConFly then return end
	local root = Character:WaitForChild("HumanoidRootPart")
	local hum = Character:FindFirstChildOfClass("Humanoid")
	if not (root and hum) then return end
	
	hum.PlatformStand = true
	
	-- Create BodyGyro for rotation (like reference)
	local bodyGyro = Instance.new("BodyGyro", root)
	bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bodyGyro.P = 9e4
	bodyGyro.CFrame = root.CFrame
	
	-- Create BodyVelocity for movement (like reference)
	local bodyVelocity = Instance.new("BodyVelocity", root)
	bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bodyVelocity.Velocity = Vector3.zero
	
	ConFly = RunService.RenderStepped:Connect(function()
		if not FlyOn or not root then return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		
		-- Use coolcapidog's camera-relative movement function
		local moveVector = getCameraRelativeMovement()
		local mv = moveVector * FlySpeed
		
		-- Add vertical movement from jump button
		if Humanoid.Jump then
			mv = mv + Vector3.new(0, FlySpeed, 0)
			Humanoid.Jump = false
		end
		
		-- Apply velocity
		bodyVelocity.Velocity = mv
		
		-- Make character look at camera direction (like reference)
		bodyGyro.CFrame = cam.CFrame
	end)
end

local function stopFly()
	if ConFly then ConFly:Disconnect() ConFly=nil end
	if Humanoid then Humanoid.PlatformStand = false end
	local root = Character:FindFirstChild("HumanoidRootPart")
	if root then
		-- Clean up all body movers
		for _, obj in pairs(root:GetChildren()) do
			if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") or obj:IsA("BodyAngularVelocity") then
				obj:Destroy()
			end
		end
	end
end

-- Toggles
BtnNoclip.MouseButton1Click:Connect(function()
	ClipOn = not ClipOn
	setButtonColor(BtnNoclip, ClipOn)
	if ClipOn then ensureStepped() else stopStepped() end
end)
BtnJump.MouseButton1Click:Connect(function()
	JumpOn = not JumpOn
	setButtonColor(BtnJump, JumpOn)
	if ConJump then ConJump:Disconnect() ConJump=nil end
	if JumpOn then
		ConJump = UserInputService.JumpRequest:Connect(function()
			if JumpOn and Humanoid then
				Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end
end)
BtnSpeed.MouseButton1Click:Connect(function()
	SpeedOn = not SpeedOn
	setButtonColor(BtnSpeed, SpeedOn)
	if Humanoid then
		if SpeedOn then
			BaseWalkSpeed = Humanoid.WalkSpeed > 0 and Humanoid.WalkSpeed or 16
			Humanoid.WalkSpeed = math.max(2, BaseWalkSpeed) * 3
		else
			Humanoid.WalkSpeed = BaseWalkSpeed or 16
		end
	end
end)
BtnFly.MouseButton1Click:Connect(function()
	FlyOn = not FlyOn
	setButtonColor(BtnFly, FlyOn)
	if FlyOn then startFly() else stopFly() end
end)

-- Respawn handler
if ConCharAdded then ConCharAdded:Disconnect() end
ConCharAdded = Plr.CharacterAdded:Connect(function(char) attachCharacter(char) end)
attachCharacter(Character)
