# CW Vehicletrackers

Track your friends and enemies with item based trackers and recievers.

### THE ITEMS BELONGING TO THIS SCRIPT **CAN NOT** BE SPAWNED USING `/ADDITEM`.

Might have some limitations and issues with qb-inventory and qb-target. Made mainly for ox-inventory.
Supports ox skillcheck and ps-ui minigames

- Works with either QBcore or Oxlib for notifications, progressbars
- Requires either OXlib or PS-ui for minigames, you can disable these in config if you don't want to 
use either

> Probably coming soon: different versions of trackers for smaller circles etc

### Looking for an active tracker system for EMS vehicles?
Check out [emsblips on our Tebex](https://cw-scripts.tebex.io/package/6243469)

# Preview 📽
[![YOUTUBE VIDEO](http://img.youtube.com/vi/EEI0hgq5i5I/0.jpg)](https://youtu.be/EEI0hgq5i5I)


# Links
### ⭐ Check out our [Tebex store](https://cw-scripts.tebex.io/category/2523396) for some cheap scripts ⭐
### 🥳 Get more [Free scripts](https://github.com/stars/Coffeelot/lists/cw-scripts) 🥳

### Join the CW discord for support, and patch notes:
[![Join The discord!](https://cdn.discordapp.com/attachments/977876510620909579/1236658007866085417/join-us-discord.png?ex=6638cf05&is=66377d85&hm=00a75b46f1d602c8aaea61dfab676bd0f26f4495a77d98a19a65eb04b59ef11c&)](https://discord.gg/FJY4mtjaKr)


# Install

## 1. Add items

> The following are for Ox inventory, if you use QB or PS or whatever, make sure it the item is correctly added to the inventory system
```lua
	["cw_tracking_pair"] = {
		label = "GPS Tracker & receiver",
		description = "A GPS tracker and a receiver for it",
		weight = 1,
		stack = false,
		close = true

	},
	["cw_receiver"] = {
		label = "Tracker receiver",
		description = "A receiver for a GPS tracker",
		weight = 1,
		stack = false,
		close = true
	},
	["cw_tracker"] = {
		label = "A GPS Tracker",
		description = "A GPS tracker",
		weight = 1,
		stack = false,
		close = true
	},
```

## 2. Add a way to get the item
Add a way to get ahold of the `GPS Tracker & receiver`. CAN NOT BE SPAWNED VIA ADDITEM COMMAND! You can spawn one in via using the *server side* `createTrackerPair` export, for example:
```lua
    exports['cw-vehicletrackers']:createTrackerPair(source) -- where source is the source of the player who you want to give it to
```
This will give the player the item. For example, you can create an npc that gives these, or add it as loot.

# Using

## Apply the tracker
Use the `GPS Tracker & receiver` item near a vehicle to add it. This creates a new item in your inventory.

## Use the reciever
Use the `Tracker receiver` to ping the tracker. This will mark the target vehicle on the map in a radius. Radius size can be configured in Config.

## Take the tracker off
To take the tracker off you can *eye* the vehicle and select check for trackers. If you find one you can remove it.
If you remove a tracker you'll get a GPS tracker item. This item can be placed on any other vehicle and is tied to the same reciever, so if you got someone tailing you you can send them on a goose chase by putting it on another vehicle!

> Tracker is removed if you put the vehicle in a garage

> See config for more options and tweaks
