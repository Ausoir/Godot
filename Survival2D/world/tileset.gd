tool
extends TileSet

const BRICK = 20
const CUSTOM_BRICK = 12

var binds = {
	BRICK: [CUSTOM_BRICK],
	CUSTOM_BRICK: [BRICK]
}

func _is_tile_bound(id, nid):
	return true
