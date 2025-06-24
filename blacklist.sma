#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <hamsandwich>
#include <engine>
#include <cromchat2>

#define PLUGIN "Blacklist Menu"
#define VERSION "1.0"
#define AUTHOR "ftl~ && WESPEOOTY"

#define PREFIX_MENU "\r[FWO]"
#pragma semicolon 1

// Path for the blacklist file
new const CONFIG_FOLDER[] = "addons/amxmodx/configs/blacklist/blacklist.txt";

// Register CVARs for blacklist
new g_iCvarBlockChat, g_iCvarBlockRadio, g_iCvarBlockVoice;
new bool:g_bIsFrozen[33];
new Array:g_BlacklistArray;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_concmd("amx_blacklist", "AmxBlacklistCmd", ADMIN_IMMUNITY);
	register_concmd("amx_unblacklist", "AmxRemoveBlacklistCmd", ADMIN_IMMUNITY);

	register_clcmd("say /blacklist", "cmdBlacklistMenu", ADMIN_IMMUNITY);
	register_clcmd("say_team /blacklist", "cmdBlacklistMenu", ADMIN_IMMUNITY);
	
	register_clcmd("say", "clcmd_say");
	register_clcmd("say_team", "clcmd_say");
	
	register_clcmd("radio1", "cmd_radio");
	register_clcmd("radio2", "cmd_radio");
	register_clcmd("radio3", "cmd_radio");

	// Register CVARs for blacklist
	g_iCvarBlockChat = register_cvar("bl_block_chat", "1");
	g_iCvarBlockRadio = register_cvar("bl_block_radio", "1");
	g_iCvarBlockVoice = register_cvar("bl_block_voice", "1");

	RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", true);
	RegisterHam(Ham_AddPlayerItem, "player", "OnAddPlayerItem", true);
	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
	register_forward(FM_Voice_SetClientListening, "fw_Voice_SetClientListening");
	
	new directory[128];
	formatex(directory, sizeof(directory) - 1, "addons/amxmodx/configs/blacklist");
	if (!dir_exists(directory))
		mkdir(directory);

	//Chat prefix
	CC_SetPrefix("&x04[FWO]");
}

public plugin_cfg() {
	register_dictionary("black_list.txt");
	
	if(g_BlacklistArray == Invalid_Array) {
		g_BlacklistArray = ArrayCreate(32, 1);
	}
	load_blacklist();
}

public plugin_end() {
	save_blacklist();
}

public client_putinserver(id) {
	g_bIsFrozen[id] = false;
	check_blacklist(id);
}

public bool:is_blacklisted(id) {
	if(g_BlacklistArray == Invalid_Array || ArraySize(g_BlacklistArray) == 0)
		return false;
		
	new steamid[32];
	get_user_authid(id, steamid, charsmax(steamid));

	new index = ArrayFindString(g_BlacklistArray, steamid);
	return (index != -1);
}

public AmxBlacklistCmd(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	new szAuthId[64];
	read_argv(1, szAuthId, 63);

	// Add ID to Array g_BlacklistArray
	if (ArrayFindString(g_BlacklistArray, szAuthId) == -1) {
		ArrayPushString(g_BlacklistArray, szAuthId);
	}

	// Apply punishment if player is online
	new player = find_player("c", szAuthId);
	if (player && is_user_connected(player)) {
		g_bIsFrozen[player] = true;
		apply_punishment(player);
	}

	CC_SendMessage(0, "%l", "AMX_BLACKLISTED", szAuthId);

	return PLUGIN_HANDLED;
}

public AmxRemoveBlacklistCmd(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	new szAuthId[64];
	read_argv(1, szAuthId, 63);

	// Remove ID from Array g_BlacklistArray
	new index = ArrayFindString(g_BlacklistArray, szAuthId);
	if (index != -1) {
		ArrayDeleteItem(g_BlacklistArray, index);
	}

	// Remove punishment if player is online
	new player = find_player("c", szAuthId);
	if (player && is_user_connected(player)) {
		g_bIsFrozen[player] = false;
		apply_punishment(player);
	}

	CC_SendMessage(0, "%l", "AMX_UNBLACKLISTED", szAuthId);

	return PLUGIN_HANDLED;
}

