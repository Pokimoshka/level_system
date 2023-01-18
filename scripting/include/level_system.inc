#include <level_system_const>

// Returns the current player level
native ls_get_level_player(iPlayer)

// Sets the level to the player
native ls_set_level_player(iPlayer, Amount)

// Returns the player's current experience
native ls_get_exp_player(iPlayer)

// Sets the experience to the player
native ls_set_exp_player(iPlayer, Amount)

// Returns the maximum level
native ls_is_max_level()

// Returns the player's current bonuses
native ls_get_point_player(iPlayer)

// Sets bonuses to the player
native ls_set_point_player(iPlayer, Amount)

/**
    Function for registering an item in the menu
    @param Name - Item name
    @Cost - Price per item
*/
native ls_item_register(const Name[], Cost)

/**
    The function gets the price of the item.
*/
native ls_item_get_cost(iItem)

/**
    The function opens the menu
*/
native ls_item_show_menu()

/**
    The function is called when the menu is opened.
    Any actions before the purchase of the item are performed in it.
*/
forward ls_item_buy_pre(iPlayer, iItem, Cost)

/**
    The function is called when the item is available for purchase.
*/
forward ls_item_buy_post(iPlayer, iItem, Cost)
