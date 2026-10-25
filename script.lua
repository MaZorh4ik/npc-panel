--1. rules: it is forbidden to change the credit name, this script was created by @carmo you will be charged dcma for changing the credit
--2. rules: changing the code using AI and claiming it as your own is not allowed

-- Защита от повторного запуска: удаляем старое окно/интерфейс, если он уже был создан
pcall(function()
    for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if gui.Name == "Obsidian" or gui.Name == "CarmoNPCPanel" then
            gui:Destroy()
        end
    end
end)

local inf = math.huge
local pi = math.pi
local partowner = function(part)
    return part and not part.Anchored
end

local clicknpc = true

local tweenservice = game:GetService("TweenService")
local rs = game:GetService("RunService")
local ws = game:GetService("Workspace")
local plrs = game:GetService("Players")
local uis = game:GetService("UserInputService")
local coreGui = game:GetService("CoreGui")
local lp = plrs.LocalPlayer
local mouse = lp:GetMouse()

local medium = TweenInfo.new(.67)
local rad = 150
local currentnpc

local highlight = Instance.new("Highlight")
highlight.Parent = lp
highlight.FillTransparency = 1
highlight.OutlineTransparency = 1

local light = function(adornee, color)
    task.spawn(function()
        highlight.Adornee = adornee
        highlight.OutlineColor = color
        tweenservice:Create(highlight, medium, {OutlineTransparency = 0}):Play()
        task.wait(.5)
        tweenservice:Create(highlight, medium, {OutlineTransparency = 1}):Play()
    end)    
end

local isnpc = function(ins)
    local humanoid = ins:FindFirstChildOfClass("Humanoid")
    local player = plrs:GetPlayerFromCharacter(ins)
    if humanoid and not player then
        return ins 
    end
    return nil
end

-- ==========================================
-- СИСТЕМА КОНТРОЛЯ NPC
-- ==========================================

local Controlling = false
local CurrentlyControlledNPC = nil
local OriginalProperties = {}
local DisposableInstances = {}
local OriginalPosition

local ToggleEnabled = true
local Client = lp
local Character = Client.Character or Client.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Humanoid.RootPart
local lastChar = Character

function CreateDisposableInstance(className, properties)
	properties = properties or {}
	local instance = Instance.new(className)
	table.insert(DisposableInstances, instance)
	for name, value in pairs(properties) do
		instance[name] = value
	end
	return instance
end

local ClientHighligher = CreateDisposableInstance("Highlight", {
	FillTransparency = 1,
	OutlineColor = Color3.fromRGB(75, 150, 255),
	Enabled = false,
	Parent = Character
})

local ClientAttachment = CreateDisposableInstance("Attachment", {Parent = HumanoidRootPart})
local DummyAttachment = CreateDisposableInstance("Attachment")
local NPCAttachment = CreateDisposableInstance("Attachment")

local ClientVelocity = CreateDisposableInstance("LinearVelocity", {
	Attachment0 = ClientAttachment,
	MaxForce = inf,
	Enabled = false,
	Parent = ws
})

local ClientAlignOrientation = CreateDisposableInstance("AlignOrientation", {
	MaxTorque = inf,
	Responsiveness = inf,
	Attachment0 = ClientAttachment,
	Attachment1 = NPCAttachment,
	Enabled = false,
	Parent = ws
})

local NPCAlignPosition = CreateDisposableInstance("AlignPosition", {
	ApplyAtCenterOfMass = false,
	Attachment0 = NPCAttachment,
	Attachment1 = DummyAttachment,
	MaxForce = inf,
	Responsiveness = inf,
	Enabled = false,
	Parent = ws
})

local NPCAlignOrientation = CreateDisposableInstance("AlignOrientation", {
	MaxTorque = inf,
	Responsiveness = inf,
	Attachment0 = NPCAttachment,
	Attachment1 = DummyAttachment,
	Enabled = false,
	Parent = ws
})

local DummyModel, DummyRootPart
local NPCModel, NPCRootPart, NPCName, NPCHighlighter
local DummyDiedConnection, ClientHealthChangedConnection

function SetOriginalProperty(instance, name, value)
	local instanceOriginalProperties = OriginalProperties[instance] or {}
	instanceOriginalProperties[name] = value
	OriginalProperties[instance] = instanceOriginalProperties
