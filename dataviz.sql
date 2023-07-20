CREATE OR REPLACE FUNCTION dataviz(_tbl regclass)
RETURNS TEXT 
LANGUAGE plpgsql
AS 
$$
-- Jean-Baptiste DESBAS, 2023 jb@desbas.fr
-- Passer en argument le nom d'une table (ou vue ou table temporaire)
-- La table doit avoir un champs x et y
-- TODO plusieurs séries, différentes options de graphiques (type de représentation, stack ou non)
-- TODO créer une page complète (avec balises html, import lib, etc)
DECLARE myout TEXT;
DECLARE opt jsonb;
DECLARE jsdata jsonb;
e record;
BEGIN	
	jsdata = '[]'::jsonb;
	FOR e IN EXECUTE(FORMAT('SELECT x, y FROM %I', _tbl) )
	LOOP
		jsdata = jsdata || jsonb_build_array(e.x, e.y);
	END LOOP;
	
	opt = jsonb_build_object(
	'xAxis', 
		jsonb_build_object('type','time'),
	'yAxis',
		jsonb_build_object('type','value') ,
	'series', jsonb_build_array(
		jsonb_build_object('type','bar',
			'data',
				jsdata
			) 
		) 
	);
	 RETURN opt;
END;
$$;
