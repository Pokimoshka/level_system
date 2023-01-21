#include <amxmodx>
#include <level_system>

public plugin_init(){
	register_plugin("[Level System Item Manager] Buy Item", PLUGIN_VERSION, "BiZaJe");
}

public ls_item_buy_pre(iPlayer, iItem, Cost){
	if(Cost){
		return TL_ITEM_CONTINUE;
    }
	
	if(ls_get_point_player(iPlayer) < ls_item_get_cost(iItem)){
		return TL_ITEM_BLOCK;
    }
	
	return TL_ITEM_CONTINUE;
}

public ls_item_buy_post(iPlayer, iItem, Cost){
	if(Cost){
		return;
    }
	
	ls_set_point_player(iPlayer, ls_get_point_player(iPlayer) - ls_item_get_cost(iItem));
}
