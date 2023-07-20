CREATE OR REPLACE FUNCTION dataviz(_tbl regclass, xaxis jsonb default '{"type":"time"}', yaxis jsonb default '{"type":"value"}')
RETURNS jsonb 
LANGUAGE plpgsql
AS 
$$
-- Jean-Baptiste DESBAS, 2023 jb@desbas.fr
-- Passer en argument le nom d'une table (ou vue ou table temporaire)
-- La table doit avoir un champs x et y
-- Champs supportés : x, y, stack, serie
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
	FOR s IN EXECUTE(FORMAT('SELECT DISTINCT serie, stack FROM %I', _tbl) )
	LOOP
		jsdata = '[]'::jsonb;
		RAISE INFO '%', (FORMAT('SELECT x, y, serie FROM %I WHERE serie=%L ORDER BY x', _tbl, s.serie) );
		FOR e IN EXECUTE(FORMAT('SELECT x, y, serie FROM %I WHERE serie=%L ORDER BY x', _tbl, s.serie) )
		LOOP
			RAISE INFO '%', e; 
			jsdata = jsdata || jsonb_build_array(jsonb_build_array(e.x, e.y));
		END LOOP;
		js_serie = jsonb_build_object('name',s.serie, 'stack', s.stack, 'type', 'bar', 'data', jsdata);
		js_series_array = js_series_array || js_serie;
	END LOOP;
	opt = jsonb_build_object(
	'xAxis', 
		xaxis,
	'yAxis',
		yaxis ,
	'series', js_series_array
	);
	 RETURN opt;
END;
$$;
