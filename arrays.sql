----

CREATE FUNCTION public.array_distinct(anyarray)
 RETURNS anyarray
 LANGUAGE sql
 IMMUTABLE
AS $function$
  """Return an array with no duplicates values """
  SELECT array_agg(DISTINCT x) FROM unnest($1) t(x);
$function$
;

----

CREATE FUNCTION public.array_sort_and_unique(_arrayval anyarray, _arraykey integer[]) --TODO biginterger plutot ?
 RETURNS anyarray
 LANGUAGE sql
 IMMUTABLE STRICT
AS $function$
	--trier le tableau 1 avec les clés (int) présentes dans le tableaux 2. Supprime les doublons (garde la clé la plus petite).
	--Exemple d'utilisation : lors d'une aggregation spatiale, formatage des noms d'observateur du plus récent au plus ancien ( -1*(epoch/1000) pour la clé)
 	--_arrayval : array_agg(identobs) ; _arraykey : arrayg_agg(-1*(epoch/1000) )
	WITH a AS (
		SELECT 
		 _arrayval AS t1,
		 _arraykey AS t2
		), b AS (
		SELECT 
		 unnest(t1) AS u1,
		 UNNEST(t2) AS u2
		FROM a 
		), c AS (
		SELECT DISTINCT ON (u1)
		u1,u2
		FROM b ORDER BY u1, u2
		)
		SELECT 
			array_agg(u1 ORDER BY u2) 
		FROM c;
$function$
;

----

--Cf https://www.postgresql-archive.org/Problem-with-custom-aggregates-and-record-pseudo-type-td5037659.html
 CREATE AGGREGATE public.array_accum(anyarray) (
  sfunc = array_cat, 
  stype = anyarray, 
  initcond = {}
);
COMMENT ON AGGREGATE public.array_accum(anyarray) IS 'Exemple : 
SELECT array_accum(i) from (values (ARRAY[1,2]), (ARRAY[3,4])) as t(i);
array_accum
-------------
{1,2,3,4}';

----
 	
