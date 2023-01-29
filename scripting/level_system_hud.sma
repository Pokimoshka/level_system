#include <amxmodx>
#include <reapi>
#include <level_system>

#define TASK_ID 9267
#define PLAYER_ID (taskID - TASK_ID)

enum CVARS{
    Float: UPDATE_HUD,
    HUD_COLOR_R,
    HUD_COLOR_G,
    HUD_COLOR_B,
    Float:HUD_POS_X,
    Float:HUD_POS_Y
}

new g_eCvars[CVARS];

new g_SyncHud;
new g_bHudShow[MAX_PLAYERS + 1];

public plugin_init()
{
    register_plugin("[Level System] Hud", PLUGIN_VERSION, "BiZaJe")

    register_dictionary("level_system_hud.txt");
    register_clcmd("say lhud", "@ShowHud");
    register_clcmd("say /lhud", "@ShowHud");
    register_clcmd("say_team /lhud", "@ShowHud");
    register_clcmd("say_team lhud", "@ShowHud");

    g_SyncHud = CreateHudSyncObj();

    @RegisterCvars();
}

public client_putinserver(iPlayer){
    g_bHudShow[iPlayer] = true;
    set_task(g_eCvars[UPDATE_HUD], "@LsHud", iPlayer + TASK_ID, .flags="b");
}

public client_disconnected(iPlayer){
    remove_task(iPlayer + TASK_ID);
}

@ShowHud(iPlayer){
    if(g_bHudShow[iPlayer]){
        g_bHudShow[iPlayer] = false;
    }else{
        g_bHudShow[iPlayer] = true;
    }
}

@LsHud(taskID) {
    new iPlayer = PLAYER_ID;

    if(!is_user_alive(iPlayer)){
        iPlayer = get_entvar(iPlayer, var_iuser2);

        if(!is_user_alive(iPlayer)){
            return;
        }
    }

    set_hudmessage(.red = g_eCvars[HUD_COLOR_R], .green = g_eCvars[HUD_COLOR_G], .blue = g_eCvars[HUD_COLOR_B], .x = g_eCvars[HUD_POS_X], .y = g_eCvars[HUD_POS_Y], .holdtime = g_eCvars[UPDATE_HUD]);
    if(ls_stop_level_system() || ls_is_clear_db()){
        ShowSyncHudMsg(PLAYER_ID, g_SyncHud, "%L", PLAYER_ID, "HUD_STOP_LEVEL_SYSTEM");
    }else{
        if(iPlayer != PLAYER_ID){
            if(ls_get_level_player(iPlayer) == ls_is_max_level()){
                ShowSyncHudMsg(PLAYER_ID, g_SyncHud, "%L %L %L", PLAYER_ID, "HUD_SPECTING", iPlayer, PLAYER_ID, "HUD_MAX_LEVEL", ls_get_level_player(iPlayer), PLAYER_ID, "HUD_POINT", ls_get_point_player(iPlayer));
            }else{
                ShowSyncHudMsg(PLAYER_ID, g_SyncHud, "%L %L %L %L", PLAYER_ID, "HUD_SPECTING", iPlayer, PLAYER_ID, "HUD_LEVEL", ls_get_level_player(iPlayer), PLAYER_ID, "HUD_EXP", ls_get_exp_player(iPlayer), ls_exp_next_level(iPlayer), PLAYER_ID, "HUD_POINT", ls_get_point_player(iPlayer));
            }
        }else{
            if(g_bHudShow[PLAYER_ID]){
                if(ls_get_level_player(PLAYER_ID) == ls_is_max_level()){
                    ShowSyncHudMsg(PLAYER_ID, g_SyncHud, "%L %L", PLAYER_ID, "HUD_MAX_LEVEL", ls_get_level_player(PLAYER_ID), PLAYER_ID, "HUD_POINT", ls_get_point_player(PLAYER_ID));
                }else{
                    ShowSyncHudMsg(PLAYER_ID, g_SyncHud, "%L %L %L", PLAYER_ID, "HUD_LEVEL", ls_get_level_player(PLAYER_ID), PLAYER_ID, "HUD_EXP", ls_get_exp_player(PLAYER_ID), ls_exp_next_level(PLAYER_ID), PLAYER_ID, "HUD_POINT", ls_get_point_player(PLAYER_ID));
                }
            }
        }
    }
}

@RegisterCvars(){
    bind_pcvar_float(create_cvar(
        "hud_update_time",
        "1.0",
        FCVAR_NONE,
        "HUD Update Time"),
        g_eCvars[UPDATE_HUD]
    );
    bind_pcvar_num(create_cvar(
        "hud_color_r",
        "0",
        FCVAR_NONE,
        "HUD color (red shade)"),
        g_eCvars[HUD_COLOR_R]
    );
    bind_pcvar_num(create_cvar(
        "hud_color_g",
        "170",
        FCVAR_NONE,
        "HUD color (green shade)"),
        g_eCvars[HUD_COLOR_G]
    );
    bind_pcvar_num(create_cvar(
        "hud_color_b",
        "255",
        FCVAR_NONE,
        "HUD color (blue shade)"),
        g_eCvars[HUD_COLOR_B]
    );
    bind_pcvar_float(create_cvar(
        "hud_position_x",
        "0.01",
        FCVAR_NONE,
        "HUD position (X)"),
        g_eCvars[HUD_POS_X]
    );
    bind_pcvar_float(create_cvar(
        "hud_position_y",
        "0.13",
        FCVAR_NONE,
        "HUD position (Y)"),
        g_eCvars[HUD_POS_Y]
    );
    AutoExecConfig(true, "level_system_hud");
}
