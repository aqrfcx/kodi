import json
import os
import subprocess
import sys
import xbmcgui
import xbmcplugin

HANDLE = int(sys.argv[1])
CATALOG = '/run/kodi-os/games.json'
LAUNCHER = '/usr/sbin/kodi-os-game-launcher'


def load_games():
    try:
        with open(CATALOG, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return data.get('games', [])
    except (OSError, ValueError):
        return []


def add_item(label, path, playable=False):
    item = xbmcgui.ListItem(label=label)
    if playable:
        item.setProperty('IsPlayable', 'true')
    xbmcplugin.addDirectoryItem(HANDLE, path, item, isFolder=not playable)


def main():
    games = load_games()
    if not games:
        add_item('No games found in /storage/roms', '')
        xbmcplugin.endOfDirectory(HANDLE)
        return

    platforms = sorted({g.get('platform', 'unknown') for g in games})
    for platform in platforms:
        add_item(platform.upper(), f'{sys.argv[0]}?platform={platform}')

    xbmcplugin.endOfDirectory(HANDLE)


if __name__ == '__main__':
    main()
