#include <amxmodx>
#include <sqlx>
#include <reapi>

#define IsPlayer(%1) (1 <= %1 <= g_MaxPlayers)

enum _:LoadStateData
{
	SQL_DATA_NO,
	SQL_DATA_YES		// есть данные
}

enum LevelCvars{
    SQL_HOST[32],
	SQL_USER[32],
	SQL_PASS[32],
	SQL_DB[32],
	SQL_CREATE_DB,
    EXP_NEXT_LEVEL,
    EXP_KILLED,
    EXP_KILLED_KNIFE,
    EXP_KILLED_GRENADE,
    EXP_PLANTING_BOMB,
    EXP_DEFUSE_BOMB,
    MAX_LEVEL,
    POINT_LEVEL,
    POINT_KILLED_KNIFE,
    POINT_KILLED_GRENADE,
    POINT_PLANTING_BOMB,
    POINT_DEFUSE_BOMB
}

new g_eCvars[LevelCvars], g_Level[MAX_PLAYERS + 1], g_Exp[MAX_PLAYERS + 1], g_Point[MAX_PLAYERS + 1];
new IsUpdate[MAX_PLAYERS + 1], IsConnecting[MAX_PLAYERS + 1];
new g_MaxPlayers;

new Handle:g_Sql;
new Handle:g_SqlConnection;

public plugin_init(){
    register_plugin("Level System", "1.0.3", "BiZaJe");

    RegisterHookChain(RG_CSGameRules_PlayerKilled, "@HC_CSGameRules_PlayerKilled", .post = false);
    RegisterHookChain(RG_CBasePlayer_Spawn, "@HC_CBasePlayer_Spawn", .post = true);
    RegisterHookChain(RG_PlantBomb, "@HC_PlantBomb", .post = true);
    RegisterHookChain(RG_CGrenade_DefuseBombEnd, "@HC_CGrenade_DefuseBombEnd", .post = true);

    g_MaxPlayers = get_maxplayers();
}

public plugin_precache(){
    @RegisterCvars();
}

public plugin_natives()
{
    register_native("ls_get_level_player", "native_get_level_player");
    register_native("ls_set_level_player", "native_set_level_player");
    register_native("ls_get_exp_player", "native_get_exp_player");
    register_native("ls_set_exp_player", "native_set_exp_player");
    register_native("ls_is_max_level", "native_is_max_level");
    register_native("ls_get_point_player", "native_get_point_player");
    register_native("ls_set_point_player", "native_set_point_player");
    register_native("ls_exp_next_level", "native_exp_next_level");
}

public OnConfigsExecuted(){
    @DBConnect();
}

public client_putinserver(iPlayer){
    @SqlSelectDB(iPlayer);
}

public client_disconnected(iPlayer){
    @SqlSetDataDB(iPlayer);
    IsConnecting[iPlayer] = false;
}

@HC_CBasePlayer_Spawn(const this){
    @SqlSetDataDB(this);
}

@HC_CSGameRules_PlayerKilled(const victim, const killer, const inflictor){
    if(!is_user_connected(victim) || killer == victim || !killer){
        return HC_CONTINUE;
    }

    if(inflictor != killer){
        if(get_member(victim, m_bKilledByGrenade)){
            g_Exp[killer] += g_eCvars[EXP_KILLED_GRENADE];
            g_Point[killer] += g_eCvars[EXP_KILLED_GRENADE];
        }
    }

    new iActiveItem = get_member(killer, m_pActiveItem);
    
    if(!is_nullent(iActiveItem) && get_member(iActiveItem, m_iId) == WEAPON_KNIFE)
    {
        g_Exp[killer] += g_eCvars[EXP_KILLED_KNIFE];
        g_Point[killer] += g_eCvars[POINT_KILLED_KNIFE];
    }else{
        g_Exp[killer] += g_eCvars[EXP_KILLED]
    }

    TransferExp(killer);

    return HC_CONTINUE;
}

@HC_PlantBomb(const index, Float:vecStart[3], Float:vecVelocity[3]){
    g_Exp[index] += g_eCvars[EXP_PLANTING_BOMB];
    g_Point[index] += g_eCvars[POINT_PLANTING_BOMB];
    TransferExp(index);
}

@HC_CGrenade_DefuseBombEnd(const this, const player, bool:bDefused){
    if(bDefused){
        g_Exp[player] += g_eCvars[EXP_DEFUSE_BOMB];
        g_Point[player] += g_eCvars[POINT_DEFUSE_BOMB];
        TransferExp(player);
    }
}

public native_get_level_player(iPlugin, iNum)
{
	new iPlayer = get_param(1)
	
	if (!IsPlayer(iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "[Level System] Invalid Player (%d)", iPlayer);
		return -1;
	}
	
	return g_Level[iPlayer];
}

