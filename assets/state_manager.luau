--< Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local StateManager = {}
StateManager.__index = StateManager

--< Types

export type Directory = { string | number }

export type DirectoryHookFunction = {
	Name: string,
	Callback: (index: any, value: any) -> (any, boolean?),
	Priority: number,
}

export type StateManagerType = {
	-- Properties
	Name: string,
	sourceTable: { [any]: any },
	Table: { [any]: any },
	Destroyed: boolean?,

	-- Methods
	GetIndexChangedSignal: (self: StateManagerType, Directory) -> RBXScriptSignal,
	HookToDirectory: (
		self: StateManagerType,
		Directory: Directory,
		HookName: string,
		Callback: (value: any) -> (any, boolean?),
		Priority: number?
	) -> DirectoryHookFunction,
	UnhookFromDirectory: (self: StateManagerType, Directory: Directory, HookName: string) -> boolean,
	Destroy: (self: StateManagerType) -> (),
}

export type StateManagerConstructor = {
	new: (Name: string, sourceTable: { [any]: any }) -> StateManagerType,
	get: (Name: string) -> StateManagerType,
	WaitForTable: (Name: string, timeOut: number?) -> StateManagerType | false,
}

--< Values

local StateManagerCache = {}

local GetMetatable
local SetupMetatable
local clone = table.clone
local insert = table.insert
local remove = table.remove
local concat = table.concat

--< Functions

--Get metatable of a new table
GetMetatable = function(self, sourceTable, Directory)
	local Metatable = {}
	local dirKeyNow = table.concat(Directory, ",")
	local dirKeyNowTable = string.split(dirKeyNow, ",")

	function Metatable.__index(table, index)
		return sourceTable[index]
	end

	function Metatable.__iter(table)
		return pairs(sourceTable)
	end

	function Metatable.__len(table)
		return #sourceTable
	end

	--New index, checks when a new value has been added to the table, if so, run directory functions and changed events
	function Metatable.__newindex(table, index, value)
		--Return if current value is the same as the new value
		if sourceTable[index] == value then
			return
		end

		--Create directory key string and table
		local directoryKey = concat(Directory, ",") .. `,{index}`
		local directoryKeyTable = string.split(directoryKey, ",")

		--Run directory functions
		local hookList = self.directoryHookFunctions[directoryKey]
		for i, hookObject in hookList or {} do
			local nValue, abort = hookObject.Callback(value)

			if abort then
				return
			end

			value = nValue
		end

		--Check if the value is a table and if its about to be removed
		if typeof(sourceTable[index]) == "table" and value == nil then
			self.subTables[dirKeyNow] = nil
		end

		--Check if theres a sub table and set up its metatable
		if typeof(value) == "table" then
			local SubDirectory = clone(Directory)
			insert(SubDirectory, index)
			SetupMetatable(self, value, SubDirectory)
		end

		--Apply change to source table
		local previousValue = sourceTable[index]
		sourceTable[index] = value

		--Fire changed event for all events connected
		local directoryKeyTable = string.split(directoryKey, ",")
		for i = #directoryKeyTable, 1, -1 do
			local tempDirKey = concat(directoryKeyTable, ",")
			if self.indexChangedCache[tempDirKey] then
				self.indexChangedCache[tempDirKey].eventInstance:Fire(value, previousValue)
			end
			remove(directoryKeyTable, i)
		end
	end

	return Metatable
end

--Set up metatable for a table and its subtables
SetupMetatable = function(self, sourceTable, Directory)
	--Check for sub tables
	for i, v in sourceTable do
		if typeof(v) == "table" then
			local SubDirectory = clone(Directory)
			insert(SubDirectory, i)
			sourceTable[i] = SetupMetatable(self, v, SubDirectory)
		end
	end

	--Add table to subtable cache
	if #Directory ~= 1 then
		local directoryKey = concat(Directory, ",")
		self.subTables[directoryKey] = {
			Directory = Directory,
			sourceTable = sourceTable,
			directoryKey = directoryKey,
		}
	end

	--Create proxy
	return setmetatable({}, GetMetatable(self, sourceTable, Directory))
