> **QBOX COMPATIBILITY NOTICE:** Experimental conversion from a QBCore-tested resource. Not tested on a Qbox server; compatibility fixes may be needed. See the repository root README for details.

# Big Bertha Recycling v5.1 — Glass
Complete replacement `bertha_recycling` resource for QBCore / qb-inventory / qb-target. No ox_lib.

1. Paste entries from `QB_ITEMS_GLASS.lua` into `QBShared.Items` in `qb-core/shared/items.lua`.
2. Add `glass_chunks.png` and `glass_sheets.png` to your qb-inventory images, or change their image names to existing icons.
3. Replace the `bertha_recycling` folder and restart the server; test data need not be migrated.

Glass recipe: 8 `glass_chunks` -> 1 `glass_sheets` in 60 seconds. Intake 160 chunks, output 20 sheets. Glass chunks weigh 2.5kg and glass sheets weigh 20kg. Skips retain 65% chance to find something; successful searches give glass (35%, 1–4 chunks) or used tires (65%, 1–3 tires). Ten-minute shared skip cooldown retained.

New glass intake, pocket quantity/MAX, withdrawal, crafting tab, queue, output collection, persistent storage. Existing rubber, tire and plastic processing remains. No furnace effects yet. FiveM in-game testing is required.

## v5.2 Temporary recycling-box worker
- Spawns at a configurable point near Bertha at Rogers Scrapyard; change `Config.SalvageWorker.coords` if needed.
- Uses qb-target with quantity entry or MAX (up to 25 boxes per exchange).
- Test item: `recycling_box_test`. Add definition from `QB_ITEMS_TEMP_BOX.lua` to qb-core items. Point image at an existing icon if you don't have a matching PNG.
- Rewards ONLY `rubber`, `plastic_scraps`, or `glass_chunks`; one randomly selected reward type per box, configurable weighted rates and quantities.
- The server validates proximity and item quantity, removes boxes and attempts to refund on inventory-add failure. Inventory failures should be tested with nearly full pockets.
- To migrate, change `Config.SalvageWorker.boxItem` to the real legacy item ID. Disable with `enabled=false`.
- No dependency on qb-recyclejob or ox_lib.
