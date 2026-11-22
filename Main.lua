
-- CARD BLINK V2
-- Animation Edition
-- LocalScript: StarterPlayerScripts

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local SPEED = 100
local RANGE = 150

local card
local targetPosition
local flying = false
local pulling = false
local selected = false
local flightConnection

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "CardBlinkV2"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function createButton(name, text, position, color)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = text
    button.Size = UDim2.fromOffset(145, 52)
    button.Position = position
    button.BackgroundColor3 = color
    button.TextColor3 = Color3.new(1,1,1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 15
    button.Parent = gui

    Instance.new("UICorner", button).CornerRadius = UDim.new(0,12)
    return button
end

local throwButton = createButton(
    "ThrowCard",
    "🃏 THROW CARD",
    UDim2.new(1,-165,1,-125),
    Color3.fromRGB(50,80,220)
)

local teleportButton = createButton(
    "Teleport",
    "✨ TELEPORT",
    UDim2.new(1,-165,1,-190),
    Color3.fromRGB(35,175,100)
)

local cancelButton = createButton(
    "Cancel",
    "CANCEL",
    UDim2.new(1,-165,1,-60),
    Color3.fromRGB(180,50,50)
)

local status = Instance.new("TextLabel")
status.Size = UDim2.fromOffset(230,35)
status.Position = UDim2.new(0.5,-115,0,25)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1,1,1)
status.Text = "CARD BLINK READY"
status.Font = Enum.Font.GothamBold
status.TextSize = 16
status.Parent = gui

teleportButton.Visible = false

local function getCharacter()
    local character = player.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if humanoid and root then
        return character, humanoid, root
    end
end

-- Throw animation
local function throwAnimation()
    local character, humanoid = getCharacter()
    if not character then return end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    local arm = character:FindFirstChild("RightUpperArm")
        or character:FindFirstChild("Right Arm")

    if arm then
        local original = arm.CFrame
        local tween = TweenService:Create(
            arm,
            TweenInfo.new(0.15, Enum.EasingStyle.Back),
            {CFrame = original * CFrame.Angles(-1,0,0)}
        )

        tween:Play()
        task.delay(0.2, function()
            if arm.Parent then
                TweenService:Create(
                    arm,
                    TweenInfo.new(0.2),
                    {CFrame = original}
                ):Play()
            end
        end)
    end
end

-- Card creation
local function createCard()
    local part = Instance.new("Part")
    part.Name = "MagicCard"
    part.Size = Vector3.new(0.15,2,1.3)
    part.Color = Color3.fromRGB(240,240,255)
    part.Material = Enum.Material.Neon
    part.Anchored = true
    part.CanCollide = false
    part.Parent = workspace

    local guiCard = Instance.new("SurfaceGui")
    guiCard.Face = Enum.NormalId.Front
    guiCard.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundColor3 = Color3.fromRGB(30,30,70)
    label.Text = "♠"
    label.TextColor3 = Color3.new(1,1,1)
    label.TextScaled = true
    label.Parent = guiCard

    local a0 = Instance.new("Attachment")
    a0.Position = Vector3.new(0,0.8,0)
    a0.Parent = part

    local a1 = Instance.new("Attachment")
    a1.Position = Vector3.new(0,-0.8,0)
    a1.Parent = part

    local trail = Instance.new("Trail")
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Lifetime = 0.35
    trail.Color = ColorSequence.new(
        Color3.fromRGB(80,100,255),
        Color3.fromRGB(200,100,255)
    )
    trail.Parent = part

    return part
end

local function clearCard()
    if flightConnection then
        flightConnection:Disconnect()
        flightConnection = nil
    end

    if card then
        card:Destroy()
        card = nil
    end

    flying = false
    selected = false
    targetPosition = nil
    teleportButton.Visible = false
end

-- Throw card
local function throwCard()
    if flying or pulling then return end

    local character, humanoid, root = getCharacter()
    if not root then return end

    clearCard()
    throwAnimation()

    card = createCard()
    card.CFrame = root.CFrame * CFrame.new(1,1,-3)

    local origin = card.Position
    local direction = camera.CFrame.LookVector
    local distance = 0

    flying = true
    status.Text = "CARD FLYING..."

    flightConnection = RunService.Heartbeat:Connect(function(dt)
        if not card or not card.Parent then
            clearCard()
            return
        end

        local step = SPEED * dt
        distance += step

        if distance >= RANGE then
            status.Text = "CARD RANGE LIMIT"
            clearCard()
            return
        end

        local nextPosition = origin + direction * distance

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {character, card}

        local result = workspace:Raycast(
            card.Position,
            direction * step,
            params
        )

        if result then
            card.Position = result.Position
            card.CFrame = CFrame.lookAt(
                result.Position,
                result.Position + direction
            )

            targetPosition = result.Position
            flying = false
            selected = true

            flightConnection:Disconnect()
            flightConnection = nil

            teleportButton.Visible = true
            status.Text = "CARD HIT! READY TO BLINK"

            return
        end

        card.CFrame =
            CFrame.lookAt(nextPosition, nextPosition + direction)
            * CFrame.Angles(0,0,math.rad(distance * 12))
    end)
end

-- Teleport effect
local function teleport()
    if not selected or not targetPosition or pulling then return end

    local character, humanoid, root = getCharacter()
    if not root then return end

    local destination = targetPosition + Vector3.new(0,3,0)

    if (destination - root.Position).Magnitude > RANGE then
        status.Text = "TARGET TOO FAR"
        return
    end

    pulling = true
    teleportButton.Visible = false
    status.Text = "BLINKING..."

    -- Visual fade
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(100,100,255)
    highlight.OutlineColor = Color3.new(1,1,1)
    highlight.Parent = character

    TweenService:Create(
        highlight,
        TweenInfo.new(0.3),
        {FillTransparency = 0}
    ):Play()

    task.wait(0.25)

    -- Local character movement
    if root.Parent then
        root.CFrame = CFrame.new(destination)
    end

    local burst = Instance.new("Part")
    burst.Shape = Enum.PartType.Ball
    burst.Size = Vector3.new(1,1,1)
    burst.Material = Enum.Material.Neon
    burst.Color = Color3.fromRGB(100,100,255)
    burst.Anchored = true
    burst.CanCollide = false
    burst.Position = destination
    burst.Parent = workspace

    TweenService:Create(
        burst,
        TweenInfo.new(0.35),
        {Size = Vector3.new(9,9,9), Transparency = 1}
    ):Play()

    Debris:AddItem(burst,0.5)
    Debris:AddItem(highlight,0.5)

    clearCard()
    pulling = false
    status.Text = "CARD BLINK COMPLETE!"
end

throwButton.MouseButton1Click:Connect(throwCard)
teleportButton.MouseButton1Click:Connect(teleport)

cancelButton.MouseButton1Click:Connect(function()
    if pulling then return end
    clearCard()
    status.Text = "CARD BLINK CANCELLED"
end)

player.CharacterAdded:Connect(function()
    clearCard()
    pulling = false
end)

