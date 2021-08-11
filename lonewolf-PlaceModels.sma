#include <amxmodx>
#include <engine>

#define PLUGIN  "PlaceModels"
#define VERSION "0.0.1"
#define AUTHOR  "lonewolf"

new const CHAT_PREFIX[] = "^4[PlaceModels]^1"
new const MODEL_PATH[] = "models/bannertest.mdl";

new model_placed;

public plugin_precache()
{
  precache_model(MODEL_PATH);
}

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR)
  
  create_model(MODEL_PATH);

  register_clcmd("test", "cmd_test");
}

public create_model(const path[])
{
  model_placed = create_entity("info_target");
  if (!is_valid_ent(model_placed))
  {
    set_fail_state("Failed to create entity ^"%s^".", "info_target");
    return PLUGIN_HANDLED;
  }

  entity_set_string(model_placed, EV_SZ_classname, "placedmodel");
  entity_set_model(model_placed, MODEL_PATH);
  entity_set_size(model_placed, Float:{0.0, 0.0, 0.0}, Float:{16.0, 16.0, 16.0});
  entity_set_int(model_placed, EV_INT_solid, SOLID_NOT);
  set_rendering(model_placed);

  return PLUGIN_CONTINUE;
}

public cmd_test(id)
{
  new Float:start[3];
  new Float:view_ofs[3];

  entity_get_vector(id, EV_VEC_origin, start);
  entity_get_vector(id, EV_VEC_view_ofs, view_ofs);
  start[0] += view_ofs[0];
  start[1] += view_ofs[1];
  start[2] += view_ofs[2];

  new Float:angles[3];
  new Float:v_forward[3];
  entity_get_vector(id, EV_VEC_v_angle, angles);
  angle_vector(angles, ANGLEVECTOR_FORWARD, v_forward);
  
  new Float:end[3];
  end[0] = start[0] + v_forward[0] * 2000.0;
  end[1] = start[1] + v_forward[1] * 2000.0;
  end[2] = start[2] + v_forward[2] * 2000.0;
  
  client_print_color(id, print_team_red,     "%s  ORIGIN1: [^3%0.1f^1, ^3%0.1f^1, ^3%0.1f^1]", CHAT_PREFIX, start[0], start[1], start[2]);
  client_print_color(id, print_team_red,     "%s  ORIGIN2: [^3%0.1f^1, ^3%0.1f^1, ^3%0.1f^1]", CHAT_PREFIX, end[0], end[1], end[2]);
  client_print_color(id, print_team_blue,    "%s  ANGLES: [^3%0.1f^1, ^3%0.1f^1, ^3%0.1f^1]", CHAT_PREFIX, angles[0], angles[1], angles[2]);

  new ret = trace_line(-1, start, end, end);
  // if (!ret && traceresult(TR_Hit) == -1)
  // {
  //   client_print_color(id, print_team_default, "%s Failed on trace! ret: %d, TR_Hit: %d", CHAT_PREFIX, ret, traceresult(TR_Hit));
  //   return PLUGIN_CONTINUE;
  // }

  new Float:normal[3];
  traceresult(TR_PlaneNormal, normal);

  normal[0] *= -1.0;
  normal[1] *= -1.0;
  normal[2] *= -1.0;

  end[0] += normal[0] * -15.0;
  end[1] += normal[1] * -15.0;
  end[2] += normal[2] * -15.0;
  
  vector_to_angle(normal, angles);
  entity_set_origin(model_placed, end);
  entity_set_vector(model_placed, EV_VEC_angles, angles);

  client_print_color(id, print_team_default, "%s Placed model ^4successfully^1.", CHAT_PREFIX);
  client_print_color(id, print_team_red,     "%s  ORIGIN: [^3%0.1f^1, ^3%0.1f^1, ^3%0.1f^1]", CHAT_PREFIX, end[0], end[1], end[2]);
  client_print_color(id, print_team_blue,    "%s  ANGLES: [^3%0.1f^1, ^3%0.1f^1, ^3%0.1f^1]", CHAT_PREFIX, angles[0], angles[1], angles[2]);

  return PLUGIN_CONTINUE;
}
