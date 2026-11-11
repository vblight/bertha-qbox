# v5.4 — Native QB inventory skips

Replace the entire `bertha_recycling` folder. Search skips via qb-target to open a normal two-sided qb-inventory stash. Shared stash IDs are generated server-side from world coordinates. Loot is seeded on first open and restocked only when the stash is empty and its cooldown has expired. Existing auto-carry, worker, Bertha, queue, glass and audio retained.

**Important:** This uses the current qb-inventory server exports `CreateInventory`, `GetInventory`, `AddItem`, and `OpenInventory`. Older forks may differ. Native qb-inventory stashes allow depositing arbitrary items unless an inventory-side move hook restricts them. Thus this build does **not** enforce the previous recycling-only deposit rule. Do not use as unrestricted public storage in production until deposit restrictions and stash access security are verified against your qb-inventory fork.

Test on your test server first. A stash may persist via qb-inventory's database even when the recycling resource restarts.
