#include <amxmodx>
#include <amxmisc>
#include <sqlx>
#include <reapi>
#include <fakemeta>
#include <level_system>

#define TASK_STATS 328869

#define PlayersInGame (get_member_game(m_iNumTerrorist) + get_member_game(m_iNumCT))

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
    G_WIN_TT,
    G_SKILL
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

enum GeneralHits{
    G_HITS_HS,
    G_HITS_CHEST,
    G_HITS_STOMACH,
    G_HITS_LHAND,
    G_HITS_RHAND,
    G_HITS_LLEG,
    G_HITS_RLEG
}

enum StatsCvars{
    STATS_SQL_NAME_TABLE[64],
    STATS_AUTOCLEAR_PLAYER,
    STATS_AUTOCLEAR_DB,
    STATS_MIN_PLAYER,
    STATS_SAVE
}

enum Informer{
    KILLER,
    Float:DISTANCE,
    Float:HP,
    Float:ARMOR,
    DMG
}

new g_PlayerStats[MAX_PLAYERS + 1][PlayerStats], g_GeneralStats[MAX_PLAYERS + 1][GeneralStats], g_HitsStats[MAX_PLAYERS + 1][Hits], g_GeneralHits[MAX_PLAYERS + 1][GeneralHits], g_Informer[MAX_PLAYERS + 1][Informer];
new g_StatsCvars[StatsCvars];
new StatsUpdate[MAX_PLAYERS + 1];
new g_VictimDistance[3], g_KillerDistance[3];

new g_iGunsEventsIdBitSum;

new TableLS[64];

new Handle:g_StatsSql;

public plugin_init(){
    register_plugin("[Level System] Stats", "1.0.4 Alpha", "BiZaJe");

    register_dictionary("level_system_stats.txt");

    register_clcmd("say /me", "@SayMe");
    register_clcmd("say_team /me", "@SayMe");
    register_clcmd("say /hp", "@SayHP");
    register_clcmd("say_team /hp", "@SayHP");

    new const GunEvent[][] = {
        "events/awp.sc", "events/g3sg1.sc", "events/ak47.sc", "events/scout.sc", "events/m249.sc",
        "events/m4a1.sc", "events/sg552.sc", "events/aug.sc", "events/sg550.sc", "events/m3.sc",
        "events/xm1014.sc", "events/usp.sc", "events/mac10.sc", "events/ump45.sc", "events/fiveseven.sc",
        "events/p90.sc", "events/deagle.sc", "events/p228.sc", "events/glock18.sc", "events/mp5n.sc",
        "events/tmp.sc", "events/elite_left.sc", "events/elite_right.sc", "events/galil.sc", "events/famas.sc"
    };

    register_srvcmd("lss_reset", "@StatsReset");

    RegisterHookChain(RG_RoundEnd, "@HC_RoundEnd", .post = true);
    RegisterHookChain(RG_CSGameRules_PlayerKilled, "@HC_CSGameRules_PlayerKilled", .post = true);
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
    @StatsAutoClear();
}

public client_putinserver(iPlayer){
    set_task(5.0, "@SqStatslSelect", iPlayer + TASK_STATS, .flags = "b");
}

public client_disconnected(iPlayer){
    if(g_StatsCvars[STATS_SAVE] == -1 || g_StatsCvars[STATS_SAVE] == 2){
        @StatsSqlSetData(iPlayer);
    }
    @ZeroStats(iPlayer);
    remove_task(iPlayer + TASK_STATS);
}