end

function SetCameraSubject(subject)
	while task.wait() do
		local camera = ws.CurrentCamera
		if camera then
			camera.CameraSubject = subject
			return
		end
	end
end

Client.CharacterAdded:Connect(function(newCharacter)
	local wasDeath = false
	if lastChar then
		local oldHumanoid = lastChar:FindFirstChildOfClass("Humanoid")
		if oldHumanoid and oldHumanoid.Health <= 0 then
			wasDeath = true
		end
	end

	if wasDeath then
		Character = newCharacter
		Humanoid = newCharacter:WaitForChild("Humanoid")
		HumanoidRootPart = Humanoid.RootPart

		ClientHighligher.Parent = Character
		ClientAttachment.Parent = HumanoidRootPart

		Humanoid.Died:Once(function()
			StopControlling()
		end)
	end

	lastChar = newCharacter
end)

function StopControlling(restorePosition)
	Controlling = false
	CurrentlyControlledNPC = nil

	if ClientHealthChangedConnection then
		ClientHealthChangedConnection:Disconnect()
		ClientHealthChangedConnection = nil
	end

	if DummyDiedConnection then
		DummyDiedConnection:Disconnect()
		DummyDiedConnection = nil
	end

	NPCAlignPosition.Enabled = false
	NPCAlignOrientation.Enabled = false
	ClientVelocity.Enabled = false
	ClientAlignOrientation.Enabled = false

	SetCameraSubject(Humanoid)
	Client.Character = Character

	DummyAttachment.Parent = nil
	NPCAttachment.Parent = nil

	if DummyModel then
		DummyModel:Destroy()
		DummyModel = nil
	end
	DummyRootPart = nil

	if NPCHighlighter then
		NPCHighlighter:Destroy()
		NPCHighlighter = nil
	end

	NPCModel = nil
	NPCRootPart = nil
	NPCName = nil

	if Humanoid and Humanoid.Health > 0 then
		if restorePosition and OriginalPosition then
			HumanoidRootPart.CFrame = OriginalPosition
			OriginalPosition = nil
		end

		for instance, originalProperties in pairs(OriginalProperties) do
			for name, value in pairs(originalProperties) do
				instance[name] = value
			end
			OriginalProperties[instance] = nil
		end

		local player = lp
		local char = player.Character or player.CharacterAdded:Wait()

		for _, part in ipairs(char:GetChildren()) do
			if part:IsA("BasePart") then
				part.CanTouch = true
			end
		end

		ClientHighligher.Enabled = false
		Humanoid.PlatformStand = false
	end
end

