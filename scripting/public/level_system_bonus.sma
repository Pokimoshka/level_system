#include <amxmodx>
#include <reapi>
#include <level_system>

enum eBonus{
    BONUS_ROUND,
    BONUS_HEGRENADE,
    BONUS_GIVE_LEVEL_HEGRENADE,
    BONUS_FLASHBANG,
    BONUS_GIVE_LEVEL_FLASHBANG,
    BONUS_SMOKEGRENADE,
    BONUS_GIVE_LEVEL_SMOKEGRENADE,
    BONUS_ARNOR,
    BONUS_GIVE_LEVEL_ARMOR
}

new g_eCvars[eBonus], g_iRoundCounter;

public plugin_init()
{
    register_plugin("[Level System] Bonus", PLUGIN_VERSION, "BiZaJe")

    register_dictionary("level_system_hud.txt");

    RegisterHookChain(RG_CSGameRules_RestartRound, "@HC_CSGameRules_RestartRound_Pre", .post = false);
    RegisterHookChain(RG_CBasePlayer_Spawn, "@HC_CBasePlayer_Spawn", .post = true);

    @RegisterCvars();
}

@HC_CSGameRules_RestartRound_Pre(){
    if(get_member_game(m_bCompleteReset)){
        g_iRoundCounter = 0;
    }
    g_iRoundCounter++;
}

@HC_CBasePlayer_Spawn(const this){
    if(g_iRoundCounter < g_eCvars[BONUS_ROUND] || ls_stop_level_system()){
        return;
    }

    if(g_eCvars[BONUS_HEGRENADE]){
        if(ls_get_level_player(this) == g_eCvars[BONUS_GIVE_LEVEL_HEGRENADE]){
            rg_give_item(this, "weapon_hegrenade");
        }
    }

    if(g_eCvars[BONUS_FLASHBANG]){
        if(ls_get_level_player(this) == g_eCvars[BONUS_GIVE_LEVEL_FLASHBANG]){
            rg_give_item(this, "weapon_flashbang");
            rg_give_item(this, "weapon_flashbang");
        }
    }

    if(g_eCvars[BONUS_SMOKEGRENADE]){
        if(ls_get_level_player(this) == g_eCvars[BONUS_GIVE_LEVEL_SMOKEGRENADE]){
            rg_give_item(this, "weapon_smokegrenade");
        }
    }

    if(g_eCvars[BONUS_ARNOR]){
        if(ls_get_level_player(this) == g_eCvars[BONUS_GIVE_LEVEL_ARMOR]){
            rg_give_item(this, "item_assaultsuit");
        }
    }
}

@RegisterCvars(){
    bind_pcvar_num(create_cvar(
        "ls_bonus_round",
        "3",
        FCVAR_NONE,
        "From which round to give out bonuses for levels?"),
        g_eCvars[BONUS_ROUND]
    );
    bind_pcvar_num(create_cvar(
        "ls_bonus_he",
        "1",
        FCVAR_NONE,
        "Enable Hegrenade output?"),
        g_eCvars[BONUS_HEGRENADE]
    );
    bind_pcvar_num(create_cvar(
        "ls_bonus_give_level_he",
        "2",
        FCVAR_NONE,
        "From what level to issue HeGrenade"),
        g_eCvars[BONUS_GIVE_LEVEL_HEGRENADE]
    );
    bind_pcvar_num(create_cvar(
        "ls_bonus_flashbang",
        "1",
        FCVAR_NONE,
        "Enable flashbang output?"),
        g_eCvars[BONUS_FLASHBANG]
    );
    bind_pcvar_num(create_cvar(
        "ls_bonus_give_level_flashbang",
        "3",
        FCVAR_NONE,
        "From what level to issue FlashBang"),
        g_eCvars[BONUS_GIVE_LEVEL_FLASHBANG]
    );

    bind_pcvar_num(create_cvar(
        "ls_bonus_smokegrenade",
        "1",
        FCVAR_NONE,
        "Enable smokegrenade output?"),
        g_eCvars[BONUS_SMOKEGRENADE]
    );
    bind_pcvar_num(create_cvar(
        "ls_bonus_give_level_smokegrenade",
        "3",
        FCVAR_NONE,
        "From what level to issue smokegrenade"),
        g_eCvars[BONUS_GIVE_LEVEL_SMOKEGRENADE]
    );
    bind_pcvar_num(create_cvar(
        "ls_bonus_armor",
        "1",
        FCVAR_NONE,
        "Enable armor output?"),
        g_eCvars[BONUS_ARNOR]
    );
    bind_pcvar_num(create_cvar(
        "ls_bonus_give_level_armor",
        "5",
        FCVAR_NONE,
        "From what level to issue armor"),
        g_eCvars[BONUS_GIVE_LEVEL_ARMOR]
    );
    AutoExecConfig(true, "level_system_bonus");
}
