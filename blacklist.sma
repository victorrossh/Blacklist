#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <cromchat2>

#define PLUGIN "Blacklist Menu"
#define VERSION "1.0"
#define AUTHOR "ftl~"

#pragma semicolon 1

// Path for the blacklist folder
new const CONFIG_FOLDER[] = "addons/amxmodx/configs/blacklist";

// Blacklist file name
new const BLACKLIST_FILE[] = "blacklist.txt";

new g_BlacklistFile[128];
new bool:g_bIsFrozen[33];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_clcmd("say /black", "cmdBlacklistMenu", ADMIN_IMMUNITY);
	register_clcmd("say_team /black", "cmdBlacklistMenu", ADMIN_IMMUNITY);
	
	register_event("HLTV", "EventNewRound", "a", "1=0", "2=0");
	register_logevent("EventNewRound", 2, "1=Round_Start");
	register_logevent("EventNewRound", 2, "1=Round_End");
	register_event("CurWeapon", "HookCurWeapon", "be", "1=1");
	
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
	
	if (!dir_exists(CONFIG_FOLDER)) {
		mkdir(CONFIG_FOLDER);
	}
	
	formatex(g_BlacklistFile, sizeof(g_BlacklistFile) - 1, "%s/%s", CONFIG_FOLDER, BLACKLIST_FILE);

	//Chat prefix
	CC_SetPrefix("&x04[FWO]");
}

public client_connect(id) {
	g_bIsFrozen[id] = false;
	check_blacklist(id);
}

public client_disconnected(id) {
	g_bIsFrozen[id] = false;
}

public cmdBlacklistMenu(id, level, cid) {
	if (!cmd_access(id, level, cid, 1)) {
		return PLUGIN_HANDLED;
	}

	new menu = menu_create("\r[FWO] \d- \wPlayer Blacklist:", "cmdBlacklistMenuHandler");

	new players[32], num;
	get_players(players, num, "ch");
	
	if (num > 0) {
		new name[32], steamid[32], item_text[64], player_id[3];
		for (new i = 0; i < num; i++) {
			new player = players[i];
			get_user_name(player, name, sizeof(name) - 1);
			get_user_authid(player, steamid, sizeof(steamid) - 1);
			
			formatex(player_id, sizeof(player_id) - 1, "%d", player);
			new bool:is_blacklisted = is_steamid_blacklisted(steamid);
			formatex(item_text, sizeof(item_text) - 1, "%s %s", name, is_blacklisted ? "\r[BLACKLIST]" : "");
			menu_additem(menu, item_text, player_id);
		}
	} else {
		menu_additem(menu, "No players found", "");
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
		new steamid[32], name[32], message[128];
		get_user_authid(player, steamid, sizeof(steamid) - 1);
		get_user_name(player, name, sizeof(name) - 1);
		
		new bool:is_blacklisted = is_steamid_blacklisted(steamid);
		manage_blacklist(player, !is_blacklisted);
		
		formatex(message, sizeof(message) - 1, "Player &x03%s &x01%s blacklist.", name, is_blacklisted ? "removed from" : "added to");
		CC_SendMessage(id, message);
	}
	
	menu_destroy(menu);
	cmdBlacklistMenu(id, 0, 0);
	return PLUGIN_HANDLED;
}

bool:is_steamid_blacklisted(const steamid[]) {
	new file = fopen(g_BlacklistFile, "rt");
	if (file) {
		new temp[32];
		while (!feof(file)) {
			fgets(file, temp, sizeof(temp) - 1);
			trim(temp);
			if (temp[0] && equal(temp, steamid)) {
				fclose(file);
				return true;
			}
		}
		fclose(file);
	}
	return false;
}

public manage_blacklist(id, bool:add) {
	new steamid[32];
	get_user_authid(id, steamid, sizeof(steamid) - 1);
	
	if (add && !is_steamid_blacklisted(steamid)) {
		new file = fopen(g_BlacklistFile, "at");
		if (file) {
			fprintf(file, "%s^n", steamid);
			fclose(file);
		}
	} else if (!add && is_steamid_blacklisted(steamid)) {
		new lines[32][32], line_count = 0;
		new file = fopen(g_BlacklistFile, "rt");
		if (file) {
			new line[32];
			while (!feof(file) && line_count < 32) {
				fgets(file, line, sizeof(line) - 1);
				trim(line);
				if (line[0] && !equal(line, steamid)) {
					copy(lines[line_count++], sizeof(lines[]) - 1, line);
				}
			}
			fclose(file);
		}
		file = fopen(g_BlacklistFile, "wt");
		if (file) {
			for (new i = 0; i < line_count; i++) {
				fprintf(file, "%s^n", lines[i]);
			}
			fclose(file);
		}
	}
	
	g_bIsFrozen[id] = add;
	if (is_user_alive(id)) {
		apply_punishment(id);
	}
}

public check_blacklist(id) {
	new steamid[32];
	get_user_authid(id, steamid, sizeof(steamid) - 1);
	
	g_bIsFrozen[id] = is_steamid_blacklisted(steamid);
	if (g_bIsFrozen[id] && is_user_alive(id)) {
		apply_punishment(id);
	}
}

public apply_punishment(id) {
	if (g_bIsFrozen[id] && is_user_alive(id)) {
		engfunc(EngFunc_SetClientMaxspeed, id, 0.0);
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN);
		
		CC_SendMessage(id, "You are &x04blacklisted &x01and cannot move or shoot.");
	} else {
		engfunc(EngFunc_SetClientMaxspeed, id, 250.0);
		set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN);
	}
}

public HookCurWeapon(id) {
	if (g_bIsFrozen[id] && is_user_alive(id)) {
		engfunc(EngFunc_SetClientMaxspeed, id, 0.0);
	}
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

public EventNewRound() {
	new players[32], num;
	get_players(players, num, "a");
	for (new i = 0; i < num; i++) {
		new id = players[i];
		check_blacklist(id);
	}
}