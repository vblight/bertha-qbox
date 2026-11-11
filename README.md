# Big Bertha Recycling — Qbox Edition

> **EXPERIMENTAL / UNTESTED ON QBOX**  
> Big Bertha was originally built and tested for **QBCore**, using `qb-inventory` and `qb-target`. This repository contains an attempted conversion for **Qbox (`qbx_core`), `ox_inventory`, `ox_target`, and `ox_lib`**. The maintainer does not currently have a Qbox server available for testing. **Full compatibility is not guaranteed.** Some conversions may need fixes before the resource works correctly.

This is a community-testing build, **not a production-ready or verified Qbox release**. Use a development server and back up your data before installation. In particular, verify inventory transfers and item names, searchable containers/stashes, crafting reservations and output collection, vehicle keys, NPC targeting, and fleet cargo persistence. Server-specific versions and configuration may require further changes. Bug reports and Qbox-tested fixes are welcome.

For the original QBCore edition, see [vblight/bertha](https://github.com/vblight/bertha).

## Included resources

- `bertha_recycling` — processing station, recycling interactions, and fleet management.
- `bertha_boxville` — separate `rboxville` vehicle resource.

## Installation

Read [`bertha_recycling/QBOX_SETUP.md`](bertha_recycling/QBOX_SETUP.md) and [`bertha_recycling/OX_ITEMS.lua`](bertha_recycling/OX_ITEMS.lua) before starting the resource. Install the required dependencies and configure the item definitions for your server. Start `bertha_boxville` before `bertha_recycling`.

**Compatibility status:** Experimental; requires independent Qbox validation.
