fx_version 'cerulean'
game 'gta5'

author 'Pin Cobra'
description 'Thương nhân xuất hiện ngẫu nhiên'
version '2.0.0'

lua54 'yes'

shared_scripts { 
    '@es_extended/imports.lua',
    'config.lua' 
}
client_scripts { 'client.lua' }
server_scripts { 'server.lua' }

dependencies { 'es_extended', 'ox_inventory', 'ox_target', 'ox_lib' }
