CREATE OR REPLACE FUNCTION gn_imports.transform_ff_username(username text)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--JB Desbas, Picardie Nature. 2020-12-15. Permet de transformer les noms FF (Prénom Nom)
-- en noms "SINP" (NOM Prénom). Gèere aussi les "Machine et Machine Dupont" ou "Machin & Machine Dupont"
BEGIN
	RETURN (SELECT replace(btrim(concat_ws(' '::text, upper(x.o[2]), x.o[1])), 'auteur non diffusé'::text, 'ANONYME'::text) AS replace
           FROM ( SELECT regexp_matches(username, '^([^\s]+(?:(?:\set\s|\s?&\s?)[^\s]+)?)\s*(.*)$'::text) AS o) AS x);
END;
$function$
;
