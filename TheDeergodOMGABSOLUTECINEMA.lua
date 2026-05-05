---====== Services ======---
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Plr = Players.LocalPlayer
local LatestRoom = ReplicatedStorage.GameData.LatestRoom

---====== Config ======---
local validRanges = {
    {27, 33},
    {61, 75},
    {85, 88}
}

local hasSpawned = false
local badgeGiven = false

---====== Helper ======---
local function isValidRoom(room)
    for _, range in ipairs(validRanges) do
        if room >= range[1] and room <= range[2] then
            return true
        end
    end
    return false
end

---====== Main Spawn Logic ======---
LatestRoom.Changed:Connect(function()
    if hasSpawned then return end

    local currentRoom = LatestRoom.Value

    -- ✅ Only allowed rooms
    if not isValidRoom(currentRoom) then return end

    -- ❌ Block during Seek
    if Workspace:FindFirstChild("SeekMoving")
    or Workspace:FindFirstChild("SeekMovingNew")
    or Workspace:FindFirstChild("SeekMovingNewClone") then
        warn("DeerGod prevented: Seek active")
        return
    end

    hasSpawned = true

    wait(0)

    pcall(function()

        ---====== Load spawner ======---
        local spawner = loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/Doors/Entity%20Spawner/V2/Source.lua"))()

        local killConnection

        ---====== Create entity ======---
        local entity = spawner.Create({
            Entity = {
                Name = "DeerGod",
                Asset = "rbxassetid://73026733624298",
                HeightOffset = 0
            },
            Lights = {
                Flicker = { Enabled = true, Duration = 100 },
                Shatter = false,
                Repair = false
            },
            Earthquake = { Enabled = false },
            CameraShake = {
                Enabled = true,
                Range = 200,
                Values = {1.5, 20, 0.1, 1}
            },
            Movement = {
                Speed = 25,
                Delay = 0,
                Reversed = false
            },
            Rebounding = { Enabled = false },
            Damage = {
                Enabled = true,
                Range = 40,
                Amount = 125
            },
            Crucifixion = {
                Enabled = false
            },
            Death = {
                Type = "Guiding",
                Hints = {
                    "You died to DeerGod...",
                    "Closets won't save you.",
                    "Hide behind solid objects.",
                    "Break line of sight!"
                },
                Cause = "DeerGod"
            }
        })

        ---====== LOS Kill Logic ======---
        entity:SetCallback("OnStartMoving", function()
            killConnection = RunService.Heartbeat:Connect(function()
                local char = Plr.Character
                local entModel = entity.Model

                if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart")
                and entModel and entModel.PrimaryPart then

                    local humanoid = char.Humanoid
                    local playerPos = char.HumanoidRootPart.Position
                    local entityPos = entModel.PrimaryPart.Position

                    local distance = (playerPos - entityPos).Magnitude

                    if distance <= 40 then
                        local direction = (playerPos - entityPos)

                        local rayParams = RaycastParams.new()
                        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                        rayParams.FilterDescendantsInstances = {entModel, char}

                        local result = workspace:Raycast(entityPos, direction, rayParams)

                        -- ✅ Only kill if visible
                        if not result or result.Instance:IsDescendantOf(char) then
                            humanoid.Health = 0

                            if ReplicatedStorage:FindFirstChild("GameStats") then
                                ReplicatedStorage.GameStats["Player_"..Plr.Name].Total.DeathCause.Value = "DeerGod"
                            end
                        end
                    end
                end
            end)
        end)

        ---====== Cleanup ======---
        entity:SetCallback("OnDespawning", function()
            if killConnection then
                killConnection:Disconnect()
            end
        end)

        ---====== ✅ FIXED BADGE LOGIC ======---
        entity:SetCallback("OnSpawned", function()
            print("DeerGod spawned")

            if not badgeGiven then
                badgeGiven = true

                local achievementGiver = loadstring(game:HttpGet("https://raw.githubusercontent.com/Voor-Pr00/Achivements/refs/heads/main/Voorpr0"))()

                achievementGiver({
                    Title = "Last chance to look at me.",
                    Desc = "Why are you running?",
                    Reason = "Encounter Deergod.",
                    Image = "rbxassetid://12331751893"
                })
            end
        end)

        ---====== Run ======---
        entity:Run()

    end)
end)
