local KeyBind = require 'engine.KeyBind'

class:bindHook('ToME:load', function(self, data)
  KeyBind:defineAction {
    default = { 'sym:_x:false:false:false:false' },
    type = 'AUTO_FIGHT',
    group = 'actions',
    name = 'Auto Fight Button',
  }
end)
