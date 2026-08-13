--Made by DoYouLikeWafflesOrNo (or gl1tch1)

--!optimize 2

--< Services

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GoodSignal = require(script.GoodSignal)
local Methods = require(script.Methods)

local StateManager = {}
StateManager.__index = StateManager

--< Types

type GoodSignalType = typeof(GoodSignal.new())

type Dictionary = { [any]: any }

type HookCallback = (value: any, index: any, oldValue: any) -> (boolean?, any?, boolean?)

type Hook = {
	Priority: number,
	Callback: HookCallback,
	Name: string,
}

type SignalGroup = {
	Nested: GoodSignalType,
	Local: GoodSignalType,
}

type HookGroup = {
	Nested: { Hook },
	Local: { Hook },
}

type ActionType = "insert" | "remove"

type StateManagerData = {
	Manager: any,
	ProxyTable: Dictionary,
	Directories: { { any } },
	SourceTable: Dictionary,

	Signals: {
		Global: SignalGroup,
		Indexes: {
			[any]: SignalGroup,
		},
	},

	Hooks: {
		Global: HookGroup,
		Indexes: {
			[any]: HookGroup,
		},
	},
}

type StateManagerClass = {
	new: (SourceTable: { any }, Name: string) -> StateManagerType,
	get: (Name: string) -> StateManagerType?,

	InjectMethods: () -> (),
	WaitForTable: (Name: string, timeOut: number?) -> StateManagerType?,
}

export type StateManagerType = {
	ID: number,
	SourceTable: Dictionary,
	Name: string,
	Table: Dictionary,
	Inserted: GoodSignalType,
	Removed: GoodSignalType,
	Destroying: GoodSignalType,

	InjectMethods: () -> (),
	GetIndexChangedSignal: (self: StateManagerType, Table: { any }?, Index: any?, Nested: boolean?) -> GoodSignalType,
	HookToDirectory: (
		self: StateManagerType,
		Table: { any }?,
		Name: string,
		Index: any?,
		Callback: HookCallback,
		Nested: boolean?,
		Priority: number?
	) -> (),
	UnhookFromDirectory: (self: StateManagerType, Table: { any }?, Index: any?, Name: string, Nested: boolean?) -> (),
	Unwrap: (self: StateManagerType) -> Dictionary,
	Destroy: (self: StateManagerType) -> (),
}

--< Values

local GlobalStateID = 0

local StateTableCache = {}
local ReferenceMetatable = {}

--< Functions

--non deep search
local function CompareTables(tbl1: Dictionary, tbl2: Dictionary): boolean
	if #tbl1 ~= #tbl2 then
		return false
	end

	for i, v in tbl1 do
		if v ~= tbl2[i] then
			return false
		end
	end

	for i, v in tbl2 do
		if v ~= tbl1[i] then
			return false
		end
	end

	return true
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

local function InjectValues(_Table: Dictionary, Values: Dictionary, notClone: boolean?)
	local Table = if notClone then _Table else table.clone(_Table)

	for index, value in Values do
		if typeof(value) == "table" and typeof(Table[index]) == "table" then
			value = InjectValues(Table[index], value)
		end

		Table[index] = value
	end

	return Table
end

local function CreateSignalGroup(): SignalGroup
	return {
		Nested = GoodSignal.new(),
		Local = GoodSignal.new(),
	}
end

local function CreateHookGroup(): HookGroup
	return {
		Nested = {},
		Local = {},
	}
end

local function CloneDirectories(Directories: { { any } }): { { any } }
	local ClonedDirectories = {}

	for _, Directory in Directories do
		table.insert(ClonedDirectories, table.clone(Directory))
	end

	return ClonedDirectories
end

local function ExtendDirectories(Directories: { { any } }, Index: any): { { any } }
	local ExtendedDirectories = {}

	for _, Directory in Directories do
		local newDirectory = table.clone(Directory)
		table.insert(newDirectory, Index)
		table.insert(ExtendedDirectories, newDirectory)
	end

	return ExtendedDirectories
end

local function AddDirectory(Directories: { { any } }, newDirectory: { any })
	for _, Directory in Directories do
		if CompareTables(Directory, newDirectory) then
			return
		end
	end

	table.insert(Directories, table.clone(newDirectory))
end

local function RemoveDirectory(Directories: { { any } }, oldDirectory: { any })
	for i = #Directories, 1, -1 do
		if CompareTables(Directories[i], oldDirectory) then
			table.remove(Directories, i)
		end
	end
