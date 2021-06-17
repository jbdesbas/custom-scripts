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
