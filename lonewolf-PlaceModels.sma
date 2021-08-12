#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <json>

#define PLUGIN  "PlaceModels"
#define VERSION "0.0.2"
#define AUTHOR  "lonewolf"

new const CHAT_PREFIX[] = "^4[PlaceModels]^1"
// new const MODEL_PATH[] = "models/bannertest.mdl";
new JSON_FILE[96] = "PlaceModels.json";
new CONFIG_PATH[64];

new JSON:root;
new JSON:precache_models;
new precache_models_count;


public plugin_precache()
{
  get_configsdir(CONFIG_PATH, charsmax(CONFIG_PATH));
  format(JSON_FILE, charsmax(JSON_FILE), "%s/%s", CONFIG_PATH, JSON_FILE);

  root = json_parse(JSON_FILE, .is_file=true, .with_comments=true);

  if (root == Invalid_JSON)
  {
    set_fail_state("[%s] Failed to parse file ^"%s^"!", PLUGIN, JSON_FILE);
  }

  if (json_get_type(root) != JSONObject)
  {
    set_fail_state("[%s] Json isn't an object!", PLUGIN);
  }

  if (!json_object_has_value(root, "precache_models"))
  {
    set_fail_state("[%s] Json don't have 'precache_models' value!", PLUGIN);
  }

  precache_models = json_object_get_value(root, "precache_models");
  if (precache_models == Invalid_JSON)
  {
    set_fail_state("[%s] 'precache_models' == Invalid_JSON!", PLUGIN);
  }
  static model_path[128];
  if (json_get_type(precache_models) != JSONArray)
  {
    // json_object_get_string(root, "precache_models", model_path, charsmax(model_path));
    // precache_model(model_path);
    set_fail_state("[%s] 'precache_models' is not an array!", PLUGIN);
  }
  else
  {
    new JSON:tmp;
    precache_models_count = json_array_get_count(precache_models);
    for (new i = 0; i < precache_models_count; ++i)
    {
      tmp = json_array_get_value(precache_models, i);
      if (tmp != Invalid_JSON)
      {
        json_object_get_string(tmp, "path", model_path, charsmax(model_path));
        precache_model(model_path);

        server_print("[%s] Precached '%s'.", PLUGIN, model_path);
      }
    }

    json_free(tmp);
  }
}

public plugin_init()
{
  register_plugin(PLUGIN, VERSION, AUTHOR);
  
  register_clcmd("test", "cmd_test");
}

public cmd_test(id)
{
  static c = 0;

  new newmodel = model_create(0, c > 1 ? 1 : c);
  model_place(id, newmodel);

  c++;
  return PLUGIN_CONTINUE;
}

public model_create(model_number, skin)
{
  new model = create_entity("info_target");
  if (!is_valid_ent(model))
  {
    set_fail_state("Failed to create entity ^"%s^".", "info_target");
    return PLUGIN_HANDLED;
  }

  new JSON:tmp;
  tmp = json_array_get_value(precache_models, model_number);
  if (tmp == Invalid_JSON)
  {
    set_fail_state("Failed to retrieve model #%d", model_number);
  }

  static model_path[128];
  json_object_get_string(tmp, "path", model_path, charsmax(model_path));

  entity_set_string(model, EV_SZ_classname, "placedmodel");
  entity_set_model(model, model_path);
  entity_set_int(model, EV_INT_skin, skin);
  // entity_set_size(model, Float:{0.0, 0.0, 0.0}, Float:{16.0, 16.0, 16.0});
  // entity_set_int(model, EV_INT_solid, SOLID_NOT);
  // set_rendering(model);

  server_print("[%s] Created model '%s' with skin %d [%d].", PLUGIN, model_path, skin, model);

  return model;
}

public model_place(id, model)
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
  
  trace_line(-1, start, end, end);
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
  entity_set_origin(model, end);
  entity_set_vector(model, EV_VEC_angles, angles);

  client_print_color(id, print_team_default, "%s Placed model #%d ^4successfully^1.", CHAT_PREFIX, model);
  client_print_color(id, print_team_red,     "%s  ORIGIN: [^3%0.1f^1, ^3%0.1f^1, ^3%0.1f^1]", CHAT_PREFIX, end[0], end[1], end[2]);
  client_print_color(id, print_team_blue,    "%s  ANGLES: [^3%0.1f^1, ^3%0.1f^1, ^3%0.1f^1]", CHAT_PREFIX, angles[0], angles[1], angles[2]);

  return PLUGIN_CONTINUE;
}
