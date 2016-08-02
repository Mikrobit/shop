--CREATE ROLE dba WITH superuser;
--GRANT dba TO lisa
--CREATE LANGUAGE plperlu
SET ROLE dba;
--CREATE TYPE apiresponse AS (ok BOOLEAN, status TEXT, output JSON);
CREATE OR REPLACE FUNCTION add_to_cart(INTEGER, INTEGER, VARCHAR(255)) RETURNS apiresponse AS $$

use strict;
use warnings;
use v5.22;

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
SET ROLE lisa;

