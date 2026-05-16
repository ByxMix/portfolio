--< Services

local Methods = require(script.Methods)

local StateManager = {}
StateManager.__index = StateManager

--< Types

type Directory = { string | number }

type DirectoryHookFunction = {
	Name: string,
	Callback: (index: any, value: any) -> (any, boolean?),
	Priority: number,
}

export type StateManagerType = {
	-- Properties
	Name: string,
	sourceTable: { [any]: any },
	Table: { [any]: any },
	Destroying: RBXScriptSignal,

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

type StateManagerConstructor = {
	new: (Name: string, sourceTable: { [any]: any }) -> StateManagerType,
	get: (Name: string) -> StateManagerType,
	WaitForTable: (Name: string, timeOut: number?) -> StateManagerType?,
	InjectMethods: () -> (),
}

--< Values

local StateManagerCache = {}
local TableMethods = {
	clear = table.clear,
	clone = table.clone,
	concat = table.concat,
	create = table.create,
	find = table.find,
	freeze = table.freeze,
	insert = table.insert,
	isfrozen = table.isfrozen,
	maxn = table.maxn,
	move = table.move,
	pack = table.pack,
	remove = table.remove,
	sort = table.sort,
	unpack = table.unpack,
}

local GetMetatable
local SetupMetatable

--< Functions

local function GetDirectoryKey(Directory)
	return table.concat(Directory, ",")
end

local function GetChildDirectory(Directory, index)
	local childDirectory = table.clone(Directory)
	table.insert(childDirectory, index)
	return childDirectory
end

local function FireIndexChanged(self, directoryKeyTable, value, previousValue, index)
	local tempDirectoryKeyTable = table.clone(directoryKeyTable)

	for i = #directoryKeyTable, 1, -1 do
		local localDirectoryKeyString = table.concat(tempDirectoryKeyTable, ",")

		local indexChangedObject = self.indexChangedCache[localDirectoryKeyString]
		if indexChangedObject then
			indexChangedObject.eventInstance:Fire(value, previousValue, index, directoryKeyTable)
		end

		table.remove(tempDirectoryKeyTable, i)
	end
end

local function RunDirectoryHooks(self, directoryKey, value, previousValue)
	local hookList = self.directoryHookFunctions[directoryKey]

	for _, hookObject in hookList or {} do
		local callbackValue, abortChange = hookObject.Callback(value, previousValue)

		if abortChange then
			return value, true
		end

		value = callbackValue
	end

	return value, false
end

local function RemoveSubTableCache(self, directoryKey)
	self.subTables[directoryKey] = nil

	local prefix = directoryKey .. ","

	for subTableKey in self.subTables do
		if string.sub(subTableKey, 1, #prefix) == prefix then
			self.subTables[subTableKey] = nil
		end
	end
end

local function PrepareValueForSet(self, value, directoryKeyTable)
	if typeof(value) ~= "table" then
		return value
	end

	local valueMetatable = getmetatable(value)

	if valueMetatable and valueMetatable.__sourcetable then
		return value
	end

	return SetupMetatable(self, value, directoryKeyTable)
end

local function DeepClone(tbl: { any }): { any }
	local clone = table.clone(tbl)

	for key, value in tbl do
		if type(value) == "table" then
			clone[key] = DeepClone(value)
		end
	end

	return clone
end

----

--Get metatable of a new table
GetMetatable = function(self, sourceTable, Directory)
	local Metatable = {}

	function Metatable.__index(tbl, index)
		return sourceTable[index]
	end

	function Metatable.__iter(tbl)
		return next(sourceTable)
	end

	function Metatable.__len(tbl)
		return #sourceTable
	end

	--TODO: Store functions outside
	--New index, checks when a new value has been added to the table, if so, run directory functions and changed events
	function Metatable.__newindex(tbl, index, value)
		if sourceTable[index] == value then
			return
		end

		local previousValue = sourceTable[index]

		local directoryKeyTable = GetChildDirectory(Directory, index)
		local directoryKey = GetDirectoryKey(directoryKeyTable)

		--Fire hooked functions
		if not Metatable.__silent then
			local abortChange
			value, abortChange = RunDirectoryHooks(self, directoryKey, value, previousValue)

			if abortChange then
				return
			end
		end

		--Check if value to be removed is a table, if so, clean it up
		if typeof(previousValue) == "table" and value == nil then
			RemoveSubTableCache(self, directoryKey)
		end

		value = PrepareValueForSet(self, value, directoryKeyTable)

		sourceTable[index] = value

		--Fire changed events
		if not Metatable.__silent then
			FireIndexChanged(self, directoryKeyTable, value, previousValue, index)
		end
	end

	--Fork for the table.removed
	function Metatable.__remove(tbl, index)
		local length = #sourceTable

		if length == 0 then
			return nil
		end

		index = index or length
		if index < 1 or index > length then
			error(`invalid position {index} for table.remove`, 2)
		end

		local previousValue = sourceTable[index]

		local directoryKeyTable = GetChildDirectory(Directory, index)
		local directoryKey = GetDirectoryKey(directoryKeyTable)

		--Fire hooked functions
		if not Metatable.__silent then
			local _, abortChange = RunDirectoryHooks(self, directoryKey, nil, previousValue)

			if abortChange then
				return nil
			end
		end

		--Check if value to be removed is a table, if so, clean it up
		if typeof(previousValue) == "table" then
			RemoveSubTableCache(self, directoryKey)
		end

		local removedValue = table.remove(sourceTable, index)

		--Fire changed events
		if not Metatable.__silent then
			FireIndexChanged(self, directoryKeyTable, nil, previousValue, index)
		end

		return removedValue
	end

	Metatable.__sourcetable = sourceTable
	Metatable.__silent = false

	return Metatable
end

--Set up metatable for a table and its subtables
SetupMetatable = function(self, sourceTable, Directory)
	--Check for sub tables
	for i, v in sourceTable do
		if typeof(v) == "table" then
			local SubDirectory = table.clone(Directory)
			table.insert(SubDirectory, i)
			sourceTable[i] = SetupMetatable(self, v, SubDirectory)
		end
	end

	--Add table to subtable cache
	if #Directory ~= 1 then
		local directoryKey = table.concat(Directory, ",")
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

function StateManager:GetIndexChangedSignal(Directory: { string? })
	Directory = Directory or {}
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

--Clean up the state replicator
function StateManager:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true

	if self.destroyingInstance then
		self.destroyingInstance:Fire()
	end

	if self.Name then
		StateManagerCache[self.Name] = nil
	end

	if self.directoryHookFunctions then
		table.clear(self.directoryHookFunctions)
		self.directoryHookFunctions = nil
	end

	if self.indexChangedCache then
		for _, indexChangedObject in self.indexChangedCache do
			if indexChangedObject.eventInstance then
				indexChangedObject.eventInstance:Destroy()
			end
		end
		table.clear(self.indexChangedCache)
		self.indexChangedCache = nil
	end

	if self.Table then
		setmetatable(self.Table, nil)
		self.Table = nil
	end

	if self.subTables then
		for _, subTable in self.subTables do
			if subTable.sourceTable then
				setmetatable(subTable.sourceTable, nil)
			end
		end
		table.clear(self.subTables)
		self.subTables = nil
	end

	if self.destroyingInstance then
		self.destroyingInstance:Destroy()
		self.destroyingInstance = nil
		self.Destroying = nil
	end

	self.sourceTable = nil
	self.Name = nil

	setmetatable(self, nil)
end

--< Main

--Script

function StateManager.new(Name: string, sourceTable: {})
	assert(typeof(sourceTable) == "table", `sourceTable was not defined as a table, instead a {typeof(sourceTable)} `)
	assert(typeof(Name) == "string", "Name was not defined as a string.")
	assert(not StateManagerCache[Name], `A table with the same name as {Name} already exists!`)

	local self = setmetatable({}, StateManager)

	--Values
	self.Name = Name :: string
	self.subTables = {}
	self.Table = SetupMetatable(self, sourceTable, { self.Name }) :: { any }

	self.sourceTable = sourceTable :: { any }
	self.directoryHookFunctions = {}
	self.indexChangedCache = {}

	self.destroyingInstance = Instance.new("BindableEvent")
	self.Destroying = self.destroyingInstance.Event

	--Add table to cache
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
			warn(`[StateManager] Infinite yield possible on waiting for table '{Name}' to be added`)
		end
	end

	return StateManagerCache[Name]
end

--This function will replace enviroment methods with the ones on the Methods module, if you don't want it to do this use the Methods module
function StateManager.InjectMethods()
	local enviroment = getfenv(2)
	local tableMethodsClone = DeepClone(TableMethods)

	enviroment.table = tableMethodsClone

	for methodName, methodCallback in Methods do
		local methodTable = methodName == "print" and enviroment or tableMethodsClone --hacky fix but works for now

		methodTable[methodName] = methodCallback
	end
end

--End

return StateManager :: StateManagerConstructor