public cmdBlacklistMenu(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	new szMenuTitle[64];
	formatex(szMenuTitle, charsmax(szMenuTitle), "%L", id, "MENU_TITLE", PREFIX_MENU);
	new menu = menu_create(szMenuTitle, "cmdBlacklistMenuHandler");

	new players[32], num;
	get_players(players, num, "ch");
	
	if (num > 0) {
		new name[32], item_text[64], player_id[3];
		for (new i = 0; i < num; i++) {
			new player = players[i];
			get_user_name(player, name, sizeof(name) - 1);
			
			formatex(player_id, sizeof(player_id) - 1, "%d", player);
			new bool:player_is_blacklisted = is_blacklisted(player);
			
			formatex(item_text, sizeof(item_text) - 1, player_is_blacklisted ? "%s %L" : "%s", name, id, "MENU_STATUS");
			menu_additem(menu, item_text, player_id);
		}
	} else {
		new szNoPlayers[32];
		formatex(szNoPlayers, charsmax(szNoPlayers), "%L", id, "MENU_NO_PLAYERS");
		menu_additem(menu, szNoPlayers, "");
	}
	
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public cmdBlacklistMenuHandler(id, menu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	new player_id[3], dummy;
	menu_item_getinfo(menu, item, dummy, player_id, sizeof(player_id) - 1);
	
	new player = str_to_num(player_id);
	if (is_user_connected(player)) {
		new name[32], message[128];
		get_user_name(player, name, sizeof(name) - 1);
		
		new bool:player_is_blacklisted = is_blacklisted(player);
		manage_blacklist(player, !player_is_blacklisted);
		
		formatex(message, sizeof(message) - 1, "%L", id, player_is_blacklisted ? "MSG_REMOVED" : "MSG_ADDED", name);
		CC_SendMessage(id, message);
	}
	cmdBlacklistMenu(id, 0, 0);
	return PLUGIN_HANDLED;
}

public clcmd_say(id) {
	if(!g_bIsFrozen[id] || !get_pcvar_num(g_iCvarBlockChat))
		return PLUGIN_CONTINUE;

	new args[2]; read_args(args, charsmax(args));
	return (args[0] == '/') ? PLUGIN_HANDLED_MAIN : PLUGIN_HANDLED;
}

public cmd_radio(id) {
	if (g_bIsFrozen[id] && get_pcvar_num(g_iCvarBlockRadio))
		return PLUGIN_HANDLED_MAIN;

	return PLUGIN_CONTINUE;
}

public fw_Voice_SetClientListening(receiver, sender, listen) {
	if (receiver == sender || !get_pcvar_num(g_iCvarBlockVoice))
		return FMRES_IGNORED;

	if (g_bIsFrozen[sender] && get_pcvar_num(g_iCvarBlockVoice)) {
		engfunc(EngFunc_SetClientListening, receiver, sender, false);
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public fw_PlayerPreThink(id) {
	if (g_bIsFrozen[id] && is_user_alive(id)) {
		new button = get_user_button(id);

		if (button & IN_ATTACK | IN_ATTACK2) {
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

public OnPlayerSpawn(id) {
	if (!is_user_connected(id))
		return HAM_IGNORED;
	
	set_task(0.1, "check_c4", id);
	check_blacklist(id);
	return HAM_IGNORED;
}

public OnAddPlayerItem(id, weapon) {
	if (!is_user_alive(id) || !g_bIsFrozen[id])
		return HAM_IGNORED;

	new classname[32];
	entity_get_string(weapon, EV_SZ_classname, classname, charsmax(classname));

	if (equal(classname, "weapon_c4")) {
		set_task(0.2, "check_c4", id);
	}
	return HAM_IGNORED;
}

public check_blacklist(id) {
	g_bIsFrozen[id] = is_blacklisted(id);
	if (g_bIsFrozen[id] && is_user_alive(id)) {
		apply_punishment(id);
	}
}

public apply_punishment(id) {
	if (g_bIsFrozen[id] && is_user_alive(id)) {
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
		CC_SendMessage(id, "%L", id, "MSG_PUNISHMENT");
	} else {
		set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN);
	}
}

public manage_blacklist(id, bool:should_be_blacklisted) {
	should_be_blacklisted ? blacklist_player(id) : remove_blacklist(id);
	
	g_bIsFrozen[id] = should_be_blacklisted;
	if (is_user_alive(id)) {
		apply_punishment(id);
	}
}

public load_blacklist() {
	new file = fopen(CONFIG_FOLDER, "rt");
	if (file) {
		new steamid[32];
		while (!feof(file)) {
			fgets(file, steamid, charsmax(steamid));
			trim(steamid);
			if (steamid[0]) {
				ArrayPushString(g_BlacklistArray, steamid);
			}
		}
		fclose(file);
	}
}

public save_blacklist() {
	new file = fopen(CONFIG_FOLDER, "wt");
	if (file) {
		for (new i = 0; i < ArraySize(g_BlacklistArray); i++) {
			new steamid[32];
			ArrayGetString(g_BlacklistArray, i, steamid, charsmax(steamid));
			fprintf(file, "%s^n", steamid);
		}
		fclose(file);
	}
}

public blacklist_player(id){
	new steamid[32];
	get_user_authid(id, steamid, charsmax(steamid));
	ArrayPushString(g_BlacklistArray, steamid);
}

public remove_blacklist(id) {
	if(g_BlacklistArray == Invalid_Array || ArraySize(g_BlacklistArray) == 0)
		return;
		
	new steamid[32];
	get_user_authid(id, steamid, charsmax(steamid));
	
	new index = ArrayFindString(g_BlacklistArray, steamid);
	if(index != -1) {
		ArrayDeleteItem(g_BlacklistArray, index);
	}
}

public check_c4(id) {
	if (!is_user_connected(id) || !is_user_alive(id) || !g_bIsFrozen[id])
		return;

	cs_set_user_money(id, 0);
	if (user_has_weapon(id, CSW_C4) && cs_get_user_team(id) == CS_TEAM_T) {
		engclient_cmd(id, "drop", "weapon_c4");
		cs_set_user_plant(id, 0, 0);
		cs_set_user_submodel(id, 0);
	}
}