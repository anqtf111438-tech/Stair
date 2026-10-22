-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer

-- Parent GUI safely (Executor / Studio compatibility)
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

-- Draggable Main Container Frame (Matching your clean style)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainContainer"
mainFrame.Size = UDim2.new(0, 150, 0, 65)
mainFrame.Position = UDim2.new(0.5, -75, 0.75, 0)
mainFrame.BackgroundTransparency = 1
mainFrame.Active = true
mainFrame.Parent = screenGui

-- Mobile & PC Smooth Dragging Implementation
local dragging = false
local dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
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

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Build Stairs Button
local buildBtn = Instance.new("TextButton")
buildBtn.Name = "BuildStairsBtn"
buildBtn.Size = UDim2.new(0, 150, 0, 65)
buildBtn.Position = UDim2.new(0, 0, 0, 0)
buildBtn.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
buildBtn.BackgroundTransparency = 0.2
buildBtn.Text = "Build Stairs"
buildBtn.TextColor3 = Color3.fromRGB(80, 80, 80)
buildBtn.TextSize = 18
buildBtn.Font = Enum.Font.SourceSans
buildBtn.AutoButtonColor = true
buildBtn.Parent = mainFrame

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 4)
corner.Parent = buildBtn

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(160, 160, 160)
stroke.Thickness = 1.5
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = buildBtn

-- Stair Tracking State
local lastStair = nil
local activeStairs = {}
local MAX_STAIRS = 60 -- Keeps the last 60 steps active

-- Click Logic to Spawn / Stack Stairs
buildBtn.MouseButton1Click:Connect(function()
    local character = localPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local stair = Instance.new("Part")
    stair.Name = "StairStep"
    stair.Size = Vector3.new(6, 1, 3)
    stair.Color = Color3.fromRGB(0, 162, 255)
    stair.Material = Enum.Material.Neon
    stair.Transparency = 0.2
    stair.CanCollide = true
    stair.Anchored = true
    stair.Massless = true

    -- Check if player is standing on or near the staircase to stack/extend it
    local isStandingOnStairs = false
    if lastStair and lastStair.Parent then
        local distance = (rootPart.Position - lastStair.Position).Magnitude
        if distance < 18 then
            isStandingOnStairs = true
        end
    end

    local lookDir = Vector3.new(rootPart.CFrame.LookVector.X, 0, rootPart.CFrame.LookVector.Z).Unit
    if lookDir.Magnitude == 0 then lookDir = Vector3.new(0, 0, -1) end

    if isStandingOnStairs and lastStair then
        -- Stack/extend forward and upward from the last stair
        local nextCFrame = lastStair.CFrame + (lookDir * 2.8) + Vector3.new(0, 1.2, 0)
        stair.CFrame = nextCFrame
    else
        -- Initial spawn: 1 stud in front of your feet
        local spawnPos = rootPart.Position + (lookDir * 4) - Vector3.new(0, 2.5, 0)
        stair.CFrame = CFrame.new(spawnPos, spawnPos + lookDir)
    end

    stair.Parent = workspace
    lastStair = stair
    table.insert(activeStairs, stair)

    -- Auto-cleanup oldest stairs if limit is reached
    if #activeStairs > MAX_STAIRS then
        local oldStair = table.remove(activeStairs, 1)
        if oldStair and oldStair.Parent then
            oldStair:Destroy()
        end
    end
end)
