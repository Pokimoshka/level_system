#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <reapi>
#include <fakemeta>
#include <level_system>

#define TASK_STATS 328869

enum _:LoadStateData
{
	SQL_DATA_NO,
	SQL_DATA_YES
}

enum PlayerStats{
    KILLS,
    KILLS_HS,
    DEATHS,
    SHOTS,
    DAMAGE,
    HITS,
    BOMB_PLANTED,
    BOMB_DEFUSED,
    WIN_CT,
    WIN_TT
}

enum GeneralStats{
    G_KILLS,
    G_KILLS_HS,
    G_DEATHS,
    G_SHOTS,
    G_DAMAGE,
    G_HITS,
    G_BOMB_PLANTED,
    G_BOMB_DEFUSED,
    G_WIN_CT,
    G_WIN_TT
}

enum Hits{
    HITS_HS,
    HITS_CHEST,
    HITS_STOMACH,
    HITS_LHAND,
    HITS_RHAND,
    HITS_LLEG,
    HITS_RLEG
}

enum GenerakHits{
    G_HITS_HS,
    G_HITS_CHEST,
    G_HITS_STOMACH,
    G_HITS_LHAND,
    G_HITS_RHAND,
    G_HITS_LLEG,
    G_HITS_RLEG
}

enum StatsCvars{
    STATS_SQL_IP[32],
    STATS_SQL_USER[32],
    STATS_SQL_PASS[32],
    STATS_SQL_DB[32],
    STATS_SQL_NAME_TABLE[64],
    STATS_AUTOCLEAR_PLAYER,
    STATS_AUTOCLEAR_DB
}

new g_PlayerStats[PlayerStats][MAX_PLAYERS + 1], g_GeneralStats[GeneralStats][MAX_PLAYERS + 1], g_HitsStats[Hits][MAX_PLAYERS + 1], g_GeneralHits[GenerakHits][MAX_PLAYERS + 1];
new g_StatsCvars[StatsCvars];
new StatsUpdate[MAX_PLAYERS + 1];

new g_iGunsEventsIdBitSum;

new Handle:g_StatsSql;
new Handle:g_SqlStatsConnect;

public plugin_init(){
    register_plugin("[Level System] Stats", "1.0.0 Alpha", "BiZaJe");

	new const GunEvent[][] = {
        "events/awp.sc", "events/g3sg1.sc", "events/ak47.sc", "events/scout.sc", "events/m249.sc",
        "events/m4a1.sc", "events/sg552.sc", "events/aug.sc", "events/sg550.sc", "events/m3.sc",
        "events/xm1014.sc", "events/usp.sc", "events/mac10.sc", "events/ump45.sc", "events/fiveseven.sc",
        "events/p90.sc", "events/deagle.sc", "events/p228.sc", "events/glock18.sc", "events/mp5n.sc",
        "events/tmp.sc", "events/elite_left.sc", "events/elite_right.sc", "events/galil.sc", "events/famas.sc"
    };

    register_srvcmd("lss_reset", "@StatsReset");

    RegisterHookChain(RG_RoundEnd, "@HC_RoundEnd", .post = true);
    RegisterHookChain(RG_CSGameRules_PlayerKilled, "@HC_CSGameRules_PlayerKilled", .post = false);
    RegisterHookChain(RG_CBasePlayer_TraceAttack, "@HC_CBasePlayer_TraceAttack", .post = true);
    RegisterHookChain(RG_PlantBomb, "@HC_PlantBomb", .post = true);

    for(new i; i<sizeof(GunEvent); i++)
    {
        g_iGunsEventsIdBitSum |= 1<<engfunc(EngFunc_PrecacheEvent, 1, GunEvent[i]);
    }

	register_forward(FM_PlaybackEvent, "@Hook_EventPlayBack");
}

public plugin_precache(){
    @LoadStatsCvars();
}

public OnConfigsExecuted(){
    @StatsDbConnect();
    @StatsAutoClear();
}

public client_putinserver(iPlayer){
    set_task(5.0, "@SqStatslSelect", iPlayer + TASK_STATS, .flags = "b");
}

