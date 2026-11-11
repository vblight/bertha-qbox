Config = {}
Config.Framework = 'qbox'
Config.Inventory = 'ox'
Config.Target = 'ox'
Config.VehicleModel = 'rboxville' -- separate bertha_boxville add-on
Config.VehiclePlate = 'RECYCLE1' -- dedicated persistent job vehicle; change for another van
Config.MaxTyres = 24
Config.RubberItem = 'rubber'
Config.RubberPerTyre = 4
Config.RubberRollItem = 'rubber_roll'
Config.RubberPerRoll = 10 -- 10 stored rubber -> 1 roll
Config.BerthaRollCapacity = 24
Config.PersistCargo = true
Config.RequireJob = false
Config.AllowedJobs = { recycler = true }
Config.CarryProp = 'prop_wheel_tyre'
Config.CarryAnim = { dict = 'anim@heists@box_carry@', clip = 'idle' }
Config.CarryOffset = { x = 0.03, y = 0.15, z = -0.14, rx = -15.0, ry = 90.0, rz = 10.0 }
Config.CargoProp = 'prop_wheel_tyre'
-- Boxville local axes: negative Y is toward the REAR, positive Y toward the cab.
-- Three tyres across by four rows, with a second layer stacked above.
-- These are tunable offsets; exact fit depends on the Boxville variant.
-- Cargo fit tuning (vehicle-local metres). Adjust these three values after a screenshot.
-- Lowers the entire stack and reduces the gap between layers.
Config.CargoBaseZ = 0.20      -- previously 0.456
Config.CargoLayerStepZ = 0.20 -- previously 0.32
Config.CargoRearShiftY = 0.0  -- negative moves toward rear doors
Config.CargoSlots = {}
for i = 1, 24 do
    local index = (i - 1) % 12
    local layer = math.floor((i - 1) / 12)
    local col = index % 3
    local row = math.floor(index / 3)
    Config.CargoSlots[i] = {
        x = -0.62 + col * 0.62,
        y = -0.85 - row * 0.60 + Config.CargoRearShiftY,
        z = Config.CargoBaseZ + layer * Config.CargoLayerStepZ,
        rx = 90.0, ry = 0.0, rz = 0.0
    }
end
-- Set to 'none' if your server uses a different key system.
Config.VehicleKeys = 'none' -- configure vehicle keys for your Qbox installation; see QBOX_SETUP.md
-- Rear doors automatically open when approaching the back of the parked fleet van.
Config.RearDoors = {
    enabled = true,
    openDistance = 3.5,
    closeDistance = 5.0,
    rearOffsetY = -3.0, -- vehicle-local distance behind the model origin
    maxSpeed = 0.8, -- metres/second: don't operate doors while driving
    indices = { 2, 3 }, -- GTA rear left / rear right
}
Config.LoadDistance = 4.5
Config.ShredderDistance = 4.0
Config.ShredderModel = 'prop_rubber_shredder'
-- Rogers Salvage & Scrap, La Puerta. These starter points are approximate;
-- use /recycleaddspot while standing at a good spot to save exact placements.
-- Z is resolved against ground at runtime. Existing maps/MLOs may need adjustments.
Config.TyreSpots = {
    { coords = vector3(-454.0, -1703.0, 18.8), heading = 20.0 },
    { coords = vector3(-451.0, -1711.0, 18.8), heading = 75.0 },
    { coords = vector3(-444.0, -1716.0, 18.8), heading = 130.0 },
    { coords = vector3(-437.0, -1709.0, 18.8), heading = 45.0 },
    { coords = vector3(-432.0, -1699.0, 18.8), heading = 95.0 },
    { coords = vector3(-442.0, -1694.0, 18.8), heading = 0.0 },
    { coords = vector3(-463.0, -1695.0, 18.8), heading = 180.0 },
    { coords = vector3(-466.0, -1708.0, 18.8), heading = 55.0 },
}
Config.CollectionRespawnSeconds = 900 -- 15 minutes
Config.CollectionStreamDistance = 85.0
Config.DebugCommands = true -- DEVELOPMENT ONLY: disable on public servers
Config.DebugRequireAce = false -- DEVELOPMENT ONLY: set true and grant recycling.debug for public testing
Config.ShredderCoords = nil -- vector3(...) if using a permanently placed shredder

-- Big Bertha: local /testshredder objects work; no networked entity required.
Config.ShredDurationMs = 6000
Config.ShredderInteractionDistance = 3.0
Config.ShredderServerDistance = 5.0
-- For a public server, set this to Bertha's permanent world position.
-- nil allows test-spawned local Bertha to register its position automatically.
Config.BerthaPosition = nil -- vector3(x, y, z)