function Control(npcModel)
	if Controlling then return end
	if CurrentlyControlledNPC == npcModel then return end

	local npcHumanoid = npcModel:FindFirstChildOfClass("Humanoid")
	local npcRootPart = npcHumanoid and npcHumanoid.RootPart

	if npcRootPart and npcHumanoid then
		local player = plrs:GetPlayerFromCharacter(npcModel)
		if player then return end
		if npcModel == Character then return end

		CurrentlyControlledNPC = npcModel
		OriginalPosition = HumanoidRootPart.CFrame

		ClientHighligher.Enabled = true
		SetOriginalProperty(HumanoidRootPart, "CFrame", HumanoidRootPart.CFrame)

		Humanoid.PlatformStand = true

		local localPlayer = lp
		local localCharacter = localPlayer.Character or localPlayer.CharacterAdded:Wait()

		for _, part in ipairs(localCharacter:GetChildren()) do
			if part:IsA("BasePart") then
				part.CanTouch = false
			end
		end

		task.wait(0.5)

		if not Humanoid or Humanoid.Health <= 0
			or not HumanoidRootPart or not HumanoidRootPart.Parent
			or not npcRootPart or not npcRootPart.Parent then
			CurrentlyControlledNPC = nil
			pcall(function() Humanoid.PlatformStand = false end)
			ClientHighligher.Enabled = false
			for _, part in ipairs(Character:GetChildren()) do
				if part:IsA("BasePart") then
					part.CanTouch = true
				end
			end
			return
		end

		pcall(function() npcRootPart.BodyPosition:Destroy() end)
		pcall(function() npcRootPart.BodyGyro:Destroy() end)

		local dummyModel = npcModel:Clone()
		local dummyHumanoid = dummyModel:FindFirstChildOfClass("Humanoid")
		local dummyRootPart = dummyModel:FindFirstChild(npcRootPart.Name)

		DummyDiedConnection = dummyHumanoid.Died:Once(function()
			if Controlling then StopControlling(true) end
		end)

		local function updateHealth()
			if Controlling then
				dummyHumanoid.MaxHealth = inf
				dummyHumanoid.Health = inf
				Humanoid.Health = inf
			end
		end

		ClientHealthChangedConnection = Humanoid.Changed:Connect(updateHealth)
		updateHealth()

		for _, descendant in pairs(dummyModel:GetDescendants()) do
			if descendant:IsA("Light") or descendant:IsA("Sound") then
				descendant:Remove()
			else
				pcall(function() descendant.Transparency = 0.95 end)
			end
		end

		DummyModel = dummyModel
		DummyRootPart = dummyRootPart
		dummyModel.Parent = ws

		DummyAttachment.Parent = dummyRootPart
		NPCAttachment.Parent = npcRootPart

		NPCModel = npcModel
        NPCRootPart = npcRootPart
		NPCName = npcModel.Name

		NPCHighlighter = Instance.new("Highlight")
		NPCHighlighter.FillTransparency = 1
		NPCHighlighter.OutlineColor = Color3.fromRGB(255, 0, 0)
		NPCHighlighter.Parent = npcModel

		local DummyHighlighter = Instance.new("Highlight")
		DummyHighlighter.FillTransparency = 1
		DummyHighlighter.OutlineColor = Color3.fromRGB(128, 0, 128)
		DummyHighlighter.Parent = dummyModel

		SetCameraSubject(dummyHumanoid)
		Client.Character = dummyModel

		NPCAlignPosition.Enabled = true
		NPCAlignOrientation.Enabled = true
		ClientAlignOrientation.Enabled = false
		ClientVelocity.Enabled = true
		Controlling = true
	end
end

rs.Heartbeat:Connect(function()
	if not (Controlling and ToggleEnabled) then return end

	if not NPCRootPart or not NPCRootPart.Parent
		or not HumanoidRootPart or not HumanoidRootPart.Parent
		or not Humanoid or Humanoid.Health <= 0 then
		return
	end

	if type(sethiddenproperty) == "function" then
		pcall(function() sethiddenproperty(Client, "SimulationRadius", inf) end)
	elseif type(setsimulationradius) == "function" then
		setsimulationradius(inf)
	end

	if NPCRootPart then
		local offset = 6
		local npcPosition = NPCRootPart.Position
		HumanoidRootPart.CFrame = CFrame.new(
			npcPosition.X, npcPosition.Y - offset, npcPosition.Z
		) * NPCRootPart.CFrame.Rotation
	end

	for _, child in pairs(Character:GetChildren()) do
		if child:IsA("BasePart") and child.CanCollide then
			SetOriginalProperty(child, "CanCollide", true)
			child.CanCollide = false
			SetOriginalProperty(child, "CanTouch", true)
			child.CanTouch = false
		end
	end

	if DummyModel then
		for _, child in pairs(DummyModel:GetChildren()) do
			if child:IsA("BasePart") and child.CanCollide then
				child.CanCollide = false
				child.CanTouch = false
			end
		end
	end

	if NPCModel then
		for _, child in pairs(NPCModel:GetChildren()) do
			if child:IsA("BasePart") and child.CanCollide then
				SetOriginalProperty(child, "CanCollide", true)
				child.CanCollide = false
			end
		end
	end
end)

-- ==========================================
-- ФУНКЦИОНАЛ ДЕЙСТВИЙ С NPC И ИГРОКОМ
-- ==========================================

local function actionKill()
    if currentnpc then
        local hum = currentnpc:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
    end
end

local function actionKillAll()
    for _, model in ipairs(ws:GetDescendants()) do
        if model:IsA("Model") and isnpc(model) and model ~= lp.Character then
            local hum = model:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = 0
            end
        end
    end
end

local function actionBring()
    if currentnpc then
        local part = currentnpc:FindFirstChild("HumanoidRootPart")
        if part and partowner(part) then
            if lp and lp.Character then
                currentnpc:PivotTo(lp.Character:GetPivot())
            end
        else
            light(currentnpc, Color3.fromRGB(255, 0, 0))
        end
    end
