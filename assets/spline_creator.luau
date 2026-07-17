--Made by DoYouLikeWafflesOrNo

--!strict
--!native
--!optimize 2

--< Services

local SplineClass = {}
SplineClass.__index = SplineClass

--< Types

type Point = Vector3 | Instance | CFrame | PathWaypoint

type BezierCurve = {
	P0: Vector3,
	P1: Vector3,
	P2: Vector3,
	P3: Vector3,
	Length: number,
}

type DebugProperties = {
	Size: Vector3?,
	CFrame: CFrame?,
	Position: Vector3?,
	Parent: Instance?,
	Color: Color3?,
	Transparency: number?,
	Name: string?,
}

export type SplineSettings = {
	Tension: number?,
	Looped: boolean?,
}

export type Spline = {
	-- Values
	Points: { Vector3 },
	Settings: SplineSettings,
	Looped: boolean,
	Tension: number,
	Length: number,
	ID: number,
	BezierCurves: { BezierCurve },

	-- Functions
	GetPosition: (self: Spline, alpha: number, isLength: boolean?) -> Vector3,
	GetCFrame: (self: Spline, alpha: number, isLength: boolean?) -> CFrame,
	SetPoint: (self: Spline, point: Vector3 | Instance | CFrame, index: number) -> nil,
	InsertPoint: (self: Spline, point: Point, index: number?) -> nil,
	RemovePoint: (self: Spline, index: number) -> nil,
	DrawDebug: (self: Spline, samples: number) -> nil,
	RemoveDebug: (self: Spline) -> nil,
	Destroy: (self: Spline) -> nil,
}

export type SplineClass = {
	new: (Points: { Point }, Settings: SplineSettings?) -> Spline,
}

--< Values

local DEFAULT_DEBUG_SAMPLES = 100
local ID = 0

local EPS = 1e-9

local GL5_X = {
	0,
	-0.5384693101056831,
	0.5384693101056831,
	-0.9061798459386640,
	0.9061798459386640,
}

local GL5_W = {
	0.5688888888888889,
	0.4786286704993665,
	0.4786286704993665,
	0.2369268850561891,
	0.2369268850561891,
}

--< Functions

--Basic bernstein function to get the position at a given alpha
local function getBernsteinPosition(p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3, t: number)
	local t2 = t * t
	local t3 = t2 * t

	local b1 = -t3 + 3 * t2 - 3 * t + 1
	local b2 = 3 * t3 - 6 * t2 + 3 * t
	local b3 = -3 * t3 + 3 * t2
	local b4 = t3

	return p1 * b1 + p2 * b2 + p3 * b3 + p4 * b4
end

--Derivative of the getBernsteinPosition function to get the velocity
local function getBernsteinDerivative(p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3, t: number)
	local t2 = t * t
	local omt = 1 - t -- one minus t
	local omt2 = omt * omt --omt times 2

	local term1 = (p2 - p1) * (3 * omt2)
	local term2 = (p3 - p2) * (6 * omt * t)
	local term3 = (p4 - p3) * (3 * t2)

	return (term1 + term2 + term3)
end

--Second derivative (not used rn)
local function getBernsteinSecondDerivative(p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3, t: number)
	local omt = 1 - t

	local term1 = (p3 - 2 * p2 + p1) * (6 * omt)
	local term2 = (p4 - 2 * p3 + p2) * (6 * t)

	return term1 + term2
end

local function createPart(Properties: DebugProperties, Part: BasePart?): BasePart
	local newPart = Part or Instance.new("Part") :: BasePart
	newPart.Size = Properties.Size or Vector3.one
	newPart.CFrame = Properties.CFrame or (Properties.Position and CFrame.new(Properties.Position) or CFrame.new())
	newPart.Anchored = true
	newPart.CanCollide = false
	newPart.Material = Enum.Material.Neon
	newPart.Color = Properties.Color or Color3.new(1, 0, 0)
	newPart.Parent = Properties.Parent or workspace
	newPart.Transparency = Properties.Transparency or 0.5
	newPart.Name = Properties.Name or "Part"
	return newPart
end

----
-- Alpha based curve calculation functions
----

local function getSpeed(p1, p2, p3, p4, t)
	return getBernsteinDerivative(p1, p2, p3, p4, t).Magnitude
end