public client_disconnected(iPlayer){
    @StatsSqlSetData(iPlayer);
}

@StatsDbConnect(){
    new iError, Error[128], Query[1024], iData[1];

    g_StatsSql = SQL_MakeDbTuple(g_StatsCvars[STATS_SQL_IP], g_StatsCvars[STATS_SQL_USER], g_StatsCvars[STATS_SQL_PASS], g_StatsCvars[STATS_SQL_DB]);
    g_SqlStatsConnect = SQL_Connect(g_StatsSql, iError, Error, charsmax(Error));

    if(g_SqlStatsConnect == Empty_Handle){
        set_fail_state("[Level System Stats] Database connection error MySQL^nServer response: %s", Error);
    }else{
        log_amx("[Level System Stats] Connection to the Mysql database was successful");
    }

    formatex(Query, charsmax(Query), "\
        CREATE TABLE IF NOT EXISTS `%s` (\
            `id` INT(10) NOT NULL AUTO_INCREMENT,\
            `nick` TEXT(64) NOT NULL,\
            `steamid` TEXT(30) NOT NULL,\
            `kills` INT(10) NOT NULL DEFAULT 0,\
            `kills_hs` INT(10) NOT NULL DEFAULT 0,\
            `damage` INT(10) NOT NULL DEFAULT 0,\
            `deaths` INT(10) NOT NULL DEFAULT 0,\
            `shots` INT(16) NOT NULL DEFAULT 0,\
            `h_head` INT(10) NOT NULL DEFAULT 0,\
            `h_chest` INT(10) NOT NULL DEFAULT 0,\
            `h_stomach` INT(10) NOT NULL DEFAULT 0,\
            `h_lhand` INT(10) NOT NULL DEFAULT 0,\
            `h_rhand` INT(10) NOT NULL DEFAULT 0,\
            `h_lleg` INT(10) NOT NULL DEFAULT 0,\
            `h_rleg` INT(10) NOT NULL DEFAULT 0,\
            `bomb_defused` INT(10) NOT NULL DEFAULT 0,\
            `bomb_planted` INT(10) NOT NULL DEFAULT 0,\
            `win_ct` INT(10) NOT NULL DEFAULT 0,\
            `win_tt` INT(10) NOT NULL DEFAULT 0,\
            `timedate` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00',\
            PRIMARY KEY (`id`)\
            );", g_StatsCvars[STATS_SQL_NAME_TABLE]);

    iData[0] = SQL_DATA_NO;

    SQL_ThreadQuery(g_StatsSql, "@StatsQueryHandler", Query, iData, sizeof(iData));
}

@SqStatslSelect(taskID)
{
    new iPlayer = taskID - TASK_STATS;
    static szSteamId[35], iData[2], Query[1024];
    get_user_authid(iPlayer, szSteamId, charsmax(szSteamId));

    if(!is_valid_steamid(szSteamId))
        return;

    formatex(Query, charsmax(Query), "SELECT * FROM %s WHERE steamid = '%s'", g_StatsCvars[STATS_SQL_NAME_TABLE], szSteamId)

    iData[0] = SQL_DATA_YES;
    iData[1] = iPlayer;

    SQL_ThreadQuery(g_StatsSql, "@StatsQueryHandler", Query, iData, sizeof(iData));
}

