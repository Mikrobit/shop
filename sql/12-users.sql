SET search_path TO shop;

CREATE OR REPLACE FUNCTION get_users(

    OUT ok              BOOLEAN,
    OUT status          TEXT,
    OUT users           JSON

) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        SELECT json_agg(u.*)
        FROM users u
        INTO users;

        ok := TRUE;
        status := 'OK';

    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            hint    = PG_EXCEPTION_HINT,
            message = MESSAGE_TEXT;

        ok := FALSE;
        status := message || ' ' || hint;

    END;
$$ LANGUAGE plpgsql;

-- Create a new user
CREATE OR REPLACE FUNCTION add_user(

    IN  uEmail      VARCHAR(255),
    IN  uToken      VARCHAR(255)    DEFAULT '',
    IN  uType       VARCHAR(255)    DEFAULT 'user',
    IN  uActive     BOOLEAN         DEFAULT FALSE,
    IN  uCart       JSON            DEFAULT '{}',
    IN  uWishlist   JSON            DEFAULT '{}',
    IN  uName       VARCHAR(255)    DEFAULT '',
    IN  uSurname    VARCHAR(255)    DEFAULT '',
    IN  uCity       VARCHAR(255)    DEFAULT '',
    IN  uProvince   VARCHAR(4)      DEFAULT '',
    IN  uCity_code  VARCHAR(10)     DEFAULT '',
    IN  uAddress    TEXT            DEFAULT '',
    IN  uCountry    VARCHAR(255)    DEFAULT '',
    IN  uTelephone  VARCHAR(255)    DEFAULT '',
    IN  uCc_number  VARCHAR(255)    DEFAULT '',
    IN  uCc_cvd     VARCHAR(5)      DEFAULT '',
    IN  uCc_valid_m SMALLINT        DEFAULT 0,
    IN  uCc_valid_y SMALLINT        DEFAULT 0,
    IN  uPaypal     VARCHAR(255)    DEFAULT '',

    OUT ok          BOOLEAN,
    OUT status      TEXT

) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        INSERT INTO users ( email, token, "type", active, cart, wishlist, name, surname, city, province, city_code, address, country, telephone, cc_number, cc_cvd, cc_valid_m, cc_valid_y, paypal )
            VALUES( uEmail, uToken, uType, uActive, uCart, uWishlist, uName, uSurname, uCity, uProvince, uCity_code, uAddress, uCountry, uTelephone, uCc_number, uCc_cvd, uCc_valid_m, uCc_valid_y, uPaypal );

        ok := TRUE;
        status := 'OK';

    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            hint    = PG_EXCEPTION_HINT,
            message = MESSAGE_TEXT;

        ok := FALSE;
        status := message || ' ' || hint;

    END;

$$ LANGUAGE plpgsql;

-- CREATE TYPE r_user AS ( ok BOOLEAN, status TEXT, user users );
-- Get the user with id
CREATE OR REPLACE FUNCTION get_user(
    IN  uEmail  VARCHAR(255)    DEFAULT NULL,

    OUT ok      BOOLEAN,
    OUT status  TEXT,
    OUT account JSON

) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        status := 'OK';

        SELECT to_json(u.*)
        FROM users u
        WHERE u.email = uEmail
        INTO account;

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

-- Update user with given data
CREATE OR REPLACE FUNCTION update_user(

    IN  uEmail      VARCHAR(255),
    IN  uToken      VARCHAR(255)    DEFAULT '',
    IN  uType       VARCHAR(255)    DEFAULT 'user',
    IN  uActive     BOOLEAN         DEFAULT FALSE,
    IN  uCart       JSON            DEFAULT '{}',
    IN  uWishlist   JSON            DEFAULT '{}',
    IN  uName       VARCHAR(255)    DEFAULT '',
    IN  uSurname    VARCHAR(255)    DEFAULT '',
    IN  uCity       VARCHAR(255)    DEFAULT '',
    IN  uProvince   VARCHAR(4)      DEFAULT '',
    IN  uCity_code  VARCHAR(10)     DEFAULT '',
    IN  uAddress    TEXT            DEFAULT '',
    IN  uCountry    VARCHAR(255)    DEFAULT '',
    IN  uTelephone  VARCHAR(255)    DEFAULT '',
    IN  uCc_number  VARCHAR(255)    DEFAULT '',
    IN  uCc_cvd     SMALLINT        DEFAULT 0,
    IN  uCc_valid_m SMALLINT        DEFAULT 0,
    IN  uCc_valid_y SMALLINT        DEFAULT 0,
    IN  uPaypal     VARCHAR(255)    DEFAULT '',

    OUT ok          BOOLEAN,
    OUT status      TEXT

) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        UPDATE users
        SET
            token = uToken,
            "type" = uType,
            active = uActive,
            cart = uCart,
            wishlist = uWishlist,
            name = uName,
            surname = uSurname,
            city = uCity,
            province = uProvince,
            city_code = uCity_code,
            address = uAddress,
            country = uCountry,
            telephone = uTelephone,
            cc_number = uCc_number,
            cc_cvd = uCc_cvd,
            cc_valid_m = uCc_valid_m,
            cc_valid_y = uCc_valid_y,
            paypal = uPaypal
        WHERE
            email = uEmail;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'User % not found.', uEmail
                USING HINT = 'Is the email correct?';
        END IF;

        ok := TRUE;
        status := 'OK';

    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            hint    = PG_EXCEPTION_HINT,
            message = MESSAGE_TEXT;

        ok := FALSE;
        status := message || ' ' || hint;

    END;
$$ LANGUAGE plpgsql;

-- Drop user with id pId
CREATE OR REPLACE FUNCTION delete_user(

    IN  uEmail  VARCHAR(255),

    OUT ok      BOOLEAN,
    OUT status  TEXT
) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        DELETE FROM users
        WHERE email = uEmail;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'User % not found.', pId
                USING HINT = 'Is the user id correct?';
        END IF;

        ok := TRUE;
        status := 'OK';

    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            hint    = PG_EXCEPTION_HINT,
            message = MESSAGE_TEXT;

        ok := FALSE;
        status := message || ' ' || hint;

    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION authenticate_user(

    IN  uEmail  VARCHAR(255),
    IN  uToken  VARCHAR(255),

    OUT ok      BOOLEAN,
    OUT status  TEXT,
    OUT "user"  JSON
) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        SELECT to_json(u.*)
        FROM users u
        WHERE email = uEmail
            AND token = uToken
        INTO "user";

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Authentication failed for user % .', uEmail
                USING HINT = 'Is the e-mail address - password couple correct?';
        END IF;

        ok := TRUE;
        status := 'OK';

    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            hint    = PG_EXCEPTION_HINT,
            message = MESSAGE_TEXT;

        ok := FALSE;
        status := message || ' ' || hint;

    END;
$$ LANGUAGE plpgsql;


