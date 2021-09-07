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



CREATE OR REPLACE FUNCTION remove_parentheses(_input_text TEXT, _typo text[] DEFAULT NULL )
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--JB Desbas, Picardie Nature. 2021-09-07.
--Supprimer les parenthesis (), brackets [] et braces {} ainsi que leur contenu.
--_typo (text[]) : liste de delimiteurs à utiliser. Laisser NULL pour tous. Valeurs possibles : 'brackets','[]', 'braces', '{}',  'parentheses', '()' 
--Pour des raisons techniques, la fonction nettoie aussi les doubles espaces en bout de chaine (trim) et à l'intérieur
--Supporte les imbrications jusqu'à 3 niveau (niveau1(niveau2(niveau3)))
DECLARE
  _text_output text;
  _invalids_args TEXT[];
  _typo_possible_values TEXT[] := ARRAY['brackets','[]','parentheses','()','braces','{}'];
BEGIN
    _text_output = _input_text;

    SELECT INTO _invalids_args array_agg(a.v) AS invalid_args FROM
        (SELECT UNNEST(_typo) AS v EXCEPT SELECT unnest(_typo_possible_values) AS v) a; 
    IF _invalids_args IS NOT NULL 
        THEN RAISE EXCEPTION 'Invalid arg : %' , _invalids_args 
                USING HINT = 'please use only ' || _typo_possible_values::text;
    END IF;
    
    IF ARRAY['brackets','[]'] && _typo IS NOT FALSE 
        THEN _text_output = regexp_replace(_text_output, '\[(?:[^\]\[]|\[(?:[^\]\[]|\[[^\]\[]*\])*\])*\]', ' ', 'g');
    END IF;
    IF ARRAY['parentheses','()'] && _typo IS NOT FALSE 
        THEN _text_output = regexp_replace(_text_output,  '\((?:[^)(]|\((?:[^)(]|\([^)(]*\))*\))*\)' , ' ', 'g');
    END IF;
    IF ARRAY['braces','{}'] && _typo IS NOT FALSE 
    THEN _text_output = regexp_replace(_text_output, '\{(?:[^\}\{]|\{(?:[^\}\{]|\{[^\}\{]*\})*\})*\}' , ' ', 'g');
    END IF;

    RETURN btrim(regexp_replace(_text_output, '\s+', ' ', 'g'));
END;
$function$
;
