#include <amxmodx>
#include <reapi>
#include <rezp>
#include <level_system>

enum iClass{
    HUMAN,
    ZOMBIE,
    SURVIVOR,
    NEMESIS,
    SNIPER,
    ASSASSIN
}

enum CvarsReZp{
    LS_GIVE_EXP_KILLED_NEMESIS,
    LS_GIVE_EXP_KILLED_ZOMBIE,
    LS_GIVE_EXP_KILLED_SURVIVOR,
    LS_GIVE_EXP_KILLED_HUMAN,
    LS_GIVE_EXP_KILLED_SNIPER,
    LS_GIVE_EXP_KILLED_ASSASSIN,
    LS_GIVE_POINT_KILLED_NEMESIS,
    LS_GIVE_POINT_KILLED_ZOMBIE,
    LS_GIVE_POINT_KILLED_SURVIVOR,
    LS_GIVE_POINT_KILLED_HUMAN,
    LS_GIVE_POINT_KILLED_SNIPER,
    LS_GIVE_POINT_KILLED_ASSASSIN
}

enum FwdLevelSystem{
    ADD_EXP_PRE,
    ADD_EXP,
    ADD_EXP_POST,
    ADD_POINT_PRE,
    ADD_POINT,
    ADD_POINT_POST
}

new g_CvarsReZp[CvarsReZp], g_eFwdLevelSystem[FwdLevelSystem];
new g_FwdReturn;

new g_iClass[iClass];

public plugin_init(){
    register_plugin("[Level System] Addon: RE ZP Charge Exp/Point", PLUGIN_VERSION, "BiZaJe");

    RegisterHookChain(RG_CSGameRules_PlayerKilled, "@HC_CSGameRules_PlayerKilled", .post = false);

    g_eFwdLevelSystem[ADD_EXP_PRE] = CreateMultiForward("ls_add_exp_pre", ET_CONTINUE, FP_CELL);
    g_eFwdLevelSystem[ADD_EXP] = CreateMultiForward("ls_add_exp", ET_IGNORE, FP_CELL, FP_CELL);
    g_eFwdLevelSystem[ADD_EXP_POST] = CreateMultiForward("ls_add_exp_post", ET_IGNORE, FP_CELL);
    g_eFwdLevelSystem[ADD_POINT_PRE] = CreateMultiForward("ls_add_point_pre", ET_CONTINUE, FP_CELL);
    g_eFwdLevelSystem[ADD_POINT] = CreateMultiForward("ls_point_exp", ET_IGNORE, FP_CELL, FP_CELL);
    g_eFwdLevelSystem[ADD_POINT_POST] = CreateMultiForward("ls_add_point_post", ET_IGNORE, FP_CELL);

    g_iClass[HUMAN] = rz_class_find("class_human");
    g_iClass[ZOMBIE] = rz_class_find("class_zombie");
    g_iClass[SURVIVOR] = rz_class_find("class_survivor");
    g_iClass[NEMESIS] = rz_class_find("class_nemesis");
    g_iClass[SNIPER] = rz_class_find("class_sniper");
    g_iClass[ASSASSIN] = rz_class_find("class_assassin");
}

public plugin_precache(){
    @RegisterCvars();
}