@StatsSqlSetData(iPlayer)
{
    if(!is_user_connected(iPlayer))
        return;

    static szSteamId[35], szName[64], iData[1], Query[1024];
    get_user_authid(iPlayer, szSteamId, charsmax(szSteamId));
    get_user_info(iPlayer, "name", szName, charsmax(szName));

    if(!is_valid_steamid(szSteamId))
        return;

    if(StatsUpdate[iPlayer]){
        formatex(Query, charsmax(Query), "UPDATE %s SET `kills` = '%i', `kills_hs` = '%i', `damage` = '%i', `deaths` = '%i',\
        `shots` = '%i', `bomb_defused` = '%i', `bomb_planted` = '%i', `win_ct` = '%i', `win_tt` = '%i', `h_head` = '%i',\
        `h_chest` = '%i', `h_stomach` = '%i', `h_lhand` = '%i', `h_rhand` = '%i', `h_lleg` = '%i', `h_rleg` = '%i',\
        `timedate` = CURRENT_TIMESTAMP WHERE `steamid` = '%s'", g_StatsCvars[STATS_SQL_NAME_TABLE], g_GeneralStats[G_KILLS][iPlayer] + g_PlayerStats[KILLS][iPlayer], g_GeneralStats[G_KILLS_HS][iPlayer] + g_PlayerStats[KILLS_HS][iPlayer], 
        g_GeneralStats[G_DAMAGE][iPlayer] + g_PlayerStats[DAMAGE][iPlayer], g_GeneralStats[G_DEATHS][iPlayer] + g_PlayerStats[DEATHS][iPlayer],
        g_GeneralStats[G_SHOTS][iPlayer] + g_PlayerStats[SHOTS][iPlayer], g_GeneralStats[G_BOMB_DEFUSED][iPlayer] + g_PlayerStats[BOMB_DEFUSED][iPlayer],
        g_GeneralStats[G_BOMB_PLANTED][iPlayer] + g_PlayerStats[BOMB_PLANTED][iPlayer], g_GeneralStats[G_WIN_CT][iPlayer] + g_PlayerStats[WIN_CT][iPlayer], 
        g_GeneralStats[G_WIN_TT][iPlayer] + g_PlayerStats[WIN_TT][iPlayer], g_GeneralHits[G_HITS_HS][iPlayer] + g_HitsStats[HITS_HS][iPlayer], 
        g_GeneralHits[G_HITS_CHEST][iPlayer] + g_HitsStats[HITS_CHEST][iPlayer], g_GeneralHits[G_HITS_STOMACH][iPlayer] + g_HitsStats[HITS_STOMACH][iPlayer], 
        g_GeneralHits[G_HITS_RHAND][iPlayer] + g_HitsStats[HITS_RHAND][iPlayer], g_GeneralHits[G_HITS_LHAND][iPlayer] + g_HitsStats[HITS_LHAND][iPlayer],
        g_GeneralHits[G_HITS_LLEG][iPlayer] + g_HitsStats[HITS_LLEG][iPlayer], g_GeneralHits[G_HITS_RLEG][iPlayer] + g_HitsStats[HITS_RLEG][iPlayer], szSteamId)
    }else{
        formatex(Query, charsmax(Query), "INSERT IGNORE INTO `%s` (`nick`, `steamid`, `kills`, `kills_hs`, `damage`, `deaths`, `shots`, \
        `bomb_defused`, `bomb_planted`, `win_ct`, `win_tt`, `h_head`, `h_chest`, `h_stomach`, `h_lhand`, `h_rhand`, `h_lleg`, `h_rleg`, `timedate`)\
        VALUES('%s', '%s', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', '%d', CURRENT_TIMESTAMP)", g_StatsCvars[STATS_SQL_NAME_TABLE], szName, szSteamId, g_PlayerStats[KILLS][iPlayer] = 0, g_PlayerStats[KILLS_HS][iPlayer] = 0,
        g_PlayerStats[DAMAGE][iPlayer] = 0, g_PlayerStats[DEATHS][iPlayer] = 0, g_PlayerStats[SHOTS][iPlayer] = 0, g_PlayerStats[BOMB_DEFUSED][iPlayer] = 0,
        g_PlayerStats[BOMB_PLANTED][iPlayer] = 0, g_PlayerStats[WIN_CT][iPlayer] = 0, g_PlayerStats[WIN_TT][iPlayer] = 0, g_HitsStats[HITS_HS][iPlayer] = 0,
        g_HitsStats[HITS_CHEST][iPlayer] = 0, g_HitsStats[HITS_STOMACH][iPlayer] = 0, g_HitsStats[HITS_LHAND][iPlayer] = 0, g_HitsStats[HITS_RHAND][iPlayer] = 0,
        g_HitsStats[HITS_LLEG][iPlayer] = 0, g_HitsStats[HITS_RLEG][iPlayer] = 0);
        StatsUpdate[iPlayer] = true;
    }

    iData[0] = SQL_DATA_NO;

    SQL_ThreadQuery(g_StatsSql, "@StatsQueryHandler", Query, iData, sizeof(iData));
}

