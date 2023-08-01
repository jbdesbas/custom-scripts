CREATE OR REPLACE FUNCTION rows_diff_jsonb(r_old record,r_new record)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE AS $function$
    -- Jean-Baptiste DESBAS, 2021 jb@desbas.fr
    -- Return a jsonb with all changed value between old and new row. NULL jsonb ('{}') is returned if no change.
    -- Used to log only differences after an update (trigger AFTER UPDATE)
    DECLARE 
        e record;
        jsonb_old jsonb;
        jsonb_new jsonb;
        diff jsonb;
    BEGIN
        jsonb_old = row_to_json(r_old)::jsonb;
        jsonb_new = row_to_json(r_new)::jsonb;
        diff = '{}'::jsonb;
        FOR e IN SELECT * FROM jsonb_each(jsonb_new) LOOP
            IF NOT jsonb_old @> jsonb_build_object(e.KEY, e.value) THEN   
                diff = diff || jsonb_build_object(e.KEY, jsonb_build_object('old', jsonb_old->e.key, 'new', e.value) );
            END IF; 
        END LOOP;
        RAISE NOTICE 'Diff %', diff;
        RETURN diff::jsonb;
    END;
$function$;
