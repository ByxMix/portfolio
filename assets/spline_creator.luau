--!native
--< Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SplineCreator = {}
SplineCreator.__index = SplineCreator

--< Types

export type SplineSettings = {
	Tension: number?,
	Looped: boolean?,
	isLengthBased: boolean?,
	samplingSteps: number?,
	segmentSize: number?,
}

export type Spline = {
	-- Values
	Points: { Vector3 },
	Settings: SplineSettings,
	Looped: boolean,
	Length: number,

	-- Functions
	GetPositionAtAlpha: (self: Spline, alphaOrLength: number) -> Vector3,
	GetCFrameAtAlpha: (self: Spline, alphaOrLength: number) -> CFrame,
	DrawDebug: (self: Spline, samples: number) -> nil,
	RemoveDebug: (self: Spline) -> nil,
	Destroy: (self: Spline) -> nil,
}

export type ModuleType = {
	new: (Points: { Vector3 | Instance | CFrame }, Settings: SplineSettings?) -> Spline,
}

--< Values

local ID = 0

--< Functions

--Basic bernstein function to get the position at a given alpha
local function getBernsteinPosition(p1, p2, p3, p4, t)
	local t2 = t * t
	local t3 = t2 * t

	local b1 = -t3 + 3 * t2 - 3 * t + 1
	local b2 = 3 * t3 - 6 * t2 + 3 * t
	local b3 = -3 * t3 + 3 * t2
	local b4 = t3

	return p1 * b1 + p2 * b2 + p3 * b3 + p4 * b4
end

--Derivative of the getBernsteinPosition function to get the direction at a given alpha
local function getBernsteinTangent(p1, p2, p3, p4, t)
	local t2 = t * t
	local omt = 1 - t -- one minus t
	local omt2 = omt * omt --omt times 2

	local term1 = (p2 - p1) * (3 * omt2)
	local term2 = (p3 - p2) * (6 * omt * t)
	local term3 = (p4 - p3) * (3 * t2)

	return (term1 + term2 + term3).Unit
end

local function createPart(Properties)
	local newPart = Instance.new("Part")
	newPart.Size = Properties.Size or Vector3.one
	newPart.CFrame = Properties.CFrame or CFrame.new()
	newPart.Anchored = true
	newPart.CanCollide = false
	newPart.Material = Enum.Material.Neon
	newPart.Color = Properties.Color or Color3.new(1, 0, 0)
	newPart.Parent = Properties.Parent or workspace
	newPart.Transparency = Properties.Transparency or 0.5
	return newPart
end

----
-- Alpha based curve calculation functions
----

local function getCurveIndexAndT(self, alpha)
	alpha = math.clamp(alpha, 0, 1)

	local totalCurves = #self.bezierCurves

	local curveIndex = math.min(math.floor(alpha * totalCurves) + 1, totalCurves)

	local localT = (alpha == 1) and 1 or (alpha * totalCurves) % 1

	return curveIndex, localT
end

function SplineCreator:_getPositionAlpha(alpha: number)
	alpha = math.clamp(alpha, 0, 1)

	local curveIndex, localT = getCurveIndexAndT(self, alpha)
	local curve = self.bezierCurves[curveIndex]

	return getBernsteinPosition(curve[1], curve[2], curve[3], curve[4], localT)
end

function SplineCreator:_getCFrameAlpha(alpha: number)
	alpha = math.clamp(alpha, 0, 1)

	local curveIndex, localT = getCurveIndexAndT(self, alpha)
	local curve = self.bezierCurves[curveIndex]

	local position = getBernsteinPosition(curve[1], curve[2], curve[3], curve[4], localT)
	local direction = getBernsteinTangent(curve[1], curve[2], curve[3], curve[4], localT)

	return CFrame.lookAt(position, position + direction)
end

----
-- Length-based curve calculation functions
----

local function getLengthSegment(self, distance)
	local alpha = distance / self.Length
	local segmentIndex = (math.floor(alpha * (self.segmentIndex - 1))) + 1

	return self.segmentCache[segmentIndex]
end

function SplineCreator:_getPositionLength(distance)
	distance = math.clamp(distance, 0, self.Length)

	local segment = getLengthSegment(self, distance)
	if not segment then
		return self:_getPositionAlpha(1)
	end

	local localAlpha = (distance - (segment.Position - segment.Length)) / segment.Length
	return segment.Start:Lerp(segment.End, localAlpha)
end

function SplineCreator:_getCFrameLength(distance)
	distance = math.clamp(distance, 0, self.Length)

	local segment = getLengthSegment(self, distance)
	if not segment then
		return self:_getCFrameAlpha(1)
	end

	local localAlpha = (distance - (segment.Position - segment.Length)) / segment.Length

	local position = segment.Start:Lerp(segment.End, localAlpha)
	local direction = (segment.End - segment.Start).Unit

	return CFrame.lookAt(position, position + direction)
end

----

function SplineCreator:GetPositionAtAlpha(alphaOrLength)
	if self.isLengthBased then
		return self:_getPositionLength(alphaOrLength)
	else
		return self:_getPositionAlpha(alphaOrLength)
	end
