--1. rules: it is forbidden to change the credit name, this script was created by @carmo you will be charged dcma for changing the credit
--2. rules: changing the code using AI and claiming it as your own is not allowed

if carmonpcpanel then return end; carmonpcpanel = true

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

local Connections = {}
local ScreenGui
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
		pcall(function() setsimulationradius(inf) end)
	end

	if NPCRootPart then
		local offset = 6 -- Единое значение смещения под NPC
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
-- ФУНКЦИОНАЛ ДЕЙСТВИЙ С NPC
-- ==========================================

local function actionKill()
    if currentnpc then
        local hum = currentnpc:FindFirstChildOfClass("Humanoid")
        if hum then hum.Health = 0 end
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

-- Функция поиска ближайшего игрока к заданной позиции или объекту
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
    -- Если других игроков нет, возвращаем локального игрока
    if not closestPlayer and lp.Character then
        return lp
    end
    return closestPlayer
end

-- 1. Функция Агра выбранного NPC на ближайшего игрока
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

-- 2. Функция Агра ВСЕХ ближайших NPC (в радиусе 50 студов) на ближайшего игрока
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
        for _, hl in ipairs(activeHighlighters) --[[@as any]] do
            hl:Destroy()
        end

        isHighlightingNPCs = false
    end)
end

-- ==========================================
-- ИНИЦИАЛИЗАЦИЯ RAYFIELD UI
-- ==========================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Carmo NPC Panel",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("main", 4483362458)
local ExtraTab = Window:CreateTab("extra", 4483362458)
local SettingsTab = Window:CreateTab("settings", 4483362458)

local MainSection = MainTab:CreateSection("main")
local ExtraSection = ExtraTab:CreateSection("extra & toggles")
local SettingsSection = SettingsTab:CreateSection("appearance & keybinds")

-- ==========================================
-- КАСТОМНЫЕ КНОПКИ И ИКОНКА
-- ==========================================

local ScreenGuiRay = coreGui:FindFirstChild("Rayfield")
if ScreenGuiRay then
    local mainFrame = ScreenGuiRay:FindFirstChild("Main")
    if mainFrame then
        
        local closeBtn = Instance.new("TextButton")
        closeBtn.Name = "CloseButton"
        closeBtn.Size = UDim2.new(0, 28, 0, 28)
        closeBtn.Position = UDim2.new(1, -35, 0, 10)
        closeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "✕"
        closeBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
        closeBtn.TextSize = 14
        closeBtn.Font = Enum.Font.SourceSansBold
        closeBtn.Parent = mainFrame

        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 6)
        closeCorner.Parent = closeBtn
        
        closeBtn.MouseButton1Click:Connect(function()
            Rayfield:Destroy()
            if KeybindGui then KeybindGui:Destroy() end
            local foundIcon = coreGui:FindFirstChild("CarmoMinimizedIcon")
            if foundIcon then foundIcon:Destroy() end
        end)

        local iconGui = Instance.new("ScreenGui")
        iconGui.Name = "CarmoMinimizedIcon"
        iconGui.Parent = coreGui
        iconGui.Enabled = false

        local iconButton = Instance.new("ImageButton")
        iconButton.Size = UDim2.new(0, 55, 0, 55)
        iconButton.Position = UDim2.new(0, 20, 0, 120)
        iconButton.BackgroundTransparency = 1
        iconButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        iconButton.Image = "rbxassetid://10734341457"
        iconButton.ScaleType = Enum.ScaleType.Fit
        iconButton.Active = true
        iconButton.Draggable = true
        iconButton.Parent = iconGui

        local minimizeBtn = Instance.new("TextButton")
        minimizeBtn.Name = "MinimizeButton"
        minimizeBtn.Size = UDim2.new(0, 28, 0, 28)
        minimizeBtn.Position = UDim2.new(1, -70, 0, 10)
        minimizeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        minimizeBtn.BorderSizePixel = 0
        minimizeBtn.Text = "-"
        minimizeBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
        minimizeBtn.TextSize = 18
        minimizeBtn.Font = Enum.Font.SourceSansBold
        minimizeBtn.Parent = mainFrame

        local minCorner = Instance.new("UICorner")
        minCorner.CornerRadius = UDim.new(0, 6)
        minCorner.Parent = minimizeBtn

        minimizeBtn.MouseButton1Click:Connect(function()
            mainFrame.Visible = false
            iconGui.Enabled = true
        end)

        iconButton.MouseButton1Click:Connect(function()
            iconGui.Enabled = false
            mainFrame.Visible = true
        end)
    end