end

local function GetFromDirectory(self, Directory: { any })
	if typeof(Directory) ~= "table" then
		return nil
	end

	local CurrentTable = self.Table

	for _, Index in Directory do
		local NextTable = CurrentTable[Index]

		if typeof(NextTable) ~= "table" then
			return nil
		end

		CurrentTable = NextTable
	end

	return CurrentTable
end

local function GetStateTable(self, DirectoryOrTable)
	local Metatable = getmetatable(DirectoryOrTable)

	return (Metatable and Metatable.__StateManagerData) and DirectoryOrTable or GetFromDirectory(self, DirectoryOrTable)
end

-----------------------

local function AttachMetatable(self, SourceTable: Dictionary, Directories: { { any } })
	local Metatable = table.clone(ReferenceMetatable)
	local ProxyTable = {}

	local DataTable: StateManagerData = {
		Manager = self,
		ProxyTable = ProxyTable,
		SourceTable = SourceTable,
		Directories = CloneDirectories(Directories),

		Signals = {
			Global = CreateSignalGroup(),
			Indexes = {},
		},

		Hooks = {
			Global = CreateHookGroup(),
			Indexes = {},
		},
	}

	Metatable.__StateManagerData = DataTable
	self.ReferenceTableCache[SourceTable] = ProxyTable

	return setmetatable(ProxyTable, Metatable)
end

local function SetupMetatable(self, Table: Dictionary, Directories: { { any } })
	local Metatable = getmetatable(Table)
	local StateTable

	if Metatable and Metatable.__StateManagerData then
		StateTable = Table
	else
		StateTable = self.ReferenceTableCache[Table]

		if not StateTable then
			StateTable = AttachMetatable(self, Table, Directories)
		end
	end

	local Data = getmetatable(StateTable).__StateManagerData :: StateManagerData

	Data.Manager = self

	for _, Directory in Directories do
		AddDirectory(Data.Directories, Directory)
	end

	for index, value in Data.SourceTable do
		if typeof(value) ~= "table" then
			continue
		end

		local newDirectories = ExtendDirectories(Directories, index)

		Data.SourceTable[index] = SetupMetatable(self, value, newDirectories)
	end

	return StateTable
end

local function RemoveTableDirectories(Table: Dictionary, Directories: { { any } })
	local Metatable = getmetatable(Table)

	if not Metatable or not Metatable.__StateManagerData then
		return
	end

	local Data = Metatable.__StateManagerData :: StateManagerData

	for _, Directory in Directories do
		RemoveDirectory(Data.Directories, Directory)
	end

	for index, value in Data.SourceTable do
		if typeof(value) ~= "table" then
			continue
		end

		RemoveTableDirectories(value, ExtendDirectories(Directories, index))
	end
end

-----------------------

local function FireHookList(
	HooksList: { Hook },
	index: any,
	newValue: any,
	oldValue: any,
	action: ActionType?
): (boolean, any)
	for _, HookData in HooksList do
		local makeChanges, callbackValue, abortChange = HookData.Callback(newValue, index, oldValue, action)

		if abortChange then
			return true, newValue
		end

		if makeChanges then
			newValue = callbackValue
		end
	end

	return false, newValue
end

local function FireHooks(
	Data: StateManagerData,
	index: any,
	newValue: any,
	oldValue: any,
	action: ActionType?
): (boolean, any)
	local function ApplyHookList(HookList: { Hook }): boolean
		local abortChange

		abortChange, newValue = FireHookList(HookList, index, newValue, oldValue, action)

		return abortChange
	end

	--Local hooks only run on the table directly being changed
	if ApplyHookList(Data.Hooks.Global.Local) then
		return true, newValue
	end

	local LocalIndexHooks = Data.Hooks.Indexes[index]

	if LocalIndexHooks then
		if ApplyHookList(LocalIndexHooks.Local) then
			return true, newValue
		end
	end

	for _, ChangedDirectory in Data.Directories do
		local DirectoryClone = table.clone(ChangedDirectory)
		local ChangedDirectoryLength = #ChangedDirectory

		for depth = ChangedDirectoryLength, 0, -1 do
			local CurrentTable = GetFromDirectory(Data.Manager, DirectoryClone)

			if CurrentTable then
				local CurrentData = getmetatable(CurrentTable).__StateManagerData :: StateManagerData

				local matchingIndex = depth == ChangedDirectoryLength and index or ChangedDirectory[depth + 1]

				if ApplyHookList(CurrentData.Hooks.Global.Nested) then
					return true, newValue
				end

				local NestedIndexHooks = CurrentData.Hooks.Indexes[matchingIndex]

				if NestedIndexHooks then
					if ApplyHookList(NestedIndexHooks.Nested) then
						return true, newValue
					end
				end
			end

			table.remove(DirectoryClone)
		end
	end

	return false, newValue
