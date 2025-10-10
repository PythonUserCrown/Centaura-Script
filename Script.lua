local gunSettingsFolder = game:GetService("ReplicatedStorage").TREKModules.GunSettings

for _, gunModule in ipairs(gunSettingsFolder:GetChildren()) do
    if gunModule:IsA("ModuleScript") then
        local m = require(gunModule)
        m.MinFalloffDistance = math.huge
        m.maxFalloffDistance = math.huge
        m.firerate = math.huge
        m.spread = 0
        m.crouchSpread = 0
        m.Recoil = 0
        m.ShellsPerShot = 30
        m.ReloadSpeed = 0
        m.ChargeSpeed = 0
    end
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Estados
local holdingX = false
local holdingShift = false
local togglePeriod = false

-- Config
local forwardOffset = 10       -- distancia frente al jugador
local horizontalRadius = 2000  -- radio horizontal del cilindro
local verticalHeight = 100     -- altura vertical del cilindro
local rotationSpeed = math.rad(45)

-- Datos por jugador
local storedPositions = {}
local rotationAngles = {}
local staticTargets = {}

-- Util
local function isEnemy(p)
	return p ~= LocalPlayer and p.Team ~= LocalPlayer.Team
end

local function anyModeActive()
	return holdingX or togglePeriod
end

local function ensureOriginalStored(player, root)
	if not storedPositions[player] then
		storedPositions[player] = root.CFrame
		rotationAngles[player] = 0
	end
end

local function restoreEnemies()
	for player, cf in pairs(storedPositions) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = cf
		end
	end
	storedPositions = {}
	rotationAngles = {}
	staticTargets = {}
end

-- Funciￃﾳn para borrar "Helmet"
local function removeHelmetsFromPlayer(player)
	if player.Character then
		for _, obj in ipairs(player.Character:GetChildren()) do
			if obj.Name == "Helmet" then
				obj:Destroy()
			end
		end
	end
end

local function removeHelmetsFromAll()
	for _, plr in ipairs(Players:GetPlayers()) do
		removeHelmetsFromPlayer(plr)
	end
end

-- Inicial y conexiones
removeHelmetsFromAll()
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(0.1)
		removeHelmetsFromPlayer(plr)
	end)
end)

-- Loop de borrado cada 1 segundo
task.spawn(function()
	while true do
		removeHelmetsFromAll()
		task.wait(1)
	end
end)

-- Funciￃﾳn para colocar enemigos frente a ti dentro del cilindro
local function pullEnemiesFront(spin, useStaticTargets)
	local myChar = LocalPlayer.Character
	if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end

	local myRoot = myChar.HumanoidRootPart
	local forwardPosition = myRoot.CFrame.Position + myRoot.CFrame.LookVector * forwardOffset

	for _, plr in ipairs(Players:GetPlayers()) do
		if isEnemy(plr) and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local root = plr.Character.HumanoidRootPart

			-- Verificar cilindro: distancia horizontal y diferencia vertical
			local horizontalVector = Vector3.new(root.Position.X - myRoot.Position.X, 0, root.Position.Z - myRoot.Position.Z)
			local horizontalDistance = horizontalVector.Magnitude
			local verticalDistance = math.abs(root.Position.Y - myRoot.Position.Y)

			if horizontalDistance <= horizontalRadius and verticalDistance <= verticalHeight then
				ensureOriginalStored(plr, root)

				local targetPos = forwardPosition
				if useStaticTargets then
					if not staticTargets[plr] then
						staticTargets[plr] = targetPos
					end
					targetPos = staticTargets[plr]
				end

				if spin then
					rotationAngles[plr] = (rotationAngles[plr] or 0) - rotationSpeed
					root.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, rotationAngles[plr], 0)
				else
					root.CFrame = CFrame.new(targetPos)
				end
			end
		end
	end
end

