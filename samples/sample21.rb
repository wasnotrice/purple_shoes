require '../lib/purple_shoes'

Shoes.app width: 300, height: 100 do
  background forestgreen, curve: 30
  border gold, strokewidth: 5, curve: 30
  subtitle fg(strong('Shoes Shoes Shoes'), white), align: 'center'
end
