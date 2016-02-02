SET search_path TO shop;

CREATE OR REPLACE FUNCTION get_orders(

    OUT ok              BOOLEAN,
    OUT status          TEXT,
    OUT orders          JSON

) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        SELECT json_agg(o.*)
        FROM orders o
        INTO orders;

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

-- Create a new order
CREATE OR REPLACE FUNCTION add_order(

    IN  uEmail      VARCHAR(255),
    IN  oProducts   BIGINT[],
    IN  oTotal      DECIMAL(15,2)   DEFAULT 0.00,
    IN  oPay_method VARCHAR(255)    DEFAULT 'paypal',
    IN  oPayed      TIMESTAMP       WITH TIME ZONE DEFAULT NULL,
    IN  oSent       TIMESTAMP       WITH TIME ZONE DEFAULT NULL,
    IN  uName       VARCHAR(255)    DEFAULT '',
    IN  uSurname    VARCHAR(255)    DEFAULT '',
    IN  uCity       VARCHAR(255)    DEFAULT '',
    IN  uProvince   VARCHAR(4)      DEFAULT '',
    IN  uCity_code  VARCHAR(10)     DEFAULT '',
    IN  uAddress    TEXT            DEFAULT '',
    IN  uCountry    VARCHAR(255)    DEFAULT '',
    IN  uTelephone  VARCHAR(255)    DEFAULT '',

    OUT ok          BOOLEAN,
    OUT status      TEXT

) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;
        prods   JSON;

    BEGIN

        SELECT json_agg(p.*)
        FROM products p
        WHERE p.id = ANY (oProducts)
        INTO prods;

        INSERT INTO orders ( "user", products, total, pay_method, payed, sent, name, surname, city, province, city_code, address, country, telephone, created )
            VALUES( uEmail, prods, oTotal, oPay_method, oPayed, oSent, uName, uSurname, uCity, uProvince, uCity_code, uAddress, uCountry, uTelephone, current_timestamp );

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

-- CREATE TYPE r_order AS ( ok BOOLEAN, status TEXT, order orders );
-- Get the order with id
CREATE OR REPLACE FUNCTION get_order(
    IN  oId         BIGINT,

    OUT ok          BOOLEAN,
    OUT status      TEXT,
    OUT "order"     JSON,
    OUT products    JSON

) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        status := 'OK';

        SELECT to_json(o.*)
        FROM orders o
        WHERE o.id = oId
        INTO "order";

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Order % not found.', oId
                USING HINT = 'Is the order id correct?';
        ELSE
            ok := TRUE;
        END IF;

        SELECT json_agg(p.*)
        FROM products p, orders_products op
        WHERE op.product = p.id
        AND op."order" = oId
        INTO products;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Products not found for order %.', oId
                USING HINT = 'Is the order id correct?';
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

-- Update order with given data
CREATE OR REPLACE FUNCTION update_order(

    IN  oId         BIGINT,
    IN  uEmail      VARCHAR(255)    DEFAULT '',
    IN  oTotal      DECIMAL(15,2)   DEFAULT 0.00,
    IN  oPay_method VARCHAR(255)    DEFAULT 'paypal',
    IN  oPayed      TIMESTAMP       WITH TIME ZONE DEFAULT NULL,
    IN  oSent       TIMESTAMP       WITH TIME ZONE DEFAULT NULL,
    IN  uName       VARCHAR(255)    DEFAULT '',
    IN  uSurname    VARCHAR(255)    DEFAULT '',
    IN  uCity       VARCHAR(255)    DEFAULT '',
    IN  uProvince   VARCHAR(4)      DEFAULT '',
    IN  uCity_code  VARCHAR(10)     DEFAULT '',
    IN  uAddress    TEXT            DEFAULT '',
    IN  uCountry    VARCHAR(255)    DEFAULT '',
    IN  uTelephone  VARCHAR(255)    DEFAULT '',

    OUT ok          BOOLEAN,
    OUT status      TEXT
   
) AS $$

    DECLARE
        
        message TEXT;
        hint    TEXT;

    BEGIN

        UPDATE orders
        SET
            "user" = uEmail,
            total = oTotal,
            pay_method = oPay_method,
            payed = oPayed,
            sent = oSent,
            name = uName,
            surname = uSurname,
            city = uCity,
            province = uProvince,
            city_code = uCity_code,
            address = uAddress,
            country = uCountry,
            telephone = uTelephone,
            modified = current_timestamp
        WHERE
            id = oId;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Order % not found.', oId
                USING HINT = 'Is the order id correct?';
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

-- Drop order with id pId
CREATE OR REPLACE FUNCTION delete_order(

    IN  oId     BIGINT,

    OUT ok      BOOLEAN,
    OUT status  TEXT
) AS $$

    DECLARE
        
        message TEXT;
        hint    TEXT;

    BEGIN

        DELETE FROM orders
        WHERE id = oId;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Order % not found.', oId
                USING HINT = 'Is the order id correct?';
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

