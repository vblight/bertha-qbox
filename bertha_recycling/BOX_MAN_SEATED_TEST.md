# Seated Box Man test

Dock worker NPC and industrial chair now use fixed coordinates beside Bertha. No ground probe or invalid native. All five qb-target actions are retained.

- Worker: `s_m_m_dockwork_01`
- Chair: `prop_chair_02`
- Default position: `vector4(-472.2, -1668.8, 18.951, 90.0)`
- Sitting scenario: `PROP_HUMAN_SEAT_CHAIR_MP_PLAYER`

**Placement is provisional** because the exact clear floor next to the machine cannot be confirmed from screenshots. If the chair clips, adjust `Config.SalvageWorker.coords`, `chairOffset`, or `zOffset` in `config.lua`. The scenario seat position and prop may need small offsets for alignment.

The vehicle spawn, BOXVILLE audio, first-livery lock, 24-tire cargo and fleet options remain unchanged. GitHub has not been updated.
