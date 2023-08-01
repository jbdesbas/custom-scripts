CREATE OR REPLACE FUNCTION http_get(uri character varying)
  RETURNS text 
  LANGUAGE plpython3u 
  VOLATILE 
AS $python$
  """Jean-Baptiste DESBAS, 2022 jb@desbas.fr
     Retourne le résultat d'une requête HTTP GET. Nécessite d'être superuser pour créer la function (car langage untrust)
  """
  import requests
  data = requests.get(uri)
  return data.text
$python$;