end

local function FireIndexChanged(Data: StateManagerData, index: any, newValue: any, oldValue: any, action: ActionType?)
	for _, Directory in Data.Directories do
		local ChangedDirectory = table.clone(Directory)

		--Local signals only fire for changes made directly to this table
		Data.Signals.Global.Local:Fire(newValue, index, oldValue, ChangedDirectory)

		local LocalIndexSignals = Data.Signals.Indexes[index]

		if LocalIndexSignals then
			LocalIndexSignals.Local:Fire(newValue, index, oldValue, ChangedDirectory, action)
		end

		--Nested signals fire on the changed table and every parent table
		local DirectoryClone = table.clone(ChangedDirectory)
		local ChangedDirectoryLength = #ChangedDirectory

		for depth = ChangedDirectoryLength, 0, -1 do
			local CurrentTable = GetFromDirectory(Data.Manager, DirectoryClone)

			if CurrentTable then
				local CurrentData = getmetatable(CurrentTable).__StateManagerData :: StateManagerData

				local matchingIndex = depth == ChangedDirectoryLength and index or ChangedDirectory[depth + 1]

				CurrentData.Signals.Global.Nested:Fire(newValue, index, oldValue, ChangedDirectory, action)

				local NestedIndexSignals = CurrentData.Signals.Indexes[matchingIndex]

				if NestedIndexSignals then
					NestedIndexSignals.Nested:Fire(newValue, index, oldValue, ChangedDirectory, action)
				end
			end

			if depth > 0 then
				table.remove(DirectoryClone)
			end
		end
	end
end

-----------------------

function ReferenceMetatable:__index(index)
	local Data = getmetatable(self).__StateManagerData :: StateManagerData

	return Data.SourceTable[index]
end

function ReferenceMetatable:__newindex(index, value, action: ActionType)
	local Data = getmetatable(self).__StateManagerData :: StateManagerData

	if Data.SourceTable[index] == value then
		return
	end

	local newDirectories = ExtendDirectories(Data.Directories, index)

	local oldValue = Data.SourceTable[index]
	local newValue = value

	local abortChange

	abortChange, newValue = FireHooks(Data, index, newValue, oldValue, action)

	if abortChange then
		return
	end

	if typeof(oldValue) == "table" then
		RemoveTableDirectories(oldValue, newDirectories)
	end

	if typeof(newValue) == "table" then
		newValue = SetupMetatable(Data.Manager, newValue, newDirectories)
	end

	local result
	if action == "insert" then --need to add a function cache table
		result = table.insert(Data.SourceTable, index, value)
	elseif action == "remove" then
		result = table.remove(Data.SourceTable, index)
	else
		Data.SourceTable[index] = newValue
	end

	FireIndexChanged(Data, index, newValue, oldValue, action)

	return result
end

function ReferenceMetatable:__iter()
	local Data = getmetatable(self).__StateManagerData :: StateManagerData

	return pairs(Data.SourceTable)
end

function ReferenceMetatable:__len()
	local Data = getmetatable(self).__StateManagerData :: StateManagerData

	return #Data.SourceTable
end

-----------------------

--[[
Get a signal event that fires after a change is made in the designated table
]]
function StateManager:GetIndexChangedSignal(Table: { any }?, Index: any?, Nested: boolean?): GoodSignalType
	local StateTable = GetStateTable(self, Table or self.Table)

	assert(StateTable, `Could not find a state table at the provided directory: ({table.concat(StateTable, ", ")})`)

	local Data = getmetatable(StateTable).__StateManagerData :: StateManagerData

	local useNested = Nested ~= false

	if Index ~= nil then
		local SignalGroup = Data.Signals.Indexes[Index]

		if not SignalGroup then
			SignalGroup = CreateSignalGroup()
			Data.Signals.Indexes[Index] = SignalGroup
		end

		return Nested and SignalGroup.Nested or SignalGroup.Local
	end

	return Nested and Data.Signals.Global.Nested or Data.Signals.Global.Local
end