@SavePlantedStats(iPlayer)
{
    if(!is_user_connected(iPlayer))
        return;

    static szSteamId[35], iData[1], Query[1024];
    get_user_authid(iPlayer, szSteamId, charsmax(szSteamId));

    if(!is_valid_steamid(szSteamId))
        return;

    formatex(Query, charsmax(Query), "UPDATE %s SET `bomb_planted` = '%i' WHERE `steamid` = '%s'", g_StatsCvars[STATS_SQL_NAME_TABLE],
        g_GeneralStats[G_BOMB_PLANTED][iPlayer] + g_PlayerStats[BOMB_PLANTED][iPlayer], szSteamId);

    iData[0] = SQL_DATA_NO;

    SQL_ThreadQuery(g_StatsSql, "@StatsQueryHandler", Query, iData, sizeof(iData));
}

@SaveDefusedStats(iPlayer)
{
    if(!is_user_connected(iPlayer))
        return;

    static szSteamId[35], iData[1], Query[1024];
    get_user_authid(iPlayer, szSteamId, charsmax(szSteamId));

    if(!is_valid_steamid(szSteamId))
        return;

    formatex(Query, charsmax(Query), "UPDATE %s SET `bomb_defused` = '%i' WHERE `steamid` = '%s'", g_StatsCvars[STATS_SQL_NAME_TABLE],
        g_GeneralStats[G_BOMB_DEFUSED][iPlayer] + g_PlayerStats[BOMB_DEFUSED][iPlayer], szSteamId);

    iData[0] = SQL_DATA_NO;

    SQL_ThreadQuery(g_StatsSql, "@StatsQueryHandler", Query, iData, sizeof(iData));
}

@SaveKillsStats(iPlayer)
{
    if(!is_user_connected(iPlayer))
        return;

    static szSteamId[35], iData[1], Query[1024];
    get_user_authid(iPlayer, szSteamId, charsmax(szSteamId));

    if(!is_valid_steamid(szSteamId))
        return;

    formatex(Query, charsmax(Query), "UPDATE %s SET `kills` = '%i', `kills_hs` = '%i', `damage` = '%i', `deaths` = '%i',\
        `shots` = '%i', `h_head` = '%i', `h_chest` = '%i', `h_stomach` = '%i', `h_lhand` = '%i', `h_rhand` = '%i', `h_lleg` = '%i', `h_rleg` = '%i',\
        WHERE `steamid` = '%s'", g_StatsCvars[STATS_SQL_NAME_TABLE], g_GeneralStats[G_KILLS][iPlayer] + g_PlayerStats[KILLS][iPlayer], g_GeneralStats[G_KILLS_HS][iPlayer] + g_PlayerStats[KILLS_HS][iPlayer], 
        g_GeneralStats[G_DAMAGE][iPlayer] + g_PlayerStats[DAMAGE][iPlayer], g_GeneralStats[G_DEATHS][iPlayer] + g_PlayerStats[DEATHS][iPlayer],
        g_GeneralStats[G_SHOTS][iPlayer] + g_PlayerStats[SHOTS][iPlayer], g_GeneralHits[G_HITS_HS][iPlayer] + g_HitsStats[HITS_HS][iPlayer], 
        g_GeneralHits[G_HITS_CHEST][iPlayer] + g_HitsStats[HITS_CHEST][iPlayer], g_GeneralHits[G_HITS_STOMACH][iPlayer] + g_HitsStats[HITS_STOMACH][iPlayer], 
        g_GeneralHits[G_HITS_RHAND][iPlayer] + g_HitsStats[HITS_RHAND][iPlayer], g_GeneralHits[G_HITS_LHAND][iPlayer] + g_HitsStats[HITS_LHAND][iPlayer],
        g_GeneralHits[G_HITS_LLEG][iPlayer] + g_HitsStats[HITS_LLEG][iPlayer], g_GeneralHits[G_HITS_RLEG][iPlayer] + g_HitsStats[HITS_RLEG][iPlayer], szSteamId)

    iData[0] = SQL_DATA_NO;

    SQL_ThreadQuery(g_StatsSql, "@StatsQueryHandler", Query, iData, sizeof(iData));
}

