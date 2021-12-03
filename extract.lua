/c local list = {}
for _, recipe in pairs(game.player.force.recipes) do
  list[#list+1] = {
    name = recipe.name,
    category = recipe.category,
    ingredients = recipe.ingredients,
    products = recipe.products,
    energy = recipe.energy
  }
end
game.write_file("recipes.json", game.table_to_json(list))
-- game.write_file("recipes.lua", serpent.block(list))

/c game.write_file("test.lua", serpent.block(game.item_prototypes["iron-plate"]))

/c game.write_file("test.lua", serpent.block(game.item_prototypes["iron-plate"]).icon)
