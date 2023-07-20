CREATE OR REPLACE FUNCTION dataviz(_tbl regclass)
RETURNS jsonb 
LANGUAGE plpgsql
AS 
$$
-- Jean-Baptiste DESBAS, 2023 jb@desbas.fr
-- Passer en argument le nom d'une table (ou vue ou table temporaire)
-- La table doit avoir un champs x et y
-- TODO plusieurs séries, différentes options de graphiques (type de représentation, stack ou non)
DECLARE myout TEXT;
DECLARE opt jsonb;
DECLARE jsdata jsonb;
DECLARE js_series_array jsonb;
DECLARE js_serie jsonb;
e record;
s record;
BEGIN	
	--TODO ajouter les colonnes manquantes avec un NATURAL FULL JOIN
	js_series_array = '[]'::jsonb;
	FOR s IN EXECUTE(FORMAT('SELECT DISTINCT serie FROM %I', _tbl) )
	LOOP
		jsdata = '[]'::jsonb;
		RAISE INFO '%', (FORMAT('SELECT x, y, serie FROM %I WHERE serie=%L ORDER BY x', _tbl, s.serie) );
		FOR e IN EXECUTE(FORMAT('SELECT x, y, serie FROM %I WHERE serie=%L ORDER BY x', _tbl, s.serie) )
		LOOP
			RAISE INFO '%', e; 
			jsdata = jsdata || jsonb_build_array(jsonb_build_array(e.x, e.y));
		END LOOP;
		js_serie = jsonb_build_object('name',s.serie, 'type', 'bar', 'data', jsdata);
		js_series_array = js_series_array || js_serie;
	END LOOP;
	opt = jsonb_build_object(
	'xAxis', 
		jsonb_build_object('type','time'),
	'yAxis',
		jsonb_build_object('type','value') ,
	'series', js_series_array
	);
	 RETURN opt;
END;
$$;
