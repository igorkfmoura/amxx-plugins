// "EnhancedAutoDemo" by lonewolf
// Check out more on: https://github.com/igorkelvin/amxx-plugins
//
// Made by scratch but very influenced by "amx_autodemorec" by "IzI"
// https://forums.alliedmods.net/showthread.php?p=770786

#include <amxmodx>
#include <engine>

#define PLUGIN  "lonewolf-EnhancedAutoDemo"
#define VERSION "0.1"
#define AUTHOR  "lonewolf"

enum Cvars 
{
  AUTO,
  DEMO_PREFIX,
  CHAT_PREFIX,
  TIMESTAMP,
  MAPNAME,
  STEAMID,
  NICKNAME,
  NOTIFY
};

new cvars[Cvars];

new authorized[MAX_PLAYERS+1];

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)
  
  cvars[AUTO]      = create_cvar("amx_demo_auto",   "1", _, "Record demo on client connect");  
  cvars[TIMESTAMP] = create_cvar("amx_demo_time",   "0", _, "Append timestamp on demo filename");
  cvars[MAPNAME]   = create_cvar("amx_demo_map",    "0", _, "Append mapname on demo filename");
  cvars[STEAMID]   = create_cvar("amx_demo_steam",  "0", _, "Append steamid on demo filename");
  cvars[NICKNAME]  = create_cvar("amx_demo_nick",   "0", _, "Append nickname on demo filename");
  cvars[NOTIFY]    = create_cvar("amx_demo_notify", "1", _, "Notify user when recording");
  
  cvars[DEMO_PREFIX] = create_cvar("amx_demo_name",   "EnhancedAutoDemo", _, "Base prefix for demo filename");
  cvars[CHAT_PREFIX] = create_cvar("amx_demo_prefix", "^4[EnhancedAutoDemo]^1", _, "Chat prefix");
  
  register_clcmd("amx_demo", "start_demo");
}


public client_putinserver(id)
{
	if(is_user_connected(id) && get_pcvar_num(cvars[AUTO])) 
	{
		set_task(5.0, "task_start_demo", 1612 + id);
	}
}


public client_authorized(id)
{
  authorized[id] = true;
}


public client_disconnected(id)
{
  authorized[id] = false;
}


public task_start_demo(id)
{
  id -= 1612;
  start_demo(id);
}

public start_demo(id)
{
  static filename[128];
  get_pcvar_string(cvars[DEMO_PREFIX], filename, 32);

  static time[32];
  get_time("%Y-%m-%d_%H-%M-%S", time, charsmax(time));
  
  if (get_pcvar_num(cvars[TIMESTAMP]))
  {
    strcat(filename, "_", charsmax(filename));
    strcat(filename, time, charsmax(filename));
  }

  static mapname[32];
  get_mapname(mapname, charsmax(mapname));
  utils_clean_string(mapname, sizeof(mapname));

  if (get_pcvar_num(cvars[MAPNAME]))
  {
    strcat(filename, "_", charsmax(filename));
    strcat(filename, mapname, charsmax(filename));
  }

  static nickname[32];
  get_user_name(id, nickname, charsmax(nickname));
  utils_clean_string(nickname, sizeof(nickname));

  if (get_pcvar_num(cvars[NICKNAME]))
  {
    strcat(filename, "_", charsmax(filename));
    strcat(filename, nickname, charsmax(filename));
  }

  new steamid[32] = "^0";

  if (!authorized[id])
  {
    log_amx("(start_demo) client %d not authorized, skipping steamid")
  }
  else
  {
    get_user_authid(id, steamid, charsmax(steamid));
    utils_clean_string(steamid, sizeof(steamid));

    if (get_pcvar_num(cvars[STEAMID]))
    {
      strcat(filename, "_", charsmax(filename));
      strcat(filename, steamid, charsmax(filename));
    }
  }

  client_cmd(id, "stop; record ^"%s^"", filename);


  if (get_pcvar_num(cvars[NOTIFY]))
  {
    set_task(2.0, "delayed_print", 9785 + id, filename, charsmax(filename));
  }

  return PLUGIN_HANDLED;
}

public delayed_print(filename[], id)
{
  id -= 9785;

  static prefix[32];
  get_pcvar_string(cvars[CHAT_PREFIX], prefix, charsmax(prefix));

  client_print(id, print_console, "^n^n");
  client_print(id, print_console, filename);
  client_print(id, print_console, "^n^n");
  
  client_print_color(id, id, "%s filename: ^3%s.dem^1", prefix, filename);
}

public utils_clean_string(str[], len)
{
  enum Key {FIND[4], REPLACE[4]};

  new const keys[][Key] = 
  {
    {"/",   ""},
    {"\",   ""},
    {" ",   "_"},
    {"<",   ""},
    {">",   ""},
    {":",   "-"},
    {"^"",  ""},
    {"|",   ""},
    {"?",   ""},
    {"*",   ""},
    {"'",   ""},
    {"^"",  ""},
    {"__",  "_"},
    {"___", "_"},
    {"  ",  " "}
    
  }

  remove_quotes(str);
  trim(str);

  new l = sizeof(keys);
  for (new i = 0; i < l; ++i)
  {
    replace_string(str, len, keys[i][FIND], keys[i][REPLACE]);
  }
}