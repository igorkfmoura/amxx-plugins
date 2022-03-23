// ReEnhancedFlashBang
// -- Made by lonewolf <igorkelvin@gmail.com>
// -- http://github.com/igorkelvin/amxx-plugins
//
// -- Inspired by Subb98 @ https://github.com/Subb98/No-team-flash
// -- Thanks to "Numb / ConnorMcLeod | Wilian M." for "No Flash Team"


#include <amxmodx>
#include <reapi>
#include <vector>
#include <xs>

#pragma semicolon 1

#define PLUGIN  "Enhanced FlashBang Reapi"
#define AUTHOR  "lonewolf"
#define VERSION "0.1"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

enum Cvars 
{
  FIX,
  TEAM,
  SELF,
  FF
};
new cvars[Cvars];

enum FlashTeammates
{
  DONT,
  ALWAYS,
  DEPEND,
  PARTIALLY
};

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR);

  cvars[FIX]  = create_cvar("amx_flash_fix", "1", _, "Fixes flashbangs blinding when turned around");
  cvars[TEAM] = create_cvar("amx_flash_team", "0", _, "<0-2> Allow team flashing. 0 - Don't flash teammates; 1 - Always flash teammates; 2 - Only flash teammates if mp_friendlyfire is '1'; 3 - Partially blind teammates");
  cvars[SELF] = create_cvar("amx_flash_self", "1", _, "<0|1> Allow self flashing");
  
  cvars[FF] = get_cvar_pointer("mp_friendlyfire");

  // todo: check regame/reapi version?

  RegisterHookChain(RG_PlayerBlind, "event_RG_PlayerBlind");
}

//todo: check if this event triggers on every ScreenFade event or just when blinded by flashbang
public event_RG_PlayerBlind(const id, const inflictor, const attacker, Float:fadetime, Float:fadehold, alpha, Float:color[3]) 
{
  if (!is_user_connected(id))
  {
    return HC_CONTINUE;
  }

  new we_should_fix_flashbangs = get_pcvar_num(cvars[FIX]);
  new FlashTeammates:flash_teammates = FlashTeammates:get_pcvar_num(cvars[TEAM]);
  new bool:is_same_team = (get_member(id, m_iTeam) == get_member(attacker, m_iTeam));

  if (id == attacker)
  {
    if (!get_pcvar_num(cvars[SELF]))
    {
      return HC_SUPERCEDE;
    }
  }
  else if (is_same_team && flash_teammates == DONT || (flash_teammates == DEPEND && !get_pcvar_num(cvars[FF])))
  {
	  return HC_SUPERCEDE;
	}

  if (alpha == 255)
  {
    new Float:dot = 1337.0;

    if (we_should_fix_flashbangs)
    {
      if (!is_entity(inflictor))
      {
        return HC_CONTINUE;
      }
  
      static Float:nade_origin[3];
      static Float:lineofsight[3];
      static Float:tmp[3];
      static Float:v_forward[3];
  
      get_entvar(inflictor, var_origin, nade_origin);
      get_entvar(id, var_origin, lineofsight);
      get_entvar(id, var_view_ofs, tmp);
  
      xs_vec_add(lineofsight, tmp, lineofsight);
      xs_vec_sub(nade_origin, lineofsight, lineofsight);
  
      get_entvar(id, var_v_angle, tmp);
      angle_vector(tmp, ANGLEVECTOR_FORWARD, v_forward);
  
      dot = xs_vec_dot(lineofsight, v_forward);
    }

    if (dot < 0 || (is_same_team && flash_teammates == PARTIALLY && (id != attacker)))
    {
      new last_alpha = get_current_alpha(id);
      alpha = (last_alpha < 200) ? 200 : last_alpha;
      SetHookChainArg(6, ATYPE_INTEGER, alpha);
    }
  }
  
  return HC_CONTINUE;
}

public get_current_alpha(id)
{
  new Float:start_time = get_member(id, m_blindStartTime);
  new Float:fade_time  = get_member(id, m_blindFadeTime);
  new Float:hold_time  = get_member(id, m_blindHoldTime);
  new Float:end_time   = fade_time + hold_time + start_time;
  new Float:now = get_gametime();

  new last_alpha = get_member(id, m_blindAlpha);

  hold_time = hold_time + start_time - now;

  if (hold_time <= 0.0)
  {
    hold_time = 0.0;
    new Float:ratio = (end_time - now) / fade_time;
    last_alpha = floatround(float(last_alpha) * ratio);
    fade_time *= ratio;
  }

  return last_alpha;
}