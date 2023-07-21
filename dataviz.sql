CREATE OR REPLACE FUNCTION dataviz(_tbl regclass, xaxis jsonb default NULL, yaxis jsonb default '{"type":"value"}', legend jsonb DEFAULT '{"top":"bottom"}', title jsonb DEFAULT '{}', tooltip jsonb DEFAULT '{}')
RETURNS jsonb 
LANGUAGE plpgsql
AS 
$$
-- Jean-Baptiste DESBAS, 2023 jb@desbas.fr
-- Passer en argument le nom d'une table (ou vue ou table temporaire)
-- La table doit avoir un champs x et y
-- Champs supportés : x, y, stack, serie, type
DECLARE myout TEXT;
DECLARE opt jsonb;
DECLARE jsdata jsonb;
DECLARE js_series_array jsonb;
DECLARE js_serie jsonb;
e record;
s record;
xtype TEXT;
ytype TEXT;
BEGIN	
	DISCARD PLANS; -- Pour éviter les erreurs si on utilise plusieurs fois la fonction avec le même nom de table mais des datatypes différents (table temporaire par ex)

	EXECUTE FORMAT('SELECT pg_typeof(x)::text FROM  %I LIMIT 1',  _tbl) INTO xtype;
	EXECUTE FORMAT('SELECT pg_typeof(y)::text FROM  %I LIMIT 1',  _tbl) INTO ytype;

	--Paramètre auto des axes selon les datatype des données et les types de graphique
	
	IF xaxis IS NULL THEN -- Auto
		IF xtype IN ('smallint', 'integer', 'bigint', 'numeric', 'real', 'double precision') THEN xaxis:='{"type":"value"}';
		ELSIF  xtype IN ('timestamp', 'timestamptz', 'date') THEN xaxis:='{"type":"time"}';
		ELSE xaxis:='{"type":"category"}';
		END IF;
	END IF;
	
	--TODO ajouter les colonnes manquantes avec un NATURAL FULL JOIN
	js_series_array = '[]'::jsonb;
	FOR s IN EXECUTE(FORMAT('SELECT DISTINCT ON(serie) serie, stack, type FROM %I', _tbl) )
	LOOP
		jsdata = '[]'::jsonb;
		FOR e IN EXECUTE(FORMAT('SELECT x, y FROM %I WHERE serie=%L and type=%L ORDER BY x', _tbl, s.serie, s."type") )
		LOOP
			IF s."type" = 'pie' THEN jsdata =  jsdata || jsonb_build_object('name', e.x, 'value', e.y );
			ELSE jsdata = jsdata || jsonb_build_array(jsonb_build_array(e.x, e.y));
			END IF;
		END LOOP;
		js_serie = jsonb_build_object('name',s.serie, 'stack', s.stack, 'type', s."type", 'data', jsdata);
		js_series_array = js_series_array || js_serie;
	END LOOP;
	opt = jsonb_build_object(
	'title',
		title,
	'legend',
		legend,
	'tooltip',
		tooltip,
	'xAxis', 
		xaxis,
	'yAxis',
		yaxis ,
	'series', js_series_array
	);
	 RETURN opt;
END;
$$;

CREATE OR REPLACE FUNCTION dataviz_page(charts_opt_arr _jsonb)
RETURNS text 
LANGUAGE plpgsql
AS 
$function$
-- Jean-Baptiste DESBAS, 2023 jb@desbas.fr
-- Génère une page html prête à l'emploi
-- Passer en argument un tableau (_jsonb) contenant les options des graphiques (générés avec dataviz())
DECLARE 
	i INTEGER := 0;
	dataviz_content TEXT := '';
	c jsonb;
BEGIN 
	FOREACH c IN ARRAY charts_opt_arr LOOP 
		dataviz_content := concat(dataviz_content,format('<div id="chart_%1$s" style="width: 600px; height: 400px;"></div>
				<script>
			        const chart_%1$s = echarts.init(document.getElementById("chart_%1$s"));
					chart_%1$s.setOption(%2$s)
				</script>', i::TEXT, c::text ));
		i := i + 1; 
	END LOOP;
	
	RETURN format('<!DOCTYPE html>
	<html>
	<head>
	    <meta charset="utf-8">
	    <title>Graphique Apache ECharts</title>
	    <!-- Charger la bibliothèque ECharts depuis un CDN -->
	    <script src="https://cdn.jsdelivr.net/npm/echarts@5.1.2/dist/echarts.min.js"></script>
	</head>
	<body>
	%s
	</body>
	</html>',dataviz_content);
END;
$function$;


