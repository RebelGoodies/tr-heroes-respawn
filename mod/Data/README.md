# Heroes Respawn (TR 3.2)

## How to launch this mod

1. Download Thrawns Revenge 3.2 from ModDB and extract it to your Mods folder as `TR32`.
   - https://www.moddb.com/mods/thrawns-revenge/downloads/steam-thrawns-revenge-32

2. Create a new folder in the Mods folder called `Respawn`, place `Data3.2` into it, and rename it to `Data`.
   - Example path: `C:\Program Files (x86)\Steam\steamapps\common\Star Wars Empire at War\corruption\Mods\Respawn\Data`

3. Set launch options:

```
ModPath=Mods\Respawn ModPath=Mods\TR32
```

---

## Description

**For those who love heroes!**

### About

- Most heroes under **50 population** (including AI) respawn on a **15 week timer** when "killed" while keeping era progression intact.
- This is intended for weaker heroes that die frequently and can be disabled mid-campaign via `GameConstants.xml`.
- Any special respawns remain unchanged.

---

### Exceptions to respawn

- All heroes over **49 population** will not respawn for balancing and player sanity.
- Some Imperial heroes do not respawn for story purposes.
- If a warlord faction gets integrated, their heroes not alive at that moment are gone.

---

### Recruitable heroes

New Republic recruitable commanders (under 50 pop) get added back to the list some time after their death so you can recruit them again.
For example, if Admiral Ackbar dies in his smaller 33 pop ship, you can recruit him again.
If he dies in his 58 pop Home One, he is gone for good.
(This feature is not affected by `GameConstants.xml`.)

---

### One Planet Start

Heroes spawn at the beginning of FTGU single-planet start games, matching the selected era.

---

### How to edit GameConstants

How to edit the time for a respawn:

1. Go to: `Steam\steamapps\workshop\content\32470\2802599273\Data\XML`
2. Open `GameConstants.xml`
3. Find the line 417: `<Default_Hero_Respawn_Time>600.0</Default_Hero_Respawn_Time>`
4. You can set it to a negative number to deactivate it between saved games.

---

# Credits

- Thanks to the EaWX team for their main mod.
- **Disclaimer**: This submod is not associated with the EaWX team.
