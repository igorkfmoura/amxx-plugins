#include <amxmodx>

#define PLUGIN  "QueryCvar"
#define VERSION "0.1.1"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

#define PREFIX_CHAT    "^4[QueryCvar]^1"
#define PREFIX_CONSOLE "[QueryCvar]"

#define USAGE          "query <0 or id or name or authid> <cvar>"
#define USAGE_EXAMPLE1  "Example 1: query ^"1^" ^"fps_max^""
#define USAGE_EXAMPLE2  "Example 2: query ^"lonewolf^" ^"cl_updaterate^""
#define USAGE_EXAMPLE3  "Example 3: query ^"STEAM_0:0:8354200^" ^"sensitivity^""

#define ADMIN_PERMISSION ADMIN_CVAR


public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR);
  
  register_clcmd("query", "cmd_query", ADMIN_PERMISSION, USAGE);
}


public cmd_query(admin)
{
  new argc = read_argc();
  if (argc != 3)
  {
    client_print(admin, print_console, "^n%s %s", PREFIX_CONSOLE, USAGE);
    client_print(admin, print_console, "%s %s", PREFIX_CONSOLE, USAGE_EXAMPLE1);
    client_print(admin, print_console, "%s %s", PREFIX_CONSOLE, USAGE_EXAMPLE2);
    client_print(admin, print_console, "%s %s^n", PREFIX_CONSOLE, USAGE_EXAMPLE3);
    return PLUGIN_HANDLED;
  }
  
  new cvar[32];
  read_argv(2, cvar, charsmax(cvar));

  remove_quotes(cvar);
  trim(cvar);

  new admin_str[3];
  num_to_str(admin, admin_str, charsmax(admin_str));

  new argv[32];
  read_argv(1, argv, charsmax(argv));

  if (argv[0] == '0')
  {
    for (new id = 1; id <= MaxClients; ++id)
    {
      if (!is_user_connected(id))
      {
        continue;
      }
      query_client_cvar(id, cvar, "query_client", charsmax(admin_str), admin_str);
    }

    return PLUGIN_HANDLED;
  }
  
  new id = find_player_ex(FindPlayer_MatchNameSubstring, argv);
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
    query_client_cvar(id, cvar, "query_client", charsmax(admin_str), admin_str);
  }
  else
  {
    client_print(admin, print_console, "^n%s Player not found!", PREFIX_CONSOLE);
    client_print(admin, print_console, "%s %s", PREFIX_CONSOLE, USAGE);
    client_print(admin, print_console, "%s %s", PREFIX_CONSOLE, USAGE_EXAMPLE1);
    client_print(admin, print_console, "%s %s", PREFIX_CONSOLE, USAGE_EXAMPLE2);
    client_print(admin, print_console, "%s %s^n", PREFIX_CONSOLE, USAGE_EXAMPLE3);
  }

  return PLUGIN_HANDLED;
}


public query_client(id, const cvar[], const value[], const param[])
{
  new admin = str_to_num(param);
  if (!is_user_connected(admin))
  {
    return PLUGIN_CONTINUE;
  }

  if (equal(value, "Bad CVAR request"))
  {
    client_print(admin, print_console, "^n%s %s", PREFIX_CONSOLE, value);
    client_print(admin, print_console, "%s you queried: %s", PREFIX_CONSOLE, cvar);
    client_print(admin, print_console, "%s %s", PREFIX_CONSOLE, USAGE);
    client_print(admin, print_console, "%s %s", PREFIX_CONSOLE, USAGE_EXAMPLE1);
    client_print(admin, print_console, "%s %s", PREFIX_CONSOLE, USAGE_EXAMPLE2);
    client_print(admin, print_console, "%s %s^n", PREFIX_CONSOLE, USAGE_EXAMPLE3);
    return PLUGIN_CONTINUE;
  }

  static name[MAX_NAME_LENGTH];
  get_user_name(id, name, charsmax(name));

  client_print(admin, print_console, "%s %s: ^"%s^" is set to ^"%s^"", PREFIX_CONSOLE, name, cvar, value);

  return PLUGIN_HANDLED;
}  