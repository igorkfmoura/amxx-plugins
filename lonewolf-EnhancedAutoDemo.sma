// "EnhancedAutoDemo" by lonewolf
// Check out more on: https://github.com/igorkelvin/amxx-plugins
//
// Made by scratch but very influenced by "amx_autodemorec" by "IzI"
// https://forums.alliedmods.net/showthread.php?p=770786

#include <amxmodx>
#include <engine>
#include <regex>

#define PLUGIN  "lonewolf-EnhancedAutoDemo"
#define VERSION "0.3.1"
#define AUTHOR  "lonewolf"

#if !defined MAX_MAPNAME_LENGTH
#define MAX_MAPNAME_LENGTH 64
#endif

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

new steamids[MAX_PLAYERS+1][32];
new nicknames[MAX_PLAYERS+1][32];

new hostname[64];
new mapname[MAX_MAPNAME_LENGTH];
new ip[32];

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
  cvars[CHAT_PREFIX] = create_cvar("amx_demo_prefix", "EnhancedAutoDemo", _, "Chat prefix");
  
  get_mapname(mapname, charsmax(mapname));
  get_user_ip(0, ip, charsmax(ip));
  get_cvar_string("hostname", hostname, charsmax(hostname))

  register_clcmd("amx_demo", "start_demo");
}


public client_authorized(id)
{
  get_user_authid(id, steamids[id], 31);
  get_user_name(id, nicknames[id], 31);
}


public client_infochanged(id) 
{
  get_user_name(id, nicknames[id], 31);
}


public client_disconnected(id)
{
  steamids[id][0]  = '^0';
  nicknames[id][0] = '^0';
}


public client_putinserver(id)
{
	if(is_user_connected(id) && get_pcvar_num(cvars[AUTO])) 
	{
		set_task(5.0, "task_start_demo", 1612 + id);
	}
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
  
  for (new i = 1; i < MaxClients; ++i)
  {
    if (is_user_connected(i))
    {
      client_print(id, print_console, "#%02d: %s, %s", i, nicknames[i], steamids[i]);
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