@StatsQueryHandler(FailState, Handle:Query, error[], iErrNum, iData[], size, Float:QueryTime) 
{
    if(FailState != TQUERY_SUCCESS)
        log_amx("[Level System Stats MySQL]: %d (%s)", iErrNum, error)

    if(iData[0] == SQL_DATA_YES){
        new iPlayer;
        iPlayer = iData[1];

        if(!is_user_connected(iPlayer))
            return;

        if(SQL_NumResults(Query) < 1)
        {
            StatsUpdate[iPlayer] = false;
            @StatsSqlSetData(iPlayer);
        }else{
            new Kills = SQL_FieldNameToNum(Query, "kills"),
                KillsHS = SQL_FieldNameToNum(Query, "kills_hs"),
                Damage = SQL_FieldNameToNum(Query, "damage"),
                Deaths = SQL_FieldNameToNum(Query, "deaths"),
                Shots = SQL_FieldNameToNum(Query, "shots"),
                hHead = SQL_FieldNameToNum(Query, "h_head"),
                hChest = SQL_FieldNameToNum(Query, "h_chest"),
                hStomach = SQL_FieldNameToNum(Query, "h_stomach"),
                hLHand = SQL_FieldNameToNum(Query, "h_lhand"),
                hRHand = SQL_FieldNameToNum(Query, "h_rhand"),
                hLLeg = SQL_FieldNameToNum(Query, "h_lleg"),
                hRLeg = SQL_FieldNameToNum(Query, "h_rleg"),
                BombDefused = SQL_FieldNameToNum(Query, "bomb_defused"),
                BombPlanted = SQL_FieldNameToNum(Query, "bomb_planted"),
                WinCT = SQL_FieldNameToNum(Query, "win_ct"),
                WinTT = SQL_FieldNameToNum(Query, "win_tt");

            g_GeneralStats[G_KILLS][iPlayer] = SQL_ReadResult(Query, Kills);
            g_GeneralStats[G_KILLS_HS][iPlayer] = SQL_ReadResult(Query, KillsHS);
            g_GeneralStats[G_DAMAGE][iPlayer] = SQL_ReadResult(Query, Damage);
            g_GeneralStats[G_DEATHS][iPlayer] = SQL_ReadResult(Query, Deaths);
            g_GeneralStats[G_SHOTS][iPlayer] = SQL_ReadResult(Query, Shots);
            g_GeneralStats[G_DAMAGE][iPlayer] = SQL_ReadResult(Query, Damage);
            g_GeneralStats[G_BOMB_DEFUSED][iPlayer] = SQL_ReadResult(Query, BombDefused);
            g_GeneralStats[G_BOMB_PLANTED][iPlayer] = SQL_ReadResult(Query, BombPlanted);
            g_GeneralStats[G_WIN_CT][iPlayer] = SQL_ReadResult(Query, WinCT);
            g_GeneralStats[G_WIN_TT][iPlayer] = SQL_ReadResult(Query, WinTT);
            g_GeneralStats[G_BOMB_PLANTED][iPlayer] = SQL_ReadResult(Query, BombPlanted);
            g_GeneralHits[G_HITS_HS][iPlayer] = SQL_ReadResult(Query, hHead);
            g_GeneralHits[G_HITS_CHEST][iPlayer] = SQL_ReadResult(Query, hChest);
            g_GeneralHits[G_HITS_STOMACH][iPlayer] = SQL_ReadResult(Query, hStomach);
            g_GeneralHits[G_HITS_LHAND][iPlayer] = SQL_ReadResult(Query, hLHand);
            g_GeneralHits[G_HITS_RHAND][iPlayer] = SQL_ReadResult(Query, hRHand);
            g_GeneralHits[G_HITS_LLEG][iPlayer] = SQL_ReadResult(Query, hLLeg);
            g_GeneralHits[G_HITS_RLEG][iPlayer] = SQL_ReadResult(Query, hRLeg);
            StatsUpdate[iPlayer] = true;
        }

        remove_task(iPlayer + TASK_STATS);
    }

    SQL_FreeHandle(Query);
}

