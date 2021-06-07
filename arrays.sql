CREATE FUNCTION public.array_distinct(anyarray)
 RETURNS anyarray
 LANGUAGE sql
 IMMUTABLE
AS $function$
  """Return an array with no duplicates values """
  SELECT array_agg(DISTINCT x) FROM unnest($1) t(x);
$function$
;
