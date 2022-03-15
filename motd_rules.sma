// MOTD Rules by lonewolf <igorkelvin@gmail.com>
// https://github.com/igorkelvin/amxx-plugins

#include <amxmodx>
#include <amxmisc>
#include <regex>

#define PLUGIN  "MOTD Rules"
#define VERSION "0.1"
#define AUTHOR  "lonewolf"
#define URL     "https://github.com/igorkelvin/amxx-plugins"

#if !defined MAX_MOTD_LENGTH
  #define MAX_MOTD_LENGTH 1536
#endif

new const prefixes[][16] = 
{
    "say .", 
    "say /", 
    "say_team .", 
    "say_team /", 
    ""
};

new const cmds[][32] =
{
    "regra",
    "regras",
    "rule",
    "rules"
};

new const PATTERN_REGEX[] = "(\.html|\.txt)$";
new Regex:regex = REGEX_PATTERN_FAIL;

new const MOTD_DEFAULT[] = "Standard rules text. Please contact this server's administrator to inform there is an error in rules file."
new motd[MAX_MOTD_LENGTH];

new cvar_rulesfile;
new rulesfile[128];

new hostname[64];


public plugin_cfg()
{
    cvar_rulesfile = create_cvar("amx_rulesfile", "rules.html", FCVAR_PRINTABLEONLY | FCVAR_NOEXTRAWHITEPACE, "Rules filename inside amxmodx's config folder");
    
    hook_cvar_change(cvar_rulesfile, "on_rulesfile_change");
    bind_pcvar_string(cvar_rulesfile, rulesfile, charsmax(rulesfile));
    
    get_cvar_string("hostname", hostname, charsmax(hostname));

    new ret, error[128];
    regex = regex_compile(PATTERN_REGEX, ret, error, charsmax(error));
    
    if (regex == REGEX_PATTERN_FAIL)
    {
        set_fail_state("[%s] Error regex, aborting (%d): %s", PLUGIN, ret, error);
    }

    update_motd();
}


public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);

    for (new i = 0; i < sizeof(cmds); ++i)
    {
        for (new j = 0; j < sizeof(prefixes); ++j)
        {
            register_clcmd(fmt("%s%s", prefixes[j], cmds[i]), "cmd_show_rules");
        }
    }
}


public on_rulesfile_change(pcvar, old_value[], new_value[])
{
    if ((pcvar == cvar_rulesfile) && !equal(old_value, new_value))
    {
        update_motd();
    }
}


public update_motd()
{
    new ret = -1;

    if (!strlen(rulesfile))
    {
        server_print("[%s] Error: Empty 'amx_rulesfile'", PLUGIN);
    }
    else if (!file_exists(rulesfile))
    {
        server_print("[%s] Error: Rules file doesn't exist: '%s'", PLUGIN, rulesfile);
    }
    else if (regex_match_c(rulesfile, regex) <= 0)
    {
        server_print("[%s] Error: Failed regex match on rules file: '%s'. Regex pattern: '%s'", PLUGIN, rulesfile, PATTERN_REGEX);
    }
    else
    {
        new len;
        ret = LoadFileForMe(rulesfile, motd, charsmax(motd), len);

        if (ret == -1)
        {
            server_print("[%s] Error: Failed to read rules file: '%s'", PLUGIN, rulesfile);
        }
        else
        {
            server_print("[%s] Rules file read sucessfully: '%s'", PLUGIN, rulesfile);
            
            len = min(len, charsmax(motd)); /* @LoadFileForMe: This may return a number larger than the buffer size */
            motd[len] = '^0';               /* @LoadFileForMe: No null-terminator is applied; the data is the raw contents of the file. */
        }
    }

    if (ret == -1)
    {
        copy(motd, charsmax(motd), MOTD_DEFAULT);
    }

    return ret;
}


public cmd_show_rules(id)
{
    if (is_user_connected(id))
    {
        show_motd(id, motd, hostname);
    }
}


public plugin_end()
{
    regex_free(regex);
}