public ls_init_sql(Handle:SqlTuple, Handle:SqlConnect){
    new Query[1024], iData[1];

    g_StatsSql = SqlTuple;

    get_cvar_string("ls_table_name", TableLS, charsmax(TableLS));

    formatex(Query, charsmax(Query), "\
        CREATE TABLE IF NOT EXISTS `%s` (\
            `id` INT(10) NOT NULL AUTO_INCREMENT,\
            `player_id` INT(10) NOT NULL DEFAULT '0',\
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
            `skill` DECIMAL(3,1) NOT NULL DEFAULT 0,\
            `timedate` TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00',\
            PRIMARY KEY (`id`),\
            INDEX `pl_id` (`player_id`),\
	        CONSTRAINT `pl_id` FOREIGN KEY (`player_id`) REFERENCES %s(`id`)\
            );", g_StatsCvars[STATS_SQL_NAME_TABLE], TableLS);

    iData[0] = SQL_DATA_NO;

    SQL_ThreadQuery(g_StatsSql, "@StatsQueryHandler", Query, iData, sizeof(iData));
}

@SqStatslSelect(taskID)
{
    new iPlayer = taskID - TASK_STATS;
    static szSteamId[MAX_AUTHID_LENGTH], iData[2], Query[1024];
    get_user_authid(iPlayer, szSteamId, MAX_AUTHID_LENGTH - 1);

    if(!is_valid_steamid(szSteamId))
        return;

    formatex(Query, charsmax(Query), "SELECT * FROM %s WHERE `player_id` = (SELECT `id` FROM `%s` WHERE `steamid` = '%s')", g_StatsCvars[STATS_SQL_NAME_TABLE], TableLS, szSteamId);

    iData[0] = SQL_DATA_YES;
    iData[1] = iPlayer;

    SQL_ThreadQuery(g_StatsSql, "@StatsQueryHandler", Query, iData, sizeof(iData));
}

@StatsSqlSetData(iPlayer)
{
    if(!is_user_connected(iPlayer))
        return;

    get_cvar_string("ls_table_name", TableLS, charsmax(TableLS));

    static szSteamId[MAX_AUTHID_LENGTH], iData[1], Query[1024];
    get_user_authid(iPlayer, szSteamId, MAX_AUTHID_LENGTH - 1);

    if(!is_valid_steamid(szSteamId))
        return;

    if(StatsUpdate[iPlayer]){
        formatex(Query, charsmax(Query), "UPDATE %s SET `kills` = '%i', `kills_hs` = '%i', `damage` = '%i', `deaths` = '%i',\
        `shots` = '%i', `bomb_defused` = '%i', `bomb_planted` = '%i', `win_ct` = '%i', `win_tt` = '%i', `h_head` = '%i',\
        `h_chest` = '%i', `h_stomach` = '%i', `h_lhand` = '%i', `h_rhand` = '%i', `h_lleg` = '%i', `h_rleg` = '%i',\
        `skill` = '%.f', `timedate` = CURRENT_TIMESTAMP WHERE `player_id` = (SELECT `id` FROM `%s` WHERE `steamid` = '%s')", g_StatsCvars[STATS_SQL_NAME_TABLE], g_GeneralStats[iPlayer][G_KILLS] + g_PlayerStats[iPlayer][KILLS], g_GeneralStats[iPlayer][G_KILLS_HS] + g_PlayerStats[iPlayer][KILLS_HS], 
        g_GeneralStats[iPlayer][G_DAMAGE] + g_PlayerStats[iPlayer][DAMAGE], g_GeneralStats[iPlayer][G_DEATHS] + g_PlayerStats[iPlayer][DEATHS],
        g_GeneralStats[iPlayer][G_SHOTS] + g_PlayerStats[iPlayer][SHOTS], g_GeneralStats[iPlayer][G_BOMB_DEFUSED] + g_PlayerStats[iPlayer][BOMB_DEFUSED],
        g_GeneralStats[iPlayer][G_BOMB_PLANTED] + g_PlayerStats[iPlayer][BOMB_PLANTED], g_GeneralStats[iPlayer][G_WIN_CT] + g_PlayerStats[iPlayer][WIN_CT], 
        g_GeneralStats[iPlayer][G_WIN_TT] + g_PlayerStats[iPlayer][WIN_TT], g_GeneralHits[iPlayer][G_HITS_HS] + g_HitsStats[iPlayer][HITS_HS], 
        g_GeneralHits[iPlayer][G_HITS_CHEST] + g_HitsStats[iPlayer][HITS_CHEST], g_GeneralHits[iPlayer][G_HITS_STOMACH] + g_HitsStats[iPlayer][HITS_STOMACH], 
        g_GeneralHits[iPlayer][G_HITS_RHAND] + g_HitsStats[iPlayer][HITS_RHAND], g_GeneralHits[iPlayer][G_HITS_LHAND] + g_HitsStats[iPlayer][HITS_LHAND],
        g_GeneralHits[iPlayer][G_HITS_LLEG] + g_HitsStats[iPlayer][HITS_LLEG], g_GeneralHits[iPlayer][G_HITS_RLEG] + g_HitsStats[iPlayer][HITS_RLEG], g_GeneralStats[iPlayer][G_SKILL], TableLS, szSteamId)
    }else{
        formatex(Query, charsmax(Query), "INSERT IGNORE INTO `%s` (`player_id`, `timedate`) VALUES((SELECT `id` FROM `%s` WHERE `steamid` = '%s'), CURRENT_TIMESTAMP)", g_StatsCvars[STATS_SQL_NAME_TABLE], TableLS, szSteamId);
        StatsUpdate[iPlayer] = true;
    }

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
            g_GeneralStats[iPlayer][G_KILLS] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "kills"));
            g_GeneralStats[iPlayer][G_KILLS_HS] = SQL_ReadResult(Query,SQL_FieldNameToNum(Query, "kills_hs"));
            g_GeneralStats[iPlayer][G_DAMAGE] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "damage"));
            g_GeneralStats[iPlayer][G_DEATHS] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "deaths"));
            g_GeneralStats[iPlayer][G_SHOTS] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "shots"));
            g_GeneralStats[iPlayer][G_BOMB_DEFUSED] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "bomb_defused"));
            g_GeneralStats[iPlayer][G_BOMB_PLANTED] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "bomb_planted"));
            g_GeneralStats[iPlayer][G_WIN_CT] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "win_ct"));
            g_GeneralStats[iPlayer][G_WIN_TT] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "win_tt"));
            g_GeneralHits[iPlayer][G_HITS_HS] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "h_head"));
            g_GeneralHits[iPlayer][G_HITS_CHEST] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "h_chest"));
            g_GeneralHits[iPlayer][G_HITS_STOMACH] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "h_stomach"));
            g_GeneralHits[iPlayer][G_HITS_LHAND] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "h_lhand"));
            g_GeneralHits[iPlayer][G_HITS_RHAND] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "h_rhand"));
            g_GeneralHits[iPlayer][G_HITS_LLEG] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "h_lleg"));
            g_GeneralHits[iPlayer][G_HITS_RLEG] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "h_rleg"));
            g_GeneralStats[iPlayer][G_SKILL] = SQL_ReadResult(Query, SQL_FieldNameToNum(Query, "skill"));
            StatsUpdate[iPlayer] = true;
        }

        remove_task(iPlayer + TASK_STATS);
    }

    SQL_FreeHandle(Query);
}

