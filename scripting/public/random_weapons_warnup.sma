#include <amxmodx>
#include <reapi>
#include <level_system>

/*■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/
#define TIME_RR 	40	// Время разминки
#define NUM_RR		2	// Кол-во рестартов
#define LATENCY		1.5	// Задержка между рестартами
#define DM_MODE		1	// Возрождение после смерти; 0 - отключить (будет длится раунд или до победы)
#define PROTECTED 	2	// Сколько секунд действует защита после возрождения (актуально для DM_MODE); 0 - отключить

#define SOUND			// Музыка под час разминки
#define STOP_PLUGS		// Отключать плагины на время разминки
#define OFF_RR			// Отключать этот плагин на указанных картах
//#define REMOVE_MAP_WPN    // Удалять ентити мешающие разминке на картах типа: awp_, 35hp_ и т.п. [по умолчанию выкл.]
//#define BLOCK           // Запрет поднятия оружия с земли (не актуально при вкл. #define REMOVE_MAP_WPN) [по умолчанию выкл.]
//#define STOP_STATS		// Отключать запись статистики на время разминки  CSStatsX SQL by serfreeman1337 0.7.4+1 [по умолчанию выкл.]
#define STOP_LEVEL_SYSTEM // Отключает запись статистики на рвемя разминки Level System by BiZaJe
/*■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■*/

#if defined REMOVE_MAP_WPN
#include <hamsandwich>
#endif

#if defined SOUND
new const soundRR[][] =	// Указывать звук, например 1.mp3
{	
	"sound/rww/RoundStart.mp3",
//	"sound/rww/2.mp3",
//	"sound/rww/3.mp3"
}
#endif

#if defined STOP_PLUGS
new g_arPlugins[][] = // Указывать название плагинов для отключения, например test.amxx
{		
	"test.amxx",
	"test2.amxx"
}
#endif

#if DM_MODE == 0
new HookChain:fwd_RRound;
new g_iRound;
#endif

#if defined REMOVE_MAP_WPN
new HamHook:fwd_Equip,
	HamHook:fwd_WpnStrip,
	HamHook:fwd_Entity;
#endif

#if defined STOP_STATS
new g_iHudSync;
#endif

#if defined STOP_LEVEL_SYSTEM
new g_iHudSyncLevel;
#endif

new g_szWeapon[32];
new g_iImmunuty, g_iRespawn, g_iWp, g_iHudSync2;
new HookChain:fwd_NewRound,
	#if defined BLOCK
	HookChain:fwd_BlockEntity,
	#endif
	HookChain:fwd_Spawn,
	HookChain:fwd_GiveC4;

const TASK_TIMER_ID = 33264;

public plugin_init()
{
	register_plugin("[ReAPI] Random Weapons WarmUP", "2.4.9", "neugomon/h1k3");

	RegisterHookChain(RG_RoundEnd, "fwdRoundEnd", true);
	DisableHookChain(fwd_NewRound = RegisterHookChain(RG_CSGameRules_CheckMapConditions, "fwdRoundStart", true));
	DisableHookChain(fwd_Spawn = RegisterHookChain(RG_CBasePlayer_Spawn, "fwdPlayerSpawnPost", true));
	DisableHookChain(fwd_GiveC4 = RegisterHookChain(RG_CSGameRules_GiveC4, "fwdGiveC4", false));

	#if defined REMOVE_MAP_WPN
	DisableHamForward(fwd_Equip = RegisterHam(Ham_Use, "game_player_equip", "CGamePlayerEquip_Use", false));
	DisableHamForward(fwd_WpnStrip = RegisterHam(Ham_Use, "player_weaponstrip", "CStripWeapons_Use", false));
	DisableHamForward(fwd_Entity = RegisterHam(Ham_CS_Restart, "armoury_entity", "CArmoury_Restart", false));
	#endif

	#if DM_MODE == 0
	EnableHookChain(fwd_RRound = RegisterHookChain(RG_CSGameRules_RestartRound, "fwdRestartRound_Pre"));
	#endif

	#if defined BLOCK
	DisableHookChain(fwd_BlockEntity = RegisterHookChain(RG_CBasePlayer_HasRestrictItem, "fwdHasRestrictItemPre", false));
	register_clcmd("drop", "ClCmd_Drop");
	#endif

	g_iImmunuty = get_cvar_pointer("mp_respawn_immunitytime");
	g_iRespawn  = get_cvar_pointer("mp_forcerespawn");
	#if defined STOP_STATS
	g_iHudSync = CreateHudSyncObj();
	#endif

	#if defined STOP_LEVEL_SYSTEM
	g_iHudSyncLevel = CreateHudSyncObj();
	#endif

	g_iHudSync2 = CreateHudSyncObj();

	state warmupOff;

	#if defined OFF_RR
	new sPref[][] = { "awp_", "aim_", "fy_", "$", "cs_", "35hp" };	// Указывать префиксы карт на которых плагин не будет работать
	new map[32]; get_mapname(map, charsmax(map));
	for(new i; i < sizeof sPref; i++)
	{
		if(containi(map, sPref[i]) != -1)
		{
			pause("ad");
			return;
		}
	}	
	#endif
}

