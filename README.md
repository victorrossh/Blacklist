# Blacklist

A custom AMX Mod X plugin developed for my personal 4Fun Counter-Strike 1.6 server.

## Description

This plugin implements a blacklist system to manage disruptive players (e.g., cheaters) on the server without banning them outright. Instead, blacklisted players can join the server but are subjected to strict punishments that prevent them from playing effectively:

- **Frozen in Place**: Blacklisted players are completely immobilized and unable to move or shoot.
- **Chat Blocked**: Their ability to use chat (both public and team) is disabled, except for commands starting with `/`.
- **Voice Communication Disabled**: They cannot use voice chat to communicate with others.
- **C4 Restrictions**: If they spawn with the C4 bomb, it is automatically dropped, planting is disabled, and their money is set to 0.

These restrictions create a frustrating yet effective punishment: blacklisted players can join but remain stuck at spawn, unable to act, and are easy targets for others.

The blacklist is managed in-memory using an Array for efficiency, with the list of SteamIDs saved to a file (`blacklist.txt`) only at the end of each map, ensuring persistence across map changes.

## Features

- **Admin Command**: Admins with `ADMIN_IMMUNITY` can use `/blacklist` (in both public and team chat) to open a menu for managing the blacklist.
- **Dynamic Menu**: Displays all online players, with an indicator (`[Blacklisted]`) for those currently on the blacklist.
- **In-Memory Storage**: Blacklist is stored in memory during gameplay, improving performance by minimizing disk I/O operations.
- **Persistent Storage**: SteamIDs are saved to `addons/amxmodx/configs/blacklist/blacklist.txt` at the end of each map and loaded at the start of the next.
- **AMX Commands**: Admins with `ADMIN_IMMUNITY` can use console commands to manage the blacklist:
	- `amx_blacklist <SteamID>`: Adds a SteamID to the blacklist, applying punishment immediately if the player is online.
	- `amx_unblacklist <SteamID>`: Removes a SteamID from the blacklist, lifting the punishment immediately if the player is online.
- **Configurable Punishments**:
	- `bl_block_chat` (default: 1): Toggles chat blocking for blacklisted players.
	- `bl_block_radio` (default: 1): Toggles radio command blocking for blacklisted players.
	- `bl_block_voice` (default: 1): Toggles voice communication blocking for blacklisted players.

## Usage

### Commands
- `/blacklist` (or `say /blacklist`, `say_team /blacklist`): Opens a menu for admins with `ADMIN_IMMUNITY` to add or remove players from the blacklist.
	- The menu lists all online players.
	- Selecting a player toggles their blacklist status (adds if not blacklisted, removes if already blacklisted).
	- Confirmation messages are shown (`Added to blacklist` or `Removed from blacklist`).
- `amx_blacklist <SteamID>`: Adds the specified SteamID to the blacklist. If the player is online, punishment (freeze, chat block, etc.) is applied instantly. Works for offline players too.
- `amx_unblacklist <SteamID>`: Removes the specified SteamID from the blacklist. If the player is online, the punishment is lifted immediately. Works for offline players too.

### Blacklist File
- The blacklist is stored in `addons/amxmodx/configs/blacklist/blacklist.txt`.
- The directory is automatically created if it doesn't exist.
- SteamIDs in this file are loaded into memory at the start of each map, and the file is updated with the current blacklist when the map ends.

### Example
1. An admin types `/blacklist` in chat.
2. The menu opens, showing all online players (e.g., "Player1", "Player2 [Blacklisted]").
3. The admin selects "Player1" to add them to the blacklist.
4. Player1 is immediately frozen, their chat and voice are blocked, and they cannot use the C4.
5. At the end of the map, Player1's SteamID is saved to `blacklist.txt`.
6. On the next map, Player1 joins and is automatically frozen again.
7. Alternatively, an admin uses `amx_blacklist "STEAM_0:1:12345678"` in the console to blacklist an offline player. When that player joins, they are frozen immediately.
8. To remove the blacklist, the admin uses `amx_unblacklist "STEAM_0:1:12345678"`, and if the player is online, the restrictions are lifted instantly.

## Authors

- **ftl~ツ**
- **WESPEOOTY**