CREATE FUNCTION ST_intersection_if_not_null(geoma geometry, geomb geometry) 
RETURNS geometry 
LANGUAGE SQL
IMMUTABLE
AS $function$
    -- Jean-Baptiste DESBAS, 2022 jb@desbas.fr
    -- Return st_intersection if both geometries are not null. Else return the non-null geometry.
    SELECT 
        CASE WHEN geoma IS NULL THEN geomb
        WHEN geomb IS NULL THEN geoma 
        ELSE st_intersection(geoma, geomb) END 
$function$;

SELECT 
    ST_intersection_if_not_null(
        (SELECT geom FROM ref_geo.l_areas la WHERE id_area = 40220),
        (SELECT geom FROM ref_geo.l_areas la WHERE id_area = 730)
);
