-- HTTP REQUESTS MUST BE ENABLED IN EXPERIENCE !
local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local MarketPlaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ModelInsertFire = ReplicatedStorage:FindFirstChild("ModelInsertFire")
local CallRecords = ServerScriptService:WaitForChild("CallRecords")
local NewInsert = ServerScriptService:WaitForChild("NewInsert")
local records = {}

-- This is cool-down that users need to wait before spawning the next car
local debounce = 10
-- These are the webhook URLs that will be used to send the notifications. You can use both Discord and Guilded webhooks.
local post_urls = {
	[1] = '',
	[2] = '',
	[3] = '',
}

CallRecords.Event:Connect(function(event: BindableEvent)
	-- table.clone(_data) doesnt work for some reason
	local _data = {}
	for k, v in pairs(records) do
		_data[k] = v
	end
	table.freeze(_data)
	event:Fire(_data)
end)

local function constructWebhookData(Player: Player, ModelID: string, asset)
	local Data = {
		["embeds"] = {{
			title = tostring(Player.Name .. " Inserted"),
			description = "UTC at: " .. tostring(DateTime.now().UnixTimestamp),
			footer = {
				text = "These are just notifications, and are not necessarily hard proof. \nhttps://github.com/Hypurrnating/hot-slot-inserter/" .. "\n"
			},
			fields = {
				{name = '__Asset Info__', value = " ", inline = false},
				{
					name = 'Asset ID',
					value = tostring(ModelID) or "nil",
					inline = true
				},
				{
					name = 'Asset Name',
					value = tostring(asset.Name) or "nil",
					inline = true
				},
				{
					name = 'Asset Created At',
					value = tostring(asset.Created),
					inline = true
				},
				{
					name = 'Asset Updated At',
					value = tostring(asset.Updated),
					inline = true
				},
				{
					name = 'Asset Creator ID',
					value = tostring(asset.Creator.CreatorTargetId) or "nil",
					inline = true
				},
				{name = '__Inserted by/Player Info__', value = " ", inline = false},
				{
					name = 'Player ID',
					value =tostring(Player.UserId) or "nil",
					inline = true
				},
				{
					name = 'Player Username',
					value = tostring(Player.Name) or "nil",
					inline = true
				},
				{
					name = 'Player Displayname',
					value = tostring(Player.DisplayName) or "nil",
					inline = true
				},
				{name = '__Game Info__', value = " ", inline = false},
				{
					name = 'Game ID',
					value = tostring(game.GameId) or "nil",
					inline = true
				},
				{
					name = 'Game Creator ID',
					value = tostring(game.CreatorId) or "nil",
					inline = true
				},
				{
					name = 'Game Creator Type',
					value = tostring(game.CreatorType) or "nil",
					inline = true
				},
				{
					name = 'Game Job ID',
					value = tostring(game.JobId) or "nil",
					inline = true
				}
			}
		}}
	}
	local data = HttpService:JSONEncode(Data)
	return data
end

local function postToWebhook(url: string, data: string)
	local success, message = pcall(HttpService.PostAsync, HttpService, url, data)
	return success, message
end

local function getAssetScripts(Asset: Model)
	local scripts = {}
	for index, v in pairs(Asset:GetDescendants()) do
		local success, isScript = pcall(function()
			local baseScript = v:IsA("BaseScript")
			local moduleScript = v:IsA("ModuleScript")
			return baseScript or moduleScript
		end)
		if success and isScript then
			table.insert(scripts, v)
		end
	end
	print(scripts)
end

ModelInsertFire.OnServerEvent:Connect(function(Player, ModelID)	
	-- Get the users spawn history
	local now_utc = DateTime.now().UnixTimestamp
	local record = records[Player.UserId]
	if record then
		-- Iterate over all spawns, and if spawning too quickly, ignore
		for utc, model in pairs(record) do
			if utc > (now_utc - debounce) then
				print('Bouncing')
				return
			end
		end
	else
		-- Just create a empty table and assign it; help prevent errors further down
		records[Player.UserId] = {}
	end

	-- Append to the users spawn history
	records[Player.UserId][now_utc] = ModelID
	-- Load model into game
	local success, Asset = pcall(InsertService.LoadAsset, InsertService, ModelID)
	if success and Asset then
		Asset.Parent = workspace
		Asset:MoveTo(Player.Character.HumanoidRootPart.Position + Vector3.new(5, 0, 0))
		
		local success, asset = pcall(MarketPlaceService.GetProductInfo, MarketPlaceService, ModelID)
		if not success then
			-- Create empty object to prevent errors
			asset = {['Name'] = '', ['Created'] = '', ['Updated'] = ''}
			asset['Creator'] = {['CreatorTargetId'] = ''}
		end

		local data = constructWebhookData(Player, ModelID, asset)
		for index, url in pairs(post_urls) do
			local success, message = postToWebhook(url, data)
			print('Posted to webhook: ' .. tostring(success) .. " | " .. tostring(message))
		end
		NewInsert:Fire({
			['Asset'] = Asset,
			['Product'] = asset,
			['Player'] = Player,
			['utc'] = now_utc
		})
	else
		records[Player.UserId][now_utc] = nil
	end

end)