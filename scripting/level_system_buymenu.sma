#include <amxmodx>
#include <ini_file>
#include <level_system_const>

new const FileName[] = "ls_item_manager";

#define PAGE_ITEMS g_MenuData[iPlayer]
new g_MenuData[MAX_PLAYERS + 1];

enum ItemsBuyForward
{
	ITEM_BUY_PRE = 0,
	ITEM_BUY_POST
}

new g_eForward[ItemsBuyForward];
new g_FwdResult;
new g_iMenuCallBack;

new Array:g_ItemName;
new Array:g_ItemCost;
new g_ItemCount;
new g_AddMenuText[32];

public plugin_init()
{
	register_plugin("[Level System] Item Manager", PLUGIN_VERSION, "BiZaJe");
	
	register_clcmd("say /lsitem", "@OpenLsItemMenu");
	register_clcmd("say_team /lsitem", "@OpenLsItemMenu");
	register_clcmd("say_team lsitem", "@OpenLsItemMenu");
	register_clcmd("say lsitem", "@OpenLsItemMenu");

	register_dictionary("level_system_buymenu.txt");

	g_iMenuCallBack = menu_makecallback("@LsItemMenuCallBack");

	g_eForward[ITEM_BUY_PRE] = CreateMultiForward("ls_item_buy_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	g_eForward[ITEM_BUY_POST] = CreateMultiForward("ls_item_buy_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
}

public plugin_precache(){
	g_ItemName = ArrayCreate(32, 1);
	g_ItemCost = ArrayCreate(1, 1);
}

public plugin_natives(){
	register_native("ls_item_register", "native_item_register");
	register_native("ls_item_show_menu", "native_item_show_menu");
	register_native("ls_item_get_cost", "native_item_get_cost");
}

public native_item_register(iPlugin, iNum)
{
	new Name[32], CostItem = get_param(3);
	get_string(1, Name, charsmax(Name));
	
	new i, ItemName[32];
	for (i = 0; i < g_ItemCount; i++)
	{
		ArrayGetString(g_ItemName, i, ItemName, charsmax(ItemName));
	}

	if(!ini_write_string(FileName, Name, "Name", Name)){
		ini_read_string(FileName, Name, "Name", Name, charsmax(Name));
	}
	ArrayPushString(g_ItemName, Name);

	if (!ini_write_int(FileName, Name, "Cost", CostItem)){
		ini_read_int(FileName, Name, "Cost", CostItem);
	}
	ArrayPushCell(g_ItemCost, CostItem);
	
	g_ItemCount++
	return g_ItemCount - 1;
}

public native_item_show_menu(iPlugin, iNum)
{
	new iPlayer = get_param(1)
	
	if (!is_user_connected(iPlayer)){
		log_error(AMX_ERR_NATIVE, "[Item Manager] Invalid Player (%d)", iPlayer);
		return false;
	}
	
	@OpenLsItemMenu(iPlayer);
	return true;
}

public native_item_get_cost(iPlugin, iNum)
{
	new iItem = get_param(1);
	
	if (iItem < 0 || iItem >= g_ItemCount){
		log_error(AMX_ERR_NATIVE, "[Item Manager] Invalid item id (%d)", iItem);
		return -1;
	}
	
	return ArrayGetCell(g_ItemCost, iItem);
}

@OpenLsItemMenu(iPlayer)
{
	if (!is_user_alive(iPlayer)){
		return;
	}
	
	@ShowLsMenu(iPlayer);
}

@ShowLsMenu(iPlayer)
{
	static l_Menu[512], Name[32], CostItem;
	new iMenu, i, ItemData[2], CallBack;
	
	formatex(l_Menu, charsmax(l_Menu), "%L:\r", iPlayer, "LS_TITLE_MENU");
	iMenu = menu_create(l_Menu, "@ls_menu_item_handler");
	
	for (i = 0; i < g_ItemCount; i++){
		g_AddMenuText[0] = 0;

		ExecuteForward(g_eForward[ITEM_BUY_PRE], g_FwdResult, iPlayer, i, 0)
		
		if(g_FwdResult == TL_ITEM_SHOW){
			CallBack = -1;
		}

		if(g_FwdResult == TL_ITEM_BLOCK){
			CallBack = g_iMenuCallBack;
		}

		ArrayGetString(g_ItemName, i, Name, charsmax(Name));
		CostItem = ArrayGetCell(g_ItemCost, i);
		
		formatex(l_Menu, charsmax(l_Menu), "%L \y%d \w%s", iPlayer, Name, CostItem, g_AddMenuText);
		
		ItemData[0] = i;
		ItemData[1] = 0;
		menu_additem(iMenu, l_Menu, ItemData, _, CallBack);
	}
	
	if (menu_items(iMenu) <= 0){
		menu_destroy(iMenu);
		return;
	}
	
	formatex(l_Menu, charsmax(l_Menu), "%L", iPlayer, "LS_MENU_BACK");
	menu_setprop(iMenu, MPROP_BACKNAME, l_Menu);
	formatex(l_Menu, charsmax(l_Menu), "%L", iPlayer, "LS_MENU_NEXT");
	menu_setprop(iMenu, MPROP_NEXTNAME, l_Menu);
	formatex(l_Menu, charsmax(l_Menu), "%L", iPlayer, "LS_MENU_EXIT");
	menu_setprop(iMenu, MPROP_EXITNAME, l_Menu);
	
	PAGE_ITEMS = min(PAGE_ITEMS, menu_pages(iMenu) -1 );
	
	menu_display(iPlayer, iMenu, PAGE_ITEMS);
}

@ls_menu_item_handler(iPlayer, iMenu, iItem)
{
	if (iItem == MENU_EXIT){
		PAGE_ITEMS = 0
		menu_destroy(iMenu)
		return PLUGIN_HANDLED;
	}
	
	PAGE_ITEMS = iItem / 7
	
	if (!is_user_alive(iPlayer)){
		menu_destroy(iMenu)
		return PLUGIN_HANDLED;
	}
	
	new ItemData[64], access, callback;
	menu_item_getinfo(iMenu, iItem, access, ItemData, charsmax(ItemData), _, _, callback);
	iItem = ItemData[0];
	
	@BuyItem(iPlayer, iItem);
	menu_destroy(iMenu);
	return PLUGIN_HANDLED;
}

@LsItemMenuCallBack(iPlayer, iMenu, iItem) {
	new l_Reason[64];
	formatex(l_Reason, charsmax(l_Reason), "%L", iPlayer, "LS_ITEM_BLOCK");
	menu_item_setname(iMenu, iItem, l_Reason)
	return ITEM_DISABLED
}

@BuyItem(iPlayer, iItem){
	ExecuteForward(g_eForward[ITEM_BUY_POST], g_FwdResult, iPlayer, iItem, 0)
}
