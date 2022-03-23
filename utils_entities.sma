#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <xs>

#define PLUGIN  "Utils: Entities"
#define VERSION "0.1"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR);
  
  register_clcmd("entities_list", "cmd_entities_list", _, "List 30 entities starting from arg1");
}

public cmd_entities_list(id)
{
  if (!is_user_connected(id))
  {
    return PLUGIN_CONTINUE;
  }

  new arg[5];
  read_args(arg, charsmax(arg));
  remove_quotes(arg);

  new start = str_to_num(arg)
  if (!start)
  {
    start = 1;
  }

  new finish = 30 + start;
  
  client_print(id, print_console, "[%s] ^"entities_list^" %d - %d", PLUGIN, start, finish);
  for (new i = start; i <= finish; ++i)
  {
    if (is_valid_ent(i))
    {
      new classname[33];
      entity_get_string(i, EV_SZ_classname, classname, charsmax(classname));
      
      new model[33];
      entity_get_string(i, EV_SZ_model, model, charsmax(model));
      
      client_print(id, print_console, "[%03d] '%s' -> '%s'", i, classname, model);
    }
  }

  return PLUGIN_HANDLED;
}