@StatsAutoClear(){
    if(g_StatsCvars[STATS_AUTOCLEAR_PLAYER] > 0){
        new UnixTime;
        UnixTime = get_systime() - (g_StatsCvars[STATS_AUTOCLEAR_PLAYER] * 24 * 3600);

        @StatsClear(UnixTime);
    }

    if(g_StatsCvars[STATS_AUTOCLEAR_DB] > 0){
        new TimeData[10];
        get_time("%j", TimeData, charsmax(TimeData));
            
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
        formatex(Query, charsmax(Query), "DELETE FROM `%s` WHERE `timedate` <=  %i", g_StatsCvars[STATS_SQL_NAME_TABLE], day);
    }else{
        formatex(Query, charsmax(Query), "DELETE FROM `%s` WHERE 1", g_StatsCvars[STATS_SQL_NAME_TABLE]);
    }
	
    iData[0] = SQL_DATA_NO;
	
    SQL_ThreadQuery(g_StatsSql, "@StatsQueryHandler", Query, iData, sizeof(iData));
}

@ZeroStats(iPlayer){
    g_PlayerStats[iPlayer][DAMAGE] = 0;
    g_HitsStats[iPlayer][HITS_HS] = 0;
    g_HitsStats[iPlayer][HITS_CHEST] = 0;
    g_HitsStats[iPlayer][HITS_STOMACH] = 0;
    g_HitsStats[iPlayer][HITS_RHAND] = 0;
    g_HitsStats[iPlayer][HITS_LHAND] = 0;
    g_HitsStats[iPlayer][HITS_RLEG] = 0;
    g_HitsStats[iPlayer][HITS_LLEG] = 0;
    g_Informer[iPlayer][DMG] = 0;
}

