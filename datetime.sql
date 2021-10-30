CREATE OR REPLACE FUNCTION is_date_in_period(input_date date, doy_start smallint, doy_stop smallint )
RETURNS boolean
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--TRUE si la date est située dans la période entre les deux "days of year". Fonctionne aussi pour les périodes à cheval sur deux années (doy_stop < doy_start)
--Return NULL si doy_start = doy_stop (impossible de déterminer la période à couvrir)
  BEGIN
    IF doy_start < doy_stop THEN
      return (input_date BETWEEN (date_trunc('year',input_date) + (doy_start-1||' days')::INTERVAL)::date 
     			AND (date_trunc('year',input_date) + (doy_stop-1||' days')::INTERVAL)::date);
    ELSIF doy_start > doy_stop THEN
      RETURN (input_date >= (date_trunc('year',input_date) + (doy_start-1||' days')::INTERVAL)::date
     			OR input_date <= (date_trunc('year',input_date) + (doy_stop-1||' days')::INTERVAL)::date);
    ELSE 
    	RETURN null;
    END IF;
  END;
$function$
;


CREATE OR REPLACE FUNCTION ymd_to_dateminmax(input_year int, input_month int, input_day int )
RETURNS date[]
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
--Transforme 3 champs ANNEE MOIS JOUR en DATE_MIN et DATE_MAX (DATE_MIN = DATE_MAX si les trois sont précisés)
--Return un array de 2 dates
  BEGIN
    IF input_day IS NULL AND input_month IS NOT null THEN
            RETURN ARRAY[
                make_date(input_year, input_month, 1),
                make_date(input_year, input_month, 1) + '1 month'::INTERVAL - '1 day'::interval
            ];
    ELSIF input_month IS NULL THEN
         RETURN ARRAY[make_date(input_year, 1, 1), make_date(input_year, 12, 31)];
    ELSE 
       RETURN ARRAY[make_date(input_year, input_month, input_day), make_date(input_year, input_month, input_day)];

    END IF;
  END;
$function$
;
