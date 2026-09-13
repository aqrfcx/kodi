import json
import os
import subprocess
import sys
from urllib.parse import parse_qs, urlencode, urlparse

import xbmcgui
import xbmcplugin

HANDLE = int(sys.argv[1])
BASE_URL = sys.argv[0]
CATALOG = '/run/kodi-os/games.json'
LAUNCHER = '/usr/sbin/kodi-os-game-launcher'


def load_games():
    try:
        with open(CATALOG, 'r', encoding='utf-8') as f:
            return json.load(f).get('games', [])
    except (OSError, ValueError, TypeError):
        return []


def query():
    return parse_qs(urlparse(sys.argv[2]).query)


def add_item(label, path, playable=False, folder=None):
    item = xbmcgui.ListItem(label=label)
    if playable:
        item.setProperty('IsPlayable', 'true')
        item.setContentLookup(False)
    xbmcplugin.addDirectoryItem(
        HANDLE,
        path,
        item,
        isFolder=(not playable if folder is None else folder),
    )


def url(params):
    return BASE_URL + '?' + urlencode(params)


def launch(path):
    if not os.path.isfile(path):
        xbmcgui.Dialog().notification('Kodi OS Games', 'Game file is no longer available')
        return
    try:
        result = subprocess.run(
            [LAUNCHER, path],
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        if result.returncode != 0:
            message = result.stderr.strip() or 'Unable to launch game'
            xbmcgui.Dialog().ok('Kodi OS Games', message[-500:])
    except OSError as exc:
        xbmcgui.Dialog().ok('Kodi OS Games', str(exc))


def main():
    games = load_games()
    args = query()
    platform = args.get('platform', [None])[0]
    selected = args.get('game', [None])[0]

    if selected:
        launch(selected)
        xbmcplugin.endOfDirectory(HANDLE, succeeded=True)
        return

    if platform:
        items = [g for g in games if g.get('platform') == platform]
        for game in sorted(items, key=lambda g: g.get('name', '').lower()):
            path = game.get('path', '')
            add_item(game.get('name', 'Unknown game'), url({'platform': platform, 'game': path}), playable=True)
        xbmcplugin.setContent(HANDLE, 'files')
        xbmcplugin.endOfDirectory(HANDLE)
        return

    if not games:
        add_item('No games found in /storage/roms', '', folder=False)
        xbmcplugin.endOfDirectory(HANDLE)
        return

    platforms = sorted({g.get('platform', 'unknown') for g in games})
    for name in platforms:
        count = sum(1 for g in games if g.get('platform') == name)
        add_item(f'{name.upper()} ({count})', url({'platform': name}), folder=True)

    xbmcplugin.setContent(HANDLE, 'files')
    xbmcplugin.endOfDirectory(HANDLE)


if __name__ == '__main__':
    main()