public native_get_exp_player(iPlugin, iNum)
{
	new iPlayer = get_param(1)
	
	if (!IsPlayer(iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "[Level System] Invalid Player (%d)", iPlayer);
		return -1;
	}
	
	return g_Exp[iPlayer];
}

public native_get_point_player(iPlugin, iNum)
{
    new iPlayer = get_param(1)
	
    if (!IsPlayer(iPlayer))
    {
	    log_error(AMX_ERR_NATIVE, "[Level System] Invalid Player (%d)", iPlayer);
	    return -1;
    }
	
    return g_Point[iPlayer];
}

public native_set_level_player(iPlugin, iNum)
{
    new iPlayer = get_param(1)
	
    if (!IsPlayer(iPlayer))
    {
        log_error(AMX_ERR_NATIVE, "[Level System] Invalid Player (%d)", iPlayer);
        return false;
    }
	
    new Amount = get_param(2)
	
    if(Amount > g_eCvars[MAX_LEVEL]){
        g_Level[iPlayer] = g_eCvars[MAX_LEVEL];
    }else{
        g_Level[iPlayer] = Amount
    }

    return true;
}

public native_set_exp_player(iPlugin, iNum)
{
    new iPlayer = get_param(1)
	
    if (!IsPlayer(iPlayer))
    {
        log_error(AMX_ERR_NATIVE, "[Level System] Invalid Player (%d)", iPlayer);
        return false;
    }
	
    new Amount = get_param(2)
	
    g_Exp[iPlayer] = Amount;

    return true;
}

public native_set_point_player(iPlugin, iNum)
{
    new iPlayer = get_param(1)
	
    if (!IsPlayer(iPlayer))
    {
        log_error(AMX_ERR_NATIVE, "[Level System] Invalid Player (%d)", iPlayer);
        return false;
    }
	
    new Amount = get_param(2)
	
    g_Point[iPlayer] = Amount

    return true;
}

public native_is_max_level(iPlugin, iNum)
{
    return g_eCvars[MAX_LEVEL];
}

public native_exp_next_level(iPlugin, iNum)
{
    new iPlayer = get_param(1)
	
    if (!IsPlayer(iPlayer))
    {
	    log_error(AMX_ERR_NATIVE, "[Level System] Invalid Player (%d)", iPlayer);
	    return -1;
    }
	
    return g_Exp[iPlayer]*g_Level[iPlayer];
}

stock TransferExp(iPlayer){
    if(g_Level[iPlayer] != g_eCvars[MAX_LEVEL]){
        if(g_Exp[iPlayer] >= (g_eCvars[EXP_NEXT_LEVEL]*g_Level[iPlayer])){
            if(g_Exp[iPlayer] > (g_eCvars[EXP_NEXT_LEVEL]*g_Level[iPlayer])){
                g_Exp[iPlayer] -= g_eCvars[EXP_NEXT_LEVEL]*g_Level[iPlayer];
                g_Level[iPlayer]++;
                g_Point[iPlayer] += g_eCvars[POINT_LEVEL];
            }else{
                g_Exp[iPlayer] = 0
                g_Level[iPlayer]++;
                g_Point[iPlayer] += g_eCvars[POINT_LEVEL];
            }
        }
    }else{
        g_Exp[iPlayer] = 0
        g_Level[iPlayer] = g_eCvars[MAX_LEVEL];
    }
}

public plugin_end(){
   	if(g_Sql){
		SQL_FreeHandle(g_Sql);
    }
}

@RegisterCvars(){
    bind_pcvar_string(create_cvar(
        "ls_db_host",
        "localhost",
        FCVAR_NONE,
        "database address"),
        g_eCvars[SQL_HOST], charsmax(g_eCvars[SQL_HOST])
    );
    bind_pcvar_string(create_cvar(
        "ls_db_user",
        "root",
        FCVAR_NONE,
        "Database User"),
        g_eCvars[SQL_USER], charsmax(g_eCvars[SQL_USER])
    );
    bind_pcvar_string(create_cvar(
        "ls_db_password",
        "",
        FCVAR_NONE,
        "Database Password"),
        g_eCvars[SQL_PASS], charsmax(g_eCvars[SQL_PASS])
    );
    bind_pcvar_string(create_cvar(
        "ls_db",
        "",
        FCVAR_NONE,
        "Database"),
        g_eCvars[SQL_DB], charsmax(g_eCvars[SQL_DB])
    );
    bind_pcvar_num(create_cvar(
        "ls_create_table",
        "1",
        FCVAR_NONE,
        "Database Auto-creation"),
        g_eCvars[SQL_CREATE_DB]
    );
    bind_pcvar_num(create_cvar(
        "ls_exp_next_level",
        "500",
        FCVAR_NONE,
        "The value for calculating the experience to the next level. (CVAR value * player level)"),
        g_eCvars[EXP_NEXT_LEVEL]
    );
    bind_pcvar_num(create_cvar(
        "ls_max_level",
        "20",
        FCVAR_NONE,
        "Maximum level"),
        g_eCvars[MAX_LEVEL]
    );
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
        "ls_point_level",
        "10",
        FCVAR_NONE,
        "How many bonuses to give for reaching a new level"),
        g_eCvars[POINT_LEVEL]
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
    AutoExecConfig(true, "level_system");
}