end

-- ==========================================
-- ПАНЕЛЬ КЕЙБИНДОВ НА ЭКРАНЕ
-- ==========================================
local KeybindGui = Instance.new("ScreenGui")
KeybindGui.Name = "CarmoKeybindsGui"
KeybindGui.Parent = coreGui
KeybindGui.Enabled = false

local KeybindFrame = Instance.new("Frame")
KeybindFrame.Size = UDim2.new(0, 220, 0, 245)
KeybindFrame.Position = UDim2.new(0, 20, 0, 150)
KeybindFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
KeybindFrame.BorderSizePixel = 0
KeybindFrame.Parent = KeybindGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = KeybindFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(75, 150, 255)
UIStroke.Thickness = 2
UIStroke.Parent = KeybindFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, 0, 0, 30)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "ACTIVE KEYBINDS"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.Parent = KeybindFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = KeybindFrame

local function createKeybindInfo(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 24)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.TextSize = 13
    lbl.Font = Enum.Font.SourceSans
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = KeybindFrame
end

createKeybindInfo("• Control NPC: C")
createKeybindInfo("• Teleport to Mouse: Z")
createKeybindInfo("• Bring NPC: B")
createKeybindInfo("• Punish NPC: P")
createKeybindInfo("• Steal Tool: T")
createKeybindInfo("• Highlight NPCs: X")
createKeybindInfo("• Aggro Selected NPC: V")

-- ==========================================
-- ВКЛАДКА MAIN
-- ==========================================

MainTab:CreateButton({
    Name = "kill npc",
    Callback = function(...) pcall(actionKill) end,
})

MainTab:CreateButton({
    Name = "bring npc",
    Callback = function(...) pcall(actionBring) end,
})

MainTab:CreateButton({
    Name = "goto npc",
    Callback = function(...) pcall(actionGoto) end,
})

MainTab:CreateButton({
    Name = "aggro selected npc",
    Callback = function(...) pcall(actionAggroNPC) end,
})

MainTab:CreateToggle({
    Name = "control npc",
    CurrentValue = false,
    Flag = "ControlNPCToggle",
    Callback = function(a)
        if a then
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
    end,
})

MainTab:CreateButton({
    Name = "punish npc",
    Callback = function(...) pcall(actionPunish) end,
})

MainTab:CreateButton({
    Name = "npc sit state",
    Callback = function(...) pcall(actionSit) end,
})

MainTab:CreateButton({
    Name = "npc jump state",
    Callback = function(...) pcall(actionJump) end,
})

local followCon
MainTab:CreateToggle({
    Name = "following npc",
    CurrentValue = false,
    Flag = "FollowingNPCToggle",
    Callback = function(a)
        if a then
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
    end,
})

local lookMouseCon
MainTab:CreateToggle({
    Name = "Look at Mouse",
    CurrentValue = false,
    Flag = "LookAtMouseToggle",
    Callback = function(a)
        if a then
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
    end,
})

MainTab:CreateButton({
    Name = "Steal Tool",
    Callback = function(...) pcall(actionSteal) end,
})

MainTab:CreateToggle({
    Name = "Teleport to Mouse",
    CurrentValue = false,
    Flag = "TeleportToMouseToggle",
    Callback = function(a)
        if a then
            if not IsTeleportingToMouse then
                actionToggleTeleportToMouse()
            end
        else
            if IsTeleportingToMouse then
                actionToggleTeleportToMouse()
            end
        end
    end,
})

-- ==========================================
-- ВКЛАДКА EXTRA
-- ==========================================

ExtraTab:CreateButton({
    Name = "bring all npcs",
    Callback = function(...) pcall(actionBringAll) end,
})

ExtraTab:CreateButton({
    Name = "aggro all nearby npcs",
    Callback = function(...) pcall(actionAggroAllNPCs) end,
})

ExtraTab:CreateToggle({
    Name = "disable click to control npc",
    CurrentValue = false,
    Flag = "DisableClickControlToggle",
    Callback = function(v)
        clicknpc = not v
    end,
})

local netOwnerCon
ExtraTab:CreateToggle({
    Name = "show network ownership of npc with your network ownership",
    CurrentValue = false,
    Flag = "NetworkOwnerToggle",
    Callback = function(a)
        if a then
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
    end,
})