public plugin_end() <warmupOff> {}

public plugin_end() <warmupOn> 
{
	finishWurmUp();
}

#if defined BLOCK
public fwdHasRestrictItemPre()
{
	SetHookChainReturn(ATYPE_INTEGER, true);
	return HC_SUPERCEDE;
}

public ClCmd_Drop() <warmupOff>
	return PLUGIN_CONTINUE;
    
public ClCmd_Drop() <warmupOn>
	return PLUGIN_HANDLED;
#endif


#if defined SOUND
public plugin_precache() 
{
	for(new i = 0; i < sizeof(soundRR); i++) 
	{
		precache_generic(soundRR[i]);
	}
}
#endif

public fwdRoundEnd(WinStatus:status, ScenarioEventEndRound:event, Float:tmDelay)
	if(event == ROUND_GAME_COMMENCE)
		EnableHookChain(fwd_NewRound);

public fwdRoundStart()
{
	state warmupOn;

	#if defined REMOVE_MAP_WPN
	EnableHamForward(fwd_Equip);
	EnableHamForward(fwd_WpnStrip);
	EnableHamForward(fwd_Entity);
	#endif

	DisableHookChain(fwd_NewRound);
	EnableHookChain(fwd_Spawn);
	EnableHookChain(fwd_GiveC4);

	set_pcvar_num(g_iRespawn, DM_MODE);
	set_pcvar_num(g_iImmunuty, PROTECTED);

	#if DM_MODE >= 1
	set_cvar_string("mp_round_infinite", "1");
	set_task(1.0, "Show_Timer", .flags = "a", .repeat = TIME_RR);
	#endif

	#if DM_MODE == 0
	set_task(1.0, "Hud_Message", .flags = "a", .repeat = 25 );
	#endif

	#if defined SOUND
	static cmd[64];
	formatex(cmd, 63, "mp3 play ^"%s^"", soundRR[random(sizeof(soundRR))]);
	client_cmd(0, "%s", cmd);
	#endif

	#if defined STOP_STATS
	set_cvar_num("csstats_pause", 1);
	#endif

	#if defined STOP_LEVEL_SYSTEM
	set_cvar_num("ls_stop", 1);
	#endif

	#if defined BLOCK
	EnableHookChain(fwd_BlockEntity);
	#endif

	#if defined STOP_PLUGS	
	PluginController(1);
	#endif

	switch(g_iWp = random(8))
	{
		case 0: formatex(g_szWeapon, charsmax(g_szWeapon), "M4A1");
		case 1: formatex(g_szWeapon, charsmax(g_szWeapon), "AK-47");
		case 2: formatex(g_szWeapon, charsmax(g_szWeapon), "МP5");
		case 3: formatex(g_szWeapon, charsmax(g_szWeapon), "SG-550");
		case 4: formatex(g_szWeapon, charsmax(g_szWeapon), "Famas");
		case 5: formatex(g_szWeapon, charsmax(g_szWeapon), "SCOUT");
		case 6: formatex(g_szWeapon, charsmax(g_szWeapon), "XM1014");
		case 7: formatex(g_szWeapon, charsmax(g_szWeapon), "M3");
	}
}

