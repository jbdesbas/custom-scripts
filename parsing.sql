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

CREATE OR REPLACE FUNCTION entity2char(t text)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE 
	AS $function$
	-- Jean-Baptiste DESBAS, Picardie Nature. 2021-11-16
	-- Permet de décoder les codes accent HTML (ex :  "&Agrave;"), présents au sein d'un texte, en charactères
	-- Adapted from https://stackoverflow.com/a/14985946/10995624

	declare
	    r record;
	    chars jsonb;
	BEGIN
	    chars = '[{"AElig" : "Æ"}, {"Aacute" : "Á"}, {"Acirc" : "Â"}, {"Agrave" : "À"}, {"Alpha" : "Α"}, {"Aring" : "Å"}, {"Atilde" : "Ã"}, {"Auml" : "Ä"}, {"Beta" : "Β"}, {"Ccedil" : "Ç"}, {"Chi" : "Χ"}, {"Dagger" : "‡"}, {"Delta" : "Δ"}, {"ETH" : "Ð"}, {"Eacute" : "É"}, {"Ecirc" : "Ê"}, {"Egrave" : "È"}, {"Epsilon" : "Ε"}, {"Eta" : "Η"}, {"Euml" : "Ë"}, {"Gamma" : "Γ"}, {"Iacute" : "Í"}, {"Icirc" : "Î"}, {"Igrave" : "Ì"}, {"Iota" : "Ι"}, {"Iuml" : "Ï"}, {"Kappa" : "Κ"}, {"Lambda" : "Λ"}, {"Mu" : "Μ"}, {"Ntilde" : "Ñ"}, {"Nu" : "Ν"}, {"OElig" : "Œ"}, {"Oacute" : "Ó"}, {"Ocirc" : "Ô"}, {"Ograve" : "Ò"}, {"Omega" : "Ω"}, {"Omicron" : "Ο"}, {"Oslash" : "Ø"}, {"Otilde" : "Õ"}, {"Ouml" : "Ö"}, {"Phi" : "Φ"}, {"Pi" : "Π"}, {"Prime" : "″"}, {"Psi" : "Ψ"}, {"Rho" : "Ρ"}, {"Scaron" : "Š"}, {"Sigma" : "Σ"}, {"THORN" : "Þ"}, {"Tau" : "Τ"}, {"Theta" : "Θ"}, {"Uacute" : "Ú"}, {"Ucirc" : "Û"}, {"Ugrave" : "Ù"}, {"Upsilon" : "Υ"}, {"Uuml" : "Ü"}, {"Xi" : "Ξ"}, {"Yacute" : "Ý"}, {"Yuml" : "Ÿ"}, {"Zeta" : "Ζ"}, {"aacute" : "á"}, {"acirc" : "â"}, {"acute" : "´"}, {"aelig" : "æ"}, {"agrave" : "à"}, {"alefsym" : "ℵ"}, {"alpha" : "α"}, {"amp" : "&"}, {"and" : "∧"}, {"ang" : "∠"}, {"aring" : "å"}, {"asymp" : "≈"}, {"atilde" : "ã"}, {"auml" : "ä"}, {"bdquo" : "„"}, {"beta" : "β"}, {"brvbar" : "¦"}, {"bull" : "•"}, {"cap" : "∩"}, {"ccedil" : "ç"}, {"cedil" : "¸"}, {"cent" : "¢"}, {"chi" : "χ"}, {"circ" : "ˆ"}, {"clubs" : "♣"}, {"cong" : "≅"}, {"copy" : "©"}, {"crarr" : "↵"}, {"cup" : "∪"}, {"curren" : "¤"}, {"dArr" : "⇓"}, {"dagger" : "†"}, {"darr" : "↓"}, {"deg" : "°"}, {"delta" : "δ"}, {"diams" : "♦"}, {"divide" : "÷"}, {"eacute" : "é"}, {"ecirc" : "ê"}, {"egrave" : "è"}, {"empty" : "∅"}, {"emsp" : " "}, {"ensp" : " "}, {"epsilon" : "ε"}, {"equiv" : "≡"}, {"eta" : "η"}, {"eth" : "ð"}, {"euml" : "ë"}, {"euro" : "€"}, {"exist" : "∃"}, {"fnof" : "ƒ"}, {"forall" : "∀"}, {"frac12" : "½"}, {"frac14" : "¼"}, {"frac34" : "¾"}, {"frasl" : "⁄"}, {"gamma" : "γ"}, {"ge" : "≥"}, {"gt" : ">"}, {"hArr" : "⇔"}, {"harr" : "↔"}, {"hearts" : "♥"}, {"hellip" : "…"}, {"iacute" : "í"}, {"icirc" : "î"}, {"iexcl" : "¡"}, {"igrave" : "ì"}, {"image" : "ℑ"}, {"infin" : "∞"}, {"int" : "∫"}, {"iota" : "ι"}, {"iquest" : "¿"}, {"isin" : "∈"}, {"iuml" : "ï"}, {"kappa" : "κ"}, {"lArr" : "⇐"}, {"lambda" : "λ"}, {"lang" : "〈"}, {"laquo" : "«"}, {"larr" : "←"}, {"lceil" : "⌈"}, {"ldquo" : "“"}, {"le" : "≤"}, {"lfloor" : "⌊"}, {"lowast" : "∗"}, {"loz" : "◊"}, {"lrm" : "‎"}, {"lsaquo" : "‹"}, {"lsquo" : "‘"}, {"lt" : "<"}, {"macr" : "¯"}, {"mdash" : "—"}, {"micro" : "µ"}, {"middot" : "·"}, {"minus" : "−"}, {"mu" : "μ"}, {"nabla" : "∇"}, {"nbsp" : " "}, {"ndash" : "–"}, {"ne" : "≠"}, {"ni" : "∋"}, {"not" : "¬"}, {"notin" : "∉"}, {"nsub" : "⊄"}, {"ntilde" : "ñ"}, {"nu" : "ν"}, {"oacute" : "ó"}, {"ocirc" : "ô"}, {"oelig" : "œ"}, {"ograve" : "ò"}, {"oline" : "‾"}, {"omega" : "ω"}, {"omicron" : "ο"}, {"oplus" : "⊕"}, {"or" : "∨"}, {"ordf" : "ª"}, {"ordm" : "º"}, {"oslash" : "ø"}, {"otilde" : "õ"}, {"otimes" : "⊗"}, {"ouml" : "ö"}, {"para" : "¶"}, {"part" : "∂"}, {"permil" : "‰"}, {"perp" : "⊥"}, {"phi" : "φ"}, {"pi" : "π"}, {"piv" : "ϖ"}, {"plusmn" : "±"}, {"pound" : "£"}, {"prime" : "′"}, {"prod" : "∏"}, {"prop" : "∝"}, {"psi" : "ψ"}, {"quot" : "\""}, {"rArr" : "⇒"}, {"radic" : "√"}, {"rang" : "〉"}, {"raquo" : "»"}, {"rarr" : "→"}, {"rceil" : "⌉"}, {"rdquo" : "”"}, {"real" : "ℜ"}, {"reg" : "®"}, {"rfloor" : "⌋"}, {"rho" : "ρ"}, {"rlm" : "‏"}, {"rsaquo" : "›"}, {"rsquo" : "’"}, {"sbquo" : "‚"}, {"scaron" : "š"}, {"sdot" : "⋅"}, {"sect" : "§"}, {"shy" : "­"}, {"sigma" : "σ"}, {"sigmaf" : "ς"}, {"sim" : "∼"}, {"spades" : "♠"}, {"sub" : "⊂"}, {"sube" : "⊆"}, {"sum" : "∑"}, {"sup" : "⊃"}, {"sup1" : "¹"}, {"sup2" : "²"}, {"sup3" : "³"}, {"supe" : "⊇"}, {"szlig" : "ß"}, {"tau" : "τ"}, {"there4" : "∴"}, {"theta" : "θ"}, {"thetasym" : "ϑ"}, {"thinsp" : " "}, {"thorn" : "þ"}, {"tilde" : "˜"}, {"times" : "×"}, {"trade" : "™"}, {"uArr" : "⇑"}, {"uacute" : "ú"}, {"uarr" : "↑"}, {"ucirc" : "û"}, {"ugrave" : "ù"}, {"uml" : "¨"}, {"upsih" : "ϒ"}, {"upsilon" : "υ"}, {"uuml" : "ü"}, {"weierp" : "℘"}, {"xi" : "ξ"}, {"yacute" : "ý"}, {"yen" : "¥"}, {"yuml" : "ÿ"}, {"zeta" : "ζ"}, {"zwj" : "‍"}, {"zwnj" : "‌"}]'::jsonb;

	    for r in
		select distinct ce.ch, ce.name
		from
		    (SELECT (e)."key" AS "name", (e).value AS ch FROM ( SELECT jsonb_each_text(jsonb_array_elements(chars)) AS e ) a ) AS ce
		    inner join (
			select name[1] "name"
			from regexp_matches(t, '&([A-Za-z]+?);', 'g') r(name)
		    ) s on ce."name" = s.name
	    loop
		t := replace(t, '&' || r.name || ';', r.ch);
	    end loop;

	    for r in
		select distinct
		    hex[1] hex,
		    ('x' || repeat('0', 8 - length(hex[1])) || hex[1])::bit(32)::int codepoint
		from regexp_matches(t, '&#x([0-9a-f]{1,8}?);', 'gi') s(hex)
	    loop
		t := regexp_replace(t, '&#x' || r.hex || ';', chr(r.codepoint), 'gi');
	    end loop;

	    for r in
		select distinct
		    chr(codepoint[1]::int) ch,
		    codepoint[1] codepoint
		from regexp_matches(t, '&#([0-9]{1,10}?);', 'g') s(codepoint)
	    loop
		t := replace(t, '&#' || r.codepoint || ';', r.ch);
	    end loop;

	    return t;
	end;
	$function$
;