-- Unified Big Bertha configuration
Config.BerthaPosition = vector3(-469.740, -1668.932, 18.951)
Config.BerthaHeading = 0.0
Config.BerthaZOffset = -1.0 -- initial adjustment; tune using /berthaz -0.2 or /berthaz 0.2
Config.BerthaCapacity = 24
Config.BerthaOutputCapacity = 240
Config.BerthaProcessMsPerTyre = 12000
Config.BerthaAutoSpawn = true
Config.BerthaSound = true -- synthesized motor/grinding audio; browser audio unlocks on panel interaction
Config.BerthaSoundVolume = 0.20 -- 0.0 to 1.0; previously 0.035
Config.BerthaSoundRange = 22.0 -- sound fades out with distance (metres)
Config.BerthaSmoke = true -- smoke only while a batch is running
Config.BerthaSmokeScale = 0.85
Config.BerthaSmokeOffset = vector3(0.0, 0.0, 1.5) -- adjust to place smoke at the outlet


-- Recipes: seconds per unit. Rubber rolls and plastic run through the timed machine queue.
Config.BerthaProcessMsPerTyre = 12000
Config.BerthaProcessMsPerRoll = 20000
Config.BerthaPlasticScrapItem = 'plastic_scraps'
Config.BerthaPlasticPelletsItem = 'plastic_pellets'
Config.BerthaPlasticScrapsPerPellet = 2
Config.BerthaPlasticPelletsPerCraft = 1
Config.BerthaPlasticPelletsTimeMs = 25000
Config.BerthaPlasticCapacity = 240
Config.BerthaPlasticOutputCapacity = 240

Config.BerthaMaxQueue = 20 -- queued jobs (excluding the currently running job)

-- v4.5: real QB inventory tyres and searchable industrial skips.
Config.UsedTyreItem = 'used_tyre'
Config.SkipSearchEnabled = true
Config.SkipSearchModels = {'prop_skip_01a','prop_skip_02a','prop_skip_03','prop_skip_04','prop_skip_05a','prop_skip_06a'}
Config.SkipSearchSeconds = 6
Config.SkipSearchCooldownSeconds = 600
Config.SkipSearchPlayerCooldownSeconds = 20
Config.SkipSearchChance = 65 -- percent chance to find tyres
Config.SkipSearchMinReward = 1
Config.SkipSearchMaxReward = 3

-- Glass recycling (8 chunks -> 1 heavy sheet, 60 seconds per sheet).
Config.BerthaGlassChunkItem = 'glass_chunks'
Config.BerthaGlassSheetItem = 'glass_sheets'
Config.BerthaGlassChunksPerSheet = 8
Config.BerthaGlassTimeMs = 60000
Config.BerthaGlassCapacity = 160
Config.BerthaGlassOutputCapacity = 20
-- After a successful skip search, chance that the reward is glass instead of tires.
Config.SkipGlassRewardChance = 35
Config.SkipGlassMinReward = 1
Config.SkipGlassMaxReward = 4

-- Temporary legacy recycling-box exchange. Turn off when the old job is retired.
Config.SalvageWorker = {
    enabled = true,
    model = 's_m_m_dockwork_01',
    -- Provisional clear-floor position beside Bertha; adjust X/Y in game if needed.
    coords = vector4(-472.2, -1668.8, 18.951, 180.0),
    zOffset = 0.0, -- fixed feet/chair reference; never auto-snap to nearby lumber
    boxItem = 'recycling_box_test', -- replace with actual main-server item name later
    maxPerExchange = 25,
    secondsPerBox = 2,
    rewards = { -- per box; one randomly selected material
        { item = 'rubber', min = 2, max = 4, weight = 35 },
        { item = 'plastic_scraps', min = 2, max = 5, weight = 40 },
        { item = 'glass_chunks', min = 1, max = 3, weight = 25 },
    }
}

-- Box Man fleet desk. Temporary parking coordinates: adjust after checking the bay in game.
Config.Fleet = {
    enabled = true,
    spawn = vector4(-468.803, -1678.039, 19.050, 179.68),
    interactDistance = 4.0,
    livery = 0, -- first livery ("livery 1" in common vehicle menus)
    clearRadius = 4.0,
    -- One shared job van at a time: avoids duplicate vehicles using the same saved-cargo plate.
    requireEmptyToReturn = true,
}

-- Searchable skips use native ox_inventory stashes (normal drag-and-drop).
-- Native stash transfers are NOT restricted to recycling items without an inventory-side hook.
Config.SkipContainerEnabled = true
Config.SkipContainerSlots = 8
Config.SkipContainerMaxPerItem = 50
Config.SkipContainerAllowed = { [Config.UsedTyreItem or 'used_tyre']=true, [Config.BerthaGlassChunkItem or 'glass_chunks']=true, [Config.BerthaPlasticScrapItem or 'plastic_scraps']=true, [Config.RubberItem or 'rubber']=true }

Config.SkipNativeMaxWeight = 150000 -- 150kg per skip stash