end

local function actionBringAll()
    if lp and lp.Character then
        local charPivot = lp.Character:GetPivot()
        for _, model in ipairs(ws:GetDescendants()) do
            if model:IsA("Model") and isnpc(model) and model ~= lp.Character then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                if hrp and partowner(hrp) then
                    model:PivotTo(charPivot)
                end
            end
        end
    end
end

local function actionGoto()
    if currentnpc then
        local part = currentnpc:FindFirstChild("HumanoidRootPart")
        if part then
            if lp and lp.Character then
                lp.Character:PivotTo(currentnpc:GetPivot())
            end
        else
            light(currentnpc, Color3.fromRGB(255, 0, 0))
        end
    end
end

local function actionPunish()
    if currentnpc then
        local part = currentnpc:FindFirstChild("HumanoidRootPart")
        if part and partowner(part) then
            currentnpc:PivotTo(CFrame.new(0, 1000, 0))
        else
            light(currentnpc, Color3.fromRGB(255, 0, 0))
        end
    end
end

-- TPWalk 2 (скорость 40)
local tpwalkEnabled = false
local function actionTPWalk()
    tpwalkEnabled = not tpwalkEnabled
end

rs.Heartbeat:Connect(function(dt)
    if tpwalkEnabled and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character:FindFirstChildOfClass("Humanoid") then
        local hum = lp.Character:FindFirstChildOfClass("Humanoid")
        local hrp = lp.Character:FindFirstChild("HumanoidRootPart")
        if hum.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (hum.MoveDirection * 40 * dt)
        end
    end
end)

-- Fly на букву F
local flying = false
local flySpeed = 50
local bg, bv
local function actionFly()
    flying = not flying
    local char = lp.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    if flying then
        if hum then hum.PlatformStand = true end
        bg = Instance.new("BodyGyro", hrp)
        bg.P = 9e4
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.cframe = hrp.CFrame
        
        bv = Instance.new("BodyVelocity", hrp)
        bv.velocity = Vector3.new(0, 0, 0)
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        
        task.spawn(function()
            while flying and char and hrp and char.Parent do
                local cam = ws.CurrentCamera
                local moveDir = Vector3.new()
                if uis:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if uis:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                
                bv.velocity = moveDir * flySpeed
                bg.cframe = cam.CFrame
                rs.RenderStepped:Wait()
            end
            if bg then bg:Destroy() end
            if bv then bv:Destroy() end
            if hum then hum.PlatformStand = false end
        end)
    else
        if hum then hum.PlatformStand = false end
        if bg then bg:Destroy() end
        if bv then bv:Destroy() end
    end
end

local function actionSit()
    if currentnpc then
        local part = currentnpc:FindFirstChild("HumanoidRootPart")
        if part and partowner(part) then
            local hum = currentnpc:FindFirstChildOfClass("Humanoid")
            if hum then hum.Sit = not hum.Sit end
        else
            light(currentnpc, Color3.fromRGB(255, 0, 0))
        end
    end
end

local function actionJump()
    if currentnpc then
        local part = currentnpc:FindFirstChild("HumanoidRootPart")
        if part and partowner(part) then
            local hum = currentnpc:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        else
            light(currentnpc, Color3.fromRGB(255, 0, 0))
        end
    end
end

local function actionSteal()
    if currentnpc and lp.Character then
        local tool = currentnpc:FindFirstChildOfClass("Tool")
        if tool then
            tool.Parent = lp.Character
        else
            light(currentnpc, Color3.fromRGB(255, 0, 0))
        end
    end
end

local function getClosestPlayerToPosition(pos)
    local closestPlayer = nil
    local shortestDist = inf
    for _, player in ipairs(plrs:GetPlayers()) do
        if player ~= lp and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - pos).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closestPlayer = player
                end
            end
        end
    end
    if not closestPlayer and lp.Character then
        return lp
    end
    return closestPlayer
end

local function actionAggroNPC()
    if currentnpc then
        local part = currentnpc:FindFirstChild("HumanoidRootPart")
        local hum = currentnpc:FindFirstChildOfClass("Humanoid")
        if part and hum and partowner(part) then
            local targetPlayer = getClosestPlayerToPosition(part.Position)
            if targetPlayer and targetPlayer.Character then
                local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if targetHrp then
                    hum:MoveTo(targetHrp.Position)
                    light(currentnpc, Color3.fromRGB(255, 100, 0))
                end
            end
        else
            light(currentnpc, Color3.fromRGB(255, 0, 0))
        end
    end
