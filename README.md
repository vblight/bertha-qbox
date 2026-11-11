# Big Bertha Recycling — Qbox Edition

> **Experimental / community testing — Qbox compatibility is not verified.**
>
> Big Bertha Recycling was originally developed and tested on **QBCore** with `qb-inventory` and `qb-target`. This repository is a conversion intended for **Qbox**, **ox_inventory**, **ox_target**, and **ox_lib**. The developer does not currently have a Qbox test server. Inventory transactions, searchable containers, tire carrying, NPC interactions, vehicle keys, and other framework-specific features may require additional fixes. **Do not install on a production server without testing and backups.**

## Features

Big Bertha is an industrial recycling and manufacturing system for FiveM, with a transparent machining UI, recipe queue, tire shredding, plastic pellets, rubber rolls, glass processing, searchable skips, and an independent recycling van with a 24-tire load.

The separate `bertha_boxville` add-on vehicle uses the spawn name `rboxville`, with a branded livery and automatic rear doors near the loading area. Box Man handles recycling-box exchanges and fleet checkout.

## Requirements

- Qbox (`qbx_core`)
- `ox_inventory`
- `ox_target`
- `ox_lib`
- A compatible vehicle-key solution, configured for your server

## Installation

1. Download or clone the repository **once the resource files are uploaded**.
2. Install `bertha_boxville` and `bertha_recycling` as separate resources.
3. Add the item definitions from `bertha_recycling/OX_ITEMS.lua` to your ox_inventory item data, reconciling any existing item names.
4. Check the configuration in `bertha_recycling/config.lua`, particularly Box Man's position, the van parking bay, and inventory item names.
5. Start the resources **after** Qbox, ox_lib, ox_inventory and ox_target:

```cfg
ensure ox_lib
ensure qbx_core
ensure ox_inventory
ensure ox_target
ensure bertha_boxville
ensure bertha_recycling
```

6. Test on a development server before going live.

## Compatibility and support

**Status: experimental; not Qbox-tested.** A successful resource start does not guarantee that item transfers, target interactions, persistence, vehicle keys or crafting work correctly. Please include server/client console errors and reproduction steps when reporting bugs.

The original QBCore edition is maintained separately at [vblight/bertha](https://github.com/vblight/bertha).

## Contributing

Qbox users are welcome to open issues and submit pull requests with tested compatibility fixes. Please avoid reporting speculative compatibility as verified.

## License

Check the included resource and vehicle asset licenses/permissions before redistribution or reuse.
