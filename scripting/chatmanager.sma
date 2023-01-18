/**
 * Credits: BlackRose, Ian Cammarata, PRoSToTeM@.
 */
#include <amxmodx>
#include <amxmisc>
#include <cstrike>

#define PLUGIN "Chat Manager"
#define VERSION "1.1.2-16"
#define AUTHOR "Mistrick"

#pragma semicolon 1

#define ADMIN_FLAG ADMIN_CHAT

//Colors: DEFAULT, TEAM, GREEN
#define PRETEXT_COLOR            DEFAULT
#define PLAYER_CHAT_COLOR        DEFAULT
#define ADMIN_CHAT_COLOR         GREEN
#define PLAYER_NAME_COLOR        TEAM
#define ADMIN_NAME_COLOR         TEAM

#define FUNCTION_ALL_CHAT

//Flags: DEFAULT_CHAT, ALIVE_SEE_DEAD, DEAD_SEE_ALIVE, TEAM_SEE_TEAM
#define PLAYER_CHAT_FLAGS (ALIVE_SEE_DEAD|DEAD_SEE_ALIVE)
#define ADMIN_CHAT_FLAGS (ALIVE_SEE_DEAD|DEAD_SEE_ALIVE)

#define FUNCTION_PLAYER_PREFIX
// #define FUNCTION_ADD_TIME_CODE
// #define FUNCTION_LOG_MESSAGES
// #define FUNCTION_HIDE_SLASH
// #define FUNCTION_TRANSLITE
// #define FUNCTION_AES_TAGS
#define FUNCTION_LEVEL_SYSTEM
// #define FUNCTION_BETA_8308_SUPPORT

// #define FUNCTION_ADD_STEAM_PREFIX

stock const STEAM_PREFIX[] = "^1[^4Steam^1] ";

#define PREFIX_MAX_LENGTH 32
#define AES_MAX_LENGTH 32

new const TEAM_NAMES[CsTeams][] = {
    "(Spectator)",
    "(Terrorist)",
    "(Counter-Terrorist)",
    "(Spectator)"
};

//DONT CHANGE!!!
#define COLOR_BUFFER 6
#define TEXT_LENGTH 128

#if defined FUNCTION_BETA_8308_SUPPORT
#define MESSAGE_LENGTH 187
#else
#define MESSAGE_LENGTH 173 // 192 - 19
#endif

#if defined FUNCTION_PLAYER_PREFIX
#define CHECK_NATIVE_ARGS_NUM(%1,%2,%3) \
    if (%1 < %2) { \
        log_error(AMX_ERR_NATIVE, "Invalid num of arguments %d. Expected %d", %1, %2); \
        return %3; \
    }

#define CHECK_NATIVE_PLAYER(%1,%2) \
    if (!is_user_connected(%1)) { \
        log_error(AMX_ERR_NATIVE, "Invalid player %d", %1); \
        return %2; \
    }
#endif

#if defined FUNCTION_AES_TAGS
native aes_get_player_stats(id,data[4]);
native aes_get_level_name(lvlnum,level[],len,idLang = 0);
new const AES_TAG_FORMAT[] = "^1[^3%s^1] ";
#endif

#if defined FUNCTION_LEVEL_SYSTEM
native ls_get_level_player(id);
new const LEVEL_SYSTEM_TAG[] = "^1[^3%L %d^1] ";
#endif

const DEFAULT_CHAT = 0;
const ALIVE_SEE_DEAD = (1 << 0);
const DEAD_SEE_ALIVE = (1 << 1);
const TEAM_SEE_TEAM = (1 << 2);

enum {
    DEFAULT = 1,
    TEAM = 3,
    GREEN = 4
};

enum _:FLAG_PREFIX_INFO {
    m_Flag,
    m_Prefix[PREFIX_MAX_LENGTH]
};

new const g_TextChannels[][] = {
    "#Cstrike_Chat_All",
    "#Cstrike_Chat_AllDead",
    "#Cstrike_Chat_T",
    "#Cstrike_Chat_T_Dead",
    "#Cstrike_Chat_CT",
    "#Cstrike_Chat_CT_Dead",
    "#Cstrike_Chat_Spec",
    "#Cstrike_Chat_AllSpec"
};

