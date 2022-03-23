#include <amxmodx>
#include <engine>
#include <cstrike>
#include <fakemeta>

#define PLUGIN  "Utils: Teams"
#define VERSION "0.2"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

#define PREFIX  "^4[TeamUtils]^1"

// https://wiki.alliedmods.net/Adding_Admins_(AMX_Mod_X)
// https://github.com/alliedmodders/amxmodx/blob/master/plugins/include/amxconst.inc
#define ADMIN_SWAP ADMIN_CVAR

new const team_names[CsTeams][] = 
{
  "", 
  "TR", 
  "CT", 
  "SPEC"
};

// static msgid_teamscore;

static bool:swapped_teams;
static team_wins[CsTeams];
static kills[MAX_PLAYERS + 1];
static deaths[MAX_PLAYERS + 1];


public plugin_init() 
{
  register_plugin(PLUGIN, VERSION, AUTHOR);
  
  // msgid_teamscore = get_user_msgid("TeamScore");
  
  register_logevent("round_start", 2, "0=World triggered", "1=Round_Start");

  register_concmd("amx_swapteams",    "cmd_swap_teams",    ADMIN_SWAP, "Swap teams and restart game keeping player's score");
  register_concmd("amx_shuffleteams", "cmd_shuffle_teams", ADMIN_SWAP, "Shuffle teams and restart game keeping player's score");
}


public cmd_swap_teams(admin)
{
  if (swapped_teams)
  {
    console_print(admin, "Swapping already in progress!");
    return PLUGIN_HANDLED;
  }
  
  team_wins[CS_TEAM_T]  = get_gamerules_int("CHalfLifeMultiplay", "m_iNumTerroristWins");
  team_wins[CS_TEAM_CT] = get_gamerules_int("CHalfLifeMultiplay", "m_iNumCTWins");
  
  client_print(0, print_console, "^n[%s] TR:%d | CT:%d", PLUGIN, team_wins[CS_TEAM_T], team_wins[CS_TEAM_CT]);
  for (new id = 1; id <= MaxClients; id++)
  {
    if (!is_user_connected(id))
    {
      continue;
    }
    
    client_cmd(id, "spk vox/administration.wav");

    new CsTeams:team = cs_get_user_team(id);
    if (team == CS_TEAM_T || team == CS_TEAM_CT)
    {
      kills[id]  = get_user_frags(id);
      deaths[id] = cs_get_user_deaths(id);
      
      new CsTeams:newteam = (team == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T;
      
      new name[32];
      get_user_name(id, name, charsmax(name));
      client_print(0, print_console, "[%s] (%02d) %s %d/%d, %s -> %s", PLUGIN, id, name,kills[id], deaths[id], team_names[team],  team_names[newteam]);
      
      user_silentkill(id);
      cs_set_user_team(id, newteam);
    }
  }
  client_print(0, print_console, "^n");
  client_print_color(0, print_team_default, "%s Trocando lado!", PREFIX);
  
  swapped_teams = true;
  server_cmd("sv_restart 1");
  
  return PLUGIN_HANDLED;
}


public cmd_shuffle_teams(admin)
{
  if (swapped_teams)
  {
    console_print(admin, "Swapping already in progress!");
    return PLUGIN_HANDLED;
  }
  
  team_wins[CS_TEAM_T]  = get_gamerules_int("CHalfLifeMultiplay", "m_iNumTerroristWins");
  team_wins[CS_TEAM_CT] = get_gamerules_int("CHalfLifeMultiplay", "m_iNumCTWins");

  client_print(0, print_console, "^n[%s] TR:%d | CT:%d", PLUGIN, team_wins[CS_TEAM_T], team_wins[CS_TEAM_CT]);  
  
  new player_count[CsTeams];
  for (new id = 1; id <= MaxClients; id++)
  {
    if (!is_user_connected(id))
    {
      continue;
    }
    
    client_cmd(id, "spk vox/administration.wav");
    
    new CsTeams:team = cs_get_user_team(id);

    if (team != CS_TEAM_T && team != CS_TEAM_CT)
    {
      continue;
    }

    new CsTeams:newteam = CsTeams:random_num(1, 2);
    
    ++player_count[newteam];
    
    kills[id]  = get_user_frags(id);
    deaths[id] = cs_get_user_deaths(id);
    
    user_silentkill(id);
    cs_set_user_team(id, newteam);
    
    new name[32];
    get_user_name(id, name, charsmax(name));
    client_print(0, print_console, "[%s] (%02d) %s %d/%d, %s -> %s", PLUGIN, id, name,kills[id], deaths[id], team_names[team],  team_names[newteam]);
  }
  

  new CsTeams:less = CS_TEAM_UNASSIGNED;
  new CsTeams:more = CS_TEAM_UNASSIGNED;

  if (player_count[CS_TEAM_CT] > player_count[CS_TEAM_T] + 1)
  {
    less = CS_TEAM_T;
    more = CS_TEAM_CT;
  }
  else if (player_count[CS_TEAM_T] > player_count[CS_TEAM_CT] + 1)
  {
    less = CS_TEAM_CT;
    more = CS_TEAM_T;
  }

  if (less && more)
  {
    client_print(0, print_console, "[%s] Equilibrando...", PLUGIN);

    while (player_count[more] > player_count[less] + 1)
    {
      new id;
      do
      {
        id = random_num(1, MaxClients);
      } while (!is_user_connected(id) || cs_get_user_team(id) != more)

      cs_set_user_team(id, less);

      --player_count[more];
      ++player_count[less];

      new name[32];
      get_user_name(id, name, charsmax(name));
      client_print(0, print_console, "[%s] (%02d) %s %d/%d, %s -> %s", PLUGIN, id, name, kills[id], deaths[id], team_names[more],  team_names[less]);

    }
  }
  
  client_print(0, print_console, "^n");
  client_print_color(0, print_team_default, "%s Misturando times!", PREFIX);

  swapped_teams = true;
  server_cmd("sv_restart 1");
  
  return PLUGIN_HANDLED;
}


public round_start()
{
  if (!swapped_teams)
  {
    return;
  }
  
  for (new id = 1; id <= MaxClients; id++)
  {
    if (!is_user_connected(id))
    {
      continue;
    }
    
    entity_set_float(id, EV_FL_frags, float(kills[id]));
    cs_set_user_deaths(id, deaths[id]);
  }
  
  // set_gamerules_int("CHalfLifeMultiplay", "m_iNumTerroristWins", team_wins[CS_TEAM_CT]);
  // set_gamerules_int("CHalfLifeMultiplay", "m_iNumCTWins", team_wins[CS_TEAM_T]);
  
  // emessage_begin(MSG_BROADCAST, msgid_teamscore);
  // ewrite_string(team_names[CS_TEAM_T]);
  // ewrite_short(team_wins[CS_TEAM_CT]);
  // emessage_end();
  
  // emessage_begin(MSG_BROADCAST, msgid_teamscore);
  // ewrite_string(team_names[CS_TEAM_CT]);
  // ewrite_short(team_wins[CS_TEAM_T]);
  // emessage_end();
  
  swapped_teams = false;
}
