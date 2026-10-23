-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer

-- Parent GUI safely
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaStairsGui"
screenGui.ResetOnSpawn = false

if gethui then
    screenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = CoreGui
else
    pcall(function() screenGui.Parent = CoreGui end)
    if not screenGui.Parent then
        screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    end
end

-- Draggable Main Container Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainContainer"
mainFrame.Size = UDim2.new(0, 185, 0, 65)
mainFrame.Position = UDim2.new(0.5, -92, 0.75, 0)
mainFrame.BackgroundTransparency = 1
mainFrame.Active = true
mainFrame.Parent = screenGui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = mainFrame

-- 1. Build Stairs Button (Purely for tapping/building, never drags)
local buildBtn = Instance.new("TextButton")
buildBtn.Name = "BuildStairsBtn"
buildBtn.Size = UDim2.new(0, 140, 0, 65)
buildBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
buildBtn.BackgroundTransparency = 0.2
buildBtn.Text = "Build Stairs"
buildBtn.TextColor3 = Color3.fromRGB(80, 80, 80)
buildBtn.TextSize = 18
buildBtn.Font = Enum.Font.SourceSans
buildBtn.AutoButtonColor = true
buildBtn.LayoutOrder = 1
buildBtn.Parent = mainFrame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 4)
corner.Parent = buildBtn

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(160, 160, 160)
stroke.Thickness = 1.5
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = buildBtn

-- 2. Tiny Drag Handle (Use this to move the menu around)
local dragHandle = Instance.new("TextButton")
dragHandle.Name = "DragHandle"
dragHandle.Size = UDim2.new(0, 35, 0, 65)
dragHandle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
dragHandle.BackgroundTransparency = 0.2
dragHandle.Text = "::"
dragHandle.TextColor3 = Color3.fromRGB(100, 100, 100)
dragHandle.TextSize = 16
dragHandle.Font = Enum.Font.SourceSansBold
dragHandle.AutoButtonColor = true
dragHandle.LayoutOrder = 2
dragHandle.Parent = mainFrame

local dragCorner = Instance.new("UICorner")
dragCorner.CornerRadius = UDim.new(0, 4)
dragCorner.Parent = dragHandle

local dragStroke = Instance.new("UIStroke")
dragStroke.Color = Color3.fromRGB(150, 150, 150)
dragStroke.Thickness = 1.5
dragStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
dragStroke.Parent = dragHandle

-- Stair Tracking State
local lastStairCFrame = nil
local activeStairs = {}
local MAX_STAIRS = 40

-- Optimized function to create the brick stair step smoothly
local function createStairStep(stepCFrame)
    local stairModel = Instance.new("Model")
    stairModel.Name = "BrickStairUnit"

    local stepWidth = 6
    local stepHeight = 1.2
    local stepDepth = 2.5

    -- 1. Red Central Tread
    local redPart = Instance.new("Part")
    redPart.Size = Vector3.new(stepWidth - 1.5, stepHeight, stepDepth)
    redPart.CFrame = stepCFrame
    redPart.Color = Color3.fromRGB(210, 34, 45)
    redPart.Material = Enum.Material.Plastic
    redPart.CanCollide = true
    redPart.Anchored = true
    redPart.Parent = stairModel

    -- 2. Left Yellow Pillar[span_0](start_span)[span_0](end_span)
    local leftYellow = Instance.new("Part")
    leftYellow.Size = Vector3.new(0.75, stepHeight, stepDepth)
    leftYellow.CFrame = stepCFrame * CFrame.new(-(stepWidth / 2) + 0.375, 0, 0)
    leftYellow.Color = Color3.fromRGB(255, 205, 3)
    leftYellow.Material = Enum.Material.Plastic
    leftYellow.CanCollide = true
    leftYellow.Anchored = true
    leftYellow.Parent = stairModel

    -- 3. Right Yellow Pillar[span_1](start_span)[span_1](end_span)
    local rightYellow = Instance.new("Part")
    rightYellow.Size = Vector3.new(0.75, stepHeight, stepDepth)
    rightYellow.CFrame = stepCFrame * CFrame.new((stepWidth / 2) - 0.375, 0, 0)
    rightYellow.Color = Color3.fromRGB(255, 205, 3)
    rightYellow.Material = Enum.Material.Plastic
    rightYellow.CanCollide = true
    rightYellow.Anchored = true
    rightYellow.Parent = stairModel

    stairModel.Parent = workspace
    return stairModel, stepCFrame
end

-- Build button click event (100% reliable tap)
buildBtn.MouseButton1Click:Connect(function()
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local lookDir = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z).Unit
    if lookDir.Magnitude == 0 then lookDir = Vector3.new(0, 0, -1) end

    local targetCFrame
    local isStacking = false

    if lastStairCFrame then
        local distance = (rootPart.Position - lastStairCFrame.Position).Magnitude
        if distance < 16 then
            isStacking = true
        end
    end

    if isStacking and lastStairCFrame then
        targetCFrame = lastStairCFrame + (lookDir * 2.5) + Vector3.new(0, 1.2, 0)
    else
        local spawnPos = rootPart.Position + (lookDir * 3.5) - Vector3.new(0, 2.5, 0)
        targetCFrame = CFrame.new(spawnPos, spawnPos + lookDir)
    end

    local newStairModel, newCFrame = createStairStep(targetCFrame)
    lastStairCFrame = newCFrame
    table.insert(activeStairs, newStairModel)

    if #activeStairs > MAX_STAIRS then
        local oldStair = table.remove(activeStairs, 1)
        if oldStair then
            oldStair:Destroy()
        end
    end
end)

-- Mobile & PC Dragging Logic attached *only* to the drag handle `::`
local dragging = false
local dragStart, startPos

dragHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)
