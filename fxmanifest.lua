fx_version 'cerulean'
games { 'gta5' }

author "Swkeep#7049"

ui_page 'ui/dist/index.html'

shared_scripts {
     '@ox_lib/init.lua',
     '@qb-core/shared/locale.lua',
     'locales/pt-br.lua',
     'config.lua',
     'shared/shared.lua',
     'shared/util.lua',
     'shared/badwords.lua' }

client_scripts {
     'client/framework.lua',
     'client/animator.lua',
     'client/functions.lua',
     'client/client.lua',
     'client/nui.lua',
     'client/nui_customization.lua',
     'client/nui_menus.lua',
     'client/menu.lua',
     'client/c_util.lua'
}

server_scripts {
     '@oxmysql/lib/MySQL.lua',
     'server/framework.lua',
     'server/functions.lua',
     'server/server.lua'
}

files {
  'ui/dist/index.html',
  'ui/dist/assets/**',
  'ui/dist/vite.svg',
  'inventory_images/*.png'
}
