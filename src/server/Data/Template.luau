--[[
	Template.luau
	Template de datos para ProfileStore.
	Define todos los valores por defecto para nuevos jugadores.
]]

return {
	-- CannonGame Data
	Money = 0,
	SpeedLevel = 1,
	BestDistance = 0,
	CannonRebirths = 0,

	-- Pet Data
	EquippedPet = "", -- "" = ninguna, "Mouse" = nombre de mascota equipada
	OwnedPets = {}, -- Lista de nombres de mascotas obtenidas (ej: {"Mouse", "Bee", "Fox"})
}
