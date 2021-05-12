# AMXX Plugins Random Folder

## Introduction

Those plugins are simple tests, features exploring or examples that are worth sharing to other devs but not exactly useful for players in the current state.

Plugins made for [Counter Strike 1.6](https://store.steampowered.com/app/10/CounterStrike/) using [AMX ModX](https://github.com/alliedmodders/amxmodx).

## Plugins

* [test-conditionals](#test-conditionals) 
* [test-configmenu](#test-configmenu) 
* [test-fakeinputs](#test-fakeinputs) 
* [test-fov](#test-fov) 
* [test-jctf_flag](#test-jctf_flag) 
* [test-regex](#test-regex) 
* [test-speed](#test-speed) 
* [test-status-text2](#test-status-text2)

### [test-conditionals](./test-conditionals.sma)

Tests to verify how the conditions are executed inside an "if" clause in a Small/Pawn plugin. 

| Command | Description |
| --- | --- |
|say /test | Print tests results |


Spoiler: ```if (1 || do_something())``` won't ```do_something()```

### [test-configmenu](./test-configmenu.sma)

An implementation of a player configuration menu using new menu system, based on the [Admin ESP Menu](https://forums.alliedmods.net/showthread.php?t=23691) by KoST as example.

| Command | Description |
| --- | --- |
|say /test | Player config menu |
|say /test2 | General config menu |
|say /esp | Disable changing config |

### [test-fakeinputs](./test-fakeinputs.sma)

Normally isn't possible to hook "slot1-slot10" inputs, but this test uses an invisible menu to catch those inputs seamless to the player.

| Command | Description |
| --- | --- |
|say /test | Enable/disable fakeinputs menu |

### [test-fillammo](./test-fillammo.sma)

Fill player primary and secundary weapons's clip and backpack ammo. This is a bit tricky because the default "cstrike" module can only get active weapon info.

| Command | Description |
| --- | --- |
|say /test | Fill player ammo |

### [test-fov](./test-fov.sma)

Changes player's fov on say command.

| Command | Description |
| --- | --- |
|say /fov <10-150> | Set fov to argument or 90 (default) |

### [test-jctf_flag](./test-jctf_flag.sma)

Implement a forward "jctf_flag" that shows how to hook flag events from [Digi's jCTF](https://github.com/OsweRRR/jCTF-by-Digi). 

### [test-regex](./test-regex.sma)

Simple regex example. Find tokens in "say" client command and echos back with replacements. On default settings echos back client saytext with pontuations replaces by "X".

| Cvar | Default | Description |
| --- | --- | --- |
| amx_regex_find | "\[^a-zA-Z0-9 _\]" | Regex tokens to find in 'say' command |
| amx_regex_replace | "X" | Replacement to tokens found |

### [test-speed](./test-speed.sma)

Small useful speed printing plugin for testing.

| Command | Description |
| --- | --- |
|say /speed | Show speed on center |

### [test-status-text2](./test-status-text2.sma)

Hooks and modifies the default StatusBar to display a custom text when a player aims at another player. This is particularly interesting alternative to just block default StatusBar in favor to a hudmessage to display custom info.