--Gets arc length of a curve by using Gauss method
local function getArcLength(p1, p2, p3, p4, a: number, b: number)
	if a == b then
		return 0
	end

	local half = (b - a) * 0.5
	local center = (a + b) * 0.5

	local sum = 0

	for i = 1, #GL5_X do
		local t = center + half * GL5_X[i]
		sum += GL5_W[i] * getSpeed(p1, p2, p3, p4, t)
	end

	return half * sum
end

local function getCurveLength(p1, p2, p3, p4)
	return getArcLength(p1, p2, p3, p4, 0, 1)
end

local function getTAtArcLength(p1, p2, p3, p4, targetLength, totalLength)
	if totalLength <= EPS then
		return 0
	end

	targetLength = math.clamp(targetLength, 0, totalLength)

	--If length is too low then return the start of spline
	if targetLength <= EPS then
		return 0
	end

	--If length is too high then return end of spline
	if math.abs(targetLength - totalLength) <= EPS then
		return 1
	end

	--Approximate t to a point where the distance is close to the localDistance (Newton-Raphson)
	local t = targetLength / totalLength
	local low = 0
	local high = 1

	for _ = 1, 12 do
		--Get the current length an error rate
		local currentLength = getArcLength(p1, p2, p3, p4, 0, t)
		local error = currentLength - targetLength

		--If error is small enough then return the final value
		if math.abs(error) < 1e-5 then
			return math.clamp(t, 0, 1)
		end

		--Adjust new high's an lows
		if error > 0 then
			high = t
		else
			low = t
		end

		--Get derivative magnitude of the curve
		local speed = getSpeed(p1, p2, p3, p4, t)

		--If speed is too low readjust t
		if speed <= EPS then
			t = (low + high) * 0.5
		else
			--If speed is normal then guess t again
			local newT = t - error / speed

			if newT <= low or newT >= high or newT ~= newT then
				t = (low + high) * 0.5
			else
				t = newT
			end
		end
	end

	return math.clamp(t, 0, 1)
end

local function cleanupPoint(point: Vector3 | Instance | CFrame | PathWaypoint)
	if typeof(point) == "Instance" and point:IsA("BasePart") then
		return point.Position
	elseif typeof(point) == "CFrame" then
		return point.Position
	elseif typeof(point) == "Vector3" then
		return point
	elseif typeof(point) == "PathWaypoint" then
		return point.Position
	end

	error(
		`Tried to insert a point in a spline with a type that isn't supported: '{tostring(point)}' ({typeof(point)})`,
		3
	)
end

----
-- Helper functions
---