@HC_CSGameRules_PlayerKilled(const victim, const killer, const inflictor){
    if(!is_user_connected(victim) || killer == victim || !killer || ls_stop_level_system() || ls_get_level_player(killer) != ls_is_max_level()){
        return;
    }

    ExecuteForward(g_eFwdLevelSystem[ADD_EXP_PRE], g_FwdReturn, killer);

    if(g_FwdReturn >= LEVEL_SYSTEM_HANDLED){
        return;
    }

    if(rz_player_get(victim, RZ_PLAYER_CLASS) == g_iClass[ZOMBIE]){
        @AddExp(killer, g_CvarsReZp[LS_GIVE_EXP_KILLED_ZOMBIE]);
        @AddPoint(killer, g_CvarsReZp[LS_GIVE_POINT_KILLED_ZOMBIE]);
    }else if(rz_player_get(victim, RZ_PLAYER_CLASS) == g_iClass[NEMESIS]){
        @AddExp(killer, g_CvarsReZp[LS_GIVE_EXP_KILLED_NEMESIS]);
        @AddPoint(killer, g_CvarsReZp[LS_GIVE_POINT_KILLED_NEMESIS]);
    }else if(rz_player_get(victim, RZ_PLAYER_CLASS) == g_iClass[SURVIVOR]){
        @AddExp(killer, g_CvarsReZp[LS_GIVE_EXP_KILLED_SURVIVOR]);
        @AddPoint(killer, g_CvarsReZp[LS_GIVE_POINT_KILLED_SURVIVOR]);
    }else if(rz_player_get(victim, RZ_PLAYER_CLASS) == g_iClass[HUMAN]){
        @AddExp(killer, g_CvarsReZp[LS_GIVE_EXP_KILLED_HUMAN]);
        @AddPoint(killer, g_CvarsReZp[LS_GIVE_POINT_KILLED_HUMAN]);
    }else if(rz_player_get(victim, RZ_PLAYER_CLASS)  == g_iClass[SNIPER]){
        @AddExp(killer, g_CvarsReZp[LS_GIVE_EXP_KILLED_SNIPER]);
        @AddPoint(killer, g_CvarsReZp[LS_GIVE_POINT_KILLED_SNIPER]);
    }else if(rz_player_get(victim, RZ_PLAYER_CLASS) == g_iClass[ASSASSIN]){
        @AddExp(killer, g_CvarsReZp[LS_GIVE_EXP_KILLED_ASSASSIN]);
        @AddPoint(killer, g_CvarsReZp[LS_GIVE_POINT_KILLED_ASSASSIN]);
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
        "ls_zp_give_exp_killed_zomboe",
        "1",
        FCVAR_NONE,
        "How much experience to give for killing zombies"),
        g_CvarsReZp[LS_GIVE_EXP_KILLED_ZOMBIE]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_exp_killed_nemesis",
        "5",
        FCVAR_NONE,
        "How much experience to give for killing nemesis"),
        g_CvarsReZp[LS_GIVE_EXP_KILLED_NEMESIS]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_exp_killed_human",
        "3",
        FCVAR_NONE,
        "How much experience to give for killing a person"),
        g_CvarsReZp[LS_GIVE_EXP_KILLED_HUMAN]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_exp_killed_survivor",
        "10",
        FCVAR_NONE,
        "How much experience to give for killing a survivor"),
        g_CvarsReZp[LS_GIVE_EXP_KILLED_SURVIVOR]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_point_killed_zomboe",
        "3",
        FCVAR_NONE,
        "How many bonuses to give for killing zombies"),
        g_CvarsReZp[LS_GIVE_POINT_KILLED_ZOMBIE]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_point_killed_sniper",
        "3",
        FCVAR_NONE,
        "How much experience should I give for killing a sniper"),
        g_CvarsReZp[LS_GIVE_POINT_KILLED_SNIPER]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_point_killed_assassin",
        "3",
        FCVAR_NONE,
        "How much experience to give for killing an assassin"),
        g_CvarsReZp[LS_GIVE_POINT_KILLED_ASSASSIN]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_point_killed_nemesis",
        "5",
        FCVAR_NONE,
        "How many bonuses to give for killing nemesis"),
        g_CvarsReZp[LS_GIVE_POINT_KILLED_NEMESIS]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_point_killed_human",
        "3",
        FCVAR_NONE,
        "How many bonuses to give for killing a person"),
        g_CvarsReZp[LS_GIVE_POINT_KILLED_HUMAN]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_point_killed_survivor",
        "10",
        FCVAR_NONE,
        "How many bonuses to give for killing a survivor"),
        g_CvarsReZp[LS_GIVE_POINT_KILLED_SURVIVOR]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_point_killed_sniper",
        "10",
        FCVAR_NONE,
        "How many bonuses to give for killing a sniper"),
        g_CvarsReZp[LS_GIVE_POINT_KILLED_SNIPER]
    );
    bind_pcvar_num(create_cvar(
        "ls_zp_give_point_killed_assassin",
        "10",
        FCVAR_NONE,
        "How many bonuses to give for killing an assassin"),
        g_CvarsReZp[LS_GIVE_POINT_KILLED_ASSASSIN]
    );
    AutoExecConfig(true, "level_system_rezp");
}