--[[
Hook a callback to a table to modify the value or abort the change before the change is made
]]
function StateManager:HookToDirectory(
	Table: { any }?,
	Name: string,
	Index: any?,
	Callback: HookCallback,
	Nested: boolean?,
	Priority: number?
)
	local StateTable = GetStateTable(self, Table or self.Table)

	assert(StateTable, "Could not find a state table at the provided directory")

	local Data = getmetatable(StateTable).__StateManagerData :: StateManagerData
	local HookTable: { Hook }

	if Index ~= nil then
		local IndexHooks = Data.Hooks.Indexes[Index]

		if not IndexHooks then
			IndexHooks = CreateHookGroup()
			Data.Hooks.Indexes[Index] = IndexHooks
		end

		HookTable = Nested and IndexHooks.Nested or IndexHooks.Local
	else
		HookTable = Nested and Data.Hooks.Global.Nested or Data.Hooks.Global.Local
	end

	table.insert(HookTable, {
		Priority = Priority or #HookTable,
		Callback = Callback,
		Name = Name,
	})

	table.sort(HookTable, function(a, b)
		return a.Priority < b.Priority
	end)
end

--[[
Remove hook with provided name from the provided table
]]
function StateManager:UnhookFromDirectory(Table: { any }?, Index: any?, Name: string, Nested: boolean?)
	local StateTable = GetStateTable(self, Table or self.Table)

	assert(StateTable, "Could not find a state table at the provided directory")

	local Data = getmetatable(StateTable).__StateManagerData :: StateManagerData

	local HookTable: { Hook }

	if Index ~= nil then
		local IndexHooks = Data.Hooks.Indexes[Index]

		if not IndexHooks then
			return
		end

		HookTable = Nested and IndexHooks.Nested or IndexHooks.Local
	else
		HookTable = Nested and Data.Hooks.Global.Nested or Data.Hooks.Global.Local
	end

	for i = #HookTable, 1, -1 do
		if HookTable[i].Name == Name then
			table.remove(HookTable, i)
		end
	end
end

--[[
Destroy the state table
]]
function StateManager:Destroy()
	self.Destroying:Fire()

	if StateTableCache[self.Name] == self then
		StateTableCache[self.Name] = nil
	end

	self.Table = nil
	self.SourceTable = nil
	self.ReferenceTableCache = nil
end

--[[
Unwrap the table and get a new table without proxies attached (this is just a clone of the table, not the original table)
]]
function StateManager:Unwrap(): Dictionary
	return Methods.table.unwrap(self.Table)
end

--< Main

--[[
Returns a state table with said name if it exists
]]
function StateManager.get(Name: string)
	return StateTableCache[Name]
end

--[[
Yields until timeout is reached or a state table with the provided name is added, timeOut defaults to infinite
]]
function StateManager.WaitForTable(Name: string, timeOut: number?)
	timeOut = timeOut or math.huge

	local timeWaited = 0
	local warned = false

	while not StateTableCache[Name] do
		timeWaited += task.wait()

		if timeWaited >= timeOut then
			return false
		end

		if timeWaited >= 5 and not warned then
			warned = true

			warn(`Infinite yield possible on waiting for state manager table '{Name}' to be added`)
		end
	end

	return StateTableCache[Name]
end

--[[
This function replaces environment methods with the methods from the
Methods module. Use the Methods module directly to avoid this behavior.
]]
function StateManager.InjectMethods()
	local Enviroment = getfenv(2)

	InjectValues(Enviroment, Methods, true)
end

--[[
Create a new state manager class
]]
function StateManager.new(SourceTable: { any }, Name: string): StateManagerType
	assert(
		SourceTable and typeof(SourceTable) == "table",
		`Source table doesn't exist or is invalid type: ({typeof(SourceTable)})`
	)

	assert(
		typeof(Name) == "string" and Name ~= "",
		`State manager name is empty or the wrong type: ({tostring(Name)}, {typeof(Name)})`
	)

	assert(not StateTableCache[Name], `A state manager with that name already exists: ({Name})`)

	local self = setmetatable({}, StateManager)

	self.ID = GlobalStateID
	self.SourceTable = SourceTable
	self.ReferenceTableCache = {}
	self.Name = Name
	self.Table = SetupMetatable(self, SourceTable, { {} })

	self.Inserted = GoodSignal.new()
	self.Removed = GoodSignal.new()
	self.Destroying = GoodSignal.new()

	StateTableCache[Name] = self
	GlobalStateID = (GlobalStateID + 1) % 999999
	return self
end

return StateManager :: StateManagerClass
