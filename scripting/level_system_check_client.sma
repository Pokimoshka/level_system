#include <amxmodx>
#include <level_system>

#define TASK_CHECK_CLIENT 298545

new g_SyncHud, bool:g_bCheckClient[MAX_PLAYERS + 1];

enum CheckCLient{
    MAX_LEVEL_NOT_OFF_CLIENT
}

new g_CheckClientCvars[CheckCLient]

public plugin_init(){
    register_plugin("[Level System] Addon: Check Client", PLUGIN_VERSION, "BiZaJe");

    g_SyncHud = CreateHudSyncObj();

    @RegisterCvars();
}

public client_putinserver(iPlayer){
    if(!is_user_bot(iPlayer)){
        if(is_user_steam(iPlayer) || ncl_is_next_client(iPlayer) > NCLV_NOT_NEXT_CLIENT){
            g_bCheckClient[iPlayer] = true;
        }else{
            g_bCheckClient[iPlayer] = false;
        }
    }
}

public ls_add_exp_pre(iPlayer){
    if(ls_get_level_player(iPlayer) >= g_CheckClientCvars[MAX_LEVEL_NOT_OFF_CLIENT] && !g_bCheckClient[iPlayer]){
        if(!task_exists(iPlayer + TASK_CHECK_CLIENT)){
            set_task(1.0, "@CheckClient", iPlayer + TASK_CHECK_CLIENT, _, _, "b");
        }
        return LEVEL_SYSTEM_HANDLED;
    }

    return LEVEL_SYSTEM_CONTINUE;
}

public ls_add_point_pre(iPlayer){
    if(ls_get_level_player(iPlayer) >= g_CheckClientCvars[MAX_LEVEL_NOT_OFF_CLIENT] && !g_bCheckClient[iPlayer]){
        return LEVEL_SYSTEM_HANDLED;
    }

    return LEVEL_SYSTEM_CONTINUE;
}

public client_disconnected(iPlayer){
    remove_task(iPlayer + TASK_CHECK_CLIENT)
}

@CheckClient(TaskId){
    new iPlayer = TaskId - TASK_CHECK_CLIENT;

    set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 6.0, 1.1, 0.0, 0.0);
    ShowSyncHudMsg(iPlayer, g_SyncHud, "%L", LANG_SERVER, "HUD_CHECK_CLIENT");
}

@RegisterCvars(){
    bind_pcvar_num(create_cvar(
        "ls_max_level_not_off_client",
        "1",
        FCVAR_NONE,
        "Maximum level for non-steam and non-nextclient"),
        g_CheckClientCvars[MAX_LEVEL_NOT_OFF_CLIENT]
    );
    AutoExecConfig(true, "level_system_check_client");
}
