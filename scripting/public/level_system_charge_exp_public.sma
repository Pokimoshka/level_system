#include <amxmodx>
#include <reapi>
#include <level_system>

#define STATS 0 // If there are statistics on MySQL
    // 0 - MySQL statistics are not used
    // 1 - CsStats MySQL by SKAJIbnEJIb
    // 2 - CSstatsX SQL by serfreeman1337

#if STATS == 1
	native csstats_get_user_stats(id, stats[22]);
#endif
#if STATS == 2
	native get_user_stats_sql(index, stats[8], bodyhits[8]);
#endif

enum LevelCvars{
    EXP_KILLED,
    EXP_KILLED_KNIFE,
    EXP_KILLED_GRENADE,
    EXP_PLANTING_BOMB,
    EXP_DEFUSE_BOMB,
    POINT_LEVEL,
    POINT_KILLED_KNIFE,
    POINT_KILLED_GRENADE,
    POINT_PLANTING_BOMB,
    POINT_DEFUSE_BOMB,
    PLACE_TOP,
    EXP_MULTI,
    POINT_MULTI,
    Float: HOLDTIME_HUD,
    HUD_COLOR_R,
    HUD_COLOR_G,
    HUD_COLOR_B,
    Float:HUD_POS_X,
    Float:HUD_POS_Y
}

enum FwdLevelSystem{
    ADD_EXP_PRE,
    ADD_EXP_POST
}

new g_eCvars[LevelCvars], g_eFwdLevelSystem[FwdLevelSystem], IsTOP[MAX_PLAYERS + 1];
new g_iRank, g_SyncHud, g_FwdReturn;

public plugin_init(){
    register_plugin("[Level System] Addon: Public Charge Exp/Point", PLUGIN_VERSION, "BiZaJe");

    register_dictionary("level_system_hud.txt");

    RegisterHookChain(RG_CSGameRules_PlayerKilled, "@HC_CSGameRules_PlayerKilled", .post = false);
    RegisterHookChain(RG_CBasePlayer_Spawn, "@HC_CBasePlayer_Spawn", .post = true);
    RegisterHookChain(RG_PlantBomb, "@HC_PlantBomb", .post = true);
    RegisterHookChain(RG_CGrenade_DefuseBombEnd, "@HC_CGrenade_DefuseBombEnd", .post = true);

    g_eFwdLevelSystem[ADD_EXP_PRE] = CreateMultiForward("ls_add_exp_pre", ET_STOP, FP_CELL);
    g_eFwdLevelSystem[ADD_EXP_POST] = CreateMultiForward("ls_add_exp_post", ET_IGNORE, FP_CELL, FP_CELL);

    g_SyncHud = CreateHudSyncObj();
}

public plugin_precache(){
    @RegisterCvars();
}

@HC_CBasePlayer_Spawn(const this){
    #if STATS == 1
		new iStats[22];
    #endif
	#if STATS == 2
		new iStats[8], iBodyHits[8];
	#endif

	#if STATS == 1
		g_iRank = csstats_get_user_stats(this, iStats);
	#endif 
    #if STATS == 2
		g_iRank = get_user_stats_sql(this, iStats, iBodyHits);
    #endif

    if(g_iRank && 0 < g_iRank <= g_eCvars[PLACE_TOP]){
        set_hudmessage(.red = g_eCvars[HUD_COLOR_R], .green = g_eCvars[HUD_COLOR_G], .blue = g_eCvars[HUD_COLOR_B], .x = g_eCvars[HUD_POS_X], .y = g_eCvars[HUD_POS_Y], .holdtime = g_eCvars[HOLDTIME_HUD]);
        ShowSyncHudMsg(this, g_SyncHud, "%L", this, "HUD_INFO_TOP", g_eCvars[PLACE_TOP]);
        IsTOP[this] = true;
    }else{
        IsTOP[this] = false;
    }
}