end

function SplineCreator:GetCFrameAtAlpha(alphaOrLength)
	if self.isLengthBased then
		return self:_getCFrameLength(alphaOrLength)
	else
		return self:_getCFrameAlpha(alphaOrLength)
	end
end

function SplineCreator:DrawDebug(samples: number)
	local debugFolderName = `_DEBUG_SPLINE_{self.ID}`
	local debugFolder = workspace:FindFirstChild(debugFolderName) or Instance.new("Folder")
	debugFolder.Name = debugFolderName
	debugFolder.Parent = workspace
	debugFolder:ClearAllChildren()

	samples = samples or 2500
	local lastPosition = nil

	for i = 0, samples do
		local alpha = (i / samples) * ((self.isLengthBased == false) and 1 or self.Length)
		local position = self:GetPositionAtAlpha(alpha)

		createPart({
			Size = Vector3.new(1, 1, 1),
			CFrame = CFrame.new(position),
			Parent = debugFolder,
		})

		if lastPosition then
			local direction = position - lastPosition
			local dist = direction.Magnitude

			if dist > 0 then
				createPart({
					Size = Vector3.new(0.25, 0.25, dist),
					CFrame = CFrame.lookAt(lastPosition + direction * 0.5, position),
					Parent = debugFolder,
					Color = Color3.new(0, 1, 0),
				})
			end
		end

		createPart({
			Size = Vector3.new(0.5, 0.5, 1),
			CFrame = self:GetCFrameAtAlpha(alpha) * CFrame.new(0, 0, -0.5),
			Parent = debugFolder,
			Color = Color3.new(0, 0, 1),
		})

		lastPosition = position
	end
end

function SplineCreator:RemoveDebug()
	local debugFolderName = `_DEBUG_SPLINE_{self.ID}`
	local debugFolder = workspace:FindFirstChild(debugFolderName)

	if debugFolder then
		debugFolder:Destroy()
	end
end

function SplineCreator:Destroy()
	if self.bezierCurves then
		table.clear(self.bezierCurves)
	end

	if self.Points then
		table.clear(self.Points)
	end

	if self.segmentCache then
		table.clear(self.segmentCache)
	end

	table.clear(self)
	self = nil
end

--< Main

function SplineCreator.new(Points: { Vector3 | Instance | CFrame }, Settings: SplineSettings)
	local self = setmetatable({}, SplineCreator)

	--<< SETTINGS

	self.Points = Points :: { Vector3 }
	self.Settings = Settings or {} :: {}
	self.bezierCurves = {} :: { [number]: { Vector3 } }
	self.Tension = self.Settings.Tension or 1
	self.Looped = (self.Settings.Looped ~= nil) and self.Settings.Looped or false
	self.ID = ID

	--< Length spline settings
	self.samplingSteps = self.Settings.samplingSteps and math.floor(self.Settings.samplingSteps) or 20000
	self.segmentSize = self.Settings.segmentSize and math.floor(self.Settings.segmentSize) or 5
	self.Length = 0

	--<< SETUP

	--< Cleanup points to position
	for i, v in Points do
		if typeof(v) == "Instance" and v:IsA("BasePart") then
			Points[i] = v.Position
		elseif typeof(v) == "CFrame" then
			Points[i] = v.Position
		end
	end

	--< Build bezier curves
	for i = 1, #Points do
		local P_prev = Points[(i - 2) % #Points + 1]
		local P0 = Points[(i - 1) % #Points + 1]
		local P1 = Points[i % #Points + 1]
		local P_next = Points[(i + 1) % #Points + 1]

		local tangent0 = (P1 - P_prev) * (self.Tension / 6)
		local tangent1 = (P_next - P0) * (self.Tension / 6)

		self.bezierCurves[i] = {
			P0,
			P0 + tangent0,
			P1 - tangent1,
			P1,
		}
	end

	-- If spline isnt looped, delete last curve
	if not self.Looped then
		self.bezierCurves[#Points] = nil
	end

	--< If its length based, create cframe cache and build distance cache
	if self.Settings.isLengthBased then
		self.segmentCache = {}
		self.segmentIndex = 0

		local previousPos = self:GetPositionAtAlpha(0)
		local nextPos = previousPos

		for i = 1, self.samplingSteps do
			nextPos = self:GetPositionAtAlpha(i / self.samplingSteps)

			local stepDistance = (nextPos - previousPos).Magnitude

			if (stepDistance >= self.segmentSize) or (i == self.samplingSteps) then
				local cacheDistance = self.segmentIndex
				self.Length += stepDistance
				self.segmentIndex += 1

				self.segmentCache[cacheDistance] = {
					Start = previousPos,
					End = nextPos,
					Length = stepDistance,
					Position = self.Length - stepDistance,
				}

				previousPos = nextPos
			end
		end
	end

	self.isLengthBased = (self.Settings.isLengthBased ~= nil) and self.Settings.isLengthBased or false
	ID += 1

	return self
end

--End

return SplineCreator :: ModuleType
