// "EnhancedAutoDemo" by lonewolf
// Check out more on: https://github.com/igorkelvin/amxx-plugins
//
// Made by scratch but very influenced by "amx_autodemorec" by "IzI"
// https://forums.alliedmods.net/showthread.php?p=770786

#include <amxmodx>
#include <engine>
#include <regex>
#include <cstrike>

#define PLUGIN  "Enhanced Auto Demo"
#define VERSION "0.5.1"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

#if !defined MAX_MAPNAME_LENGTH
#define MAX_MAPNAME_LENGTH 64
#endif

#define ADMIN_PERMISSION ADMIN_CVAR

new usages[][96] =
{
  "amx_demo <0 or * or ID or NICK or AUTHID>",
  "Example 1: amx_demo ^"1^" -> record demo of player #1 on ^"status^"",
  "Example 2: amx_demo ^"lonewolf^" -> record demo player with ^"lonewolf^" on nick",
  "Example 3: amx_demo ^"STEAM_0:0:8354200^"",
  "Example 4: amx_demo ^"0^" -> Record demo of all players",
  "Example 5: amx_demo ^"*^" -> Record demo of all players"
};

enum Cvars 
{
  AUTO,
  DEMO_PREFIX,
  CHAT_PREFIX,
  TIMESTAMP,
  MAPNAME,
  STEAMID,
  NICKNAME,
  NOTIFY,
  AUTOSTOP
};
new cvars[Cvars];

new steamids[MAX_PLAYERS+1][32];
new nicknames[MAX_PLAYERS+1][32];
new Float:last_record_time[MAX_PLAYERS+1];

new hostname[64];
new mapname[MAX_MAPNAME_LENGTH];
new ip[32];

new menu_demomenu_callback_id;

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR);
  
  cvars[AUTO]      = create_cvar("amx_demo_auto",     "1", _, "Record demo on client connect");  
  cvars[TIMESTAMP] = create_cvar("amx_demo_time",     "0", _, "Append timestamp on demo filename");
  cvars[MAPNAME]   = create_cvar("amx_demo_map",      "0", _, "Append mapname on demo filename");
  cvars[STEAMID]   = create_cvar("amx_demo_steam",    "0", _, "Append steamid on demo filename");
  cvars[NICKNAME]  = create_cvar("amx_demo_nick",     "0", _, "Append nickname on demo filename");
  cvars[NOTIFY]    = create_cvar("amx_demo_notify",   "1", _, "Notify user when recording");
  cvars[AUTOSTOP]  = create_cvar("amx_demo_autostop", "1", _, "Automatically stop demo on map end");
  
  cvars[DEMO_PREFIX] = create_cvar("amx_demo_name",   "EnhancedAutoDemo", _, "Base prefix for demo filename");
  cvars[CHAT_PREFIX] = create_cvar("amx_demo_prefix", "EnhancedAutoDemo", _, "Chat prefix");
  
  get_mapname(mapname, charsmax(mapname));
  get_user_ip(0, ip, charsmax(ip));
  get_cvar_string("hostname", hostname, charsmax(hostname))

  menu_demomenu_callback_id = menu_makecallback("menu_demomenu_callback");

  register_concmd("amx_demo",     "cmd_demo",     ADMIN_PERMISSION, usages[0]);
  register_concmd("amx_demoall",  "cmd_demoall",  ADMIN_PERMISSION, "Record demo of all players");
  register_concmd("amx_stopall",  "cmd_stopall",  ADMIN_PERMISSION, "Stop demo record of all players");

  register_clcmd("amx_demomenu", "cmd_demomenu", ADMIN_PERMISSION, "Open demo record menu");  

  register_message(SVC_INTERMISSION, "event_intermission");
}


public cmd_stopall(admin)
{
  // if (!is_user_connected(admin))
  // {
  //   return PLUGIN_HANDLED;
  // }

  for (new id = 1; id <= MaxClients; ++id)
  {
    if (is_user_connected(id))
    {
      client_cmd(id, "stop");
    }
  }

  return PLUGIN_HANDLED;
}

public client_authorized(id)
{
  get_user_authid(id, steamids[id], 31);
  get_user_name(id, nicknames[id], 31);

  last_record_time[id] = 0.0;
}


public client_infochanged(id) 
{
  get_user_name(id, nicknames[id], 31);
}


public client_disconnected(id)
{
  steamids[id][0]  = '^0';
  nicknames[id][0] = '^0';

  last_record_time[id] = 0.0;
}