function SplineClass:_buildCurve(i: number)
	local Points = self.Points :: { Vector3 }
	local Tension = self.Tension :: number

	local P_prev = self.Looped and Points[(i - 2) % #Points + 1] or Points[math.clamp(i - 1, 1, #Points)]
	local P0 = self.Looped and Points[(i - 1) % #Points + 1] or Points[math.clamp(i, 1, #Points)]
	local P1 = self.Looped and Points[i % #Points + 1] or Points[math.clamp(i + 1, 1, #Points)]
	local P_next = self.Looped and Points[(i + 1) % #Points + 1] or Points[math.clamp(i + 2, 1, #Points)]

	local distance = (P1 - P0).Magnitude
	local forwardDir = (P1 - P_prev).Magnitude > 1e-5 and (P1 - P_prev).Unit or Vector3.zero
	local backwardDir = (P_next - P0).Magnitude > 1e-5 and (P_next - P0).Unit or Vector3.zero
	local distanceTension = distance * (Tension / 3)

	local tangent0 = forwardDir * distanceTension
	local tangent1 = backwardDir * distanceTension

	local p0 = P0
	local p1 = P0 + tangent0
	local p2 = P1 - tangent1
	local p3 = P1

	local curveLength = getCurveLength(p0, p1, p2, p3) :: number

	local curve: BezierCurve = {
		P0 = p0,
		P1 = p1,
		P2 = p2,
		P3 = p3,
		Length = curveLength,
	}

	self.BezierCurves[i] = curve
	return curve
end

function SplineClass:_rebuildPoints(index: number, add: number)
	self = self :: Spline
	local rebuilt = {}

	for i = index - (2 + add), index + 1 do
		local curveIndex = i % #self.Points + 1
		local curve = self.BezierCurves[curveIndex] :: BezierCurve

		if rebuilt[curveIndex] then
			continue
		else
			rebuilt[curveIndex] = true
		end

		if curve then
			self.Length -= curve.Length --roblox typecheck sucks so much
		end

		SplineClass._buildCurve(self, curveIndex)

		self.Length += self.BezierCurves[curveIndex].Length
	end

	if not self.Looped and self.BezierCurves[#self.Points] then
		self.Length -= self.BezierCurves[#self.Points].Length
		self.BezierCurves[#self.Points] = nil
	end
end

function SplineClass:_getCurveLocalT(targetDistance: number)
	local accumulatedDistance = 0

	if self.Length <= EPS then
		local curve = self.BezierCurves[1]
		return 0, curve
	end

	--TODO: Transform this into binary search (maybe?)
	for _, curve in self.BezierCurves do
		local curveLength = curve.Length
		local nextDistance = accumulatedDistance + curveLength

		if targetDistance <= nextDistance then
			local localDistance = targetDistance - accumulatedDistance

			local localT = getTAtArcLength(curve.P0, curve.P1, curve.P2, curve.P3, localDistance, curveLength)

			return localT, curve
		end

		accumulatedDistance = nextDistance
	end

	local curve = self.BezierCurves[#self.BezierCurves]
	return 1, curve
end

----
-- Main functions
----

function SplineClass:GetPosition(_alpha, _isLength)
	local alpha = _alpha or 0
	local isLength = _isLength or false

	assert(
		type(alpha) == "number",
		`Tried to get position with an invalid alpha type: {tostring(alpha)} ({type(alpha)})`
	)
	assert(
		type(isLength) == "boolean",
		`Tried to get position with an invalid isLength type: {tostring(isLength)} ({type(isLength)})`
	)

	local targetDistance

	if isLength then
		alpha = math.clamp(alpha, 0, self.Length)
		targetDistance = alpha
	else
		alpha = math.clamp(alpha, 0, 1)
		targetDistance = alpha * self.Length
	end

	local localT, curve = self._getCurveLocalT(self, targetDistance)

	if not curve then
		return self.Points[1] or Vector3.zero
	end

	local position = getBernsteinPosition(curve.P0, curve.P1, curve.P2, curve.P3, localT)

	return position
end

function SplineClass:GetCFrame(_alpha, _isLength)
	local alpha = _alpha or 0
	local isLength = _isLength or false

	assert(
		type(alpha) == "number",
		`Tried to get position with an invalid alpha type: {tostring(alpha)} ({type(alpha)})`
	)
	assert(
		type(isLength) == "boolean",
		`Tried to get position with an invalid isLength type: {tostring(isLength)} ({type(isLength)})`
	)

	local targetDistance

	if isLength then
		alpha = math.clamp(alpha, 0, self.Length)
		targetDistance = alpha
	else
		alpha = math.clamp(alpha, 0, 1)
		targetDistance = alpha * self.Length
	end

	local localT, curve = self._getCurveLocalT(self, targetDistance)

	if not curve then
		return CFrame.new(self.Points[1] or Vector3.zero)
	end

	local position = getBernsteinPosition(curve.P0, curve.P1, curve.P2, curve.P3, localT)

	local derivative = getBernsteinDerivative(curve.P0, curve.P1, curve.P2, curve.P3, localT)

	local direction = derivative.Unit

	return CFrame.lookAt(position, position + direction, -Vector3.yAxis)
end

function SplineClass:DrawDebug(_samples: number?)
	_samples = _samples or DEFAULT_DEBUG_SAMPLES
	assert(
		type(_samples) == "number",
		`Tried to draw spline visual debug with an invalid sample type: {tostring(_samples)} ({type(_samples)})`
	)

	local DebugDrawData = {
		Parts = {},
		CFrames = {},
	}

	local debugFolderName = `_DEBUG_SPLINE_{self.ID}`
	local debugFolder = workspace:FindFirstChild(debugFolderName) or Instance.new("Folder")
	debugFolder.Name = debugFolderName
	debugFolder.Parent = workspace

	local samples = _samples or DEFAULT_DEBUG_SAMPLES :: number
	local lastPosition = nil :: Vector3?

	if #debugFolder:GetChildren() // 2 ~= samples then -- 2 is amount of parts per sample
		debugFolder:ClearAllChildren()
	end

	for i = 0, samples do
		local alpha = i / samples
		local position = self:GetPosition(alpha) :: Vector3
		local cframe = self:GetCFrame(alpha) :: CFrame

		local _samplePart = debugFolder:FindFirstChild(`{i}_main`) :: BasePart?
		local samplePart = createPart({
			Size = Vector3.new(1, 1, 1),
			Parent = debugFolder,
			Name = `{i}_main`,
		}, _samplePart)
		table.insert(DebugDrawData.Parts, samplePart)
		table.insert(DebugDrawData.CFrames, CFrame.new(position))

		if lastPosition then
			local direction = position - lastPosition
			local dist = direction.Magnitude

			if dist > 0 then
				local _lengthPart = debugFolder:FindFirstChild(`{i}_length`) :: BasePart?
				local lengthPart = createPart({
					Size = Vector3.new(0.25, 0.25, dist),
					Parent = debugFolder,
					Color = Color3.new(0, 1, 0),
					Name = `{i}_length`,
				}, _lengthPart)
				table.insert(DebugDrawData.Parts, lengthPart)
				table.insert(DebugDrawData.CFrames, CFrame.lookAt(lastPosition + direction * 0.5, position))
			end
		end

		lastPosition = position
	end

	workspace:BulkMoveTo(DebugDrawData.Parts, DebugDrawData.CFrames, Enum.BulkMoveMode.FireCFrameChanged)
end

function SplineClass:RemoveDebug()
	local debugFolderName = `_DEBUG_SPLINE_{self.ID}`
	local debugFolder = workspace:FindFirstChild(debugFolderName)

	if debugFolder then
		debugFolder:Destroy()
	end
end

function SplineClass:SetPoint(_point: Vector3 | Instance | CFrame, _index: number)
	assert(
		type(_index) == "number",
		`Tried to set a point with an invalid index type: {tostring(_index)} ({type(_index)})`
	)

	local point = cleanupPoint(_point)
	self.Points[_index] = point
	self._rebuildPoints(self, _index, 1)
end

function SplineClass:InsertPoint(_point: Vector3 | Instance | CFrame, _index: number?)
	assert(
		type(_index) == "number",
		`Tried to set a point with an invalid index type: {tostring(_index)} ({type(_index)})`
	)

	local point = cleanupPoint(_point)
	local index = _index or #self.Points + 1 :: number

	table.insert(self.Points, index, point)

	self._rebuildPoints(self, index, 1)
end

function SplineClass:RemovePoint(_index: number)
	assert(
		type(_index) == "number",
		`Tried to set a point with an invalid index type: {tostring(_index)} ({type(_index)})`
	)

	local index = _index or #self.Points + 1
	table.remove(self.Points, index)
	self._rebuildPoints(self, index, #self.Points)
end

function SplineClass:Destroy()
	self.RemoveDebug(self)

	if self.BezierCurves then
		table.clear(self.BezierCurves)
	end

	if self.Points then
		table.clear(self.Points)
	end

	if self.Settings then
		table.clear(self.Settings)
	end

	self.Tension = nil
	self.Looped = nil
	self.ID = nil
	self.Length = nil

	setmetatable(self, nil)
end

--< Main

function SplineClass.new(Points: { Point }, Settings: SplineSettings)
	local self = setmetatable({}, SplineClass)

	--<< SANITY CHECKS

	local isDictionary = not not (#Points == 0 and next(Points)) --simple way buy works
	if isDictionary then
		error(`Tried to create a Spline object when Points table is a dictionary or invalid`, 2)
	end

	--<< SETTINGS

	self.Points = table.clone(Points) :: { Vector3 }
	self.Settings = Settings and table.clone(Settings) or {} :: SplineSettings
	self.BezierCurves = {} :: { BezierCurve }
	self.Tension = self.Settings.Tension or 1
	self.Looped = (self.Settings.Looped ~= nil) and self.Settings.Looped or false
	self.ID = ID
	self.Length = 0

	--<< SETUP

	--< Cleanup points to position
	for i, v in self.Points do
		local success, Point = pcall(function()
			cleanupPoint(v)
		end)

		if not success then
			self.Destroy(self)
			error(`Invalid spline point type found inside the point table at index {i}: ({typeof(v)})`, 2)
		else
			self.Points[i] = cleanupPoint(v)
		end
	end

	--< Build bezier curves
	for i = 1, #self.Points do
		self:_buildCurve(i)
	end

	--< If spline isnt looped, delete last curve
	if not self.Looped then
		self.BezierCurves[#self.Points] = nil
	end

	--< Add up all curves
	for _, curve in self.BezierCurves do
		self.Length += curve.Length
	end

	ID += 1
	return self
end

--End

return SplineClass :: SplineClass