end

----

--Hook a function to the state manager object that fires each time
function StateManager:HookToDirectory(Directory, HookName, Callback, Priority)
	table.insert(Directory, 1, self.Name)
	local directoryKey = table.concat(Directory, ",")
	local hookList = self.directoryHookFunctions[directoryKey]

	--Create hook list if missing
	if not hookList then
		self.directoryHookFunctions[directoryKey] = {}
		hookList = self.directoryHookFunctions[directoryKey]
	end

	--Create hook object
	local hookObject = {
		Name = HookName,
		Callback = Callback,
		Priority = Priority or #hookList,
	}

	--Add and sort by priority
	table.insert(hookList, hookObject)

	table.sort(hookList, function(a, b)
		return a.Priority > b.Priority
	end)

	return hookObject
end

--Unhooks the function if found
function StateManager:UnhookFromDirectory(Directory, HookName)
	table.insert(Directory, 1, self.Name)
	local directoryKey = table.concat(Directory, ",")
	local hookList = self.directoryHookFunctions[directoryKey]

	if not hookList then
		return false
	end

	local removed = false

	for i = #hookList, 1, -1 do
		if hookList[i].Name == HookName then
			table.remove(hookList, i)
			removed = true
		end
	end

	return removed
end

----

function StateManager:GetIndexChangedSignal(Directory: { string })
	table.insert(Directory, 1, self.Name)
	local directoryString = table.concat(Directory, ",")

	if not self.indexChangedCache[directoryString] then
		local eventInstance = Instance.new("BindableEvent")

		self.indexChangedCache[directoryString] = {
			Event = eventInstance.Event,
			eventInstance = eventInstance,
		}
	end

	return self.indexChangedCache[directoryString].Event
end

----

--Clean up the state replicator
function StateManager:Destroy()
	self.Destroyed = true

	StateManagerCache[self.Name] = nil

	setmetatable(self.Table, nil)
	for i, subTable in self.subTables do
		setmetatable(subTable.sourceTable, nil)
	end

	for i, indexChangedObject in self.indexChangedCache do
		indexChangedObject.eventInstance:Destroy()
	end

	self.Table = nil
	self.Name = nil
	self.sourceTable = nil
	self.subTables = nil
end

--< Main

--Setup

--Script

function StateManager.new(Name: string, sourceTable: {})
	assert(typeof(sourceTable) == "table", `sourceTable was not defined as a table, instead a {typeof(sourceTable)} `)
	assert(typeof(Name) == "string", "Name was not defined as a string.")
	assert(not StateManagerCache[Name], `A table with the same name as {Name} already exists!`)

	local self = setmetatable({}, StateManager)

	--< Values

	self.Name = Name :: string
	self.sourceTable = sourceTable :: { any }
	self.subTables = {}
	self.Table = SetupMetatable(self, sourceTable, { self.Name }) :: { any }

	self.directoryHookFunctions = {}
	self.indexChangedCache = {}

	-- Add table to cache
	StateManagerCache[Name] = self

	--< End
	return self
end

function StateManager.get(Name: string)
	return StateManagerCache[Name]
end

function StateManager.WaitForTable(Name: string, timeOut: number?)
	timeOut = timeOut or math.huge
	local timeWaited = 0
	local warned = false

	while not StateManagerCache[Name] do
		timeWaited += task.wait()

		if timeWaited >= timeOut then
			return false
		end

		if timeWaited >= 5 and not warned then
			warned = true
			warn(`StateManager: Infinite yield possible on waiting for table '{Name}' to be added`)
		end
	end

	return StateManagerCache[Name]
end

--End

return StateManager :: StateManagerConstructor
