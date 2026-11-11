# Box Man Fleet Desk — Test Build

The existing recycling-box worker now also handles the recycling van. Target him with `qb-target`:

- **Collect Recycling Van** — server-spawns one shared `rboxville`, assigns keys using `qb-vehiclekeys` if enabled.
- **Return Recycling Van** — requires the van to be near the worker and **empty**; this protects its saved tire cargo.
- **Check Van Cargo** — shows the existing 24-tire cargo counter.
- **Break Down Recycling Boxes / MAX** — unchanged.

Configure the parking bay in `config.lua`:

```lua
Config.Fleet = {
    enabled = true,
    spawn = vector4(-460.5, -1675.0, 18.7, 90.0),
    interactDistance = 4.0,
    clearRadius = 4.0,
    requireEmptyToReturn = true,
}
```

**The parking position is a provisional coordinate, not a verified free parking bay.** If it is obstructed or badly positioned, change `Config.Fleet.spawn` before testing again.

One shared van is permitted because the existing cargo persistence uses one fixed plate (`RECYCLE1`). The debug `/recyclevan` command is disabled while fleet management is enabled, to avoid duplicate plates. This version does not yet provide per-player fleet ownership or respawn an existing checked-out van after resource restart. A restart with a van still in the world may require cleanup before testing again.

This package is for local FiveM testing. The GitHub repository has **not** been changed.

## Latest placement changes

- Box Man uses fixed `coords.z + zOffset` rather than automatic ground detection; default `zOffset = -0.65`. Fine-tune this number in `Config.SalvageWorker`.
- Van spawn is exactly `vector4(-468.803, -1678.039, 19.050, 179.68)` facing south.
- Fleet van is forced to the first livery (zero-based index 0).
- Primary `rboxville` vehicle audio hash is `BOXVILLE`; edit to `RUMPO` in `bertha_boxville/common/vehicles.meta` if necessary.

This has not been tested inside FiveM.