public client_putinserver(id)
{
  if (!is_user_connected(id)) 
  {
    return;
  }
  
  if (get_pcvar_num(cvars[AUTOSTOP]))
  {
    client_cmd(id, "stop");
  }

  if (get_pcvar_num(cvars[AUTO]))
  {
    set_task(5.0, "task_start_demo", 1612 + id);
  }
}


public task_start_demo(id)
{
  id -= 1612;
  start_demo(id);
}

public print_usage(id)
{
  client_print(id, print_console, "^n");

  new len = sizeof(usages);
  for (new i = 0; i < len; ++i)
  {
    client_print(id, print_console, "[%s] %s", PLUGIN, usages[i]);
  }
  
  client_print(id, print_console, "^n");
}


public cmd_demo(admin)
{
  // if (!is_user_connected(admin))
  // {
  //   return PLUGIN_HANDLED;
  // }

  new argc = read_argc();
  if (argc < 2)
  {
    print_usage(admin);
    return PLUGIN_HANDLED;
  }
  
  new argv[32];
  read_argv(1, argv, charsmax(argv));

  if (argv[0] == '0' || argv[0] == '*')
  {
    for (new id = 1; id <= MaxClients; ++id)
    {
      if (is_user_connected(id))
      {
        start_demo(id);
      }
    }

    return PLUGIN_HANDLED;
  }

  new id = str_to_num(argv);
  if (id && is_user_connected(id))
  {
    start_demo(id);
    return PLUGIN_HANDLED;
  }

  id = find_player_ex(FindPlayer_MatchNameSubstring, argv);
  if (!id)
  {
    id = find_player_ex(FindPlayer_MatchAuthId, argv);
    if (!id)
    {
      id = str_to_num(argv);
    }
  }
  
  if (is_user_connected(id))
  {
    start_demo(id);
  }
  else if (is_user_connected(admin))
  {
    client_print(admin, print_console, "^n[%s] Player not found!", PLUGIN);
    print_usage(admin);
  }

  return PLUGIN_HANDLED;
}


public cmd_demoall(admin)
{
  // if (!is_user_connected(admin))
  // {
  //   return PLUGIN_HANDLED;
  // }

  for (new id = 1; id <= MaxClients; ++id)
  {
    if (is_user_connected(id))
    {
      start_demo(id);
    }
  }

  return PLUGIN_HANDLED;
}


public cmd_demomenu(admin)
{
  if (is_user_connected(admin))
  {
    menu_demomenu(admin);
  }

  return PLUGIN_HANDLED;
}

public menu_demomenu(admin)
{
  new menu = menu_create("Admin EnhancedDemo Menu^n\d(amx_demomenu)\w", "menu_demomenu_handler");

  static item[48];
  for (new id = 1; id <= MaxClients; ++id)
  {
    if (!is_user_connected(id))
    {
      continue;
    }

    static name[32];
    get_user_name(id, name, charsmax(name));

    new const team_prefixes[CsTeams][] = { "", "\rTR", "\yCT", "\dSPEC" };
    new CsTeams:team = cs_get_user_team(id);

    new color[][] = {"\w", "\r"};

    formatex(item, charsmax(item), "\d[%s\d] %s%s", team_prefixes[team], color[(last_record_time[id] > 0.0)], name);

    new id_str[3];
    num_to_str(id, id_str, charsmax(id_str));

    menu_additem(menu, item, id_str, ADMIN_PERMISSION, menu_demomenu_callback_id);
  }

  menu_display(admin, menu);

  return PLUGIN_HANDLED;
}

public menu_demomenu_callback(admin, menu, item)
{
  new info[4];
  menu_item_getinfo(menu, item, _, info, charsmax(info));
  new id = str_to_num(info);

  if (is_user_connected(id))
  {
    if (last_record_time[id] == 0.0 || last_record_time[id] + 30.0 < get_gametime())
    {
      return ITEM_IGNORE;
    }
  }
  
  return ITEM_DISABLED;
}


public menu_demomenu_handler(admin, menu, item)
{
  if (item == MENU_EXIT || !is_user_connected(admin))
  {
    menu_destroy(menu);
    return PLUGIN_HANDLED;
  }

  new info[4];
  menu_item_getinfo(menu, item, _, info, charsmax(info));
  new id = str_to_num(info);

  if (is_user_connected(id))
  {
    static prefix[32];
    get_pcvar_string(cvars[CHAT_PREFIX], prefix, charsmax(prefix));

    static name[32];
    get_user_name(id, name, charsmax(name));

    client_print_color(admin, id, "^4[%s]^1 Started demo record for ^3%s^1.", prefix, name);
    start_demo(id);
  }

  menu_destroy(menu);
  menu_demomenu(admin);

  return PLUGIN_HANDLED;
}

