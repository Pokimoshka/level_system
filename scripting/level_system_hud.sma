#include <amxmodx>
#include <level_system>

#define TASK_ID 9267

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

public plugin_init()
{
    register_plugin("[Level System] Hud", "1.0.1", "BiZaJe")

    register_dictionary("level_system_hud.txt");

    g_SyncHud = CreateHudSyncObj();

    @RegisterCvars();
}

public client_putinserver(iPlayer){
    set_task(g_eCvars[UPDATE_HUD], "@LsHud", iPlayer + TASK_ID, .flags="b");
}

public client_disconnected(iPlayer){
    remove_task(iPlayer + TASK_ID);
}

@LsHud(taskID) {
    new iPlayer = taskID - TASK_ID;

    set_hudmessage(.red = g_eCvars[HUD_COLOR_R], .green = g_eCvars[HUD_COLOR_G], .blue = g_eCvars[HUD_COLOR_B], .x = g_eCvars[HUD_POS_X], .y = g_eCvars[HUD_POS_Y]);
    if(ls_get_level_player(iPlayer) == ls_is_max_level()){
        ShowSyncHudMsg(iPlayer, g_SyncHud, "%L %L", iPlayer, "HUD_MAX_LEVEL", ls_get_level_player(iPlayer));
    }else{
        ShowSyncHudMsg(iPlayer, g_SyncHud, "%L %L %L", iPlayer, "HUD_LEVEL", ls_get_level_player(iPlayer), iPlayer, "HUD_EXP", ls_get_exp_player(iPlayer), iPlayer, "HUD_POINT", ls_get_point_player(iPlayer));
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
