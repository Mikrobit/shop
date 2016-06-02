--CREATE TYPE apiresponse AS (ok BOOLEAN, status TEXT, output JSON);
CREATE OR REPLACE FUNCTION add_to_cart(INTEGER, VARCHAR(255)) RETURNS apiresponse AS $$

use JSON;

my $ok = 0;
my $status = "Not ok";
my $output = "{}";

$output = encode_json($output);
return { ok => $ok, status => $status, output => $output };

$$ LANGUAGE plperlu;


CREATE OR REPLACE FUNCTION add_to_cart_old(
    IN  pId     INTEGER         DEFAULT NULL,
    IN  uEmail  VARCHAR(255)    DEFAULT NULL,

    OUT ok      BOOLEAN,
    OUT status  TEXT

) AS $$
    DECLARE

        hint        TEXT;
        message     TEXT;
        origCart    TEXT;

    BEGIN

        status := 'OK';
        ok := TRUE;

        -- Check if product is already in the cart.

        SELECT cart
        FROM users
        WHERE email = uEmail
            AND cart->pId IS NOT NULL
        INTO origCart;

        -- If it isn't, add it
        IF NOT FOUND THEN
            UPDATE users
            SET cart = json_build_object(origCart,pId)
            WHERE email = uEmail;
        END IF;

        -- If it is, add one. Maybe later.

--    EXCEPTION WHEN OTHERS THEN
--        GET STACKED DIAGNOSTICS
--            hint    = PG_EXCEPTION_HINT,
--            message = MESSAGE_TEXT;
--
--        ok := FALSE;
--        status := message || ' ' || hint;

    END;
$$ LANGUAGE plpgsql;