@HC_CSGameRules_PlayerKilled(const victim, const killer, const inflictor){
    if(!is_user_connected(victim) || killer == victim || !killer || ls_stop_level_system()){
        return;
    }

    ExecuteForward(g_eFwdLevelSystem[ADD_EXP_PRE], g_FwdReturn, killer);

    if(g_FwdReturn >= LEVEL_SYSTEM_HANDLED){
        return;
    }

    if(IsTOP[killer]){
        if(inflictor != killer){
            if(get_member(victim, m_bKilledByGrenade)){
                if(ls_get_level_player(killer) != ls_is_max_level()){
                    ls_set_exp_player(killer, ls_get_exp_player(killer) + (g_eCvars[EXP_KILLED_GRENADE]*g_eCvars[EXP_MULTI]));
                    ExecuteForward(g_eFwdLevelSystem[ADD_EXP_POST], g_FwdReturn, killer, (g_eCvars[EXP_KILLED_GRENADE]*g_eCvars[EXP_MULTI]));
                }
                ls_set_point_player(killer, ls_get_point_player(killer) + (g_eCvars[POINT_KILLED_GRENADE]*g_eCvars[POINT_MULTI]));
            }
        }

        new iActiveItem = get_member(killer, m_pActiveItem);
        
        if(!is_nullent(iActiveItem) && get_member(iActiveItem, m_iId) == WEAPON_KNIFE)
        {
            if(ls_get_level_player(killer) != ls_is_max_level()){
                ls_set_exp_player(killer, ls_get_exp_player(killer) + (g_eCvars[EXP_KILLED_KNIFE]*g_eCvars[EXP_MULTI]));
                ExecuteForward(g_eFwdLevelSystem[ADD_EXP_POST], g_FwdReturn, killer, (g_eCvars[EXP_KILLED_KNIFE]*g_eCvars[EXP_MULTI]));
            }
            ls_set_point_player(killer, ls_get_point_player(killer) + (g_eCvars[POINT_KILLED_KNIFE]*g_eCvars[POINT_MULTI]));
        }else{
            if(ls_get_level_player(killer) != ls_is_max_level()){
                ls_set_exp_player(killer, ls_get_exp_player(killer) + (g_eCvars[EXP_KILLED]*g_eCvars[EXP_MULTI]));
                ExecuteForward(g_eFwdLevelSystem[ADD_EXP_POST], g_FwdReturn, killer, (g_eCvars[EXP_KILLED]*g_eCvars[EXP_MULTI]));
            }
        }
    }else{
        if(inflictor != killer){
            if(get_member(victim, m_bKilledByGrenade)){
                if(ls_get_level_player(killer) != ls_is_max_level()){
                    ls_set_exp_player(killer, ls_get_exp_player(killer) + g_eCvars[EXP_KILLED_GRENADE]);
                    ExecuteForward(g_eFwdLevelSystem[ADD_EXP_POST], g_FwdReturn, killer, g_eCvars[EXP_KILLED_GRENADE]);
                }
                ls_set_point_player(killer, ls_get_point_player(killer) + g_eCvars[POINT_KILLED_GRENADE]);
            }
        }

        new iActiveItem = get_member(killer, m_pActiveItem);
        
        if(!is_nullent(iActiveItem) && get_member(iActiveItem, m_iId) == WEAPON_KNIFE)
        {
            if(ls_get_level_player(killer) != ls_is_max_level()){
                ls_set_exp_player(killer, ls_get_exp_player(killer) + g_eCvars[EXP_KILLED_KNIFE]);
                ExecuteForward(g_eFwdLevelSystem[ADD_EXP_POST], g_FwdReturn, killer, g_eCvars[EXP_KILLED_KNIFE]);
            }
            ls_set_point_player(killer, ls_get_point_player(killer) + g_eCvars[POINT_KILLED_KNIFE]);
        }else{
            if(ls_get_level_player(killer) != ls_is_max_level()){
                ls_set_exp_player(killer, ls_get_exp_player(killer) + g_eCvars[EXP_KILLED]);
                ExecuteForward(g_eFwdLevelSystem[ADD_EXP_POST], g_FwdReturn, killer, g_eCvars[EXP_KILLED]);
            }
        } 
    }
}

@HC_PlantBomb(const index, Float:vecStart[3], Float:vecVelocity[3]){
    if(ls_stop_level_system()){
        return;
    }

    ExecuteForward(g_eFwdLevelSystem[ADD_EXP_PRE], g_FwdReturn, index);

    if(g_FwdReturn >= LEVEL_SYSTEM_HANDLED){
        return;
    }

    ls_set_point_player(index, ls_get_point_player(index) + g_eCvars[POINT_PLANTING_BOMB]);
    if(ls_get_level_player(index) != ls_is_max_level()){
        ls_set_exp_player(index, ls_get_exp_player(index) + g_eCvars[EXP_PLANTING_BOMB]);
        ExecuteForward(g_eFwdLevelSystem[ADD_EXP_POST], g_FwdReturn, index, g_eCvars[EXP_PLANTING_BOMB]);
    }
}