@StatsAutoClear(){
    if(g_StatsCvars[STATS_AUTOCLEAR_PLAYER] > 0){
        @StatsClear(g_StatsCvars[STATS_AUTOCLEAR_PLAYER]);
    }

    if(g_StatsCvars[STATS_AUTOCLEAR_DB] > 0){
        new TimeData[10];
        get_time("%d", TimeData, charsmax(TimeData));
            
        if(str_to_num(TimeData) == g_StatsCvars[STATS_AUTOCLEAR_DB]){
            TimeData[0] = 0;
            get_vaultdata("stats_reset", TimeData, charsmax(TimeData));
            if(!str_to_num(TimeData)){
                set_vaultdata("stats_reset", "1");
                @StatsClear(-1);
            }
        }else{
            set_vaultdata("stats_reset", "0");
        }
	}
}

@StatsClear(day)
{
    if(day == -1)
    {
        log_amx("[Level System Stats] Database reset");
    }
	
    new Query[1024], iData[1];

    if(day > 0){
        formatex(Query, charsmax(Query), "DELETE `%s` FROM `%s` WHERE `%s`.`timedate` <= DATE_SUB(NOW(),INTERVAL %d DAY);", day);
    }else{
        formatex(Query, charsmax(Query), "DELETE `%s` FROM `%s` WHERE 1");
    }
	
    iData[0] = SQL_DATA_NO;
	
    SQL_ThreadQuery(g_StatsSql, "@StatsQueryHandler", Query, iData, sizeof(iData));
}

@HC_RoundEnd(WinStatus:iStatus, ScenarioEventEndRound:iEvent, Float:flDelay)
{
    if(iStatus != WINSTATUS_CTS && iStatus != WINSTATUS_TERRORISTS)
        return;

    //new iPlayersNum = get_playersnum_ex(GetPlayers_ExcludeBots|GetPlayers_ExcludeHLTV);

    /*if(iPlayersNum < g_iMinPlayers)
        return;*/

    new iPlayers[MAX_PLAYERS], iPlayerCount, iPlayer;
    get_players_ex(iPlayers, iPlayerCount, GetPlayers_MatchTeam, iStatus == WINSTATUS_TERRORISTS ? "TERRORIST" : "CT");

    for(new i; i < iPlayerCount; i++)
    {
        iPlayer = iPlayers[i];

        if(iStatus == WINSTATUS_TERRORISTS){
            g_PlayerStats[WIN_TT][iPlayer]++;
        }else{
            g_PlayerStats[WIN_CT][iPlayer]++;
        }
    }
}

@HC_CSGameRules_PlayerKilled(const victim, const killer, const inflictor){
    if(!is_user_connected(victim) || killer == victim || !killer || ls_stop_level_system()){
        return;
    }

    if(get_member(victim, m_bHeadshotKilled)){
        g_PlayerStats[KILLS_HS][killer]++;
    }

    g_PlayerStats[KILLS][killer]++;
    g_PlayerStats[DEATHS][victim]++;

    @SaveKillsStats(victim);
}

@HC_PlantBomb(const index, Float:vecStart[3], Float:vecVelocity[3]){
    if(ls_stop_level_system()){
        return;
    }

    g_PlayerStats[BOMB_PLANTED][index]++;

    @SavePlantedStats(index);
}

@HC_CGrenade_DefuseBombEnd(const this, const player, bool:bDefused){
    if(ls_stop_level_system()){
        return;
    }

    if(bDefused){
        g_PlayerStats[BOMB_DEFUSED][player]++;
        @SaveDefusedStats(player);
    }
}

