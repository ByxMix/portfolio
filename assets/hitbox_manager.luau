--!native
--!optimize 2

--< Services

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(script.Config)
local HitboxManager = {}

--< Types

type Hitbox = Part
type Proxy = Part

export type HitboxQuerySettings = {
	Type: "Raycast" | "Box" | "Magnitude",
	timeOffsetMs: number?,
	Tag: string?,

	--Box
	CFrame: CFrame?,
	Size: Vector3?,

	--Raycast
	Origin: Vector3?,
	Direction: Vector3?,

	--Magnitude
	Radius: number?,
	AngleOrigin: Vector3,
	Angle: number?,
}

type Snapshot = {
	Hitboxes: { Hitbox },
	CFrames: { CFrame },
	indexMap: { [Hitbox]: number },
}

--< Values

local registeredHitboxes: { Hitbox } = {}
local registeredHitboxMap: { [Hitbox]: number } = {}

local hitboxSnapshots: { [number]: Snapshot } = {}
local hitboxProxyPool: { [Hitbox]: Proxy } = {}
local proxyHitboxMap: { [Proxy]: Hitbox } = {}
local hitboxFunctions: { [string]: ({ any }, { Instance }) -> { BasePart? } } = {}

local UPDATE_INTERVAL_MS = Config.UPDATES_INTERVAL
local MAX_SNAPSHOT_AGE_MS = Config.MAX_SNAPSHOT_AGE_MS
local UPDATE_WAIT_SECONDS = UPDATE_INTERVAL_MS / 1000
local PROXY_HITBOX_OFFSET = Config.PROXY_HITBOX_OFFSET