end

local function actionAggroAllNPCs()
    if lp and lp.Character then
        local myHrp = lp.Character:FindFirstChild("HumanoidRootPart")
        if not myHrp then return end
        
        local partsInRadius = ws:GetPartBoundsInRadius(myHrp.Position, 50)
        for _, part in ipairs(partsInRadius) do
            local model = part:FindFirstAncestorOfClass("Model")
            if model and isnpc(model) and model ~= lp.Character then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                local hum = model:FindFirstChildOfClass("Humanoid")
                if hrp and hum and partowner(hrp) then
                    local targetPlayer = getClosestPlayerToPosition(hrp.Position)
                    if targetPlayer and targetPlayer.Character then
                        local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if targetHrp then
                            hum:MoveTo(targetHrp.Position)
                        end
                    end
                end
            end
        end
    end
end

local function actionToggleControl()
    if Controlling then
        StopControlling(true)
    else
        if currentnpc then
            local part = currentnpc:FindFirstChild("HumanoidRootPart")
            if part and partowner(part) then
                Control(currentnpc)
            else
                light(currentnpc, Color3.fromRGB(255, 0, 0))
            end
        end
    end
end

local IsTeleportingToMouse = false
local tpMouseCon

local function actionToggleTeleportToMouse()
    IsTeleportingToMouse = not IsTeleportingToMouse
    
    if IsTeleportingToMouse then
        tpMouseCon = rs.Heartbeat:Connect(function()
            if currentnpc then
                local part = currentnpc:FindFirstChild("HumanoidRootPart")
                local hitPos = mouse.Hit.Position
                if part and partowner(part) then
                    currentnpc:PivotTo(CFrame.new(hitPos + Vector3.new(0, 3, 0)))
                else
                    light(currentnpc, Color3.fromRGB(255, 0, 0))
                end
            end
        end)
    else
        if tpMouseCon then
            tpMouseCon:Disconnect()
            tpMouseCon = nil
        end
    end
end

local isHighlightingNPCs = false
local function actionHighlightControllableNPCs()
    if isHighlightingNPCs then return end
    isHighlightingNPCs = true

    task.spawn(function()
        local activeHighlighters = {}

        for _, model in ipairs(ws:GetDescendants()) do
            if model:IsA("Model") and isnpc(model) and model ~= lp.Character then
                local hrp = model:FindFirstChild("HumanoidRootPart")
                if hrp and partowner(hrp) then
                    local hl = Instance.new("Highlight")
                    hl.FillTransparency = 1
                    hl.OutlineTransparency = 1
                    hl.OutlineColor = Color3.fromRGB(0, 255, 100)
                    hl.Parent = model
                    table.insert(activeHighlighters, hl)
                    
                    tweenservice:Create(hl, medium, {OutlineTransparency = 0}):Play()
                end
            end
        end

        task.wait(2)

        for _, hl in ipairs(activeHighlighters) do
            if hl.Parent then
                tweenservice:Create(hl, medium, {OutlineTransparency = 1}):Play()
            end
        end

        task.wait(0.7)
        for _, hl in ipairs(activeHighlighters) do
            hl:Destroy()
        end

        isHighlightingNPCs = false
    end)
end

-- ==========================================
-- ИНИЦИАЛИЗАЦИЯ ОБСИДИАНА
-- ==========================================

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = "Carmo NPC Panel",
    Icon = "rbxassetid://10734341457",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local MainTab = Window:AddTab("Main", "rbxassetid://10723407389")
local ExtraTab = Window:AddTab("Extra", "rbxassetid://10734950309")
local SettingsTab = Window:AddTab("Settings", "rbxassetid://10734950309")

local MainGroup = MainTab:AddLeftGroupbox("NPC Actions")
local MainTogglesGroup = MainTab:AddRightGroupbox("Toggles")

local ExtraGroup = ExtraTab:AddLeftGroupbox("Global Actions")
local ExtraTogglesGroup = ExtraTab:AddRightGroupbox("Auras & Network")

