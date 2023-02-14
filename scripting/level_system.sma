#include <amxmodx>
#include <sqlx>
#include <level_system_const>

#define TASK_SELECTDB 2000
#define IsPlayer(%1) (1 <= %1 <= g_MaxPlayers)

enum _:LoadStateData
{
	SQL_DATA_NO,
	SQL_DATA_YES
}

enum LevelCvars{
    SQL_HOST[32],
	SQL_USER[32],
	SQL_PASS[32],
	SQL_DB[32],
    SQL_TABLE_NAME[32],
    SQL_AUTOCLEAR_PLAYER,
    SQL_AUTOCLEAR_DB,
	SQL_CREATE_DB,
    LEVEL_SYSTEM_STOP,
    EXP_NEXT_LEVEL,
    MAX_LEVEL,
    POINT_LEVEL
}

new g_eCvars[LevelCvars], g_Level[MAX_PLAYERS + 1], g_Exp[MAX_PLAYERS + 1], g_Point[MAX_PLAYERS + 1];
new IsUpdate[MAX_PLAYERS + 1];
new g_MaxPlayers, bool:IsStop, bool:IsMoreExp[MAX_PLAYERS + 1];

new Handle:g_Sql;
new Handle:g_SqlConnection;

public plugin_init(){
    register_plugin("Level System", PLUGIN_VERSION, "BiZaJe");

    register_srvcmd("level_system_reset", "@DBReset");

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
    register_native("ls_sub_exp_player", "native_set_exp_player");
    register_native("ls_is_max_level", "native_is_max_level");
    register_native("ls_get_point_player", "native_get_point_player");
    register_native("ls_set_point_player", "native_set_point_player");
    register_native("ls_exp_next_level", "native_exp_next_level");
    register_native("ls_stop_level_system", "native_stop_level_system");
}

public OnConfigsExecuted(){
    @DBConnect();
    @AutoClearDB();
}

public client_putinserver(iPlayer){
    set_task(5.0, "@SqlSelectDB", iPlayer + TASK_SELECTDB, .flags = "b");
}

public client_disconnected(iPlayer){
    @SqlSetDataDB(iPlayer);
}

@HC_CBasePlayer_Spawn(const this){
    @SqlSetDataDB(this);
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
    TransferExp(iPlayer);

    return true;
}

public native_sub_exp_player(iPlugin, iNum)
{
    new iPlayer = get_param(1);
	
    if (!IsPlayer(iPlayer))
    {
        log_error(AMX_ERR_NATIVE, "[Level System] Invalid Player (%d)", iPlayer);
        return false;
    }
	
    new Amount = get_param(2)
	
    SubExp(iPlayer, Amount);

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
	
    return g_eCvars[EXP_NEXT_LEVEL]*g_Level[iPlayer];
}

public native_stop_level_system(iPlugin, iNum)
{
    return IsStopLevelSystem();
}

stock TransferExp(iPlayer){
    if(g_Level[iPlayer] != g_eCvars[MAX_LEVEL]){
        IsMoreExp[iPlayer] = true;
        while(IsMoreExp[iPlayer]){
            if(g_Exp[iPlayer] >= (g_eCvars[EXP_NEXT_LEVEL]*g_Level[iPlayer])){
                g_Exp[iPlayer] -= (g_eCvars[EXP_NEXT_LEVEL]*g_Level[iPlayer]);
                g_Level[iPlayer]++;
                g_Point[iPlayer] += g_eCvars[POINT_LEVEL];
            }else{
                IsMoreExp[iPlayer] = false;
            }
        }
    }else{
        g_Exp[iPlayer] = 0
        g_Level[iPlayer] = g_eCvars[MAX_LEVEL];
    }
}