local lastUpdate = (DateTime.now().UnixTimestampMillis // UPDATE_INTERVAL_MS) * UPDATE_INTERVAL_MS

local collisionParams = RaycastParams.new()
collisionParams.FilterType = Enum.RaycastFilterType.Exclude
collisionParams.RespectCanCollide = true

--< Functions

local function createPart()
	local Part = Instance.new("Part")
	Part.Anchored = true
	Part.Transparency = 0.8
	Part.Color = RunService:IsClient() and Color3.new(0, 0.666667, 1) or Color3.new(0.666667, 1, 0.498039)
	Part.Parent = workspace
	Part.CanCollide = false
	Part.CanQuery = false
	Part.CanTouch = false

	return Part
end

function hitboxFunctions.Raycast(Settings, proxyMap)
	local results = {}

	local origin = Settings.Origin or Vector3.new()
	local direction = Settings.Direction or Vector3.new(0, 0, -1)

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = proxyMap

	while true do
		local raycastResult = workspace:Raycast(origin, direction, raycastParams)

		if not raycastResult then
			break
		end

		local hitProxy = raycastResult.Instance :: Proxy
		if hitProxy then
			local hitbox = proxyHitboxMap[hitProxy] :: Hitbox
			if hitbox then
				table.insert(results, hitProxy)
			end

			hitProxy.Position = PROXY_HITBOX_OFFSET
		else
			break
		end
	end

	return results
end

function hitboxFunctions.Box(Settings, proxyMap)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = proxyMap

	local Size = Settings.Size * (RunService:IsServer() and (1 + (Settings.timeOffsetMs / 1000)) or 1)
	local results = workspace:GetPartBoundsInBox(Settings.CFrame, Size, overlapParams)

	local part = createPart()
	part.CFrame = Settings.CFrame
	part.Size = Size

	local Time = #results ~= 0 and 5 or 1
	TweenService:Create(part, TweenInfo.new(Time), { Transparency = 1 }):Play()

	task.delay(Time, function()
		part:Destroy()
	end)

	return results
end

function hitboxFunctions.Magnitude(Settings, proxyMap)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = proxyMap

	local Radius = Settings.Radius * (RunService:IsServer() and (1 + (Settings.timeOffsetMs / 1000)) or 1)
	local origin = Settings.Origin.Position

	local results = workspace:GetPartBoundsInRadius(Settings.CFrame.Position, Radius, overlapParams)

	if Settings.Direction then
		local forward = Settings.Direction.Unit

		for i = #results, 1, -1 do
			local proxyPart = results[i]
			local toTarget = (proxyPart.Position - origin).Unit

			local angle = forward:Angle(toTarget)

			if angle > Settings.Angle then
				table.remove(results, i)
			end
		end
	end

	return results
end

---------------------------------------------------------

local function isGrounded(part: BasePart): boolean
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { part }
	rayParams.RespectCanCollide = true

	return not not workspace:Raycast(part.Position, -Vector3.yAxis * Config.IS_GROUNDED_DISTANCE, rayParams)
end

local function updateHitboxMap()
	local nowMs = DateTime.now().UnixTimestampMillis
	local nowUpdate = (nowMs // UPDATE_INTERVAL_MS) * UPDATE_INTERVAL_MS

	if nowUpdate ~= lastUpdate then
		for indexMs = lastUpdate + UPDATE_INTERVAL_MS, nowUpdate, UPDATE_INTERVAL_MS do
			local indexBefore = ((indexMs - MAX_SNAPSHOT_AGE_MS) // UPDATE_INTERVAL_MS) * UPDATE_INTERVAL_MS
			local snapshotHitboxes = table.clone(registeredHitboxes)
			local snapshotCFrames = table.create(#snapshotHitboxes)
			local indexMap = {}

			for i, hitbox in snapshotHitboxes do
				snapshotCFrames[i] = hitbox.CFrame
				indexMap[hitbox] = i
			end

			hitboxSnapshots[indexMs] = {
				Hitboxes = snapshotHitboxes,
				CFrames = snapshotCFrames,
				indexMap = indexMap,
			}

			hitboxSnapshots[indexBefore] = nil
			hitboxSnapshots[indexBefore - UPDATE_INTERVAL_MS] = nil
		end

		lastUpdate = nowUpdate
	end

	return hitboxSnapshots[nowUpdate]
end

local function createProxyPart(): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Color = RunService:IsClient() and Color3.fromRGB(43, 177, 255) or Color3.fromRGB(0, 184, 100) --can be scrapped
	part.Transparency = 0.5
	part.Parent = workspace
	return part
end

local function getClosestSnapshot(snapshotIndex: number)
	for loopIndex = 0, 3 do
		for i = -UPDATE_INTERVAL_MS * loopIndex, UPDATE_INTERVAL_MS * loopIndex, UPDATE_INTERVAL_MS do
			if hitboxSnapshots[snapshotIndex + i] then
				return hitboxSnapshots[snapshotIndex + i]
			end
		end
	end

	return updateHitboxMap()
end

---------------------------------------------------------

function HitboxManager.RegisterHitbox(hitbox: Part)
	if registeredHitboxMap[hitbox] then
		return
	end

	table.insert(registeredHitboxes, hitbox)
	registeredHitboxMap[hitbox] = #registeredHitboxes

	hitboxProxyPool[hitbox] = createProxyPart()
	hitboxProxyPool[hitbox].Size = hitbox.Size
	hitboxProxyPool[hitbox].Name = `HitboxProxy_{(RunService:IsClient() and "Client" or "Server")}`
	proxyHitboxMap[hitboxProxyPool[hitbox]] = hitbox
end

function HitboxManager.UnregisterHitbox(hitbox: Part)
	local index = registeredHitboxMap[hitbox]
	assert(index, `Failed to find hitbox to be removed in the cache: ({hitbox})`)

	local lastHitbox = registeredHitboxes[#registeredHitboxes]

	registeredHitboxes[index] = lastHitbox
	registeredHitboxMap[lastHitbox] = index

	table.remove(registeredHitboxes)
	registeredHitboxMap[hitbox] = nil

	hitboxProxyPool[hitbox]:Destroy()
	proxyHitboxMap[hitboxProxyPool[hitbox]] = nil
	hitboxProxyPool[hitbox] = nil
end

function HitboxManager.GetRegisteredHitboxes(): { Hitbox }
	return registeredHitboxes
end

---------------------------------------------------------

--[[
Predict the future cframe of a basepart with some pseudo-physics
]]
function HitboxManager.PredictHitboxAtTimestamp(hitbox: BasePart, timeStamp: number): CFrame
	timeStamp = math.max(timeStamp, 0)

	local dt = (timeStamp / Config.ROBLOX_PHYSICS_STEPS)
	local gravity = workspace.Gravity

	local velocity = hitbox.AssemblyLinearVelocity
	local position = hitbox.Position + velocity * dt

	if velocity.Y ~= 0 and not isGrounded(hitbox) then
		position -= Vector3.new(0, 0.5 * gravity * dt * dt, 0)
	end

	collisionParams.FilterDescendantsInstances =
		{ hitbox.Parent ~= workspace and hitbox.Parent or nil, Config.PHYSICS_COLLISIONS_EXCLUDE }
	local direction = (position - hitbox.Position) * 1.5
	local raycast = workspace:Raycast(hitbox.Position, direction, collisionParams)
	if raycast then
		position = position * (Vector3.one - raycast.Normal) + (raycast.Normal * Config.PHYSICS_COLLISION_OFFSET)
	end

	return CFrame.new(position) * hitbox.CFrame.Rotation
end

--Could expand this to support area types in the future

--[[
Get hitboxes at an specific timeframe
]]
function HitboxManager.GetHitboxesInArea(Settings: HitboxQuerySettings): { BasePart }
	Settings.timeOffsetMs = math.clamp(Settings.timeOffsetMs or 0, -MAX_SNAPSHOT_AGE_MS, MAX_SNAPSHOT_AGE_MS)
	local nowMs = DateTime.now().UnixTimestampMillis
	local snapshotIndex = ((nowMs - Settings.timeOffsetMs) // UPDATE_INTERVAL_MS) * UPDATE_INTERVAL_MS
	local proxyMap: { Proxy } = {}

	local snapshot0: Snapshot = hitboxSnapshots[snapshotIndex] or getClosestSnapshot(snapshotIndex)
	local snapshot1: Snapshot = hitboxSnapshots[snapshotIndex - UPDATE_INTERVAL_MS] or snapshot0

	--spatial pre-query to remove unnecesary hitboxes from the check
	local nearbyHitboxes = snapshot0.Hitboxes
	if Settings.Type == "Box" then
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Include
		overlapParams.FilterDescendantsInstances = registeredHitboxes

		nearbyHitboxes = workspace:GetPartBoundsInBox(
			Settings.CFrame,
			Settings.Size + Vector3.one * Settings.timeOffsetMs,
			overlapParams
		)
	end

	for _, hitbox in nearbyHitboxes do
		local index = snapshot0.indexMap[hitbox]
		if not index then
			continue
		end

		local proxy = hitboxProxyPool[hitbox]
		local targetCFrame

		if Settings.timeOffsetMs < 0 then
			targetCFrame = HitboxManager.PredictHitboxAtTimestamp(hitbox, Settings.timeOffsetMs)
		else
			local alpha = (Settings.timeOffsetMs % UPDATE_INTERVAL_MS) / UPDATE_INTERVAL_MS
			targetCFrame = snapshot0.CFrames[index]:Lerp(snapshot1.CFrames[index], alpha)
		end

		proxy.CFrame = targetCFrame
		proxy.Size = hitbox.Size
		table.insert(proxyMap, proxy)
	end

	local Results = hitboxFunctions[Settings.Type](Settings, proxyMap)

	for _, proxy in proxyMap do
		proxy.Position = PROXY_HITBOX_OFFSET
	end

	for i, proxy in Results do
		Results[i] = proxyHitboxMap[proxy]
	end

	if Settings.Tag then
		for i = #Results, 1, -1 do
			if not Results[i]:HasTag(Settings.Tag) then
				table.remove(Results, i)
			end
		end
	end

	return Results
end

--< Main

--Script

RunService:BindToSimulation(updateHitboxMap, Enum.StepFrequency.Hz5)

--End

return HitboxManager
