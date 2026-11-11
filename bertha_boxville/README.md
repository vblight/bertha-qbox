# Bertha Boxville

Separate FiveM add-on vehicle resource for Big Bertha Recycling.

## Install

1. Put `bertha_boxville` into your resources directory.
2. Add `ensure bertha_boxville` **before** `ensure bertha_recycling` in `server.cfg`.
3. Spawn `rboxville` to test the recycling van. The original second variant remains available as `boxvilleretro2`.
4. `bertha_recycling/config.lua` is already configured with `Config.VehicleModel = 'rboxville'`.

This package renames the primary model's streamed `.yft` files and model metadata, while retaining its original texture dictionary names so existing texture references can resolve. The original GTA Boxville is not replaced.

**Important testing:** The new model name and livery need verification in FiveM. If the van is invisible, untextured, or fails to spawn, the original `.yft` may contain model-name references that require re-exporting in Sollumz. Test the livery, rear doors, collision, and wheel setup.

The 24 tire cargo offsets are unchanged from the working stock-Boxville build. They are configurable in `bertha_recycling/config.lua`; test alignment with a full load before treating it as final.

The second `boxvilleretro2` variant is retained unchanged, except for the shared resource folder name. Original model files/texture dictionaries are not replaced in the base game.

## Audio and livery

The primary `rboxville` model uses `<audioNameHash>BOXVILLE</audioNameHash>` in `common/vehicles.meta`. If your server build does not provide usable audio for `BOXVILLE`, change that entry to `RUMPO` and restart `bertha_boxville`.

The first livery is locked in `carvariations.meta` and enforced on the fleet van by `bertha_recycling` (livery index `0`, called **Livery 1** in many menus). This does not change the second `boxvilleretro2` variant.
