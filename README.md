# AMXX Plugins

## Introduction

Plugins made for [Counter Strike 1.6](https://store.steampowered.com/app/10/CounterStrike/) using [AMX ModX](https://github.com/alliedmodders/amxmodx).

## Plugins

* [AdvancedObserver](#AdvancedObserver) 
* [AimPrecision](#AimPrecision) 
* [AimTrainer](#AimTrainer) 
* [EnhancedMultiJump](#EnhancedMultiJump) 
* [EnhancedParachuteLite](#EnhancedParachuteLite) 
* [MaxSpeed](#MaxSpeed) 
* [QueryCvar](#QueryCvar) 
* [SwapTeams](#SwapTeams) 

### [AdvancedObserver](./lonewolf-AdvancedObserver.sma)

Brings many quality-of-life features for spectators/observers focused on Clan-vs-Clans matches and big matches.

#### Features:

* New key (+camera_grenade) to follow grenades like CSGO;
* Observers will be able to see even if target is blinded (like CSGO);
* Find player by proximity and direction with WASD keys;
* Fast deathcam, automatically switches targets for fast-paced combat instead of default random next player;
* New key (+camera_c4) to switch target to C4 owner or entity if dropped or planted;
* New keys (+camera_flag_red/+camera_flag_blue) to support [Digi's jCTF](https://github.com/OsweRRR/jCTF-by-Digi) matches;
* Fixes missing observer's crosshair;
* Fixes wrong angles and origin when switching to Free Look;
* Fixes bugs related to 'mp_forcecamera' and targets;

### [AimPrecision](./lonewolf-AimPrecision.sma)

Reversed enginered Counter-Strike's pseudo random for shot spread and precision real time visualization with laser beams for training purposes. Implemented for AK-47 and Deagle only. (Why would you use anything else?)

| Command | Description |
| --- | --- |
|say /precision | Enable/disable AimPrecision laserbeam |

### [AimTrainer](./lonewolf-AimTrainer.sma)

Tracks user's Deagle shot precision and timing, informing if shot was in perfect conditions of precision and how late or early was the shot time in relation with the minimum recovery time.

| Command | Description |
| --- | --- |
|say /aim | Enable/disable AimTrainer info |

### [EnhancedMultiJump](./lonewolf-EnhancedMultiJump.sma)

Based on twistedeuphoria's [MultiJump](https://forums.alliedmods.net/showthread.php?t=10159) this plugin uses Counter Strike's [jump implementation](https://github.com/s1lentq/ReGameDLL_CS/blob/e86284b08cb7dcae3c66cc08262e88d7b81dbafc/regamedll/pm_shared/pm_shared.cpp#L2345) to make multi jumps that behave like real jumps.

#### Features:

* User now can smoothly jump with mouse scroll without accidently triggering multi jumps;
* Air jumps don't just throw the player up like the original, it works like a normal CS 1.6 jump, correctly setting player's friction/fuser2;
* Auto-jumping with maximum height just by holding spacebar;
* Auto-compensating vertical velocity to stardardize jump height independently of custom gravity, player's FPS or bad timing;
* No jump height randomness like the original;
* Improved airjump flexibility by enabling it even if player didn't jump before leaving ground, like falling on ledge or double ducking;
* Proper handling of ladder jump, further improving the range of movements;

| Cvar | Default | Description |
| --- | --- | --- |
|amx_maxjumps | "1" | \<int\> maximum number of airjumps |

### [EnhancedParachuteLite](./lonewolf-EnhancedParachuteLite.sma)

Parachute plugin based on CSRevo's [Parachute Lite](https://www.csrevo.com/2019/09/plugin-paraquedas-lite.html) by Wilian M. with few rare bugs corrected and configurable anti speed abuse features.

| Cvar | Default | Description |
| --- | --- | --- |
| parachute_fallspeed | "100" | \<0-2000\> Parachute fallspeed. |
| parachute_noaccel | "0" | \<0\|1\> Disable speed gain on parachute. |
| parachute_maxspeed | "2000" | \<0-2000\> Parachute maxspeed. |

### [MaxSpeed](./lonewolf-MaxSpeed.sma)

Anti-acceleration abuse plugin, limits the maximum speed or even acceleration in many different scenarios in a smooth fashion while maintaining the velocity direction for better user experience.

| Command | Description |
| --- | --- |
| say /speed | Enables real time speed and max speed info for debug purposes |

| Cvar | Default | Description |
| --- | --- | --- |
| amx_maxspeed_enabled | "1" | \<0/1\> Disable/Enable MaxSpeed Plugin |
| amx_maxspeed | "400" | \<0-2000\> Maximum airspeed) |
| amx_maxspeed_surfspeed | "2000" | \<0-2000\> Maximum speed while surfing |
| amx_maxspeed_duckspeed | "300" | \<0-2000\> Maximum speed after double-ducking |
| amx_maxspeed_swimspeed | "400" | \<0-2000\> Maximum speed on water |
| amx_maxspeed_usespeed | "400" | \<0-2000\> Maximum speed holding +use, usually applied for parachute |
| amx_maxspeed_debug | "0" | \<0/1\> Enables "say /speed" command |
| amx_maxspeed_noaccel | "0" | \<0-7\> Bitsum: 1-Airstrafe noaccel \| 2-Swim noaccel \| 4-Surf noaccel |

### [QueryCvar](./lonewolf-QueryCvar.sma)

Admin command to query an user's config by id, user steam or nickname.

| Command | Usage |
| --- | --- |
|query | query \<0 or id or name or authid\> \<cvar\> |

### [SwapTeams](./lonewolf-SwapTeams.sma)

Adds a simple admin command to restart the game and swap teams while keeping player's and team's scores. Guaranteed to keep player's scores but may not team's scores if there is another plugin controling it like jCTF or some PUG MIX plugins.

| Command | Description |
| --- | --- |
| amx_swapteams | Swap teams and restart game keeping player's score |