# AMXX Plugins

## Introduction

Plugins made for [Counter Strike 1.6](https://store.steampowered.com/app/10/CounterStrike/) using [AMX ModX](https://github.com/alliedmodders/amxmodx).

## Plugins

* [AdvancedObserver](#AdvancedObserver) 
* [AimPrecision](#AimPrecision) 
* [AimTrainer](#AimTrainer) 
* [Cameras](#Cameras) 
* [EnhancedAutoDemo](#EnhancedAutoDemo)
* [EnhancedMultiJump](#EnhancedMultiJump) 
* [EnhancedParachuteLite](#EnhancedParachuteLite) 
* [EntitiesUtils](#EntitiesUtils) 
* [MaxSpeed](#MaxSpeed) 
* [QueryCvar](#QueryCvar) 
* [TeamUtils](#TeamUtils) 

### [AdvancedObserver](./lonewolf-AdvancedObserver.sma)

Brings many quality-of-life features for spectators/observers focused on Clan-vs-Clans matches and big matches.

#### Features:

* New key (+camera_grenade) to follow grenades like CSGO;
* Observers will be able to see even if target is blinded (like CSGO);
* Find player by proximity and direction using WASD keys;
* While in Free Look switches to nearest target in Observer's vision just by left clicking (+attack);
* Fast deathcam, automatically switches targets for fast-paced combat instead of default random next player;
* New key (+camera_c4) to switch target to C4 owner or entity if dropped or planted;
* New keys (+camera_flag_red/+camera_flag_blue) to support [Digi's jCTF](https://github.com/OsweRRR/jCTF-by-Digi) matches;
* Fixes missing observer's crosshair;
* Fixes wrong angles and origin when switching to Free Look;
* Fixes bugs related to 'mp_forcecamera', "mp_forcechasecam" and targets;

#### Commands

| Command | Alternative | Description |
| --- | --- | --- |
| say /obs | | Enable/disable Advanced Observer features |
| say /obsdebug | | Enable/disable Advanced Observer debug |
| say /debug | | Print debug |
| +camera_grenade | +reload | Real time target's grenade following |
| | slot1 | Switches target to next Terrorist alive |
| | slot2 | Switches target to next Counter-terrorist alive |
| +camera_c4 | slot5 | Follow player holding C4 or C4 entity if dropped or planted |
| +camera_flag_red | slot6 | Follow player holding Red Flag or Red Flag entity if dropped or in stand |
| +camera_flag_blue | slot7 | Follow player holding Blue Flag or Blue Flag entity if dropped or in stand |
| +camera_chase | | Hold key to keep Observer mode to Locked Chase |
| +camera_hook | | Switch to aimed target while in Free look |


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

### [Cameras](./lonewolf-Cameras.sma)

Easy to configure Fixed Cameras Teleports plugin for spectator usage with objective to dynamize matches' online streaming. Fully configurable by menu or by editing server's "maps/\<mapname\>.cameras" file, which is automatically generated when saved in-game by an admin with [ADMIN_CVAR](https://wiki.alliedmods.net/Adding_Admins_(AMX_Mod_X)#Access_Levels) flag. Perfect combo to [AdvancedSpectator](#AdvancedSpectator).

| Command | Description |
| --- | --- |
| say /cam | Open Cameras' teleport menu |
| say /cam \<number\> | Teleport to Camera \<number\> without menu prompt |
| say /camcfg | Open Cameras' config menu |
| +cameras_shift | Hold to add +10 to "say /cam" argument |

| Cvar | Default | Description |
| --- | --- | --- |
| amx_cameras_enabled | "1" | \<0/1\> Disable/Enable Cameras Plugin |
| amx_cameras_spec_only | "1" | \<0/1\> Only spectators can use Cameras |

### [EnhancedAutoDemo](./lonewolf-EnhancedAutoDemo.sma)


Demo recorder plugin with timestamp, server name, ip, mapname that footprints all players nick and steamid on demo start. No-config-needed made from scratch replacement for [Auto Demo Recorder](https://forums.alliedmods.net/showthread.php?p=770786) by IzI with the main objective of recording demos with unique filename for Clan Fights.

Enhancements:
* Configurable parameters on filename: clan prefix, timestamp, steamid, nickname and mapname;
* Report server and players info on client's console on demo start, including server's hostname, IP address, mapname, timestamp and a list of players in server with nickname and steamid;
* Auto stopping demo recording on map change;

| Command | Usage |
| --- | --- |
| amx_demo | amx_demo \<0 or * or ID or NICK or STEAMID\> |
| amx_demoall | Same as "amx_demo *" |
| amx_demomenu | Open demo record menu |

| Cvar | Default | Description |
| --- | --- | --- |
| amx_demo_auto | "1" | Record demo on client connect |
| amx_demo_time | "0" | Append timestamp on demo filename |
| amx_demo_map | "0" | Append mapname on demo filename |
| amx_demo_steam | "0" | Append steamid on demo filename |
| amx_demo_nick | "0" | Append nickname on demo filename |
| amx_demo_notify | "1" | Print demo info on chat on record start |
| amx_demo_name | "EnhancedAutoDemo" | Base prefix for demo filename |
| amx_demo_prefix | "EnhancedAutoDemo" | Chat prefix |
| amx_demo_autostop | "1" | Automatically stop demo on map end |

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

### [EntitiesUtils](./lonewolf-EntitiesUtils.sma)

Work-in-progress plugin with useful entities info commands.

| Command | Description |
| --- | --- |
| entities_list \<number\> | Print 30 entities's ID, Classname and Model starting from \<number\> |

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
| amx_maxspeed_noaccel | "0" | \<0-15\> Bitsum: 1-Airstrafe noaccel, 2-Swim noaccel, 4-Surf noaccel, 8-Use noaccel |

### [QueryCvar](./lonewolf-QueryCvar.sma)

Admin command to query an user's config by id, user steam or nickname.

| Command | Usage |
| --- | --- |
|query | query \<0 or id or name or authid\> \<cvar\> |

### [TeamUtils](./lonewolf-TeamUtils.sma)

Useful admins commands to swap or shuffle teams while keeping player's scores.

| Command | Description |
| --- | --- |
| amx_shuffleteams | Shuffle teams and restart game keeping player's score |
| amx_swapteams | Swap teams and restart game keeping player's score |