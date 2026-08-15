--< Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local EncodingService = game:GetService("EncodingService")
local HttpService = game:GetService("HttpService")

local BufferEncoder = require(script.BufferEncoder)
local Config = require(script.Config)

local ParallelManager = {}
ParallelManager.__index = ParallelManager

--< Types

type Dictionary = { [any]: any }

type ReturnCallback = (index: number, value: any) -> ()?

type Callback = (index: number, localData: any, globalData: Dictionary) -> ()?

export type ParallelManager = {
	Name: string,
	LocalData: { any },
	GlobalData: { any },
	Callback: ModuleScript,
	ResultCallback: ReturnCallback,

	Run: (self: ParallelManager, Loops: number?) -> { [number]: any },
	UpdateWorkload: (self: ParallelManager, dataType: string, Data: any) -> (),
	Destroy: (self: ParallelManager) -> (),
}

type Settings = {
	Encode: boolean?,
	AutoSort: boolean?,
	ReturnResult: boolean?,
}

type ParallelManagerConstructor = {
	new: (
		Callback: ModuleScript,
		ResultCallback: ReturnCallback,
		LocalData: { any }?,
		GlobalData: { any }?,
		Settings: Settings?
	) -> ParallelManager,
}

--< Values

local GlobalID = 0
local GlobalWorkloadID = 0
local Assets = script.Assets
local Actors = Instance.new("Folder")
local loaderName = RunService:IsClient() and "loaderClient" or "loaderServer"

--< Functions

function ParallelManager:Run(Loops: number)
	GlobalWorkloadID = GlobalWorkloadID % Config.ID_CAP

	local workloadID = GlobalWorkloadID + 1
	local dataAmount = Loops or #self.LocalData
	local Result = {}

	local workloadSplit = dataAmount // Config.ACTOR_AMOUNT
	local workloadRemainder = dataAmount % Config.ACTOR_AMOUNT
	local actorAmount = math.min(dataAmount, Config.ACTOR_AMOUNT)

	local Connection = Assets.WorkloadEvent.Event:Connect(function(ID, actorWorkloadID, actorID, actorResult)
		if (self.ID ~= ID) or (workloadID ~= actorWorkloadID) then
			return
		end

		Result[actorID] = self.Settings.Encode and BufferEncoder.Decode(actorResult) or actorResult

		if self.ResultCallback then
			for i, v in actorResult do
				self.ResultCallback(tonumber(i), v)
			end
		end
	end)

	local workloadSent = 0
	for i = 1, actorAmount do
		local Actor = script.Actors:FindFirstChild(tostring(i))
		local workloadAmount = workloadSplit + (i <= workloadRemainder and 1 or 0)
		local startIndex = workloadSent + 1
		local endIndex = workloadAmount + workloadSent

		Actor:SendMessage("RunWorkload", self.ID, workloadID, startIndex, endIndex)

		workloadSent += workloadAmount
	end

	while #Result ~= actorAmount do
		task.wait()
	end
	Connection:Disconnect()

	if not self.Settings.ReturnResult then
		return
	end

	local returnResult = Result[1]
	for i, tbl in Result do
		if i == 1 then
			continue
		end

		table.move(tbl, 1, #tbl, #returnResult + 1, returnResult)
	end

	return returnResult
end

function ParallelManager:UpdateWorkload(dataType: string, Data: any)
	self[dataType] = Data

	for _, Actor: Actor in Actors:GetChildren() do
		Actor:SendMessage("UpdateWorkload", self.ID, dataType, Data)
	end
end

function ParallelManager:Destroy()
	for _, Actor: Actor in Actors:GetChildren() do
		Actor:SendMessage("DestroyWorkload", self.ID)
	end
end

--< Main

--Setup

--Create actor folder
Actors.Name = "Actors"
Actors.Parent = script

--Clear previous actors (mainly server actors)
Actors:ClearAllChildren()

--Bind message to thread loaded to log actors bootup
local loadedActors = 0
Assets.ThreadLoaded.Event:Connect(function(ActorID)
	loadedActors += 1
end)

--Create new actors and boot them up
for i = 1, Config.ACTOR_AMOUNT do
	local Actor = Assets.Actor:Clone()
	Actor.Parent = Actors
	Actor.Name = i
	Actor[loaderName].Enabled = true
end

--Wait for all actors to load
repeat
	task.wait()
until loadedActors == Config.ACTOR_AMOUNT

--Script

function ParallelManager.new(
	Callback: ModuleScript,
	ResultCallback: (any) -> ()?,
	LocalData: { any }?,
	GlobalData: { any }?,
	Settings: Settings?
)
	local self = setmetatable({}, ParallelManager)

	--< Values

	self.ID = GlobalID
	self.GlobalData = GlobalData or {}
	self.LocalData = LocalData or {}
	self.Settings = Settings or {}
	self.Callback = Callback
	self.ResultCallback = ResultCallback

	--< Setup

	local classClone = setmetatable(table.clone(self), {})

	for _, Actor: Actor in Actors:GetChildren() do
		Actor:SendMessage("BindWorkload", classClone)
	end

	--< End

	GlobalID = (GlobalID + 1) % Config.ID_CAP
	return self
end

--End

return ParallelManager :: ParallelManagerConstructor
