#include <amxmodx>
#include <reapi>
#include <level_system>
#include <zombieplague>

enum CvarsZp{
    LS_EXP_INFECTED,
    LS_GIVE_EXP_INFECTED,
    LS_EXP_KILLED_NEMESIS,
    LS_GIVE_EXP_KILLED_NEMESIS,
    LS_EXP_KILLED_ZOMBIE,
    LS_GIVE_EXP_KILLED_ZOMBIE,
    LS_EXP_KILLED_SURVIVOR,
    LS_GIVE_EXP_KILLED_SURVIVOR,
    LS_EXP_KILLED_HUMAN,
    LS_GIVE_EXP_KILLED_HUMAN,
    LS_POINT_KILLED_NEMESIS,
    LS_GIVE_POINT_KILLED_NEMESIS,
    LS_POINT_KILLED_ZOMBIE,
    LS_GIVE_POINT_KILLED_ZOMBIE,
    LS_POINT_KILLED_SURVIVOR,
    LS_GIVE_POINT_KILLED_SURVIVOR,
    LS_POINT_KILLED_HUMAN,
    LS_GIVE_POINT_KILLED_HUMAN
}

enum FwdLevelSystem{
    ADD_EXP_PRE,
    ADD_EXP,
    ADD_EXP_POST,
    ADD_POINT_PRE,
    ADD_POINT,
    ADD_POINT_POST
}

new g_CvarsZp[CvarsZp], g_eFwdLevelSystem[FwdLevelSystem];
new g_FwdReturn;

public plugin_init(){
    register_plugin("[Level System] Addon: ZP 50 Charge Exp/Point", PLUGIN_VERSION, "BiZaJe");

    RegisterHookChain(RG_CSGameRules_PlayerKilled, "@HC_CSGameRules_PlayerKilled", .post = false);

    g_eFwdLevelSystem[ADD_EXP_PRE] = CreateMultiForward("ls_add_exp_pre", ET_CONTINUE, FP_CELL);
    g_eFwdLevelSystem[ADD_EXP] = CreateMultiForward("ls_add_exp", ET_IGNORE, FP_CELL, FP_CELL);
    g_eFwdLevelSystem[ADD_EXP_POST] = CreateMultiForward("ls_add_exp_post", ET_IGNORE, FP_CELL);
    g_eFwdLevelSystem[ADD_POINT_PRE] = CreateMultiForward("ls_add_point_pre", ET_CONTINUE, FP_CELL);
    g_eFwdLevelSystem[ADD_POINT] = CreateMultiForward("ls_point_exp", ET_IGNORE, FP_CELL, FP_CELL);
    g_eFwdLevelSystem[ADD_POINT_POST] = CreateMultiForward("ls_add_point_post", ET_IGNORE, FP_CELL);
}

public plugin_precache(){
    @RegisterCvars();
}

public zp_user_infected_post(iPlayer, iInfector) {
    if(!is_user_connected(iInfector) && iInfector == iPlayer){
        return;
    }

    if(g_CvarsZp[LS_EXP_INFECTED]){
        @AddExp(iInfector, g_CvarsZp[LS_GIVE_EXP_INFECTED]);
    }
}

@HC_CSGameRules_PlayerKilled(const victim, const killer, const inflictor){
    if(!is_user_connected(victim) || killer == victim || !killer || ls_stop_level_system()){
        return;
    }

    if(zp_get_user_nemesis(victim)){
        if(g_CvarsZp[LS_EXP_KILLED_NEMESIS]){
            @AddExp(killer, g_CvarsZp[LS_GIVE_EXP_KILLED_NEMESIS]);
            if(g_CvarsZp[LS_POINT_KILLED_NEMESIS]){
                @AddPoint(killer, g_CvarsZp[LS_GIVE_POINT_KILLED_NEMESIS]);
            }
        }
    }

    if(zp_get_user_zombie(victim)){
        if(g_CvarsZp[LS_EXP_KILLED_ZOMBIE]){
            @AddExp(killer, g_CvarsZp[LS_GIVE_EXP_KILLED_ZOMBIE]);
            if(g_CvarsZp[LS_POINT_KILLED_ZOMBIE]){
                @AddPoint(killer, g_CvarsZp[LS_GIVE_POINT_KILLED_ZOMBIE]);
            }
        }
    }

    if(zp_get_user_survivor(victim)){
        if( g_CvarsZp[LS_EXP_KILLED_SURVIVOR]){
            @AddExp(killer, g_CvarsZp[LS_GIVE_EXP_KILLED_SURVIVOR]);
            if(g_CvarsZp[LS_POINT_KILLED_SURVIVOR]){
                @AddPoint(killer, g_CvarsZp[LS_GIVE_POINT_KILLED_SURVIVOR]);
            }
        }
    }

    if(zp_get_user_zombie(killer) && !zp_get_user_zombie(victim)){
        if(g_CvarsZp[LS_EXP_KILLED_HUMAN]){
            @AddExp(killer, g_CvarsZp[LS_GIVE_EXP_KILLED_HUMAN]);
            if(g_CvarsZp[LS_POINT_KILLED_HUMAN]){
                @AddPoint(killer, g_CvarsZp[LS_GIVE_POINT_KILLED_HUMAN]);
            }
        }
    }
}