local KeybindsGroup = SettingsTab:AddLeftGroupbox("Keybinds & UI Settings")
local UIManagementGroup = SettingsTab:AddRightGroupbox("UI Management")

-- Активация Keybind Menu из документации
Library.ShowToggleFrameInKeybinds = true
if Library.KeybindFrame then
    Library.KeybindFrame.Visible = true
end

-- ==========================================
-- ВКЛАДКА MAIN
-- ==========================================

MainGroup:AddButton({
    Text = "Kill NPC",
    Func = function() pcall(actionKill) end
})

MainGroup:AddButton({
    Text = "Bring NPC",
    Func = function() pcall(actionBring) end
})

MainGroup:AddButton({
    Text = "Goto NPC",
    Func = function() pcall(actionGoto) end
})

MainGroup:AddButton({
    Text = "Aggro Selected NPC",
    Func = function() pcall(actionAggroNPC) end
})

MainGroup:AddButton({
    Text = "Punish NPC",
    Func = function() pcall(actionPunish) end
})

MainGroup:AddButton({
    Text = "TPWalk 2",
    Func = function() pcall(actionTPWalk) end
})

MainGroup:AddButton({
    Text = "NPC Sit State",
    Func = function() pcall(actionSit) end
})

MainGroup:AddButton({
    Text = "NPC Jump State",
    Func = function() pcall(actionJump) end
})

MainGroup:AddButton({
    Text = "Steal Tool",
    Func = function() pcall(actionSteal) end
})

MainTogglesGroup:AddToggle("ControlNPC", {
    Text = "Control NPC",
    Default = false,
    Callback = function(Value)
        if Value then
            if currentnpc then
                local part = currentnpc:FindFirstChild("HumanoidRootPart")
                if part and partowner(part) then
                    Control(currentnpc)
                else
                    light(currentnpc, Color3.fromRGB(255, 0, 0))
                end
            end
        else
            StopControlling(true)
        end
    end
})

local followCon
MainTogglesGroup:AddToggle("FollowNPC", {
    Text = "Following NPC",
    Default = false,
    Callback = function(Value)
        if Value then
            followCon = rs.RenderStepped:Connect(function()
                if currentnpc then
                    local part = currentnpc:FindFirstChild("HumanoidRootPart")
                    if part and partowner(part) then
                        local hum = currentnpc:FindFirstChildOfClass("Humanoid")
                        if hum then
                            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                hum:MoveTo(hrp.Position + Vector3.new(-4, 0, 0))
                            end
                        end
                    else
                        light(currentnpc, Color3.fromRGB(255, 0, 0))
                        if followCon then followCon:Disconnect(); followCon = nil end
                    end
                else
                    if followCon then followCon:Disconnect(); followCon = nil end
                end
            end)
        else
            if followCon then followCon:Disconnect(); followCon = nil end
        end
    end
})

local lookMouseCon
MainTogglesGroup:AddToggle("LookAtMouse", {
    Text = "Look at Mouse",
    Default = false,
    Callback = function(Value)
        if Value then
            lookMouseCon = rs.Heartbeat:Connect(function()
                if currentnpc then
                    local npcPart = currentnpc:FindFirstChild("HumanoidRootPart")
                    if npcPart and partowner(npcPart) then
                        local mouseHit = mouse.Hit.Position
                        npcPart.CFrame = CFrame.new(npcPart.Position, Vector3.new(mouseHit.X, npcPart.Position.Y, mouseHit.Z))
                    else
                        light(currentnpc, Color3.fromRGB(255, 0, 0))
                    end
                end
            end)
        else
            if lookMouseCon then lookMouseCon:Disconnect(); lookMouseCon = nil end
        end
    end
})

MainTogglesGroup:AddToggle("TeleportToMouse", {
    Text = "Teleport to Mouse",
    Default = false,
    Callback = function(Value)
        if Value then
            if not IsTeleportingToMouse then
                actionToggleTeleportToMouse()
            end
        else
            if IsTeleportingToMouse then
                actionToggleTeleportToMouse()
            end
        end
    end
})

-- ==========================================
-- ВКЛАДКА EXTRA
-- ==========================================

ExtraGroup:AddButton({
    Text = "Bring All NPCs",
    Func = function() pcall(actionBringAll) end
})

