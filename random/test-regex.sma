#include <amxmodx>
#include <engine>
#include <regex>

#define PLUGIN  "test-regex"
#define VERSION "0.1"
#define AUTHOR  "lonewolf"

#define PREFIX "^4[test-regex]^1"

enum Cvars 
{
  FIND,
  REPLACE
};
new cvars[Cvars];

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)
  
  cvars[FIND]    = create_cvar("amx_regex_find", "[^^a-zA-Z0-9 _]");
  cvars[REPLACE] = create_cvar("amx_regex_replace", "X");

  register_clcmd("say", "cmd_say");
}


public cmd_say(id)
{
  if (!is_user_connected(id))
  {
    return PLUGIN_HANDLED;
  }

  static saytext[128];
  read_args(saytext, charsmax(saytext));
  remove_quotes(saytext);
  
  static pattern[32];
  get_pcvar_string(cvars[FIND], pattern, charsmax(pattern));

  new err;
  new Regex:regex = regex_compile(pattern, err, _, _, "x");

  if (err)
  {
    log_amx("(cmd_say) Error on regex. err: %d", err);
    
    regex_free(regex);
    return PLUGIN_CONTINUE;
  }

  static replace[32];
  get_pcvar_string(cvars[REPLACE], replace, charsmax(replace));

  new replacements = regex_replace(regex, saytext, charsmax(saytext), replace);
  
  if (replacements > 0)
  {
    client_print_color(id, id, "%s %s", PREFIX, saytext);
  }

  regex_free(regex);
  return PLUGIN_CONTINUE;
}