@HC_CBasePlayer_TraceAttack(const this, pevAttacker, Float:flDamage, Float:vecDir[3], tracehandle, bitsDamageType){
    if(pevAttacker == this || !pevAttacker || ls_stop_level_system()){
        return;
    }

    switch(get_member(this, m_LastHitGroup)){
        case HITGROUP_HEAD:{
            g_PlayerStats[HITS][pevAttacker]++;
            g_HitsStats[HITS_HS][pevAttacker]++;
        }
        case HITGROUP_CHEST:{
            g_PlayerStats[HITS][pevAttacker]++;
            g_HitsStats[HITS_CHEST][pevAttacker]++;
        }
        case HITGROUP_STOMACH:{
            g_PlayerStats[HITS][pevAttacker]++;
            g_HitsStats[HITS_STOMACH][pevAttacker]++;
        }
        case HITGROUP_LEFTARM:{
            g_PlayerStats[HITS][pevAttacker]++;
            g_HitsStats[HITS_LHAND][pevAttacker]++;
        }
        case HITGROUP_RIGHTARM:{
            g_PlayerStats[HITS][pevAttacker]++;
            g_HitsStats[HITS_RHAND][pevAttacker]++;
        }
        case HITGROUP_RIGHTLEG:{
            g_PlayerStats[HITS][pevAttacker]++;
            g_HitsStats[HITS_RLEG][pevAttacker]++;
        }
        case HITGROUP_LEFTLEG:{
            g_PlayerStats[HITS][pevAttacker]++;
            g_HitsStats[HITS_LLEG][pevAttacker]++;
        }
    }

    g_PlayerStats[DAMAGE][pevAttacker] += floatround(flDamage, floatround_floor);
}

@Hook_EventPlayBack(flags, const pInvoker, eventindex){
	if(!(g_iGunsEventsIdBitSum & (1 << eventindex)) || !(1 <= pInvoker <= MaxClients))
		return FMRES_IGNORED
	
	g_PlayerStats[SHOTS][pInvoker]++;
		
	return FMRES_HANDLED;
}

@DBReset(){
	@StatsClear(-1);
}

@LoadStatsCvars(){
    bind_pcvar_string(create_cvar(
        "stats_db_host",
        "localhost",
        FCVAR_PROTECTED,
        "database address"),
        g_StatsCvars[STATS_SQL_IP], charsmax(g_StatsCvars[STATS_SQL_IP])
    );
    bind_pcvar_string(create_cvar(
        "stats_db_user",
        "root",
        FCVAR_PROTECTED,
        "Database User"),
        g_StatsCvars[STATS_SQL_USER], charsmax(g_StatsCvars[STATS_SQL_USER])
    );
    bind_pcvar_string(create_cvar(
        "stats_db_password",
        "",
        FCVAR_PROTECTED,
        "Database Password"),
        g_StatsCvars[STATS_SQL_PASS], charsmax(g_StatsCvars[STATS_SQL_PASS])
    );
    bind_pcvar_string(create_cvar(
        "stats_db",
        "",
        FCVAR_PROTECTED,
        "Database"),
        g_StatsCvars[STATS_SQL_DB], charsmax(g_StatsCvars[STATS_SQL_DB])
    );
    bind_pcvar_string(create_cvar(
        "stats_name_table",
        "",
        FCVAR_PROTECTED,
        "Table name"),
        g_StatsCvars[STATS_SQL_NAME_TABLE], charsmax(g_StatsCvars[STATS_SQL_NAME_TABLE])
    );
    bind_pcvar_num(create_cvar(
        "stats_clear_db_player",
        "7",
        FCVAR_NONE,
        "After how many days to delete inactive players from the database"),
        g_StatsCvars[STATS_AUTOCLEAR_PLAYER]
    );
    bind_pcvar_num(create_cvar(
        "stats_clear_db",
        "30",
        FCVAR_NONE,
        "After how many days to clear the database"),
        g_StatsCvars[STATS_AUTOCLEAR_DB]
    );
    AutoExecConfig(true, "level_system_stats");
}

stock bool:is_valid_steamid(const szSteamId[])
{
    if(contain(szSteamId, "ID_LAN") != -1 || contain(szSteamId, "BOT") != -1 || contain(szSteamId, "HLTV") != -1)
        return false

    return true
}
