# Blacklist

A custom AMX Mod X plugin developed for my personal 4Fun Counter-Strike 1.6 server.

## Description

This plugin implements a blacklist system where specific players (usually cheaters or disruptive users) can be prevented from playing without being outright banned.

Instead of kicking or banning the player, this plugin allows them to join the server but applies the following punishments:

- They are completely frozen and unable to move or shoot.
- Their chat is blocked.
- Voice communication is disabled for them.
- If they spawn with the C4 bomb, it is automatically dropped and planting is disabled.

This creates a frustrating yet effective punishment: the player joins, but cannot play — they remain stuck at spawn, unable to act, and can be easily killed by others.

## Usage

Admins with `ADMIN_IMMUNITY` access can use the command:

- `/blacklist` in chat to open the menu.

From the menu, they can add or remove online players from the blacklist. The blacklist is stored in:

``addons/amxmodx/configs/blacklist/blacklist.txt``

SteamIDs listed in this file will be automatically frozen upon joining.

## **Authors**

- **ftl~ツ**
- **WESPEOOTY**