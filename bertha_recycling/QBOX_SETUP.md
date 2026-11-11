> **QBOX COMPATIBILITY NOTICE:** Experimental conversion from a QBCore-tested resource. Not tested on a Qbox server; compatibility fixes may be needed. See the repository root README for details.

# Big Bertha — Qbox / ox conversion (test build)

This is a **separate Qbox edition**. Do not overwrite your known-good QB edition on the production server until you have tested this one. The vehicle resource `bertha_boxville` is unchanged.

## Requirements

- `qbx_core`, `ox_lib`, `ox_target`, `ox_inventory`
- FiveM OneSync enabled for the server-created fleet vehicle
- `bertha_boxville` vehicle resource

Start the resources in dependency order, for example:

```cfg
ensure ox_lib
ensure qbx_core
ensure ox_target
ensure ox_inventory
ensure bertha_boxville
ensure bertha_recycling
```

Your Qbox installation may have additional dependencies; keep its standard start order. **Do not run the old QB recycling resource alongside this edition.**

## Inventory items

Add missing entries from `OX_ITEMS.lua` to `ox_inventory/data/items.lua` (inside its return table). The provided file is a snippet, **not** a standalone resource. Do not duplicate names already defined by Qbox/ox_inventory. For test items, use the inventory's admin item-giving workflow. The original `recycling_box_test` is temporary; replace `Config.SalvageWorker.boxItem` with your live box name later.

## Converted systems

- `ox_target` for Big Bertha, loose tires, industrial skips, van loading, and Box Man
- `ox_inventory` for tire carry counts, input/output, box exchange and native skip stashes
- `ox_lib` notifications and cancellable progress bars
- `qbx_core` job checks when `Config.RequireJob` is enabled
- Same production queue, UI, cargo persistence, 24-tire van and automatic rear doors

## Known integration details / first tests

1. **Vehicle keys:** `Config.VehicleKeys = 'none'` because Qbox servers vary in their key system. The fleet vehicle will spawn, but you must connect your Qbox vehicle-key resource before players can drive it if keys are enforced. Do not simply re-enable the QB event names.
2. **Skip stash initialization:** Registered ox stashes are opened using `openInventory('stash', id)`. Test taking and returning loot, then reopening the same skip. ox_inventory's stash persistence depends on its configured database.
3. **Carry animation:** The script checks ox_inventory counts when inventory updates and every 1.5 seconds. Test whether this conflicts with your server's custom animations.
4. **NPC:** Fixed Box Man Z and south heading retained. Test targeting after resource restart.
5. **Fleet:** One shared `RECYCLE1` van. Verify that it spawns at `vector4(-468.803, -1678.039, 19.050, 179.68)` and opens rear doors on approach.
6. **Security:** This preserves the prototype's existing client-supplied skip coordinates. Before public release, validate that the searched entity is a configured skip model server-side, and consider a stash access hook to limit item deposits.
7. **Legacy state:** The machine and vehicle cargo save files are separate from ox_inventory stash storage. Back them up before migrating existing data.

This build has been inspected and packaged but **not run on a live Qbox server**. GitHub has not been changed by this conversion.