@HC_CGrenade_DefuseBombEnd(const this, const player, bool:bDefused){
    if(ls_stop_level_system()){
        return;
    }

    ExecuteForward(g_eFwdLevelSystem[ADD_EXP_PRE], g_FwdReturn, player);

    if(g_FwdReturn >= LEVEL_SYSTEM_HANDLED){
        return;
    }

    if(bDefused){
        ls_set_point_player(player, ls_get_point_player(player) + g_eCvars[POINT_DEFUSE_BOMB]);
        if(ls_get_level_player(player) != ls_is_max_level()){
            ls_set_exp_player(player, ls_get_exp_player(player) + g_eCvars[EXP_DEFUSE_BOMB]);
            ExecuteForward(g_eFwdLevelSystem[ADD_EXP_POST], g_FwdReturn, player, g_eCvars[POINT_DEFUSE_BOMB]);
        }
    }
}

@RegisterCvars(){
    bind_pcvar_num(create_cvar(
        "ls_exp_killed",
        "1",
        FCVAR_NONE,
        "How much experience to give for killing a player"),
        g_eCvars[EXP_KILLED]
    );
    bind_pcvar_num(create_cvar(
        "ls_exp_killed_knife",
        "2",
        FCVAR_NONE,
        "How much experience to give for killing a player with a knife"),
        g_eCvars[EXP_KILLED_KNIFE]
    );
    bind_pcvar_num(create_cvar(
        "ls_exp_killed_grenade",
        "3",
        FCVAR_NONE,
        "How much experience should I give for killing a player with a grenade"),
        g_eCvars[EXP_KILLED_GRENADE]
    );
    bind_pcvar_num(create_cvar(
        "ls_exp_planting_bomb",
        "2",
        FCVAR_NONE,
        "How much experience should I give for installing a bomb"),
        g_eCvars[EXP_PLANTING_BOMB]
    );
    bind_pcvar_num(create_cvar(
        "ls_exp_planting_bomb",
        "2",
        FCVAR_NONE,
        "How much experience should I give for defusing a bomb"),
        g_eCvars[EXP_DEFUSE_BOMB]
    );
    bind_pcvar_num(create_cvar(
        "ls_point_killed_knife",
        "5",
        FCVAR_NONE,
        "How many bonuses to give for killing a player with a knife"),
        g_eCvars[POINT_KILLED_KNIFE]
    );
    bind_pcvar_num(create_cvar(
        "ls_point_killed_grenade",
        "5",
        FCVAR_NONE,
        "How many bonuses to give for killing a player with a grenade"),
        g_eCvars[POINT_KILLED_GRENADE]
    );
    bind_pcvar_num(create_cvar(
        "ls_point_planting_bomb",
        "8",
        FCVAR_NONE,
        "How many bonuses to give for installing a bomb"),
        g_eCvars[POINT_PLANTING_BOMB]
    );
    bind_pcvar_num(create_cvar(
        "ls_point_defuse_bomb",
        "8",
        FCVAR_NONE,
        "How many bonuses to give for bomb disposal"),
        g_eCvars[POINT_DEFUSE_BOMB]
    );
    bind_pcvar_num(create_cvar(
        "ls_place_top",
        "5",
        FCVAR_NONE,
        "The first N in the top get an experience multiplier"),
        g_eCvars[PLACE_TOP]
    );
    bind_pcvar_num(create_cvar(
        "ls_exp_multi",
        "2",
        FCVAR_NONE,
        "How many times to increase the experience of players in the TOP n"),
        g_eCvars[EXP_MULTI]
    );
    bind_pcvar_num(create_cvar(
        "ls_point_multi",
        "2",
        FCVAR_NONE,
        "How many times to increase bonuses to players in the TOP n"),
        g_eCvars[POINT_MULTI]
    );
    bind_pcvar_float(create_cvar(
        "ls_holdtime_hud",
        "5.0",
        FCVAR_NONE,
        "How long will the HUD alert be on the screen"),
        g_eCvars[HOLDTIME_HUD]
    );
    bind_pcvar_num(create_cvar(
        "ls_hud_color_r",
        "0",
        FCVAR_NONE,
        "HUD color (red shade)"),
        g_eCvars[HUD_COLOR_R]
    );
    bind_pcvar_num(create_cvar(
        "ls_hud_color_g",
        "170",
        FCVAR_NONE,
        "HUD color (green shade)"),
        g_eCvars[HUD_COLOR_G]
    );
    bind_pcvar_num(create_cvar(
        "ls_hud_color_b",
        "0",
        FCVAR_NONE,
        "HUD color (blue shade)"),
        g_eCvars[HUD_COLOR_B]
    );
    bind_pcvar_float(create_cvar(
        "ls_hud_position_x",
        "-1.0",
        FCVAR_NONE,
        "HUD position (X)"),
        g_eCvars[HUD_POS_X]
    );
    bind_pcvar_float(create_cvar(
        "ls_hud_position_y",
        "0.8",
        FCVAR_NONE,
        "HUD position (Y)"),
        g_eCvars[HUD_POS_Y]
    );
    AutoExecConfig(true, "level_system_public");
}