@HC_RoundEnd(WinStatus:iStatus, ScenarioEventEndRound:iEvent, Float:flDelay)
{
    if(iStatus != WINSTATUS_CTS && iStatus != WINSTATUS_TERRORISTS)
        return;

    if(PlayersInGame < g_StatsCvars[STATS_MIN_PLAYER])
        return;

    new iPlayers[MAX_PLAYERS], iPlayerCount, iPlayer;
    get_players_ex(iPlayers, iPlayerCount, GetPlayers_MatchTeam, iStatus == WINSTATUS_TERRORISTS ? "TERRORIST" : "CT");

    for(new i; i < iPlayerCount; i++)
    {
        iPlayer = iPlayers[i];

        if(iStatus == WINSTATUS_TERRORISTS){
            g_PlayerStats[iPlayer][WIN_TT]++;
        }else{
            g_PlayerStats[iPlayer][WIN_CT]++;
        }

        if(g_StatsCvars[STATS_SAVE] == 0){
            @StatsSqlSetData(i);
        }
    }
}

@HC_CSGameRules_PlayerKilled(const victim, const killer, const inflictor){
    if(!is_user_connected(victim) || killer == victim || !killer || ls_stop_level_system() || PlayersInGame < g_StatsCvars[STATS_MIN_PLAYER]){
        return;
    }

    get_user_origin(victim, g_VictimDistance);
    get_user_origin(killer, g_KillerDistance);

    g_Informer[victim][HP] = get_entvar(killer, var_health);
    g_Informer[victim][ARMOR] = get_entvar(killer, var_armorvalue);
    g_Informer[victim][DISTANCE] = get_distance(g_KillerDistance, g_VictimDistance) * 0.0254;
    g_Informer[victim][KILLER] = killer;

    if(get_member(victim, m_bHeadshotKilled)){
        g_PlayerStats[killer][KILLS_HS]++;
    }

    new Float:Delta = 1.0/(1.0 + floatpower(10.0, (g_GeneralStats[killer][G_KILLS] - g_GeneralStats[victim][G_KILLS])/100.0));
    new Float:KillerRation = (g_GeneralStats[killer][G_KILLS] < 100) ? 2.0 : 1.5
    new Float:VictimRation = (g_GeneralStats[victim][G_KILLS] < 100) ? 2.0 : 1.5
				
    g_GeneralStats[killer][G_SKILL] += (KillerRation*Delta);
    g_GeneralStats[victim][G_SKILL] -= (VictimRation*Delta);

    g_PlayerStats[killer][KILLS]++;
    g_PlayerStats[victim][DEATHS]++;

    if(g_StatsCvars[STATS_SAVE] == 1 || g_StatsCvars[STATS_SAVE] == 2){
        @StatsSqlSetData(victim);
    }

    if(g_Informer[victim][KILLER] != 0 && !get_member(victim, m_bKilledByBomb)){
        @SayHP(victim);
    }
    @SayMe(victim);
}

@HC_PlantBomb(const index, Float:vecStart[3], Float:vecVelocity[3]){
    if(ls_stop_level_system()){
        return;
    }

    g_PlayerStats[index][BOMB_PLANTED]++;
}

@HC_CGrenade_DefuseBombEnd(const this, const player, bool:bDefused){
    if(ls_stop_level_system() || PlayersInGame < g_StatsCvars[STATS_MIN_PLAYER]){
        return;
    }

    if(bDefused){
        g_PlayerStats[player][BOMB_DEFUSED]++;
    }
}