stock SubExp(iPlayer, Amount){
    if(g_Level[iPlayer] > 1){
        g_Exp[iPlayer] -= Amount
        while(g_Exp[iPlayer] < 0){
            g_Exp[iPlayer] += (g_eCvars[EXP_NEXT_LEVEL]*(g_Level[iPlayer] - 1));
            g_Level[iPlayer]--;
        }
    }else{
        g_Exp[iPlayer] = 0;
        g_Level[iPlayer] = 1;
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
        FCVAR_PROTECTED,
        "database address"),
        g_eCvars[SQL_HOST], charsmax(g_eCvars[SQL_HOST])
    );
    bind_pcvar_string(create_cvar(
        "ls_db_user",
        "root",
        FCVAR_PROTECTED,
        "Database User"),
        g_eCvars[SQL_USER], charsmax(g_eCvars[SQL_USER])
    );
    bind_pcvar_string(create_cvar(
        "ls_db_password",
        "",
        FCVAR_PROTECTED,
        "Database Password"),
        g_eCvars[SQL_PASS], charsmax(g_eCvars[SQL_PASS])
    );
    bind_pcvar_string(create_cvar(
        "ls_db",
        "",
        FCVAR_PROTECTED,
        "Database"),
        g_eCvars[SQL_DB], charsmax(g_eCvars[SQL_DB])
    );
    bind_pcvar_string(create_cvar(
        "ls_table_name",
        "",
        FCVAR_PROTECTED,
        "Table name"),
        g_eCvars[SQL_TABLE_NAME], charsmax(g_eCvars[SQL_TABLE_NAME])
    );
    bind_pcvar_num(create_cvar(
        "ls_clear_db_player",
        "7",
        FCVAR_NONE,
        "After how many days to delete inactive players from the database"),
        g_eCvars[SQL_AUTOCLEAR_PLAYER]
    );
    bind_pcvar_num(create_cvar(
        "ls_clear_db",
        "30",
        FCVAR_NONE,
        "After how many days to clear the database"),
        g_eCvars[SQL_AUTOCLEAR_DB]
    );
    bind_pcvar_num(create_cvar(
        "ls_stop",
        "0",
        FCVAR_NONE,
        "Stop level system"),
        g_eCvars[LEVEL_SYSTEM_STOP]
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
        "ls_point_level",
        "10",
        FCVAR_NONE,
        "How many bonuses to give for reaching a new level"),
        g_eCvars[POINT_LEVEL]
    );
    hook_cvar_change(get_cvar_pointer("ls_stop"), "Hook_StopLevelSystem")
    AutoExecConfig(true, "level_system");
}

public Hook_StopLevelSystem(pcvar, const old_value[], const new_value[]) {
	IsStop = (g_eCvars[LEVEL_SYSTEM_STOP] > 0);
}

@DBConnect(){
    new iError, Error[128], Query[1024], iData[1];

    g_Sql = SQL_MakeDbTuple(g_eCvars[SQL_HOST], g_eCvars[SQL_USER], g_eCvars[SQL_PASS], g_eCvars[SQL_DB]);
    g_SqlConnection = SQL_Connect(g_Sql, iError, Error, charsmax(Error));

    if(g_SqlConnection == Empty_Handle){
        set_fail_state("[Level System] Database connection error MySQL^nServer response: %s", Error);
    }else{
        log_amx("[Level System] Connection to the Mysql database was successful");
    }

    formatex(Query, charsmax(Query), "\
        CREATE TABLE IF NOT EXISTS `%s` (\
            `id` INT(11) NOT NULL AUTO_INCREMENT,\
            `steamid` VARCHAR(30) NULL DEFAULT '0',\
            `level` INT(3) NOT NULL DEFAULT '0',\
            `exp` INT(10) NOT NULL DEFAULT '0',\
            `point` INT(16) NOT NULL DEFAULT '0',\
            `timedate` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00',\
            PRIMARY KEY (`id`),\
            UNIQUE INDEX `steamid` (`steamid`)\
    );", g_eCvars[SQL_TABLE_NAME]);

    iData[0] = SQL_DATA_NO;

    SQL_ThreadQuery(g_Sql, "@QueryHandler", Query, iData, sizeof(iData));
}

@SqlSelectDB(taskID)
{
    new iPlayer = taskID - TASK_SELECTDB;
    static szSteamId[MAX_AUTHID_LENGTH], iData[2], Query[1024];
    get_user_authid(iPlayer, szSteamId, MAX_AUTHID_LENGTH - 1);

    if(!is_valid_steamid(szSteamId))
        return;

    formatex(Query, charsmax(Query), "SELECT * FROM %s WHERE steamid = '%s'", g_eCvars[SQL_TABLE_NAME], szSteamId)

    iData[0] = SQL_DATA_YES;
    iData[1] = iPlayer;

    SQL_ThreadQuery(g_Sql, "@QueryHandler", Query, iData, sizeof(iData));
}

