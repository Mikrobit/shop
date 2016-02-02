SET search_path TO shop;

-- Create a new category
CREATE OR REPLACE FUNCTION add_category(

    IN  cName       JSON,
    IN  cSlug       VARCHAR(255)    DEFAULT '',
    IN  cShort_desc JSON            DEFAULT '{}',
    IN  cLong_desc  JSON            DEFAULT '{}',
    IN  cImages     JSON            DEFAULT '{}',
    IN  cDiscount   DECIMAL(6,2)    DEFAULT 0,
    IN  cPublished  BOOLEAN         DEFAULT TRUE,
    IN  cStarred    BOOLEAN         DEFAULT FALSE,

    OUT ok          BOOLEAN,
    OUT status      TEXT,
    OUT category_id  BIGINT

) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        INSERT INTO categories( name, slug, short_desc, long_desc, images, discount, published, starred, created )
            VALUES( cName, cSlug, cShort_desc, cLong_desc, cImages, cDiscount, cPublished, cStarred, now() );

        SELECT LASTVAL() INTO category_id;

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
CREATE OR REPLACE FUNCTION get_categories(

    OUT ok              BOOLEAN,
    OUT status          TEXT,
    OUT categories        JSON

) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        SELECT json_agg(c.*)
        FROM categories c
        WHERE c.name->>'it' != ''
        INTO categories;

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

-- Get the category with id
CREATE OR REPLACE FUNCTION get_category_by_id(
    IN  category_id  BIGINT  DEFAULT NULL,

    OUT ok          BOOLEAN,
    OUT status      TEXT,
    OUT category    JSON,
    OUT products    JSON

) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        status := 'OK';

        SELECT to_json(c.*)
        FROM categories c
        WHERE c.id = category_id
        INTO category;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Category % not found.', category_id
                USING HINT = 'Is the category id correct?';
        ELSE
            ok := TRUE;
        END IF;

        SELECT json_agg(p.*)
        FROM products p, categories_products cp
        WHERE p.id = cp.product
        AND cp.category = category_id
        INTO products;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Products for category % not found.', category_id
                USING HINT = 'Is the category id correct?';
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

-- Get the category with slug
CREATE OR REPLACE FUNCTION get_category_by_slug(

    IN cSlug  VARCHAR(255)  DEFAULT '',

    OUT ok  BOOLEAN,
    OUT status  TEXT,
    OUT category JSON
) AS $$
    DECLARE

        category_id  BIGINT;
        hint        TEXT;
        message     TEXT;

    BEGIN

        status := 'OK';

        SELECT id FROM categories WHERE slug = cSlug INTO category_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Category % not found.', pSlug
                USING HINT = 'Is the category slug correct?';
        ELSE
            ok := TRUE;
        END IF;

        SELECT to_json(c.*)
        FROM categories c
        WHERE c.id = category_id
        INTO category;

    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            hint    = PG_EXCEPTION_HINT,
            message = MESSAGE_TEXT;

        ok := FALSE;
        status := message || ' ' || hint;

    END;
$$ LANGUAGE plpgsql;

-- Get the categories for product with id
CREATE OR REPLACE FUNCTION get_categories_for_product(
    IN  product_id  BIGINT  DEFAULT NULL,

    OUT ok          BOOLEAN,
    OUT status      TEXT,
    OUT categories  JSON
) AS $$
    DECLARE

        hint    TEXT;
        message TEXT;

    BEGIN

        status := 'OK';

        SELECT json_agg(category)
        FROM categories_products
        WHERE product = product_id
        INTO categories;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Categories not found for product %s.', category_id
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



-- Update category with given data
CREATE OR REPLACE FUNCTION update_category(

    IN  cId         BIGINT,
    IN  cName       JSON,
    IN  cSlug       VARCHAR(255)    DEFAULT '',
    IN  cShort_desc JSON            DEFAULT '{}',
    IN  cLong_desc  JSON            DEFAULT '{}',
    IN  cImages     JSON            DEFAULT '{}',
    IN  cDiscount   DECIMAL(6,2)    DEFAULT 0,
    IN  cPublished  BOOLEAN         DEFAULT TRUE,
    IN  cStarred    BOOLEAN         DEFAULT FALSE,

    OUT ok      BOOLEAN,
    OUT status  TEXT

) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        UPDATE categories
        SET
            name = cName,
            slug = cSlug,
            short_desc = cShort_desc,
            long_desc = cLong_desc,
            images = cImages,
            discount = cDiscount,
            published = cPublished,
            starred = cStarred,
            modified = now()
        WHERE
            id = cId;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Category % not found.', cId
                USING HINT = 'Is the category id correct?';
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

CREATE OR REPLACE FUNCTION star_category(

    IN  cId     BIGINT,

    OUT ok      BOOLEAN,
    OUT status  TEXT

) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        UPDATE categories SET starred = TRUE WHERE id = cId;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % not found.', cId
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

CREATE OR REPLACE FUNCTION toggle_category_star(

    IN  cId     BIGINT,

    OUT ok      BOOLEAN,
    OUT status  TEXT

) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        UPDATE categories SET starred = NOT starred WHERE id = cId;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Product % not found.', cId
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

-- Drop category with id pId
CREATE OR REPLACE FUNCTION delete_category(

    IN  cId     BIGINT,

    OUT ok      BOOLEAN,
    OUT status  TEXT
) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        DELETE FROM categories
        WHERE id = cId;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Category % not found.', pId
                USING HINT = 'Is the category id correct?';
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

CREATE OR REPLACE FUNCTION add_product_to_category(

    IN  pId     BIGINT,
    IN  cId     BIGINT,

    OUT ok      BOOLEAN,
    OUT status  TEXT
) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        INSERT INTO categories_products VALUES( pId, cId );

        ok := TRUE;
        status := 'OK';

    EXCEPTION WHEN unique_violation THEN
        ok := TRUE;
        status := 'OK';

    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            hint    = PG_EXCEPTION_HINT,
            message = MESSAGE_TEXT;

        ok := FALSE;
        status := message || ' ' || hint;

    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION del_product_from_category(

    IN  pId     BIGINT,
    IN  cId     BIGINT,

    OUT ok      BOOLEAN,
    OUT status  TEXT
) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        DELETE FROM categories_products WHERE product = pId AND category = cId;

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

CREATE OR REPLACE FUNCTION del_products_from_category(

    IN  cId     BIGINT,

    OUT ok      BOOLEAN,
    OUT status  TEXT
) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        DELETE FROM categories_products WHERE category = cId;

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

CREATE OR REPLACE FUNCTION del_product_from_categories(

    IN  pId     BIGINT,

    OUT ok      BOOLEAN,
    OUT status  TEXT
) AS $$

    DECLARE

        message TEXT;
        hint    TEXT;

    BEGIN

        DELETE FROM categories_products WHERE product = pId;

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
