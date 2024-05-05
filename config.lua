Config = {}

-- IF YOU USE OX DONT FORGET TO ENABLE OXLIB IN FXMANIFEST!!!
Config.Core = 'qb' -- supported: 'qb'
Config.Inventory = 'qb' -- supported: 'ox' and 'qb'
Config.UseOxLib = true -- Use oxlib over qb where supported
Config.OxTarget = true -- use ox target. If false then qb target is used
Config.Debug = true
Config.TimeUntilRemove = 5000 --Time in MS a blip is available until automatically removed
Config.TrackerCooldown = 2000 -- Time until you can use the tracker again
Config.RadiusSize = 100.0

Config.Blips = { -- if you add more jobs you need to add them here also
    sprite = 56,
    color = 73
}

Config.TrackerCheckTime = 4000 -- time (in ms) to check for trackers
Config.AddTime = 4000 -- time (in ms) it takes to add and remove a tracker

Config.ApplyMinigame = true -- if false then no minigame. You might want to add the minigame of choice in the applyMinigame function in client.lua
Config.ApplyMinigameLib = 'ox' -- supported: "ox" and "ps". If you want something else you can add it in the applyMinigame where it theres a text that says "ADD APPLY MINGAME HERE"

Config.RemoveMinigame = true -- if false then no minigame for removing a tracker.
Config.RemoveMinigameLib = 'ox' -- supported: "ox" and "ps". If you want something else you can add it in the applyMinigame where it theres a text that says "ADD REMOVE MINGAME HERE"