# In-Game AddOn Manager

A lightweight in-game manager for finding, enabling, and disabling World of Warcraft AddOns without returning to the character-selection screen.

## Features

- View installed AddOns while logged into the game
- Search by AddOn name, title, author, or description
- Enable or disable individual AddOns
- Enable or disable all optional AddOns
- Reload the interface to apply changes
- Open from the Escape menu with the **AddOn Manager** button
- Open directly with `/iga`
- Keeps the manager itself enabled so it remains available after reloading

## Supported versions

| Branch | Game client | Interface |
|---|---|---:|
| [`classic`](../../tree/classic) | Vanilla / Classic 1.12.1 | 11200 |
| [`tbc`](../../tree/tbc) | The Burning Crusade 2.4.3 | 20400 |
| [`wotlk`](../../tree/wotlk) | Wrath of the Lich King 3.3.5a | 30300 |

Choose the branch that matches your game client.

## Installation

1. Open the branch for your game version.
2. Select **Code**, then **Download ZIP**.
3. Extract the `IGA` folder into your World of Warcraft `Interface/AddOns` folder.
4. Restart the game or reload the interface.

The installed files should be located at:

```text
Interface/AddOns/IGA/IGA.toc
Interface/AddOns/IGA/IGA.lua
```

## Usage

Open the Escape menu and select **AddOn Manager**, or type:

```text
/iga
```

Check or uncheck AddOns, then choose **Reload UI** to apply the changes.

## Version

Current release: **1.1.0**
