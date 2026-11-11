fx_version 'cerulean'
game 'gta5'
lua54 'yes'
name 'bertha_recycling'
description 'Independent tyre recycling prototype - Qbox, ox_inventory, ox_target, persistent Boxville cargo'
version '0.4.0-qbox-test'
shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'bridge/client.lua', 'client/main.lua', 'client/salvage_worker.lua' }
server_scripts { 'bridge/server.lua', 'server/main.lua', 'server/salvage_worker.lua', 'server/fleet.lua' }
dependencies { 'qbx_core', 'ox_lib', 'ox_target', 'ox_inventory' }

ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/app.js', 'html/machinery-hum.mp3' }
data_file 'DLC_ITYP_REQUEST' 'stream/prop_rubber_shredder.ytyp'
