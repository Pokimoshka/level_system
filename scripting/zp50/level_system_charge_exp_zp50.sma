#include <amxmodx>
#include <reapi>
#include <level_system>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>

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

new g_CvarsZp[CvarsZp];

public plugin_init(){
    register_plugin("[Level System] Addon: ZP 50 Charge Exp/Point", PLUGIN_VERSION, "BiZaJe");

    RegisterHookChain(RG_CSGameRules_PlayerKilled, "@HC_CSGameRules_PlayerKilled", .post = false);
}

public plugin_precache(){
    @RegisterCvars();
}

public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_SURVIVOR))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public zp_fw_core_infect_post(iPlayer, iAttacker){
	if(!is_user_connected(iAttacker) && iAttacker == iPlayer){
        return;
    }

	if(g_CvarsZp[LS_EXP_INFECTED]){
        ls_set_exp_player(iAttacker, ls_get_exp_player(iAttacker) + g_CvarsZp[LS_GIVE_EXP_INFECTED]);
    }
}

@HC_CSGameRules_PlayerKilled(const victim, const killer, const inflictor){
    if(!is_user_connected(victim) || killer == victim || !killer || ls_stop_level_system()){
        return;
    }

    if(zp_core_is_zombie(victim)){
        if(LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(victim) && g_CvarsZp[LS_EXP_KILLED_NEMESIS]){
            ls_set_exp_player(killer, ls_get_exp_player(killer) + g_CvarsZp[LS_GIVE_EXP_KILLED_NEMESIS]);
            if(g_CvarsZp[LS_POINT_KILLED_NEMESIS]){
                ls_set_point_player(killer, ls_get_point_player(killer) + g_CvarsZp[LS_GIVE_POINT_KILLED_NEMESIS]);
            }
        }else if(g_CvarsZp[LS_EXP_KILLED_ZOMBIE]){
            ls_set_exp_player(killer, ls_get_exp_player(killer) + g_CvarsZp[LS_GIVE_EXP_KILLED_ZOMBIE]);
            if(g_CvarsZp[LS_POINT_KILLED_ZOMBIE]){
                ls_set_point_player(killer, ls_get_point_player(killer) + g_CvarsZp[LS_GIVE_POINT_KILLED_ZOMBIE]);
            }
        }
    }else{
        if(LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(victim) && g_CvarsZp[LS_EXP_KILLED_SURVIVOR]){
            ls_set_exp_player(killer, ls_get_exp_player(killer) + g_CvarsZp[LS_GIVE_EXP_KILLED_SURVIVOR]);
            if(g_CvarsZp[LS_POINT_KILLED_SURVIVOR]){
                ls_set_point_player(killer, ls_get_point_player(killer) + g_CvarsZp[LS_GIVE_POINT_KILLED_SURVIVOR]);
            }
        }else if(g_CvarsZp[LS_EXP_KILLED_HUMAN]){
            ls_set_exp_player(killer, ls_get_exp_player(killer) + g_CvarsZp[LS_GIVE_EXP_KILLED_HUMAN]);
            if(g_CvarsZp[LS_POINT_KILLED_HUMAN]){
                ls_set_point_player(killer, ls_get_point_player(killer) + g_CvarsZp[LS_GIVE_POINT_KILLED_HUMAN]);
            }
        }
    }
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
    AutoExecConfig(true, "level_system_zp50");
}
