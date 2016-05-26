CREATE OR REPLACE FUNCTION add_to_cart(
    IN  pId     INTEGER         DEFAULT NULL,
    IN  uEmail  VARCHAR(255)    DEFAULT NULL,

    OUT ok      BOOLEAN,
    OUT status  TEXT

) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        status := 'OK';

        -- Check if product is already in the cart.
        -- If it is, go ahead
        -- If it isn't, add it

        IF NOT FOUND THEN
            RAISE EXCEPTION 'User % not found.', uEmail
                USING HINT = 'Is the email correct?';
        ELSE
            ok := TRUE;
        END IF;

    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            hint    = PG_EXCEPTION_HINT,
            message = MESSAGE_TEXT;

        ok := FALSE;
        status := message || ' ' || hint;

    END;
$$ LANGUAGE plpgsql;


