**Disclaimer**: This project is not affiliated with the EaWX team.

<img src="mod/Splash.png" alt="Splash image" width="128" style="float: right; margin-left: 1em; margin-bottom: 1em;">

# TR Heroes Respawn

For those who love heroes!

### About

- Most heroes under **50 population** (including AI) respawn on a **15 week timer** when "killed" while keeping era progression intact.
- This is intended for weaker heroes that die frequently and can be disabled mid-campaign via `GameConstants.xml`.
- Any special respawns remain unchanged.

### Exceptions to respawn

- All heroes over **49 population** will not respawn for balancing and player sanity.
- Some Imperial heroes do not respawn for story purposes.
- If a warlord faction gets integrated, their heroes not alive at that moment are gone.

### Recruitable heroes

New Republic recruitable commanders (under 50 pop) get added back to the list some time after their death so you can recruit them again.
For example, if Admiral Ackbar dies in his smaller 33 pop ship, you can recruit him again.
If he dies in his 58 pop Home One, he is gone for good.
(This feature is not affected by `GameConstants.xml`.)

### One Planet Start

Heroes spawn at the beginning of FTGU single-planet start games, matching the selected era.

### How to edit GameConstants

How to edit the time for a respawn:

1. Go to: `Data/XML`
2. Open `GameConstants.xml`
3. Find the line 417: `<Default_Hero_Respawn_Time>600.0</Default_Hero_Respawn_Time>`
4. You can set it to a negative number to deactivate it between saved games.

# License

All **original code** authored in this project is available under the [MIT License](LICENSE).

This repository depends on files derived from **EaWX mods**.
See [ASSETS.md](ASSETS.md) for details on third-party content and asset usage.

### Workshop Content

The `mod/` directory contains the files uploaded to the Steam Workshop.

# Credits

Thanks to the EaWX team for creating and maintaining the EaWX mods.
