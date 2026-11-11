# Big Bertha Recycling v5.3 — Searchable Containers & Auto-Carry

Full replacement of the v5.2 `bertha_recycling` resource. Uses QBCore, qb-target, qb-inventory; no ox_lib.

## What's new
- Search an industrial skip using qb-target; after the existing search animation, a compact black-glass container inventory opens.
- Server generates shared loot (existing 65% search chance; successful finds: 35% glass chunks 1–4, otherwise used tires 1–3).
- Take individual quantities, use MAX IN SKIP, return approved items, or use MAX IN POCKETS. Items are transferred server-side and checked for inventory space.
- Approved deposits: `used_tyre`, `glass_chunks`, `plastic_scraps`, `rubber`. Other items are rejected.
- Shared container contents are held in server memory; empty skips restock after the configured 10-minute cooldown. Contents **reset on resource/server restart**; do not use as permanent storage.
- Having at least one `used_tyre` in QB inventory automatically shows a single carried tire prop; loading or removing the final tire clears the prop. No manual carry command needed.

## Install
1. Stop `bertha_recycling`.
2. Replace the whole folder with this one.
3. Ensure `qb-core`, `qb-inventory` and `qb-target` start first, then `ensure bertha_recycling`.
4. Existing QB item names remain unchanged. Glass item definitions from v5.1 are still required.

## Notes
- This is a **custom small container UI**, not the native two-pane qb-inventory drag/drop interface. It provides quantity and MAX controls for take and return.
- This implementation trusts the client-supplied world prop coordinates for the search interaction and checks proximity server-side. For public-server anti-exploit hardening, use a server-side allowlist of container positions or networked entities.
- This version has not been run inside FiveM. Test skip contents, transfers, auto-carry, van loading and Bertha intake before deployment to the main server.
