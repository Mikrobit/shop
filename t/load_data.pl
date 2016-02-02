#!/usr/bin/env perl

use v5.20;
use strict;
use warnings;
use open ':encoding(utf8)';

use Data::Printer;
use LWP::UserAgent;
use JSON;

my $product;
my $category;

open( my $c_images, '<', "json/categories_images.json" );
eval {
    our $/ = undef;
    while( <$c_images> ) {
        $category->{'images'} = $_;
    }
};

open( my $c_long, '<', "json/categories_long_desc.json" );
eval {
    our $/ = undef;
    while( <$c_long> ) {
        $category->{'long_desc'} = $_;
    }
};

open( my $c_name, '<', "json/categories_name.json" );
eval {
    our $/ = undef;
    while( <$c_name> ) {
        $category->{'name'} = $_;
    }
};

open( my $c_short, '<', "json/categories_short_desc.json" );
eval {
    our $/ = undef;
    while( <$c_short> ) {
        $category->{'short_desc'} = $_;
    }
};

open( my $p_images, '<', "json/products_images.json" );
eval {
    our $/ = undef;
    while( <$p_images> ) {
        $product->{'images'} = $_;
    }
};

open( my $p_long, '<', "json/products_long_desc.json" );
eval {
    our $/ = undef;
    while( <$p_long> ) {
        $product->{'long_desc'} = $_;
    }
};

open( my $p_name, '<', "json/products_name.json" );
eval {
    our $/ = undef;
    while( <$p_name> ) {
        $product->{'name'} = $_;
    }
};

open( my $p_short, '<', "json/products_short_desc.json" );
eval {
    our $/ = undef;
    while( <$p_short> ) {
        $product->{'short_desc'} = $_;
    }
};

open( my $p_var, '<', "json/products_variations.json" );
eval {
    our $/ = undef;
    while( <$p_var> ) {
        $product->{'variations'} = $_;
    }
};

# Finished loading json data, let's put some contents on the db

my $ua = LWP::UserAgent->new;
my $api_base = 'http://api.iannella.sh';

my @products;
my @categories;

# Create some categories

for my $i ( 1..5 ) {
    my $c = {
        name        => from_json( $category->{'name'} ),
        short_desc  => from_json( $category->{'short_desc'} ),
        long_desc   => from_json( $category->{'long_desc'} ),
        images      => from_json( $category->{'images'} ),
        discount    => 0,
        published   => 1,
    };
    my $response = $ua->post(
        $api_base . '/category',
        { category => encode_json($c) }
    );
    $response->is_success or die("[Add][Category] $response->code: $response->content");
    push @categories, $response->content;

    say $i . ":\t" . $response->code . "\t" . $response->content;
}

# Create some products

for my $i ( 1..100 ) {
    my $p = {
        name        => from_json( $product->{'name'} ),
        short_desc  => from_json( $product->{'short_desc'} ),
        long_desc   => from_json( $product->{'long_desc'} ),
        variations  => from_json( $product->{'variations'} ),
        images      => from_json( $product->{'images'} ),
        price       => rand(100),
        taxes       => 22,
        stock       => 1,
        discount    => 0,
        published   => 1,
    };
    my $response = $ua->post(
        $api_base . '/product',
        { product => encode_json($p) }
    );
    $response->is_success or die("[Add][Product] $response->code: $response->content");

    push @products, $response->content;
    say $i . ":\t" . $response->code . "\t" . $response->content;
}

my $n_cat = $#categories;
my $n_prod = $#products;

# Add products to random categories.

for my $prod ( @products ) {
    my $c_key = rand($n_cat);
    my $response = $ua->get( $api_base . '/category/'. $categories[$c_key] . '/add/' . $prod );
    $response->is_success or die("[Link][Product] $response->code: $response->content");

    say $prod . ":\t" . $response->code . "\t" . $response->content;
}
