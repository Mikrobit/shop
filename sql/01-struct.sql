-- Everything should be in a schema (!= public)
-- CREATE SCHEMA IF NOT EXISTS shop;
SET search_path TO shop;

-- Categories are better managed by postgres to limit complexity in the app.
CREATE TABLE IF NOT EXISTS categories (
    id          BIGSERIAL    PRIMARY KEY,
    name        JSON         NOT NULL,              -- {"IT": "Campo in italiano", "EN": "Field in english", ...}
    slug        VARCHAR(255) NOT NULL UNIQUE,
    short_desc  JSON         DEFAULT '{}',
    long_desc   JSON         DEFAULT '{}',
    images      JSON         DEFAULT '[]',          -- [{ "url": "/img/image1.png", "caption": "/img/image2.jpg" }, ...]
    discount    DECIMAL(6,2) DEFAULT 0.0,           -- %NNN.NN discount
    published   BOOLEAN      DEFAULT TRUE,
    starred     BOOLEAN      DEFAULT FALSE,
    created     TIMESTAMP    WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
    modified    TIMESTAMP    WITH TIME ZONE NOT NULL DEFAULT current_timestamp,

    CONSTRAINT too_much_discount CHECK (discount <= 100.0)
);
CREATE INDEX categories_id_idx ON categories (id);
CREATE UNIQUE INDEX categories_slug_idx ON categories (slug);

CREATE TABLE IF NOT EXISTS products (
    id          BIGSERIAL PRIMARY KEY,
    name        JSON            NOT NULL,
    slug        VARCHAR(255)    NOT NULL UNIQUE,
    short_desc  JSON            DEFAULT '{}',
    long_desc   JSON            DEFAULT '{}',
    variations  JSON            DEFAULT '{}', -- ["IT": {"Colore Laccio": "blue"}, "EN": {"Lace Color": "blue"}, ...]
    images      JSON            DEFAULT '[]', -- [{ "url": "/img/image1.png", "caption": "/img/image2.jpg" }, ...]
    price       DECIMAL(15,2)   DEFAULT 0.0,  -- NNNNNNNNNNNNNNN.NN
    taxes       DECIMAL(6,2)    DEFAULT 0.0, -- % - vat, iva...
    discount    DECIMAL(6,2)    DEFAULT 0.0,
    weight      INTEGER         DEFAULT 100,
    published   BOOLEAN         DEFAULT TRUE,
    starred     BOOLEAN         DEFAULT FALSE,
    stock       INTEGER         DEFAULT 1,    -- How many in stock ?
    created     TIMESTAMP       WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
    modified    TIMESTAMP       WITH TIME ZONE NOT NULL DEFAULT current_timestamp,

    CONSTRAINT valid_price CHECK (price >= 0),
    CONSTRAINT too_much_discount CHECK (discount <= 100.0)
);
CREATE INDEX products_id_idx ON products (id);
CREATE UNIQUE INDEX products_slug_idx ON products (slug);

CREATE TABLE IF NOT EXISTS categories_products (
    product  BIGINT REFERENCES products   ON DELETE CASCADE,   -- If product gets removed, remove entries here
    category BIGINT REFERENCES categories ON DELETE CASCADE,

    PRIMARY KEY(product,category)
);
CREATE UNIQUE INDEX categories_products_idx ON categories_products (product,category);

-- One user, one cart + one wishlist
CREATE TABLE IF NOT EXISTS users (
    email       VARCHAR(255) PRIMARY KEY,
    token       VARCHAR(255),               -- activation code, random hash?
    "type"      VARCHAR(255),               -- user, admin, guest...
    active      BOOLEAN      DEFAULT FALSE, -- TRUE if user is authenticated
    -- one cart/wishlist per user
    cart        JSON,    -- List of products [1,2,3,4,5]...
    wishlist    JSON,
    -- courier info
    name        VARCHAR(255),
    surname     VARCHAR(255),
    city        VARCHAR(255),
    province    VARCHAR(4),
    city_code   VARCHAR(10),
    address     TEXT,
    country     VARCHAR(255),
    telephone   VARCHAR(255),
    -- credit card info
    cc_number   VARCHAR(255),
    cc_cvd      VARCHAR(5),
    cc_valid_m  SMALLINT,
    cc_valid_y  SMALLINT,
    -- paypal account
    paypal      VARCHAR(255),

    CONSTRAINT valid_month CHECK (cc_valid_m BETWEEN 1 AND 12),
    CONSTRAINT valid_year CHECK (cc_valid_y >= EXTRACT( YEAR FROM now()))
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
    id          BIGSERIAL       PRIMARY KEY,
    "user"      VARCHAR         REFERENCES users ON DELETE CASCADE,
    products    JSON            DEFAULT '[]',
    total       DECIMAL(15,2)   DEFAULT 0.00,       -- Taxes included
    pay_method  VARCHAR(255)    DEFAULT 'stripe',
    created     TIMESTAMP       WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
    modified    TIMESTAMP       WITH TIME ZONE NOT NULL DEFAULT current_timestamp,
    payed       TIMESTAMP       WITH TIME ZONE DEFAULT NULL,
    sent        TIMESTAMP       WITH TIME ZONE DEFAULT NULL,
    -- Send to:
    name        VARCHAR(255)    NOT NULL,
    surname     VARCHAR(255)    NOT NULL,
    city        VARCHAR(255)    NOT NULL,
    province    VARCHAR(4)      NOT NULL,
    city_code   VARCHAR(10)     NOT NULL,
    address     TEXT            NOT NULL,
    country     VARCHAR(255)    NOT NULL,
    telephone   VARCHAR(255)    NOT NULL
);

CREATE TABLE IF NOT EXISTS orders_products (
    product     BIGINT REFERENCES products ON DELETE CASCADE,
    "order"     BIGINT REFERENCES orders ON DELETE CASCADE,

    PRIMARY KEY(product,"order")
);

