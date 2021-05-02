#include <amxmodx>
#include <engine>
#include <cstrike>
#include <fakemeta>

// https://wiki.alliedmods.net/Adding_Admins_(AMX_Mod_X)
// https://github.com/alliedmodders/amxmodx/blob/master/plugins/include/amxconst.inc
#define ADMIN_SWAP ADMIN_CVAR

new const team_names[CsTeams][] = {"", "TERRORIST", "CT", "SPECTATOR"};

static msgid_teamscore;

static bool:swapped_teams;
static team_wins[CsTeams];
static kills[MAX_PLAYERS + 1];
static deaths[MAX_PLAYERS + 1];

new maxplayers;

public plugin_init() 
{
  register_plugin("SwapTeams", "0.1", "lonewolf");
  
  msgid_teamscore = get_user_msgid("TeamScore");
  
  register_logevent("round_start", 2, "0=World triggered", "1=Round_Start");
  
  register_clcmd("amx_swapteams", "swap_teams", ADMIN_SWAP);
  
  maxplayers = get_maxplayers();
}

// https://github.com/alliedmodders/amxmodx/blob/master/plugins/include/fakemeta_util.inc#L500
public swap_teams(admin)
{
  if (swapped_teams)
  {
    console_print(admin, "Swapping already in progress!");
    return PLUGIN_HANDLED;
  }
  
  team_wins[CS_TEAM_T]  = get_gamerules_int("CHalfLifeMultiplay", "m_iNumTerroristWins");
  team_wins[CS_TEAM_CT] = get_gamerules_int("CHalfLifeMultiplay", "m_iNumCTWins");
  
  // client_print(0, print_chat, "TR:%d | CT:%d", team_wins[CS_TEAM_T], team_wins[CS_TEAM_CT]);
  for (new id = 1; id <= maxplayers; id++)
  {
    if (!is_user_connected(id))
    {
      continue;
    }
    
    new CsTeams:team = cs_get_user_team(id);
    if (team == CS_TEAM_T || team == CS_TEAM_CT)
    {
      kills[id]  = get_user_frags(id);
      deaths[id] = cs_get_user_deaths(id);
      
      new CsTeams:newteam = (team == CS_TEAM_T) ? CS_TEAM_CT : CS_TEAM_T;
      
      // new name[32];
      // get_user_name(id, name, charsmax(name));
      // client_print(0, print_chat, "[%02d] %s %s %d/%d", id, (team == CS_TEAM_T) ? "TR" : "CT", name, kills[id], deaths[id]);
      
      user_silentkill(id);
      cs_set_user_team(id, newteam);
      
      client_cmd(id, "spk vox/administration.wav");
    }
  }
  
  client_print_color(0, print_team_default, "^4[SwapTeams]^1 Trocando lado!");
  
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
  
  for (new id = 1; id <= maxplayers; id++)
  {
    if (!is_user_connected(id))
    {
      continue;
    }
    
    entity_set_float(id, EV_FL_frags, float(kills[id]));
    cs_set_user_deaths(id, deaths[id]);
  }
  
  set_gamerules_int("CHalfLifeMultiplay", "m_iNumTerroristWins", team_wins[CS_TEAM_CT]);
  set_gamerules_int("CHalfLifeMultiplay", "m_iNumCTWins", team_wins[CS_TEAM_T]);
  
  emessage_begin(MSG_BROADCAST, msgid_teamscore);
  ewrite_string(team_names[CS_TEAM_T]);
  ewrite_short(team_wins[CS_TEAM_CT]);
  emessage_end();
  
  emessage_begin(MSG_BROADCAST, msgid_teamscore);
  ewrite_string(team_names[CS_TEAM_CT]);
  ewrite_short(team_wins[CS_TEAM_T]);
  emessage_end();
  
  swapped_teams = false;
}