ExtraGroup:AddButton({
    Text = "Aggro All Nearby NPCs",
    Func = function() pcall(actionAggroAllNPCs) end
})

ExtraTogglesGroup:AddToggle("DisableClickControl", {
    Text = "Disable Click Control",
    Default = false,
    Callback = function(Value)
        clicknpc = not Value
    end
})

local netOwnerCon
ExtraTogglesGroup:AddToggle("NetworkOwner", {
    Text = "Network Ownership Sync",
    Default = false,
    Callback = function(Value)
        if Value then
            netOwnerCon = rs.Heartbeat:Connect(function()
                if currentnpc then
                    local part = currentnpc:FindFirstChild("HumanoidRootPart")
                    if part and partowner(part) then
                        pcall(function()
                            for _, child in ipairs(currentnpc:GetDescendants()) do
                                if child:IsA("BasePart") and not child.Anchored then
                                    if child:GetNetworkOwner() ~= lp then
                                        child:SetNetworkOwner(lp)
                                    end
                                end
                            end
                        end)
                    end
                end
            end)
        else
            if netOwnerCon then netOwnerCon:Disconnect(); netOwnerCon = nil end
        end
    end
})

local con1, con2
ExtraTogglesGroup:AddToggle("KillAura", {
    Text = "Kill Aura",
    Default = false,
    Callback = function(Value)
        if Value then
            con1 = rs.Stepped:Connect(function()
                local hrp1 = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not hrp1 then return end
                local nbp = ws:GetPartBoundsInRadius(hrp1.Position, 13)
                for _, part in pairs(nbp) do
                    local model = part:FindFirstAncestorOfClass("Model")
                    if model and isnpc(model) then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        if hum and model ~= lp.Character then hum.Health = 0 end
                    end
                end
            end)
        else
            if con1 then con1:Disconnect(); con1 = nil end
        end
    end
})

ExtraTogglesGroup:AddToggle("JumpAura", {
    Text = "Jump Aura",
    Default = false,
    Callback = function(Value)
        if Value then
            con2 = rs.Stepped:Connect(function()
                local hrp1 = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
                if not hrp1 then return end
                local nbp = ws:GetPartBoundsInRadius(hrp1.Position, 13)
                for _, part in pairs(nbp) do
                    local model = part:FindFirstAncestorOfClass("Model")
                    if model and isnpc(model) then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        if hum and model ~= lp.Character then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                    end
                end
            end)
        else
            if con2 then con2:Disconnect(); con2 = nil end
        end
    end
})

-- ==========================================
-- ВКЛАДКА SETTINGS (КЕЙБИНДЫ И УПРАВЛЕНИЕ UI)
-- ==========================================

KeybindsGroup:AddLabel("Control NPC"):AddKeyPicker("Bind_ControlNPC", {
    Default = "C",
    Mode = "Toggle",
    NoUI = false,
    Text = "Control NPC",
    Callback = function() pcall(actionToggleControl) end
})

KeybindsGroup:AddLabel("Teleport to Mouse"):AddKeyPicker("Bind_TPMouse", {
    Default = "Z",
    Mode = "Toggle",
    NoUI = false,
    Text = "Teleport to Mouse",
    Callback = function() pcall(actionToggleTeleportToMouse) end
})

KeybindsGroup:AddLabel("Fly"):AddKeyPicker("Bind_Fly", {
    Default = "F",
    Mode = "Toggle",
    NoUI = false,
    Text = "Fly",
    Callback = function() pcall(actionFly) end
})

KeybindsGroup:AddLabel("TPWalk 2"):AddKeyPicker("Bind_TPWalk", {
    Default = "R",
    Mode = "Toggle",
    NoUI = false,
    Text = "TPWalk 2",
    Callback = function() pcall(actionTPWalk) end
})

KeybindsGroup:AddLabel("Bring NPC"):AddKeyPicker("Bind_BringNPC", {
    Default = "B",
    Mode = "Press",
    NoUI = false,
    Text = "Bring NPC"
})

KeybindsGroup:AddLabel("Punish NPC"):AddKeyPicker("Bind_PunishNPC", {
    Default = "P",
    Mode = "Press",
    NoUI = false,
    Text = "Punish NPC"
})

KeybindsGroup:AddLabel("Kill All NPCs"):AddKeyPicker("Bind_KillAll", {
    Default = "G",
    Mode = "Press",
    NoUI = false,
    Text = "Kill All NPCs"
})