@DBConnect(){
    new iError, Error[128], Query[1024], iData[1];

    g_Sql = SQL_MakeDbTuple(g_eCvars[SQL_HOST], g_eCvars[SQL_USER], g_eCvars[SQL_PASS], g_eCvars[SQL_DB]);
    g_SqlConnection = SQL_Connect(g_Sql, iError, iData, charsmax(iData));

    if(g_SqlConnection == Empty_Handle){
        set_fail_state("[Level System] Database connection error MySQL^nServer response: %s", Error);
    }else{
        log_amx("[Level System] Connection to the Mysql database was successful");
    }

    formatex(Query, charsmax(Query), "\
        CREATE TABLE IF NOT EXISTS `player_level_system` (\
            `id` INT(11) NOT NULL AUTO_INCREMENT,\
            `steamid` VARCHAR(30) NULL DEFAULT '0',\
            `level` INT(3) NOT NULL DEFAULT '0',\
            `exp` INT(10) NOT NULL DEFAULT '0',\
            `point` INT(16) NOT NULL DEFAULT '0',\
            PRIMARY KEY (`id`)\
    );");

    iData[0] = SQL_DATA_NO;

    SQL_ThreadQuery(g_Sql, "@QueryHandler", Query, iData, sizeof(iData));
}

@SqlSelectDB(iPlayer)
{
    static szSteamId[35], iData[2], Query[1024];
    get_user_authid(iPlayer, szSteamId, charsmax(szSteamId));

    if(!is_valid_steamid(szSteamId))
        return;

    formatex(Query, charsmax(Query), "SELECT * FROM player_level_system WHERE steamid = '%s'", szSteamId)

    iData[0] = SQL_DATA_YES;
    iData[1] = iPlayer;

    SQL_ThreadQuery(g_Sql, "@QueryHandler", Query, iData, sizeof(iData));
}

@SqlSetDataDB(iPlayer)
{
    if(!IsConnecting[iPlayer])
        return;

    static szSteamId[35], iData[1], Query[1024];
    get_user_authid(iPlayer, szSteamId, charsmax(szSteamId));

    if(!is_valid_steamid(szSteamId))
        return;

    if(IsUpdate[iPlayer]){
        formatex(Query, charsmax(Query), "UPDATE player_level_system SET `level` = '%i', `exp` = '%i', `point` = '%i' WHERE `steamid` = '%s'", g_Level[iPlayer], g_Exp[iPlayer], g_Point[iPlayer], szSteamId)
    }else{
        formatex(Query, charsmax(Query), "INSERT INTO `player_level_system` (`steamid`, `level`, `exp`, `point`) VALUES('%s', '%d', '%d', '%d')", szSteamId, g_Level[iPlayer] = 1, g_Exp[iPlayer] = 0, g_Point[iPlayer] = 0);
        IsUpdate[iPlayer] = true;
    }

    iData[0] = SQL_DATA_NO;

    SQL_ThreadQuery(g_Sql, "@QueryHandler", Query, iData, sizeof(iData));
}

@QueryHandler(FailState, Handle:Query, error[], iErrNum, iData[], size, Float:QueryTime) 
{
    if(FailState != TQUERY_SUCCESS)
        log_amx("[Level System MySQL]: %d (%s)", iErrNum, error)

    if(iData[0] == SQL_DATA_YES)
    {
        new iPlayer;
        iPlayer = iData[1];

        if(!is_user_connected(iPlayer))
            return;

        if(SQL_NumResults(Query) > 0)
        {
            new Level = SQL_FieldNameToNum(Query, "level"),
                Exp = SQL_FieldNameToNum(Query, "exp"),
                Point = SQL_FieldNameToNum(Query, "point");

            g_Level[iPlayer] = SQL_ReadResult(Query, Level);
            g_Exp[iPlayer] = SQL_ReadResult(Query, Exp);
            g_Point[iPlayer] = SQL_ReadResult(Query, Point);
            IsUpdate[iPlayer] = true;
        }else{
            IsUpdate[iPlayer] = false;
            @SqlSetDataDB(iPlayer);
        }

        IsConnecting[iPlayer] = true;
    }

    SQL_FreeHandle(Query);
}

stock bool: is_valid_steamid(const szSteamId[])
{
    if(contain(szSteamId, "ID_LAN") != -1 || contain(szSteamId, "BOT") != -1 || contain(szSteamId, "HLTV") != -1)
        return false

    return true
}
