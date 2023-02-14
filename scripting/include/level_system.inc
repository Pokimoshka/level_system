#include <level_system_const>

/**
    Returns the current player level
    @param iPlayer - Index Player
*/
native ls_get_level_player(iPlayer)

/**
    Sets the level to the player
    @param iPlayer - Index Player
*/
native ls_set_level_player(iPlayer, Amount)

/**
    Returns the player's current experience
    @param iPlayer - Index Player
*/
native ls_get_exp_player(iPlayer)

/**
    Sets the experience to the player
    @param iPlayer - Index Player
    @param Amount - Value for addition
*/
native ls_set_exp_player(iPlayer, Amount)

/**
    Takes away a certain amount of experience
    @param iPlayer - Index Player
    @param Amount - Value for subtraction
*/
native ls_sub_exp_player(iPlayer, Amount)

// Returns the maximum level
native ls_is_max_level()

/**
    Returns the player's current bonuses
    @param iPlayer - Index Player
*/
native ls_get_point_player(iPlayer)

/**
    Sets bonuses to the player
    @param iPlayer - Index Player
    @param Amount - Value for addition
*/
native ls_set_point_player(iPlayer, Amount)

/**
    Returns experience to the next level
    @param iPlayer - Index Player
*/
native ls_exp_next_level(iPlayer)

// Checks if the system is stopped
native ls_stop_level_system()

// Checks whether auto-cleaning of the database is running
native ls_is_clear_db()

/**
    Function for registering an item in the menu
    @param Name - Item name
    @param Cost - Price per item
*/
native ls_item_register(const Name[], Cost)

/**
    The function gets the price of the item.
    @param iItem - Item
*/
native ls_item_get_cost(iItem)

/**
    The function is called when the menu is opened.
    Any actions before the purchase of the item are performed in it.
    @param iPlayer - Index Player
    @param iItem - Item
    @param Cost - Price per item
*/
forward ls_item_buy_pre(iPlayer, iItem, Cost)

/**
    The function is called when the item is available for purchase.
    @param iPlayer - Index Player
    @param iItem - Item
    @param Cost - Price per item
*/
forward ls_item_buy_post(iPlayer, iItem, Cost)

/*
    The function is called until the moment of experience
    @param iPlayer - Index Player
*/
forward ls_add_exp_pre(iPlayer)

/*
    The function is called at the moment of receiving the main experience
    @param iPlayer - Index Player
    @param Amount - The value of basic experience for manipulation
*/
forward ls_add_exp(iPlayer, Amount)

/*
    The function is called after receiving the main experience
    @param iPlayer - Index Player
*/
forward ls_add_exp_post(iPlayer)

/*
    The function is called before receiving bonuses
    @param iPlayer - Index Player
*/
forward ls_add_point_pre(iPlayer)

/*
    The function is called at the moment of receiving the main bonuses
    @param iPlayer - Index Player
    @param Amount - Bonus values for manipulation
*/
forward ls_add_point(iPlayer, Amount)

/*
    The function is called after receiving the main bonuses
    @param iPlayer - Index Player
*/
forward ls_add_point_post(iPlayer)