@SqlSetDataDB(iPlayer)
{
    if(!is_user_connected(iPlayer))
        return;

    static szSteamId[MAX_AUTHID_LENGTH], iData[1], Query[1024];
    get_user_authid(iPlayer, szSteamId, MAX_AUTHID_LENGTH - 1);

    if(!is_valid_steamid(szSteamId))
        return;

    if(IsUpdate[iPlayer]){
        formatex(Query, charsmax(Query), "UPDATE %s SET `level` = '%i', `exp` = '%i', `point` = '%i', `timedate` = CURRENT_TIMESTAMP WHERE `steamid` = '%s'", g_eCvars[SQL_TABLE_NAME], g_Level[iPlayer], g_Exp[iPlayer], g_Point[iPlayer], szSteamId)
    }else{
        formatex(Query, charsmax(Query), "INSERT IGNORE INTO `%s` (`steamid`, `level`, `exp`, `point`, `timedate`) VALUES('%s', '%d', '%d', '%d', CURRENT_TIMESTAMP)", g_eCvars[SQL_TABLE_NAME], szSteamId, g_Level[iPlayer] = 1, g_Exp[iPlayer] = 0, g_Point[iPlayer] = 0);
        IsUpdate[iPlayer] = true;
    }

    iData[0] = SQL_DATA_NO;

    SQL_ThreadQuery(g_Sql, "@QueryHandler", Query, iData, sizeof(iData));
}

@DBReset(){
	@ClearDB(-1);
}

@AutoClearDB(){
    if(g_eCvars[SQL_AUTOCLEAR_PLAYER] > 0){
        @ClearDB(g_eCvars[SQL_AUTOCLEAR_PLAYER]);
    }

    if(g_eCvars[SQL_AUTOCLEAR_DB] > 0){
        new TimeData[10];
        get_time("%j", TimeData, charsmax(TimeData));
            
        if(str_to_num(TimeData) == g_eCvars[SQL_AUTOCLEAR_DB]){
            TimeData[0] = 0;
            get_vaultdata("ls_reset", TimeData, charsmax(TimeData));
            if(!str_to_num(TimeData)){
                set_vaultdata("ls_reset", "1");
                @ClearDB(-1);
            }
        }else{
            set_vaultdata("ls_reset", "0");
        }
	}
}

@ClearDB(day)
{
    if(day == -1)
    {
        log_amx("[Level System] Database reset");
    }
	
    new Query[1024], iData[1];

    if(day > 0){
        formatex(Query, charsmax(Query), "DELETE FROM `%s` WHERE `timedate` <= DATE_SUB(NOW(),INTERVAL %d DAY);", g_eCvars[SQL_TABLE_NAME], day);
    }else{
        formatex(Query, charsmax(Query), "DELETE `%s` FROM `player_level_system` WHERE 1", g_eCvars[SQL_TABLE_NAME]);
    }
	
    iData[0] = SQL_DATA_NO;
	
    SQL_ThreadQuery(g_Sql, "@QueryHandler", Query, iData, sizeof(iData));
}

@QueryHandler(FailState, Handle:Query, error[], iErrNum, iData[], size, Float:QueryTime) 
{
    if(FailState != TQUERY_SUCCESS)
        log_amx("[Level System MySQL]: %d (%s)", iErrNum, error)

    if(iData[0] == SQL_DATA_YES){
        new iPlayer;
        iPlayer = iData[1];

        if(!is_user_connected(iPlayer))
            return;

        if(SQL_NumResults(Query) < 1)
        {
            IsUpdate[iPlayer] = false;
            @SqlSetDataDB(iPlayer);
        }else{
            new Level = SQL_FieldNameToNum(Query, "level"),
                Exp = SQL_FieldNameToNum(Query, "exp"),
                Point = SQL_FieldNameToNum(Query, "point");

            g_Level[iPlayer] = SQL_ReadResult(Query, Level);
            g_Exp[iPlayer] = SQL_ReadResult(Query, Exp);
            g_Point[iPlayer] = SQL_ReadResult(Query, Point);
            IsUpdate[iPlayer] = true;
        }

        remove_task(iPlayer + TASK_SELECTDB);
    }

    SQL_FreeHandle(Query);
}

stock bool:is_valid_steamid(const szSteamId[])
{
    if(contain(szSteamId, "ID_LAN") != -1 || contain(szSteamId, "BOT") != -1 || contain(szSteamId, "HLTV") != -1)
        return false

    return true
}


stock IsStopLevelSystem() {
	return IsStop;
}
