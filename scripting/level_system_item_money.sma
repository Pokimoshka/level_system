#include <amxmodx>
#include <reapi>
#include <level_system>

#define ITEM_NAME "FULL_MONEY"
#define ITEM_COST 2
#define BLOCK_GIVE_MONEY 10000
#define GIVE_MONEY 16000

new g_ItemMoney, g_iRoundCounter;

public plugin_init(){
    register_plugin("[Level System] Item: Full Money", PLUGIN_VERSION, "BiZaJe");

    RegisterHookChain(RG_CSGameRules_RestartRound, "@HC_CSGameRules_RestartRound_Pre", .post = false);

    g_ItemMoney = ls_item_register(ITEM_NAME, ITEM_COST);
}

@HC_CSGameRules_RestartRound_Pre()
{
	if(get_member_game(m_bCompleteReset)){
		g_iRoundCounter = 0;
	}
	g_iRoundCounter++;
}

public ls_item_buy_pre(iPlayer, iItem, Cost){
    if(iItem != g_ItemMoney || get_member(iPlayer, m_iAccount) >= BLOCK_GIVE_MONEY || g_iRoundCounter < 3){
        return TL_ITEM_BLOCK;
    }

    return TL_ITEM_SHOW;
}

public ls_item_buy_post(iPlayer, iItem, Cost){
    if(iItem != g_ItemMoney){
        return;
    }

    rg_add_account(iPlayer, GIVE_MONEY);
}