-- Entradas
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.X then
		holdingX = true
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		holdingShift = true
	elseif input.KeyCode == Enum.KeyCode.Period then
		togglePeriod = not togglePeriod
	elseif input.KeyCode == Enum.KeyCode.RightAlt then
		script:Destroy()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.X then
		holdingX = false
		if not anyModeActive() then
			restoreEnemies()
		end
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		holdingShift = false
	end
end)

-- Limpieza si un jugador se va
Players.PlayerRemoving:Connect(function(plr)
	storedPositions[plr] = nil
	rotationAngles[plr] = nil
	staticTargets[plr] = nil
end)

-- Loop de render
RunService.RenderStepped:Connect(function()
	if holdingX then
		pullEnemiesFront(holdingShift, false)
	elseif togglePeriod then
		pullEnemiesFront(false, true)
	end
end)


local StarterGui = game:GetService("StarterGui")

local function showFriendNotification(name)
    StarterGui:SetCore("SendNotification", {
        Title = "Script Executed!",
        Text = name .. "RAPE NIGGERS",
        Duration = 5,            -- segundos
        Button1 = "Yes daddy",      -- opcional
        Callback = function()    -- opcional, se ejecuta si presionan Button1
            print("Usuario cerró la notificación")
        end
    })
end

-- Ejemplo de uso
showFriendNotification("")


-- LocalScript en StarterPlayerScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local highlightColorEnemy = Color3.fromRGB(255, 0, 0)      -- color enemigos
local updateRate = 0.1 -- cada 0,1 segundos

local visuals = {} -- almacena highlight y BillboardGui por jugador

-- Función que asegura que todos los enemigos tengan highlight y GUI
local function updateEnemies()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Team ~= localPlayer.Team then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then

                -- Crear o recrear Highlight
                local highlight = visuals[player] and visuals[player].Highlight
                if not highlight or not highlight.Parent or highlight.Parent ~= character then
                    if highlight then highlight:Destroy() end
                    highlight = Instance.new("Highlight")
                    highlight.Name = "EnemyHighlight"
                    highlight.FillColor = highlightColorEnemy
                    highlight.FillTransparency = 0.7
                    highlight.OutlineColor = Color3.fromRGB(255,50,50)
                    highlight.OutlineTransparency = 0.3
                    highlight.Parent = character

                    if not visuals[player] then visuals[player] = {} end
                    visuals[player].Highlight = highlight
                end

                -- Crear o recrear BillboardGui
                local billboard = visuals[player] and visuals[player].Billboard
                if not billboard or not billboard.Parent or billboard.Parent ~= character.HumanoidRootPart then
                    if billboard then billboard:Destroy() end

                    local humanoidRoot = character.HumanoidRootPart
                    billboard = Instance.new("BillboardGui")
                    billboard.Name = "EnemyInfo"
                    billboard.Size = UDim2.new(0, 100, 0, 30)
                    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = humanoidRoot

                    local textLabel = Instance.new("TextLabel")
                    textLabel.Size = UDim2.new(1,0,1,0)
                    textLabel.BackgroundTransparency = 1
                    textLabel.TextColor3 = Color3.fromRGB(255,255,255)
                    textLabel.TextStrokeTransparency = 0
                    textLabel.Font = Enum.Font.SourceSansBold
                    textLabel.TextScaled = true
                    textLabel.TextSize = 5 -- doble más pequeño
                    textLabel.Parent = billboard

                    visuals[player].Billboard = billboard
                    visuals[player].TextLabel = textLabel
                end

                -- Actualizar texto
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    local distance = (character.HumanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude
                    visuals[player].TextLabel.Text = string.format("HP: %d\nDist: %.1f", humanoid.Health, distance)
                end
            end
        else
            -- Eliminar visuales si es amigo o LocalPlayer
            if visuals[player] then
                if visuals[player].Highlight then visuals[player].Highlight:Destroy() end
                if visuals[player].Billboard then visuals[player].Billboard:Destroy() end
                visuals[player] = nil
            end
        end
    end
end

-- Loop continuo para asegurar que todos los enemigos tengan visuales
while true do
    updateEnemies()
    task.wait(updateRate)
end