KeybindsGroup:AddLabel("Steal Tool"):AddKeyPicker("Bind_StealTool", {
    Default = "T",
    Mode = "Press",
    NoUI = false,
    Text = "Steal Tool"
})

KeybindsGroup:AddLabel("Highlight NPCs"):AddKeyPicker("Bind_HighlightNPCs", {
    Default = "X",
    Mode = "Press",
    NoUI = false,
    Text = "Highlight NPCs"
})

KeybindsGroup:AddLabel("Aggro Selected NPC"):AddKeyPicker("Bind_AggroNPC", {
    Default = "V",
    Mode = "Press",
    NoUI = false,
    Text = "Aggro Selected NPC"
})

KeybindsGroup:AddLabel("Toggle Menu"):AddKeyPicker("Bind_MenuToggle", {
    Default = "RightShift",
    Mode = "Toggle",
    NoUI = true,
    Text = "Toggle Menu"
})

Library.ToggleKeybind = Options.Bind_MenuToggle

-- Нативная обработка удержания для кнопок в режиме Press
rs.Heartbeat:Connect(function()
    if uis:GetFocusedTextBox() then return end
    
    if Options.Bind_BringNPC and Options.Bind_BringNPC.Value and uis:IsKeyDown(Enum.KeyCode[Options.Bind_BringNPC.Value]) then
        pcall(actionBring)
    end
    if Options.Bind_PunishNPC and Options.Bind_PunishNPC.Value and uis:IsKeyDown(Enum.KeyCode[Options.Bind_PunishNPC.Value]) then
        pcall(actionPunish)
    end
    if Options.Bind_KillAll and Options.Bind_KillAll.Value and uis:IsKeyDown(Enum.KeyCode[Options.Bind_KillAll.Value]) then
        pcall(actionKillAll)
    end
    if Options.Bind_StealTool and Options.Bind_StealTool.Value and uis:IsKeyDown(Enum.KeyCode[Options.Bind_StealTool.Value]) then
        pcall(actionSteal)
    end
    if Options.Bind_HighlightNPCs and Options.Bind_HighlightNPCs.Value and uis:IsKeyDown(Enum.KeyCode[Options.Bind_HighlightNPCs.Value]) then
        pcall(actionHighlightControllableNPCs)
    end
    if Options.Bind_AggroNPC and Options.Bind_AggroNPC.Value and uis:IsKeyDown(Enum.KeyCode[Options.Bind_AggroNPC.Value]) then
        pcall(actionAggroNPC)
    end
end)

-- Дополнительные элементы управления UI из документации Obsidian
UIManagementGroup:AddToggle("KeybindsOverlayToggle", {
    Text = "Show Keybind Menu Overlay",
    Default = true,
    Callback = function(State)
        if Library.KeybindFrame then
            Library.KeybindFrame.Visible = State
        end
    end
})

UIManagementGroup:AddButton({
    Text = "Unload UI",
    Func = function()
        Library:Unload()
    end
})

-- Инициализация ThemeManager и SaveManager из документации Obsidian
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder("CarmoNPCPanel")
SaveManager:SetFolder("CarmoNPCPanel/configs")
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)
SaveManager:LoadAutoloadConfig()

-- ==========================================
-- ВЫБОР NPC МЫШКОЙ И СИМУЛЯЦИЯ
-- ==========================================

mouse.Button1Down:Connect(function()
    if clicknpc and mouse.Target and mouse.Target.Parent and mouse.Target.Parent:FindFirstChild("HumanoidRootPart") then
        local targetModel = mouse.Target.Parent
        local hrp = targetModel:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Anchored == false then
            if not plrs:GetPlayerFromCharacter(targetModel) then
                if partowner(hrp) then
                    currentnpc = targetModel
                    light(currentnpc, Color3.fromRGB(0, 150, 255))
                else
                    light(targetModel, Color3.fromRGB(255, 0, 0))
                end
            end
        else
            light(targetModel, Color3.fromRGB(255, 0, 0))
        end
    end
end)

rs.RenderStepped:Connect(function()
    if sethiddenproperty then
        sethiddenproperty(lp, "SimulationRadius", rad)
    else
        lp.SimulationRadius = rad
    end
end)