public fwdPlayerSpawnPost(const id)
{
	if(!is_user_alive(id))
		return;

	#if defined REMOVE_MAP_WPN
	InvisibilityArmourys();
	#endif

	BuyZone_ToogleSolid(SOLID_NOT);
	rg_remove_all_items(id);
	set_member_game(m_bMapHasBuyZone, true);
	rg_give_item(id, "weapon_knife");

	switch(g_iWp)
	{
		case 0:
		{
			rg_give_item(id, "weapon_m4a1");
			rg_set_user_bpammo(id, WEAPON_M4A1, 90);
		}
		case 1:
		{
			rg_give_item(id, "weapon_ak47");
			rg_set_user_bpammo(id, WEAPON_AK47, 90);
		}
		case 2:
		{
			rg_give_item(id, "weapon_mp5navy");
			rg_set_user_bpammo(id, WEAPON_MP5N, 120);
		}
		case 3:
		{
			rg_give_item(id, "weapon_sg550");
			rg_set_user_bpammo(id, WEAPON_SG550, 90);
		}
		case 4:
		{
			rg_give_item(id, "weapon_famas");
			rg_set_user_bpammo(id, WEAPON_FAMAS, 90);
		}
		case 5:
		{
			rg_give_item(id, "weapon_scout");
			rg_set_user_bpammo(id, WEAPON_SCOUT, 30);	
		}
		case 6:
		{
			rg_give_item(id, "weapon_xm1014");
			rg_set_user_bpammo(id, WEAPON_XM1014, 50);
		}
		case 7:
		{
			rg_give_item(id, "weapon_m3");
			rg_set_user_bpammo(id, WEAPON_M3, 50);
		}		
	}	
}

public fwdGiveC4()
{
	return HC_SUPERCEDE;
}

#if DM_MODE >= 1
public Show_Timer()
{	
	static timer = -1; 
	if(timer == -1) timer = TIME_RR;

	switch(--timer)
	{
		case 0: 
		{
			finishWurmUp();
			timer = -1;
		}
		default:
		{
			#if defined STOP_STATS
			set_hudmessage(255, 0, 0, .x = -1.0, .y = 0.05, .holdtime = 0.9, .channel = -1);
			ShowSyncHudMsg(0, g_iHudSync, "[Статистика Отключена]");
			#endif

			#if defined STOP_LEVEL_SYSTEM
			set_hudmessage(255, 0, 0, .x = -1.0, .y = 0.6, .holdtime = 0.9, .channel = -1);
			ShowSyncHudMsg(0, g_iHudSyncLevel, "[Система уровней отключена]");
			#endif

			set_hudmessage(135, 206, 235, .x = -1.0, .y = 0.08, .holdtime = 0.9, .channel = -1);
			ShowSyncHudMsg(0, g_iHudSync2, "Разминка на %s!^nРестарт через %d сек", g_szWeapon, timer);
		}
	}
}
#endif

#if DM_MODE == 0
public fwdRestartRound_Pre()
{
	g_iRound++;

	if(g_iRound >= 2) {
		DisableHookChain(fwd_RRound);
		finishWurmUp();
	}
}

public Hud_Message()
{
	#if defined STOP_STATS
	set_hudmessage(255, 0, 0, .x = -1.0, .y = 0.05, .holdtime = 0.9, .channel = -1);
	ShowSyncHudMsg(0, g_iHudSync, "[Система уровней отключена]");
	#endif

	#if defined STOP_LEVEL_SYSTEM
	set_hudmessage(255, 0, 0, .x = -1.0, .y = 0.6, .holdtime = 0.9, .channel = -1);
	ShowSyncHudMsg(0, g_iHudSyncLevel, "[Статистика Отключена]");
	#endif

	set_hudmessage(135, 206, 235, .x = -1.0, .y = 0.08, .holdtime = 0.9, .channel = -1);
	ShowSyncHudMsg(0, g_iHudSync2, "Разминка на %s!", g_szWeapon);
}
#endif