@AddExp(iPlayer, Amount){
    ExecuteForward(g_eFwdLevelSystem[ADD_EXP_PRE], g_FwdReturn, iPlayer);

    if(g_FwdReturn >= LEVEL_SYSTEM_HANDLED){
        return;
    }

    ExecuteForward(g_eFwdLevelSystem[ADD_EXP], g_FwdReturn, iPlayer, Amount);
    ls_set_exp_player(iPlayer, ls_get_exp_player(iPlayer) + Amount);

    ExecuteForward(g_eFwdLevelSystem[ADD_EXP_POST], g_FwdReturn, iPlayer);
}

@AddPoint(iPlayer, Amount){
    ExecuteForward(g_eFwdLevelSystem[ADD_POINT_PRE], g_FwdReturn, iPlayer);

    if(g_FwdReturn >= LEVEL_SYSTEM_HANDLED){
        return;
    }

    ExecuteForward(g_eFwdLevelSystem[ADD_POINT], g_FwdReturn, iPlayer, Amount);
    ls_set_point_player(iPlayer, ls_get_point_player(iPlayer) + Amount);

    ExecuteForward(g_eFwdLevelSystem[ADD_POINT_POST], g_FwdReturn, iPlayer);
}

@RegisterCvars(){
    bind_pcvar_num(create_cvar(
        "ls_zp_exp_infected",
        "1",
        FCVAR_NONE,
        "Give experience for infection?"),
        g_CvarsZp[LS_EXP_INFECTED]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_exp_infected",
        "2",
        FCVAR_NONE,
        "How much experience to give for infection"),
        g_CvarsZp[LS_GIVE_EXP_INFECTED]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_exp_killed_zombie",
        "1",
        FCVAR_NONE,
        "Give experience for killing zombies?"),
        g_CvarsZp[LS_EXP_KILLED_ZOMBIE]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_exp_killed_zomboe",
        "1",
        FCVAR_NONE,
        "How much experience to give for killing zombies"),
        g_CvarsZp[LS_GIVE_EXP_KILLED_ZOMBIE]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_exp_killed_nemesis",
        "1",
        FCVAR_NONE,
        "Give experience for killing nemesis?"),
        g_CvarsZp[LS_EXP_KILLED_NEMESIS]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_exp_killed_nemesis",
        "5",
        FCVAR_NONE,
        "How much experience to give for killing nemesis"),
        g_CvarsZp[LS_GIVE_EXP_KILLED_NEMESIS]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_exp_killed_human",
        "1",
        FCVAR_NONE,
        "How much experience to give for killing zombies"),
        g_CvarsZp[LS_EXP_KILLED_HUMAN]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_exp_killed_human",
        "3",
        FCVAR_NONE,
        "How much experience to give for killing a person"),
        g_CvarsZp[LS_GIVE_EXP_KILLED_HUMAN]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_exp_killed_survivor",
        "1",
        FCVAR_NONE,
        "Give experience for killing a survivor?"),
        g_CvarsZp[LS_EXP_KILLED_SURVIVOR]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_exp_killed_survivor",
        "10",
        FCVAR_NONE,
        "How much experience to give for killing a survivor"),
        g_CvarsZp[LS_GIVE_EXP_KILLED_SURVIVOR]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_point_killed_zombie",
        "1",
        FCVAR_NONE,
        "Give bonuses for killing zombies?"),
        g_CvarsZp[LS_POINT_KILLED_ZOMBIE]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_point_killed_zomboe",
        "3",
        FCVAR_NONE,
        "How many bonuses to give for killing zombies"),
        g_CvarsZp[LS_GIVE_POINT_KILLED_ZOMBIE]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_point_killed_nemesis",
        "1",
        FCVAR_NONE,
        "Give bonuses for killing nemesis?"),
        g_CvarsZp[LS_POINT_KILLED_NEMESIS]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_point_killed_nemesis",
        "5",
        FCVAR_NONE,
        "How many bonuses to give for killing nemesis"),
        g_CvarsZp[LS_GIVE_POINT_KILLED_NEMESIS]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_point_killed_human",
        "1",
        FCVAR_NONE,
        "Give bonuses for killing a person?"),
        g_CvarsZp[LS_POINT_KILLED_HUMAN]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_point_killed_human",
        "3",
        FCVAR_NONE,
        "How many bonuses to give for killing a person"),
        g_CvarsZp[LS_GIVE_POINT_KILLED_HUMAN]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_point_killed_survivor",
        "1",
        FCVAR_NONE,
        "Give bonuses for killing a survivor?"),
        g_CvarsZp[LS_POINT_KILLED_SURVIVOR]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_point_killed_survivor",
        "10",
        FCVAR_NONE,
        "How many bonuses to give for killing a survivor"),
        g_CvarsZp[LS_GIVE_POINT_KILLED_SURVIVOR]
    );
    AutoExecConfig(true, "level_system_zp43");
}