new g_SayText;
new g_sMessage[MESSAGE_LENGTH];

#if defined FUNCTION_PLAYER_PREFIX
new const FILE_PREFIXES[] = "chatmanager_prefixes.ini";

new g_bCustomPrefix[33], g_sPlayerPrefix[33][PREFIX_MAX_LENGTH];
new Trie:g_tSteamPrefixes, g_iTrieSteamSize;
new Trie:g_tNamePrefixes, g_iTrieNameSize;
new Array:g_aFlagPrefixes, g_iArrayFlagSize;
#endif

#if defined FUNCTION_LOG_MESSAGES
new g_szLogFile[128];
#endif

#if defined FUNCTION_TRANSLITE
new g_bTranslite[33];
#endif

#if defined FUNCTION_ADD_STEAM_PREFIX
new g_bSteamPlayer[33];
#endif

enum Forwards {
    SEND_MESSAGE
};

enum _:MessageReturn {
    MESSAGE_IGNORED,
    MESSAGE_CHANGED,
    MESSAGE_BLOCKED
};

new g_iForwards[Forwards];
new g_sNewMessage[MESSAGE_LENGTH];

public plugin_init()
{
    register_plugin(PLUGIN, VERSION, AUTHOR);
    
    #if defined FUNCTION_PLAYER_PREFIX
    register_concmd("cm_set_prefix", "concmd__set_prefix", ADMIN_RCON, "<name or #userid> <prefix>");
    #endif
    
    #if defined FUNCTION_TRANSLITE
    register_clcmd("say /rus", "clcmd__lang_change");
    register_clcmd("say /eng", "clcmd__lang_change");
    #endif
    
    register_clcmd("say", "clcmd__say_handler");
    register_clcmd("say_team", "clcmd__say_handler");
    
    register_message((g_SayText = get_user_msgid("SayText")), "message__say_text");

    // cm_player_send_message(id, message[], team_chat);
    g_iForwards[SEND_MESSAGE] = CreateMultiForward("cm_player_send_message", ET_STOP, FP_CELL, FP_STRING, FP_CELL);
}
public plugin_cfg()
{
    #if defined FUNCTION_LOG_MESSAGES
    new dir[] = "addons/amxmodx/logs/chatmanager";
    if(!dir_exists(dir)) {
        mkdir(dir);
    }
    new date[16]; get_time("%Y%m%d", date, charsmax(date));
    formatex(g_szLogFile, charsmax(g_szLogFile), "%s/chatlog_%s.html", dir, date);
    if(!file_exists(g_szLogFile)) {
        write_file(g_szLogFile, "<meta charset=utf-8><title>ChatManager Log</title>");
    }
    #endif
    
    #if defined FUNCTION_PLAYER_PREFIX
    LoadPlayersPrefixes();
    #endif
    
    #if defined FUNCTION_AES_TAGS
    register_dictionary("aes.txt");
    #endif

    #if defined FUNCTION_LEVEL_SYSTEM
    register_dictionary("level_system.txt");
    #endif
}
#if defined FUNCTION_PLAYER_PREFIX
LoadPlayersPrefixes()
{
    new dir[128]; get_localinfo("amxx_configsdir", dir, charsmax(dir));
    new file_name[128]; formatex(file_name, charsmax(file_name), "%s/%s", dir, FILE_PREFIXES);
    
    if(!file_exists(file_name)) {
        log_amx("Prefixes file doesn't exist!");
        return;
    }
    
    g_tSteamPrefixes = TrieCreate();
    g_tNamePrefixes = TrieCreate();
    g_aFlagPrefixes = ArrayCreate(FLAG_PREFIX_INFO);
    
    new file = fopen(file_name, "rt");
    
    if(file) {
        new text[128], type[6], auth[32], prefix[PREFIX_MAX_LENGTH + COLOR_BUFFER], prefix_info[FLAG_PREFIX_INFO];
        while(!feof(file)) {
            fgets(file, text, charsmax(text));
            parse(text, type, charsmax(type), auth, charsmax(auth), prefix, charsmax(prefix));
            
            if(!type[0] || type[0] == ';' || !auth[0] || !prefix[0]) continue;
            
            replace_color_tag(prefix);
            
            switch(type[0]) {
                //steam
                case 's': {
                    TrieSetString(g_tSteamPrefixes, auth, prefix);
                    g_iTrieSteamSize++;
                }
                //name
                case 'n': {
                    TrieSetString(g_tNamePrefixes, auth, prefix);
                    g_iTrieNameSize++;
                }
                //flag
                case 'f': {
                    prefix_info[m_Flag] = read_flags(auth);
                    copy(prefix_info[m_Prefix], charsmax(prefix_info[m_Prefix]), prefix);
                    ArrayPushArray(g_aFlagPrefixes, prefix_info);
                    g_iArrayFlagSize++;
                }
            }
        }
        fclose(file);
    }
}
#endif
public plugin_natives()
{
    register_native("cm_set_player_message", "native_set_player_message");

    #if defined FUNCTION_PLAYER_PREFIX
    register_native("cm_set_prefix", "native_set_prefix");
    register_native("cm_get_prefix", "native_get_prefix");
    register_native("cm_reset_prefix", "native_reset_prefix");
    #endif
}
public native_set_player_message(plugin, params)
{
    enum { arg_new_message = 1 };
    get_string(arg_new_message, g_sNewMessage, charsmax(g_sNewMessage));
}
#if defined FUNCTION_PLAYER_PREFIX
public native_set_prefix(plugin, params)
{
    enum { 
        arg_player = 1,
        arg_prefix
    };

    CHECK_NATIVE_ARGS_NUM(params, arg_prefix, 0)
    new player = get_param(arg_player);
    CHECK_NATIVE_PLAYER(player, 0)

    get_string(arg_prefix, g_sPlayerPrefix[player], charsmax(g_sPlayerPrefix[]));
    g_bCustomPrefix[player] = true;
    return 1;
}
public native_get_prefix(plugin, params)
{
    enum {
        arg_player = 1,
        arg_dest,
        arg_length
    };
    
    CHECK_NATIVE_ARGS_NUM(params, arg_length, 0)
    new player = get_param(arg_player);
    CHECK_NATIVE_PLAYER(player, 0)

    if (!g_bCustomPrefix[player]) {
        return 0;
    }

    return set_string(arg_dest, g_sPlayerPrefix[player], get_param(arg_length));
}
public native_reset_prefix(plugin, params)
{
    enum { arg_player = 1 };

    CHECK_NATIVE_ARGS_NUM(params, arg_player, 0)
    new player = get_param(arg_player);
    CHECK_NATIVE_PLAYER(player, 0)

    arrayset(g_sPlayerPrefix[player], 0, sizeof g_sPlayerPrefix[]);
    g_bCustomPrefix[player] = false;
    return 1;
}
#endif
public client_putinserver(id)
{
    #if defined FUNCTION_TRANSLITE
    g_bTranslite[id] = false;
    #endif
    
    #if defined FUNCTION_PLAYER_PREFIX
    g_sPlayerPrefix[id] = "";
    g_bCustomPrefix[id] = false;
    
    new steamid[32];
    get_user_authid(id, steamid, charsmax(steamid));
    if(g_iTrieSteamSize && TrieKeyExists(g_tSteamPrefixes, steamid)) {
        g_bCustomPrefix[id] = true;
        TrieGetString(g_tSteamPrefixes, steamid, g_sPlayerPrefix[id], charsmax(g_sPlayerPrefix[]));
    }
    #endif
    
    #if defined FUNCTION_ADD_STEAM_PREFIX
    g_bSteamPlayer[id] = is_user_steam(id);
    #endif
}
#if defined FUNCTION_PLAYER_PREFIX
public concmd__set_prefix(id, level, cid)
{
    if(!cmd_access(id, level, cid, 2)) {
        return PLUGIN_HANDLED;
    }

    new szArg[32]; read_argv(1, szArg, charsmax(szArg));
    new player = cmd_target(id, szArg, CMDTARGET_ALLOW_SELF);
    
    if(!player) {
        return PLUGIN_HANDLED;
    }
    
    new prefix[PREFIX_MAX_LENGTH + COLOR_BUFFER];
    read_argv(2, prefix, charsmax(prefix));
    replace_color_tag(prefix);
    
    console_print(id, "You changed player prefix from ^"%s^" to ^"%s^".", g_sPlayerPrefix[player], prefix);
    
    copy(g_sPlayerPrefix[player], charsmax(g_sPlayerPrefix[]), prefix);
    g_bCustomPrefix[player] = g_sPlayerPrefix[player][0] != EOS ? true : false;
    
    return PLUGIN_HANDLED;
}
#endif
#if defined FUNCTION_TRANSLITE
public clcmd__lang_change(id)
{
    g_bTranslite[id] = !g_bTranslite[id];
    color_print(id, "^4[ChatManager]^1 You changed language to ^3%s^1.", g_bTranslite[id] ? "rus" : "eng");
    return PLUGIN_HANDLED;
}
#endif
public clcmd__say_handler(id)
{
    if (!is_user_connected(id)) {
        return PLUGIN_HANDLED;
    }
    
    new message[TEXT_LENGTH];
    
    read_argv(0, message, charsmax(message));
    new is_team_msg = (message[3] == '_');
    
    read_args(message, charsmax(message));
    remove_quotes(message);
    replace_wrong_simbols(message);
    trim(message);
    
    if(!message[0]) {
        return PLUGIN_HANDLED;
    }
    
    #if defined FUNCTION_HIDE_SLASH
    if(message[0] == '/') {
        return PLUGIN_HANDLED_MAIN;
    }
    #endif
    
    new flags, name[32];
    flags = get_user_flags(id);
    get_user_name(id, name, charsmax(name));
    
    #if defined FUNCTION_PLAYER_PREFIX
    if(!g_bCustomPrefix[id]) {
        if(g_iTrieNameSize && TrieKeyExists(g_tNamePrefixes, name)) {
            TrieGetString(g_tNamePrefixes, name, g_sPlayerPrefix[id], charsmax(g_sPlayerPrefix[]));
        } else if(g_iArrayFlagSize) {
            new prefix_info[FLAG_PREFIX_INFO], bFoundPrefix = false;
            for(new i; i < g_iArrayFlagSize; i++) {
                ArrayGetArray(g_aFlagPrefixes, i, prefix_info);
                if(check_flags(flags, prefix_info[m_Flag])) {
                    bFoundPrefix = true;
                    copy(g_sPlayerPrefix[id], charsmax(g_sPlayerPrefix[]), prefix_info[m_Prefix]);
                    break;
                }
            }
            
            if(!bFoundPrefix) {
                g_sPlayerPrefix[id] = "";
            }
        }
    }
    #endif
    
    #if defined FUNCTION_TRANSLITE
    if(g_bTranslite[id]) {
        if(message[0] == '/') {
            copy(message, charsmax(message), message[1]);
        } else {
            new translited[TEXT_LENGTH];
            translite_string(translited, charsmax(translited), message);
            copy(message, charsmax(message), translited);
        }
    }
    #endif
    
    new ret; ExecuteForward(g_iForwards[SEND_MESSAGE], ret, id, message, is_team_msg);

    if(ret) {
        if(ret == MESSAGE_BLOCKED) {
            return PLUGIN_HANDLED;
        }
        copy(message, charsmax(message), g_sNewMessage);
    }

    if(!message[0]) {
        return PLUGIN_HANDLED;
    }

    new name_color = flags & ADMIN_FLAG ? ADMIN_NAME_COLOR : PLAYER_NAME_COLOR;
    new chat_color = flags & ADMIN_FLAG ? ADMIN_CHAT_COLOR : PLAYER_CHAT_COLOR;
    
    new time_code[16];
    get_time("[%H:%M:%S] ", time_code, charsmax(time_code));
    
    new is_sender_alive = is_user_alive(id);
    new CsTeams:sender_team = cs_get_user_team(id);
    
    new channel = get_user_text_channel(is_sender_alive, is_team_msg, sender_team);
    
    FormatMessage(id, sender_team, channel, name_color, chat_color, time_code, name, message);
    
    #if defined FUNCTION_ALL_CHAT
    new players[32], players_num, player, is_player_alive, CsTeams:player_team, player_flags;
    get_players(players, players_num, "ch");
    
    for(new i; i < players_num; i++) {
        player = players[i];
        
        if(player == id) {
            continue;
        }
        
        is_player_alive = is_user_alive(player);
        player_team = cs_get_user_team(player);
        player_flags = get_user_flags(player) & ADMIN_FLAG ? ADMIN_CHAT_FLAGS : PLAYER_CHAT_FLAGS;
        
        if(player_flags & ALIVE_SEE_DEAD && !is_sender_alive && is_player_alive && (!is_team_msg || is_team_msg && sender_team == player_team) //flag ALIVE_SEE_DEAD
        || player_flags & DEAD_SEE_ALIVE && is_sender_alive && !is_player_alive && (!is_team_msg || is_team_msg && sender_team == player_team) //flag DEAD_SEE_ALIVE
        || player_flags & TEAM_SEE_TEAM && is_team_msg && sender_team != player_team) //flag TEAM_SEE_TEAM
        {
            emessage_begin(MSG_ONE, g_SayText, _, player);
            ewrite_byte(id);
            ewrite_string(g_TextChannels[channel]);
            ewrite_string("");
            ewrite_string("");
            emessage_end();
        }
    }
    #endif
    
    #if defined FUNCTION_LOG_MESSAGES
    static const team_color[CsTeams][] = {"gray", "red", "blue", "gray"};
    new log_msg[256];
    formatex(log_msg, charsmax(log_msg), "<br><font color=black>%s %s %s <font color=%s><b>%s</b> </font>:</font><font color=%s> %s </font>", time_code, is_sender_alive ? "" : (_:sender_team == 1 || _:sender_team == 2 ? "*DEAD*" : "*SPEC*"), is_team_msg ? "(TEAM)" : "", team_color[sender_team], name, chat_color == GREEN ? "green" : "#FFB41E", message);
    write_file(g_szLogFile, log_msg);
    #endif
    
    return PLUGIN_CONTINUE;
}
public FormatMessage(sender, CsTeams:sender_team, channel, name_color, chat_color, time_code[], name[], message[])
{
    new text[MESSAGE_LENGTH], len = 1;
    text[0] = PRETEXT_COLOR;
    
    if(channel % 2) {
        len += formatex(text[len], charsmax(text) - len, "%s", channel != 7 ? "*DEAD*" : "*SPEC*");
    }
    
    if(channel > 1 && channel < 7) {
        len += formatex(text[len], charsmax(text) - len, "%s ", TEAM_NAMES[sender_team]);
    } else if(channel) {
        len += formatex(text[len], charsmax(text) - len, " ");
    }
    
    #if defined FUNCTION_ADD_TIME_CODE
    len += formatex(text[len], charsmax(text) - len, "%s", time_code);
    #endif
    
    #if defined FUNCTION_ADD_STEAM_PREFIX
    if(g_bSteamPlayer[sender]) {
        len += formatex(text[len], charsmax(text) - len, "%s", STEAM_PREFIX);
    }
    #endif
    
    #if defined FUNCTION_AES_TAGS
    new data[4], szAesTag[AES_MAX_LENGTH]; aes_get_player_stats(sender, data); aes_get_level_name(data[1], szAesTag, charsmax(szAesTag));
    len += formatex(text[len], charsmax(text) - len, AES_TAG_FORMAT, szAesTag);
    #endif
    
    #if defined FUNCTION_LEVEL_SYSTEM
    len += formatex(text[len], charsmax(text) - len, LEVEL_SYSTEM_TAG, sender, "LS_TEXT_LEVEL", ls_get_level_player(sender));
    #endif

    #if defined FUNCTION_PLAYER_PREFIX
    len += formatex(text[len], charsmax(text) - len, "%s", g_sPlayerPrefix[sender]);
    #endif
    
    len += formatex(text[len], charsmax(text) - len, "%c%s^1 :%c %s", name_color, name, chat_color, message);
    
    copy(g_sMessage, charsmax(g_sMessage), text);
}
public message__say_text(msgid, dest, receiver)
{
    if(get_msg_args() != 4) {
        return PLUGIN_CONTINUE;
    }
    
    new str2[22], channel;

    get_msg_arg_string(2, str2, charsmax(str2));
    channel = get_msg_channel(str2);
    
    if(!channel) {
        return PLUGIN_CONTINUE;
    }
    
    new str3[2];
    get_msg_arg_string(3, str3, charsmax(str3));
    
    if(str3[0]) {
        return PLUGIN_CONTINUE;
    }
    
    #if defined FUNCTION_BETA_8308_SUPPORT
    set_msg_arg_string(2, "%s");
    #else
    set_msg_arg_string(2, "#Spec_PlayerItem");
    #endif

    set_msg_arg_string(3, g_sMessage);
    set_msg_arg_string(4, "");
    
    return PLUGIN_CONTINUE;
}
get_msg_channel(str[])
{
    for(new i; i < sizeof(g_TextChannels); i++) {
        if(equal(str, g_TextChannels[i])) {
            return i + 1;
        }
    }
    return 0;
}
stock get_user_text_channel(is_sender_alive, is_team_msg, CsTeams:sender_team)
{
    if (is_team_msg) {
        switch(sender_team) {
            case CS_TEAM_T: {
                return is_sender_alive ? 2 : 3;
            }
            case CS_TEAM_CT: {
                return is_sender_alive ? 4 : 5;
            }
            default: {
                return 6;
            }
        }
    }
    return is_sender_alive ? 0 : (sender_team == CS_TEAM_SPECTATOR ? 7 : 1);
}
stock replace_wrong_simbols(string[])
{
    new len = 0;
    for(new i; string[i] != EOS; i++) {
        if(/* string[i] == '%' || string[i] == '#' || */ 0x01 <= string[i] <= 0x04) {
            continue;
        }
        string[len++] = string[i];
    }
    string[len] = EOS;
}
#if defined FUNCTION_PLAYER_PREFIX
replace_color_tag(string[])
{
    new len = 0;
    for (new i; string[i] != EOS; i++) {
        if (string[i] == '!') {
            switch (string[++i]) {
                case 'd': string[len++] = 0x01;
                case 't': string[len++] = 0x03;
                case 'g': string[len++] = 0x04;
                case EOS: break;
                default: string[len++] = string[i];
            }
        } else {
            string[len++] = string[i];
        }
    }
    string[len] = EOS;
}
#endif
stock translite_string(string[], size, source[])
{
    static const table[][] = {
        "Э", "#", ";", "%", "?", "э", "(", ")", "*", "+", "б", "-", "ю", ".", "0", "1", "2", "3", "4",
        "5", "6", "7", "8", "9", "Ж", "ж", "Б", "=", "Ю", ",", "^"", "Ф", "И", "С", "В", "У", "А", "П",
        "Р", "Ш", "О", "Л", "Д", "Ь", "Т", "Щ", "З", "Й", "К", "Ы", "Е", "Г", "М", "Ц", "Ч", "Н", "Я",
        "х", "\", "ъ", ":", "_", "ё", "ф", "и", "с", "в", "у", "а", "п", "р", "ш", "о", "л", "д", "ь",
        "т", "щ", "з", "й", "к", "ы", "е", "г", "м", "ц", "ч", "н", "я", "Х", "/", "Ъ", "Ё"
    };
    
    new len = 0;
    for (new i = 0; source[i] != EOS && len < size; i++) {
        new ch = source[i];
        
        if ('"' <= ch <= '~') {
            ch -= '"';
            string[len++] = table[ch][0];
            if (table[ch][1] != EOS) {
                string[len++] = table[ch][1];
            }
        } else {
            string[len++] = ch;
        }
    }
    string[len] = EOS;
    
    return len;
}
stock color_print(id, text[], any:...)
{
    new formated[190]; vformat(formated, charsmax(formated), text, 3);
    message_begin(id ? MSG_ONE : MSG_ALL, g_SayText, _, id);
    write_byte(id);
    write_string(formated);
    message_end();
}
stock check_flags(flags, need_flags)
{
    return ((flags & need_flags) == need_flags) ? 1 : 0;
}
stock is_user_steam(id)
{
    static dp_pointer;
    if(dp_pointer || (dp_pointer = get_cvar_pointer("dp_r_id_provider"))) {
        server_cmd("dp_clientinfo %d", id); server_exec();
        return (get_pcvar_num(dp_pointer) == 2) ? true : false;
    }
    return false;
}
