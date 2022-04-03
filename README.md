# AMXX Plugins

## Introduction

Plugins made for [Counter Strike 1.6](https://store.steampowered.com/app/10/CounterStrike/) using [AMX Mod X](https://github.com/alliedmodders/amxmodx).

## Plugins

* [Advanced Observer](#advanced-observer) 
* [Advanced Observer Reapi](#advanced-observer-reapi) 
* [Aim Precision](#aim-precision) 
* [Aim Trainer](#aim-trainer) 
* [Anti Duck Scroll](#anti-duck-scroll) 
* [Enhanced Auto Demo](#enhanced-auto-demo)
* [Enhanced Flashbang Reapi](#enhanced-flashbang-reapi)
* [Enhanced MultiJump](#enhanced-multiJump) 
* [Enhanced Parachute Lite](#enhanced-parachute-lite) 
* [Fix FPS Speed](#fix-fps-speed)
* [Maxspeed](#maxspeed) 
* [MOTD Rules](#motd-rules)
* [Observer Cameras](#observer-cameras) 
* [Place Models](#place-models) 
* [Utils: Entities](#utils-entities) 
* [Utils: Query Cvar](#utils-query-cvar)
* [Utils: Teams](#utils-team) 

### [Advanced Observer](./advanced_observer.sma)

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
| say /obs | | Enable/disable Advanced Observer features. |
| say /obsdebug | | Enable/disable Advanced Observer debug. |
| say /debug | | Print debug. |
| +camera_grenade | +reload | Real time target's grenade following. |
| | slot1 | Switches target to next Terrorist alive. |
| | slot2 | Switches target to next Counter-terrorist alive. |
| +camera_c4 | slot5 | Follow player holding C4 or C4 entity if dropped or planted. |
| +camera_flag_red | slot6 | Follow player holding Red Flag or Red Flag entity if dropped or in stand. |
| +camera_flag_blue | slot7 | Follow player holding Blue Flag or Blue Flag entity if dropped or in stand. |
| +camera_chase | | Hold key to keep Observer mode to Locked Chase. |
| +camera_hook | | Switch to aimed target while in Free look. |

### [Advanced Observer Reapi](./advanced_observer_reapi.sma)

#### WORK IN PROGRESS!

Reapi rework of [Advanced Observer](#advanced-observer), focusing on better server performance and safety.

### [Aim Precision](./aim_precision.sma)

Reversed enginered Counter-Strike's pseudo random for shot spread and precision real time visualization with laser beams for training purposes. Implemented for AK-47 and Deagle only. (Why would you use anything else?)

| Command | Description |
| --- | --- |
|say /precision | Enable/disable AimPrecision laserbeam. |

### [Aim Trainer](./aim_trainer.sma)

Tracks user's Deagle shot precision and timing, informing if shot was in perfect conditions of precision and how late or early was the shot time in relation with the minimum recovery time.

| Command | Description |
| --- | --- |
|say /aim | Enable/disable AimTrainer info. |

### [Anti Duck Scroll](./anti_duck_scroll.sma)

Anti duck scroll plugin. 

| Cvar | Default | Description |
| --- | --- | --- |
| amx_dd_delay | 20.0 | Maximum delay to be counted as a scroll double duck. Setting bigger values than default may impact double duck with ```ctrl``` |

### [Enhanced Auto Demo](./enhanced_auto_demo.sma)


Demo recorder plugin with timestamp, server name, ip, mapname that footprints all players nick and steamid on demo start. No-config-needed made from scratch replacement for [Auto Demo Recorder](https://forums.alliedmods.net/showthread.php?p=770786) by IzI with the main objective of recording demos with unique filename for Clan Fights.

Enhancements:
* Configurable parameters on filename: clan prefix, timestamp, steamid, nickname and mapname;
* Report server and players info on client's console on demo start, including server's hostname, IP address, mapname, timestamp and a list of players in server with nickname and steamid;
* Auto stopping demo recording on map change;

| Command | Description |
| --- | --- |
| amx_demo | Start recording for selected players.<br/>`amx_demo 0` - Record all players<br/>`amx_demo *` - Record all players<br/>`amx_demo 1` - Record player with id "1"<br/>`amx_demo lonewolf` - Record player with name "lonewolf"<br/>`amx_demo STEAM_0:0:8354200` - Record player with authid "STEAM_0:0:8354200" |
| amx_demoall | Same as `amx_demo *`. |
| amx_demomenu | Open demo record menu. |

| Cvar | Default | Description |
| --- | --- | --- |
| amx_demo_auto | 1 | Record demo on client connect. |
| amx_demo_time | 0 | Append timestamp on demo filename. |
| amx_demo_map | 0 | Append mapname on demo filename. |
| amx_demo_steam | 0 | Append steamid on demo filename. |
| amx_demo_nick | 0 | Append nickname on demo filename. |
| amx_demo_notify | 1 | Print demo info on chat on record start. |
| amx_demo_name | "EnhancedAutoDemo" | Base prefix for demo filename. |
| amx_demo_prefix | "EnhancedAutoDemo" | Chat prefix. |
| amx_demo_autostop | 1 | Automatically stop demo on map change. |

### [Enhanced Flashbang Reapi](./enhanced_flashbang_reapi.sma)

Initially created to fix an old bug on the flashbang's blinding logic that if a player has been totally blinded, but the flash hasn't fully faded, any other flashbang will totally blind him, even if it explodes behind his back. It also implements options to not blind teammates, totally or partially, or the player itself.

| Cvar | Default | Description |
| --- | --- | --- |
| amx_flash_fix | 1 | Fixes flashbang's blinding logic when turned around.<br/>`0` disabled<br/>`1` enabled |
| amx_flash_team | 0 | Allow team flashing.<br/>`0` don't flash teammates<br/>`1` always flash teammates<br/>`2` only flash teammates if `mp_friendlyfire` is enabled<br/>`3` partially blind teammates" |
| amx_flash_self | 1 | When set the flashbang will blind its owner.<br/>`0` disabled<br/>`1` enabled |

### [Enhanced MultiJump](./enhanced_multijump.sma)

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
| amx_maxjumps | 1 | Maximum number of air jumps.<br/>`0` only standard jump<br/> `1-9999` number of air jumps|
| amx_airjumplikebhop | 0 | Should the horizontal speed of air jump works like in a standard bhop in CS 1.6.<br/>`0` unlimited speed while air jumping<br/>`1` limit speed higher than ~120% of current weapon's maximum speed |

### [Enhanced Parachute Lite](./enhanced_parachute_lite.sma)

Parachute plugin based on CSRevo's [Parachute Lite](https://www.csrevo.com/2019/09/plugin-paraquedas-lite.html) by Wilian M. with few rare bugs corrected and configurable anti speed abuse features.

| Cvar | Default | Description |
| --- | --- | --- |
| parachute_fallspeed | 100 | Parachute fallspeed.<br/>`0 - 2000` fallspeed in units/s |
| parachute_noaccel | 0 | Acceleration behavior on parachute.<br/>`0` normal speed behavior<br/>`1` player is unable to gain speed while using parachute|
| parachute_maxspeed | 2000 | Parachute maximum speed.<br/>`0 - 2000` player's maximum speed while using parachute |

### [Fix FPS Speed](./fix_fps_speed.sma)

#### WORK IN PROGRESS!

Plugin to fix the unfair acceleration on clients with high FPS. Works good on ```sv_airaccelerate 100``` and could be enough for some servers, but I am still working on calculations. Feedback appreciated.

| Cvar | Default | Description |
| --- | --- | --- |
| amx_fix_fps_speed | 1 | FPS Speed fix behavior<br/>`0` Disabled, default speed<br/>`1` Enabled |


### [Maxspeed](./maxspeed.sma)

Anti-acceleration abuse plugin, limits the maximum speed or even acceleration in many different scenarios in a smooth fashion while maintaining the velocity direction for better user experience.

| Command | Description |
| --- | --- |
| say /speed | Enables real time speed and max speed info for debug purposes |

| Cvar | Default | Description |
| --- | --- | --- |
| amx_maxspeed_enabled | 1 | Globally enables Max Speed Plugin.<br/>`0` disabled<br/>`1` enabled |
| amx_maxspeed | 400 | Maximum air speed in a normal jump.<br/>`0 - 2000` in units/s |
| amx_maxspeed_surfspeed | 2000 | Maximum speed while surfing.<br/>`0 - 2000` in units/s |
| amx_maxspeed_duckspeed | 300 | Maximum speed after double-ducking.<br/>`0 - 2000` in units/s |
| amx_maxspeed_swimspeed | 400 | Maximum speed under water.<br/>`0 - 2000` in units/s |
| amx_maxspeed_usespeed | 400 | Maximum speed holding `+use`, usually applied for parachute.<br/>`0 - 2000` in units/s |
| amx_maxspeed_debug | 0 | Allow debug.<br/>`0` normal behavior<br/>`1` enables `say /speed` command |
| amx_maxspeed_noaccel | 0 | `0 - 15` Bitsum:<br/> `1` disable airstrafe acceleration<br/>`2` disable swim acceleration<br/>`4` disable surf acceleration<br/>`8` disable `+use` acceleration<br/> Example:<br/>`amx_maxspeed_noaccel 11` is the bitsum of `1 + 4 + 8` and removes acceleration for normal jumping, surfing and `+use`, while keeping freely allowing player to surf. |
| amx_maxspeed_relative | 1 | Sets the player's maximum speed relative to his actual maximum speed weapon, using knife' maxspeed of 250 units/s as reference.<br/>`0` maximum speed configured is absolute for any weapon<br/>`1` maximum speed respects player's actual entity's maxspeed|

### [MOTD Rules](./motd_rules.sma)

Simple file based MOTD viewer with custom path defined by cvar. Just configure your ```filename.html``` or ```filename.txt``` and point the configuration cvar to the right path. Uses a regex based filename checker to guarantee that file is a html or txt file.

| Command | Description |
| --- | --- |
| say /rules | Show Rules MOTD |

| Cvar | Default | Description |
| --- | --- | --- |
| amx_rulesfile | "rules.html" | Rules file **Absolute** path. By default has its roots on ```cstrike/``` folder.|

### [Observer Cameras](./observer_cameras.sma)

Easy to configure Fixed Cameras Teleports plugin for spectator usage with objective to dynamize matches' online streaming. Fully configurable by menu or by editing server's "maps/\<mapname\>.cameras" file, which is automatically generated when saved in-game by an admin with [ADMIN_CVAR](https://wiki.alliedmods.net/Adding_Admins_(AMX_Mod_X)#Access_Levels) flag. Perfect combo to [Advanced Observer](#advanced-observer).

| Command | Description |
| --- | --- |
| say /cam | Open Cameras' teleport menu |
| say /cam \<number\> | Teleport to Camera \<number\> without menu prompt |
| say /camcfg | Open Cameras' config menu |
| +cameras_shift | Hold to add +10 to "say /cam" argument |

| Cvar | Default | Description |
| --- | --- | --- |
| amx_cameras_enabled | 1 | Globally enables cameras usage<br/>`0` disabled<br/>`1` enabled |
| amx_cameras_spec_only | 1 | Who can use can use cameras<br/>`0` everyone, alive or dead<br/>`1` only spectators |

### [Place Models](./place_models.sma)

#### WORK IN PROGRESS!

In-map configurable static models placer, focused on simplicity to set origin and angle, configurable model list and skins. Still in alpha and do not save placed models or distinguish mapnames.

| Command | Description |
| --- | --- |
| say /place | Opens PlaceModels menu |
| say /models | Toggle rendering of placed models, player based |

### [Utils: Entities](./utils_entities.sma)

Work-in-progress plugin with useful entities info commands.

| Command | Description |
| --- | --- |
| entities_list `<number>` | Print 30 entities's ID, Classname and Model starting from `<number>` |

### [Utils: Query Cvar](utils_query_cvar.sma)

Admin command to query an user's config by id, user steam or nickname.

| Command | Usage |
| --- | --- |
|query | query `0` or `id` or `name` or `authid` `cvar` |

### [Utils: Teams](./utils_teams.sma)

Useful admins commands to swap or shuffle teams while keeping player's scores.

| Command | Description |
| --- | --- |
| amx_shuffleteams | Shuffle teams and restart game keeping player's score |
| amx_swapteams | Swap teams and restart game keeping player's score |