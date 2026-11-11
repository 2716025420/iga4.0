class_name TerritoryButton
extends Button

var region_id := "campus"

func _has_point(point: Vector2) -> bool:
 return Geometry2D.is_point_in_polygon(point,RegionCatalog.territory(region_id))
