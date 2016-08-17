--CREATE ROLE dba WITH superuser;
--GRANT dba TO lisa
--CREATE LANGUAGE plperlu
SET ROLE dba;
--CREATE TYPE apiresponse AS (ok BOOLEAN, status TEXT, output JSON);
CREATE OR REPLACE FUNCTION add_to_cart(INTEGER, INTEGER, VARCHAR(255)) RETURNS apiresponse AS $$

use strict;
use warnings;
use v5.20;

use JSON;

my $ok = 0;
my $status = "Not ok";
my $output = {};

my $pId = shift;
my $quantity = shift;
my $uEmail = shift;

my $query = 'SELECT cart FROM users WHERE email = ' . quote_literal($uEmail);
my $rv = spi_exec_query($query,1);
my $cart = decode_json($rv->{'rows'}[0]->{'cart'});
$cart->{$pId}{'quantity'} += $quantity;
$cart = encode_json($cart);

$query = 'UPDATE users SET cart = '. quote_literal($cart) .' WHERE email = ' . quote_literal($uEmail);
my $res = spi_exec_query($query);
$ok = $res->{'ok'};
$status = $res->{'status'};

$output = encode_json($output);
return { ok => $ok, status => $status, output => $output };

$$ LANGUAGE plperlu;

CREATE OR REPLACE FUNCTION add_to_wishlist(INTEGER, INTEGER, VARCHAR(255)) RETURNS apiresponse AS $$

use strict;
use warnings;
use v5.20;

use JSON;

my $ok = 0;
my $status = "Not ok";
my $output = {};

my $pId = shift;
my $quantity = shift;
my $uEmail = shift;

my $query = 'SELECT wishlist FROM users WHERE email = ' . quote_literal($uEmail);
my $rv = spi_exec_query($query,1);
my $wishlist = decode_json($rv->{'rows'}[0]->{'cart'});
$wishlist->{$pId}{'quantity'} += $quantity;
$wishlist = encode_json($wishlist);

$query = 'UPDATE users SET wishlist = '. quote_literal($wishlist) .' WHERE email = ' . quote_literal($uEmail);
my $res = spi_exec_query($query);
$ok = $res->{'ok'};
$status = $res->{'status'};

$output = encode_json($output);
return { ok => $ok, status => $status, output => $output };

$$ LANGUAGE plperlu;

CREATE OR REPLACE FUNCTION sub_from_cart(INTEGER, INTEGER, VARCHAR(255)) RETURNS apiresponse AS $$

use strict;
use warnings;
use v5.20;

use JSON;

my $ok = 0;
my $status = "Not ok";
my $output = {};

my $pId = shift;
my $quantity = shift;
my $uEmail = shift;

my $query = 'SELECT cart FROM users WHERE email = ' . quote_literal($uEmail);
my $rv = spi_exec_query($query,1);
my $cart = decode_json($rv->{'rows'}[0]->{'cart'});
$cart->{$pId}{'quantity'} -= $quantity;
if( $cart->{$pId}{'quantity'} < 1 ) {
    delete $cart->{$pId};
}
$cart = encode_json($cart);

$query = 'UPDATE users SET cart = '. quote_literal($cart) .' WHERE email = ' . quote_literal($uEmail);
my $res = spi_exec_query($query);
$ok = $res->{'ok'};
$status = $res->{'status'};

$output = encode_json($output);
return { ok => $ok, status => $status, output => $output };

$$ LANGUAGE plperlu;

CREATE OR REPLACE FUNCTION sub_from_wishlist(INTEGER, INTEGER, VARCHAR(255)) RETURNS apiresponse AS $$

use strict;
use warnings;
use v5.20;

use JSON;

my $ok = 0;
my $status = "Not ok";
my $output = {};

my $pId = shift;
my $quantity = shift;
my $uEmail = shift;

my $query = 'SELECT wishlist FROM users WHERE email = ' . quote_literal($uEmail);
my $rv = spi_exec_query($query,1);
my $wishlist = decode_json($rv->{'rows'}[0]->{'cart'});
$wishlist->{$pId}{'quantity'} -= $quantity;
if( $wishlist->{$pId}{'quantity'} < 1 ) {
    delete $wishlist->{$pId};
}
$wishlist = encode_json($wishlist);

$query = 'UPDATE users SET wishlist = '. quote_literal($wishlist) .' WHERE email = ' . quote_literal($uEmail);
my $res = spi_exec_query($query);
$ok = $res->{'ok'};
$status = $res->{'status'};

$output = encode_json($output);
return { ok => $ok, status => $status, output => $output };

$$ LANGUAGE plperlu;

CREATE OR REPLACE FUNCTION empty_cart(VARCHAR(255)) RETURNS apiresponse AS $$

use strict;
use warnings;
use v5.20;

use JSON;

my $ok = 0;
my $status = "Not ok";
my $output = {};

my $uEmail = shift;

my $query = "UPDATE users SET cart = '{}' WHERE email = " . quote_literal($uEmail);
my $res = spi_exec_query($query);
$ok = $res->{'ok'};
$status = $res->{'status'};

$output = encode_json($output);
return { ok => $ok, status => $status, output => $output };

$$ LANGUAGE plperlu;

CREATE OR REPLACE FUNCTION empty_wishlist(VARCHAR(255)) RETURNS apiresponse AS $$

use strict;
use warnings;
use v5.20;

use JSON;

my $ok = 0;
my $status = "Not ok";
my $output = {};

my $uEmail = shift;

my $query = "UPDATE users SET wishlist = '{}' WHERE email = " . quote_literal($uEmail);
my $res = spi_exec_query($query);
$ok = $res->{'ok'};
$status = $res->{'status'};

$output = encode_json($output);
return { ok => $ok, status => $status, output => $output };

$$ LANGUAGE plperlu;



SET ROLE lisa;

-- lies, damn lies:
-- vim:ft=perl
