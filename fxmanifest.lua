fx_version 'cerulean'
game 'gta5'

author 'Pin Cobra'
description 'Thương nhân xuất hiện ngẫu nhiên'
version '1.0.0'

lua54 'yes' -- Kích hoạt Lua 5.4

shared_scripts { '@es_extended/imports.lua' }
client_scripts { 'client.lua' }
server_scripts { 'server.lua' }

dependencies { 'es_extended', 'ox_inventory', 'ox_target', 'ox_lib' }

