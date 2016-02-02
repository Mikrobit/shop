package front;
use Dancer2;

use HTTP::Tiny;
use JSON::Parse qw(valid_json);
use Encode;
use Data::Printer;

our $VERSION = '0.1';

my $ua = HTTP::Tiny->new;
my $host = config->{'api_base'};
$ua->timeout(30);

get '/' => sub {
    template 'home';
};

prefix '/shop' => sub {

    # Show starred products for each category
    get '/' => sub {
        my $r_cat = $ua->get( $host . '/category/list' );
        my $categories = from_json( $r_cat->{'content'} );
        my $i = 0;
        for my $cat ( @{$categories} ) {
            my $r_prod = $ua->get( $host . '/category/' . $cat->{'id'} . '/starred' );
            $categories->[$i]->{'products'} = from_json( $r_prod->{'content'} );
            $i++;
        }

        template 'shop/index' => {
            categories => $categories,
        };
    };

    # Show product's card
    get '/product/:id' => sub {
        my $r = $ua->get( $host . '/product/' . param 'id' );
        my $product = from_json( $r->{'content'} );

        template 'shop/product' => {
            product => $product,
        };
    };

    # Show all products for this category
    get '/category/:cat' => sub {
        my $r = $ua->get( $host . '/category/' . param 'cat' );
        my $res = from_json( $r->{'content'} );
        my $products = $res->{'products'};
        my $category = $res->{'category'};

        template 'shop/category' => {
            category => $category,
            products => $products,
        };
    };

=cut
    get '/all' => sub {
        my $r_prod = $ua->get( $host . '/product/list' );
        my $products = from_json( $r_prod->{'content'} );
        my $r_cat = $ua->get( $host . '/category/list' );
        my $categories = from_json( $r_cat->{'content'} );

        template 'index' => {
            products => $products,
            categories => $categories,
        };
    };
=cut
};
true;
