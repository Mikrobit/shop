SET search_path TO shop;

-- Create a new product
CREATE OR REPLACE FUNCTION add_product(

    IN  pName       JSON,
    IN  pSlug       VARCHAR(255)    DEFAULT '',
    IN  pShort_desc JSON            DEFAULT '{}',
    IN  pLong_desc  JSON            DEFAULT '{}',
    IN  pVariations JSON            DEFAULT '{}',
    IN  pImages     JSON            DEFAULT '{}',
    IN  pPrice      DECIMAL(15,2)   DEFAULT 1.0,
    IN  pTaxes      DECIMAL(6,2)    DEFAULT 0.0,
    IN  pStock      INTEGER         DEFAULT 1,
    IN  pDiscount   DECIMAL(6,2)    DEFAULT 0,
    IN  pWeight     INTEGER         DEFAULT 100,
    IN  pPublished  BOOLEAN         DEFAULT TRUE,
    IN  pStarred    BOOLEAN         DEFAULT FALSE,

    OUT ok          BOOLEAN,
    OUT status      TEXT,
    OUT product_id  BIGINT

) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        INSERT INTO products( name, slug, short_desc, long_desc, variations, images, price, taxes, stock, discount, weight, published, starred, created )
            VALUES( pName, pSlug, pShort_desc, pLong_desc, pVariations, pImages, pPrice, pTaxes, pStock, pDiscount, pWeight, pPublished, pStarred, now() );

        SELECT LASTVAL() INTO product_id;

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

-- Get `limit` products starting from the `offset`th.
CREATE OR REPLACE FUNCTION get_products(

    IN  order_column    VARCHAR(255)    DEFAULT 'modified',
    IN  order_direction VARCHAR(5)      DEFAULT 'DESC',
    IN  pLimit          INTEGER         DEFAULT NULL,
    IN  pOffset         INTEGER         DEFAULT NULL,

    OUT ok              BOOLEAN,
    OUT status          TEXT,
    OUT products        JSON

) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        SELECT json_agg(p.*)
        FROM products p
        WHERE price != 0.0
        ORDER BY order_column DESC
        INTO products;

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

-- Get `limit` products in this category starting from the `offset`th.
CREATE OR REPLACE FUNCTION get_products_by_category(

    IN  category_id     BIGINT          DEFAULT NULL,  -- But... seriously, give me a category.
    IN  order_column    VARCHAR(255)    DEFAULT 'modified',
    IN  order_direction VARCHAR(5)      DEFAULT 'DESC',
    IN  pLimit          INTEGER         DEFAULT NULL,
    IN  pOffset         INTEGER         DEFAULT NULL,

    OUT ok              BOOLEAN,
    OUT status          TEXT,
    OUT products        JSON

) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        SELECT json_agg(p.*)
        FROM
            products p,
            categories_products cp
        WHERE
            p.id = cp.product
            AND cp.category = category_id
        ORDER BY order_column DESC
        INTO products;

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

-- Get `limit` products in this category starting from the `offset`th.
DROP function IF EXISTS get_starred_by_category (bigint, character varying, character varying, integer, integer);
CREATE OR REPLACE FUNCTION get_starred_by_category(

    IN  category_id     BIGINT          DEFAULT NULL,  -- But... seriously, give me a category.

    OUT ok              BOOLEAN,
    OUT status          TEXT,
    OUT products        JSON

) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        SELECT json_agg(p.*)
        FROM
            products p,
            categories_products cp
        WHERE
            p.id = cp.product
            AND cp.category = category_id
            AND p.starred = TRUE
        LIMIT 6
        INTO products;

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



-- CREATE TYPE r_product AS ( ok BOOLEAN, status TEXT, product products );
-- Get the product with id
CREATE OR REPLACE FUNCTION get_product_by_id(
    IN  product_id  BIGINT  DEFAULT NULL,

    OUT ok      BOOLEAN,
    OUT status  TEXT,
    OUT product JSON
) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        status := 'OK';

        SELECT to_json(p.*)
        FROM products p
        WHERE p.id = product_id
        INTO product;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % not found.', product_id
                USING HINT = 'Is the product id correct?';
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

-- Get the product with slug
CREATE OR REPLACE FUNCTION get_product_by_slug(

    IN pSlug  VARCHAR(255)  DEFAULT '',

    OUT ok  BOOLEAN,
    OUT status  TEXT,
    OUT product JSON
) AS $$
    DECLARE

        product_id  BIGINT;
        hint        TEXT;
        message     TEXT;

    BEGIN

        status := 'OK';

        SELECT id FROM products WHERE slug = pSlug INTO product_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % not found.', pSlug
                USING HINT = 'Is the product slug correct?';
        ELSE
            ok := TRUE;
        END IF;

        SELECT to_json(p.*)
        FROM products p
        WHERE p.id = product_id
        INTO product;

    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            hint    = PG_EXCEPTION_HINT,
            message = MESSAGE_TEXT;

        ok := FALSE;
        status := message || ' ' || hint;

    END;
$$ LANGUAGE plpgsql;

-- Update product with given data
CREATE OR REPLACE FUNCTION update_product(

    IN  pId         BIGINT,
    IN  pName       JSON,
    IN  pSlug       VARCHAR(255)    DEFAULT '',
    IN  pShort_desc JSON            DEFAULT '{}',
    IN  pLong_desc  JSON            DEFAULT '{}',
    IN  pVariations JSON            DEFAULT '{}',
    IN  pImages     JSON            DEFAULT '{}',
    IN  pPrice      DECIMAL(15,2)   DEFAULT 1.0,
    IN  pTaxes      DECIMAL(6,2)    DEFAULT 0.0,
    IN  pStock      INTEGER         DEFAULT 1,
    IN  pDiscount   DECIMAL(6,2)    DEFAULT 0,
    IN  pWeight     INTEGER         DEFAULT 100,
    IN  pPublished  BOOLEAN         DEFAULT TRUE,
    IN  pStarred    BOOLEAN         DEFAULT FALSE,

    OUT ok      BOOLEAN,
    OUT status  TEXT

) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        UPDATE products
        SET
            name = pName,
            slug = pSlug,
            short_desc = pShort_desc,
            long_desc = pLong_desc,
            variations = pVariations,
            images = pImages,
            price = pPrice,
            taxes = pTaxes,
            stock = pStock,
            discount = pDiscount,
            weight = pWeight,
            published = pPublished,
            starred = pStarred,
            modified = now()
        WHERE
            id = pId;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % not found.', pId
                USING HINT = 'Is the product id correct?';
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

CREATE OR REPLACE FUNCTION star_product(

    IN  pId     BIGINT,

    OUT ok      BOOLEAN,
    OUT status  TEXT

) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        UPDATE products SET starred = TRUE WHERE id = pId;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % not found.', pId
                USING HINT = 'Is the product id correct?';
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

CREATE OR REPLACE FUNCTION toggle_product_star(

    IN  pId     BIGINT,

    OUT ok      BOOLEAN,
    OUT status  TEXT

) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        UPDATE products SET starred = NOT starred WHERE id = pId;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % not found.', pId
                USING HINT = 'Is the product id correct?';
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

-- Drop product with id pId
CREATE OR REPLACE FUNCTION delete_product(

    IN  pId     BIGINT,

    OUT ok      BOOLEAN,
    OUT status  TEXT
) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        DELETE FROM products
        WHERE id = pId;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % not found.', pId
                USING HINT = 'Is the product id correct?';
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

