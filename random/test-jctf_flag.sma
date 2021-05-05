#include <amxmodx>
#include <engine>

#define PLUGIN  "test-jctf_flag"
#define VERSION "0.1"
#define AUTHOR  "lonewolf"

#define PREFIX "^4[jctf_flag]^1"

enum FlagEvent
{
  FLAG_STOLEN = 0,
  FLAG_PICKED,
  FLAG_DROPPED,
  FLAG_MANUALDROP,
  FLAG_RETURNED,
  FLAG_CAPTURED,
  FLAG_AUTORETURN,
  FLAG_ADMINRETURN
};


enum FlagTeam
{ 
  TEAM_NONE = 0, 
  TEAM_RED, 
  TEAM_BLUE, 
  TEAM_SPEC 
};

enum FlagAssist
{
  NO_ASSIST,
  ASSISTED
};

new events[FlagEvent][FlagAssist][] =
{
  {"roubou a bandeira",  ""},
  {"pegou a bandeira",  ""},
  {"perdeu a bandeira",  ""},
  {"largou a bandeira",  ""},
  {"retornou a bandeira",  "ajudou a retornar a bandeira"},
  {"capturou a bandeira",  "ajudou a capturar a bandeira"},
  {"A ^3bandeira^1 foi retornada automaticamente!",  ""},
  {"usou seus poderes de admin pra retornar a bandeira",  ""},
};

new team_names[FlagTeam][] =
{
  "",
  "TR",
  "CT",
  ""
};

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)
}

public jctf_flag(FlagEvent:event, id, FlagTeam:team, FlagAssist:is_assist)
{
  if (event == FLAG_MANUALDROP)
  {
    // when MANUALDROP event FLAG_DROPPED is also triggered, avoid redundant print
    return;
  }

  static name[32];
  get_user_name(id, name, charsmax(name));

  new color = (team == TEAM_RED) ? print_team_red : print_team_blue;
  // client_print(id, print_chat, "(jctf_flag) event: %d, id: %d, team: %d, is_assist: %d", event, id, team, is_assist)

  if (!id)
  {
    client_print_color(0, color, "%s %s", PREFIX, events[event][NO_ASSIST]);
    return;
  }

  client_print_color(0, color, "%s Jogador ^4%s^1 %s ^3%s^1!", PREFIX, name, events[event][is_assist], team_names[team]);
  return;
}