@HC_CBasePlayer_TraceAttack(const this, pevAttacker, Float:flDamage, Float:vecDir[3], tracehandle, bitsDamageType){
    if(pevAttacker == this || !pevAttacker || ls_stop_level_system() || PlayersInGame < g_StatsCvars[STATS_MIN_PLAYER]){
        return;
    }

    switch(get_member(this, m_LastHitGroup)){
        case HITGROUP_HEAD:{
            g_PlayerStats[pevAttacker][HITS]++;
            g_HitsStats[pevAttacker][HITS_HS]++;
        }
        case HITGROUP_CHEST:{
            g_PlayerStats[pevAttacker][HITS]++;
            g_HitsStats[pevAttacker][HITS_CHEST]++;
        }
        case HITGROUP_STOMACH:{
            g_PlayerStats[pevAttacker][HITS]++;
            g_HitsStats[pevAttacker][HITS_STOMACH]++;
        }
        case HITGROUP_LEFTARM:{
            g_PlayerStats[pevAttacker][HITS]++;
            g_HitsStats[pevAttacker][HITS_LHAND]++;
        }
        case HITGROUP_RIGHTARM:{
            g_PlayerStats[pevAttacker][HITS]++;
            g_HitsStats[pevAttacker][HITS_RHAND]++;
        }
        case HITGROUP_RIGHTLEG:{
            g_PlayerStats[pevAttacker][HITS]++;
            g_HitsStats[pevAttacker][HITS_RLEG]++;
        }
        case HITGROUP_LEFTLEG:{
            g_PlayerStats[pevAttacker][HITS]++;
            g_HitsStats[pevAttacker][HITS_LLEG]++;
        }
    }

    g_PlayerStats[pevAttacker][DAMAGE] += floatround(flDamage, floatround_floor);
    g_Informer[pevAttacker][DMG] = g_PlayerStats[pevAttacker][DAMAGE];
}

@Hook_EventPlayBack(flags, const pInvoker, eventindex){
	if(!(g_iGunsEventsIdBitSum & (1 << eventindex)) || !(1 <= pInvoker <= MaxClients) || PlayersInGame < g_StatsCvars[STATS_MIN_PLAYER])
		return FMRES_IGNORED
	
	g_PlayerStats[pInvoker][SHOTS]++;
		
	return FMRES_HANDLED;
}

@StatsReset(){
	@StatsClear(-1);
}

@SayMe(iVictim){
    if(is_user_alive(iVictim))
    {
        client_print_color(iVictim, print_team_default, "%L", iVictim, "STATS_ALIVE"); 
        return PLUGIN_HANDLED;                 
    }    

    switch(g_Informer[iVictim][DMG])
    {
        case 0:{
            client_print_color(iVictim, print_team_default, "%L", iVictim, "STATS_NO_DAMAGE");
        }
        default:{
            client_print_color(iVictim, print_team_default, "%L", iVictim, "STATS_DAMAGE", g_Informer[iVictim][DMG]);
        }
    }    

    g_Informer[iVictim][DMG] = 0
    return PLUGIN_HANDLED;    
}

@SayHP(iVictim){
    switch(g_Informer[iVictim][KILLER])
    {
        case 0:{
            client_print_color(iVictim, print_team_default, "%L", iVictim, "STATS_NO_KILLER");     
        }
        default:{
            client_print_color(iVictim, print_team_default, "%L", iVictim, "STATS_KILLER", g_Informer[iVictim][KILLER], g_Informer[iVictim][DISTANCE], g_Informer[iVictim][HP], g_Informer[iVictim][ARMOR]);
        }
    }
    return PLUGIN_HANDLED;
}

@LoadStatsCvars(){
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
    bind_pcvar_num(create_cvar(
        "stats_min_players",
        "5",
        FCVAR_NONE,
        "Minimum number of players to account for statistics"),
        g_StatsCvars[STATS_MIN_PLAYER]
    );
    bind_pcvar_num(create_cvar(
        "stats_save",
        "-1",
        FCVAR_NONE,
        "Method of saving statistics^n\
        -1 - When disconnecting^n\
        0 - At the end of the round^n\
        1 - At the death of the player^n\
        2 - Upon death and disconnection of the player"),
        g_StatsCvars[STATS_MIN_PLAYER]
    );
    AutoExecConfig(true, "level_system_stats");
}

stock bool:is_valid_steamid(const szSteamId[])
{
    if(contain(szSteamId, "ID_LAN") != -1 || contain(szSteamId, "BOT") != -1 || contain(szSteamId, "HLTV") != -1)
        return false

    return true
}