public SV_Restart()
{
	set_cvar_num("sv_restart", 1);
	set_task(2.0, "End_RR");
}

public End_RR()
{
	#if defined STOP_STATS
	set_hudmessage(255, 0, 0, .x = -1.0, .y = 0.05, .holdtime = 5.0, .channel = -1);
	ShowSyncHudMsg(0, g_iHudSync, "[Статистика Включена]");
	#endif

	#if defined STOP_LEVEL_SYSTEM
	set_hudmessage(255, 0, 0, .x = -1.0, .y = 0.6, .holdtime = 5.0, .channel = -1);
	ShowSyncHudMsg(0, g_iHudSyncLevel, "[Система уровней включена]");
	#endif

	set_hudmessage(135, 206, 235, .x = -1.0, .y = 0.08, .holdtime = 5.0, .channel = -1);
	ShowSyncHudMsg(0, g_iHudSync2, "Разминка окончена!");
	for(new i = 1; i <= MaxClients; i++)
	{
		if(is_user_alive(i))
		{
			rg_remove_items_by_slot(i, PRIMARY_WEAPON_SLOT);
		}
	}
}

#if defined REMOVE_MAP_WPN
public CArmoury_Restart(const pArmoury) 
{
	return HAM_SUPERCEDE;
}

public CGamePlayerEquip_Use() 
{
	return HAM_SUPERCEDE;
}

public CStripWeapons_Use() 
{
	return HAM_SUPERCEDE;
}

InvisibilityArmourys()
{
	new pArmoury = NULLENT
	while((pArmoury = rg_find_ent_by_class(pArmoury, "armoury_entity")))
	{
		if(get_member(pArmoury, m_Armoury_iCount) > 0)
		{
			set_entvar(pArmoury, var_effects, get_entvar(pArmoury, var_effects) | EF_NODRAW)
			set_entvar(pArmoury, var_solid, SOLID_NOT)
			set_member(pArmoury, m_Armoury_iCount, 0)
		}
	}
}
#endif

finishWurmUp()
{
	state warmupOff;
			  
	BuyZone_ToogleSolid(SOLID_TRIGGER);

	#if defined REMOVE_MAP_WPN
	DisableHamForward(fwd_Equip);
	DisableHamForward(fwd_WpnStrip);
	DisableHamForward(fwd_Entity);
	#endif

	DisableHookChain(fwd_Spawn);
	DisableHookChain(fwd_GiveC4);

	set_cvar_string("mp_forcerespawn", "0");
	set_cvar_string("mp_respawn_immunitytime", "0");
	set_cvar_string("mp_round_infinite", "0");

	#if defined STOP_STATS
	set_cvar_num("csstats_pause", 0);
	#endif

	#if defined STOP_LEVEL_SYSTEM
	set_cvar_num("ls_stop", 0);
	#endif

	#if defined BLOCK
	DisableHookChain(fwd_BlockEntity);
	#endif

	#if defined STOP_PLUGS   
	PluginController(0);
	#endif 

	#if NUM_RR > 1       
	set_task(LATENCY, "SV_Restart", .flags = "a", .repeat = NUM_RR);
	#else
	SV_Restart();
	#endif

	remove_task(TASK_TIMER_ID);
}

stock PluginController(stop)
{
	for(new i; i < sizeof g_arPlugins; i++)
	{
		if(stop)pause  ("ac", g_arPlugins[i]);
		else	unpause("ac", g_arPlugins[i]);
	}	
}

stock BuyZone_ToogleSolid(const solid)
{
	new entityIndex = 0;
	while ((entityIndex = rg_find_ent_by_class(entityIndex, "func_buyzone")))
		set_entvar(entityIndex, var_solid, solid);
}