public start_demo(id)
{
  static filename[128];
  get_pcvar_string(cvars[DEMO_PREFIX], filename, 32);

  static timestamp[32];
  get_time("%Y-%m-%d_%H-%M-%S", timestamp, charsmax(timestamp));
  
  if (get_pcvar_num(cvars[TIMESTAMP]))
  {
    strcat(filename, "_", charsmax(filename));
    strcat(filename, timestamp, charsmax(filename));
  }

  if (get_pcvar_num(cvars[MAPNAME]))
  {
    strcat(filename, "_", charsmax(filename));
    strcat(filename, mapname, charsmax(filename));
  }

  if (nicknames[id][0] && get_pcvar_num(cvars[NICKNAME]))
  {
    strcat(filename, "_", charsmax(filename));
    strcat(filename, nicknames[id], charsmax(filename));
  }

  if (steamids[id][0] && get_pcvar_num(cvars[STEAMID]))
  {
    strcat(filename, "_", charsmax(filename));
    strcat(filename, steamids[id], charsmax(filename));
  }

  utils_clean_string(filename, charsmax(filename))
  client_cmd(id, "stop; record ^"%s^"", filename);
  last_record_time[id] = get_gametime();

  set_task(2.0, "delayed_print", 9785 + id, filename, charsmax(filename));

  return PLUGIN_HANDLED;
}


public delayed_print(filename[], id)
{
  id -= 9785;

  static timestamp[32];
  get_time("%Y-%m-%d_%H-%M-%S", timestamp, charsmax(timestamp));

  static prefix[32];
  get_pcvar_string(cvars[CHAT_PREFIX], prefix, charsmax(prefix));

  client_print(id, print_console, "^n-------------------------");
  client_print(id, print_console, "^"%s^" v%s by ^"%s^"", PLUGIN, VERSION, AUTHOR);
  client_print(id, print_console, "Check it out and more: https://github.com/igorkelvin/amxx-plugins");
  client_print(id, print_console, "-------------------------");
  client_print(id, print_console, "Recording demo: %s.dem", filename);
  client_print(id, print_console, "Hostname: %s", hostname);
  client_print(id, print_console, "Host IP: %s", ip);
  client_print(id, print_console, "Map: %s", mapname);
  client_print(id, print_console, "Timestamp: %s", timestamp);
  client_print(id, print_console, "-------------------------");
  client_print(id, print_console, "Players in server:");
  
  new count = 0;
  for (new i = 1; i < MaxClients; ++i)
  {
    if (is_user_connected(i))
    {
      ++count;
      client_print(id, print_console, "#%02d: %s, %s", count, nicknames[i], steamids[i]);
    }
  }

  client_print(id, print_console, "-------------------------^n");

  if (get_pcvar_num(cvars[NOTIFY]))
  {
    client_print_color(id, id, "^4[%s]^1 Recording demo: ^3%s.dem", prefix, filename);
    client_print_color(id, id, "^4[%s]^1 Hostname: ^3%s", prefix, hostname);
    client_print_color(id, id, "^4[%s]^1 Host IP: ^3%s", prefix, ip);
    client_print_color(id, id, "^4[%s]^1 Map: ^3%s", prefix, mapname);
    client_print_color(id, id, "^4[%s]^1 Timestamp: ^3%s", prefix, timestamp);
  }

  // set_task(1.0, "snapshot_delayed", id + 9785+33)
}


public snapshot_delayed(id)
{
  id -= (9785+33);

  if (is_user_connected(id))
  {
    client_cmd(id, "snapshot");
  }
}


public event_intermission()
{
  if(!get_pcvar_num(cvars[AUTOSTOP]))
  {
    return;
  }

  for (new id = 1; id < MaxClients; ++id)
  {
    if (is_user_connected(id))
    {
      client_cmd(id, "stop");
    }
  }
}


public utils_clean_string(str[], len)
{
  static pattern[32] = "[^^a-zA-Z0-9_-]";
  static replace[32] = "_";

  new err;
  new Regex:regex = regex_compile(pattern, err);

  if (err)
  {
    log_amx("(utils_clean_string) Error on regex. err: %d", err);
    
    regex_free(regex);
    return PLUGIN_CONTINUE;
  }

  regex_replace(regex, str, len, replace);

  regex = regex_compile("_{2,}", err);

  if (err)
  {
    log_amx("(utils_clean_string) Error on regex. err: %d", err);
    
    regex_free(regex);
    return PLUGIN_CONTINUE;
  }

  regex_replace(regex, str, len, "_");

  return PLUGIN_HANDLED;
}