local con1, con2
ExtraTab:CreateToggle({
    Name = "kill aura any npc",
    CurrentValue = false,
    Flag = "KillAuraToggle",
    Callback = function(a)
        if a then
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
    end,
})

ExtraTab:CreateToggle({
    Name = "jump aura any npc",
    CurrentValue = false,
    Flag = "JumpAuraToggle",
    Callback = function(a)
        if a then
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
    end,
})

-- ==========================================
-- ВКЛАДКА SETTINGS
-- ==========================================

SettingsTab:CreateSection("Theme Color & Background")

SettingsTab:CreateColorPicker({
    Name = "UI Accent Color",
    Color = Color3.fromRGB(75, 150, 255),
    Flag = "UIThemeColor",
    Callback = function(Value)
        if not Value then return end
        pcall(function()
            for _, gui in ipairs(coreGui:GetDescendants()) do
                if gui:IsA("UIStroke") then
                    gui.Color = Value
                elseif gui:IsA("TextLabel") and gui.TextColor3 ~= Color3.fromRGB(255, 255, 255) and gui.TextColor3 ~= Color3.fromRGB(240, 240, 240) then
                    if gui.Parent and (gui.Parent.Name == "Title" or gui.Parent.Name == "TabButton" or gui.Parent.Name:lower():find("selected")) then
                        gui.TextColor3 = Value
                    end
                elseif gui:IsA("Frame") and (gui.Name == "Selected" or gui.Name == "Indicator" or gui.Name == "Bar" or gui.Name == "Active") then
                    gui.BackgroundColor3 = Value
                end
            end
        end)
    end
})

SettingsTab:CreateInput({
    Name = "Background Decal ID",
    PlaceholderText = "Enter Decal ID or URL",
    RemoveTextAfterFocusLost = false,
    Flag = "BackgroundDecalInput",
    Callback = function(Text)
        pcall(function()
            local assetId = tonumber(Text) or Text
            if type(assetId) == "number" then
                assetId = "rbxassetid://" .. tostring(assetId)
            end
            Window.Background = assetId
        end)
    end,
})

SettingsTab:CreateSection("HUD & Visuals")

SettingsTab:CreateToggle({
    Name = "Show Keybinds Overlay on Screen",
    CurrentValue = false,
    Flag = "ShowKeybindsOverlayToggle",
    Callback = function(State)
        KeybindGui.Enabled = State
    end,
})

SettingsTab:CreateSection("All Functions Keybinds")

SettingsTab:CreateKeybind({
    Name = "Control NPC",
    CurrentKeybind = "C",
    HoldToInteract = false,
    Flag = "ControlNPCKeybind",
    Callback = function(...)
        pcall(actionToggleControl)
    end,
})

SettingsTab:CreateKeybind({
    Name = "Teleport to Mouse",
    CurrentKeybind = "Z",
    HoldToInteract = false,
    Flag = "TeleportToMouseKeybind",
    Callback = function(...)
        pcall(actionToggleTeleportToMouse)
    end,
})

SettingsTab:CreateKeybind({
    Name = "Bring NPC",
    CurrentKeybind = "B",
    HoldToInteract = false,
    Flag = "BringNPCKeybind",
    Callback = function(...)
        pcall(actionBring)
    end,
})

SettingsTab:CreateKeybind({
    Name = "Punish NPC",
    CurrentKeybind = "P",
    HoldToInteract = false,
    Flag = "PunishNPCKeybind",
    Callback = function(...)
        pcall(actionPunish)
    end,
})

SettingsTab:CreateKeybind({
    Name = "Steal Tool",
    CurrentKeybind = "T",
    HoldToInteract = false,
    Flag = "StealToolKeybind",
    Callback = function(...)
        pcall(actionSteal)
    end,
})

SettingsTab:CreateKeybind({
    Name = "Highlight Controllable NPCs",
    CurrentKeybind = "X",
    HoldToInteract = false,
    Flag = "HighlightNPCsKeybind",
    Callback = function(...)
        pcall(actionHighlightControllableNPCs)
    end,
})

SettingsTab:CreateKeybind({
    Name = "Aggro Selected NPC",
    CurrentKeybind = "V",
    HoldToInteract = false,
    Flag = "AggroNPCKeybind",
    Callback = function(...)
        pcall(actionAggroNPC)
    end,
})

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
