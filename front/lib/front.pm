package front;
use Dancer2;

use HTTP::Tiny;
use JSON qw(encode_json decode_json);
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

# Receive user & password, store session and redirect appropriately.
post '/login' => sub {

    redirect params->{'url'} . '?failed=1' unless ( params->{'email'} and params->{'token'} );
    my $email = params->{'email'};
    my $pass = params->{'token'};

    my $response = $ua->post_form(
        $host . '/login',
        { email => $email, pass => $pass }
    );

    if( $response->{'success'} ) {
        my $user = decode_json( $response->{'content'} );

		session email => $user->{'email'};
		session nicename => $user->{'name'} . ' ' . $user->{'surname'};
		session type => $user->{'type'};

		redirect params->{'url'};
    } else {
        redirect params->{'url'} . '?failed=1';
    }
};

post '/register' => sub {

    redirect params->{'url'} . '?failed=1' unless ( params->{'email'} and params->{'token'} );
    my $email = params->{'email'};
    my $pass = params->{'token'};

    my $response = $ua->post_form(
        $host . '/user/',
        { user => encode_json({ email => $email, token => $pass }) }
    );
    if( $response->{'success'} ) {
        session email => $email;
        session nicename => $email;
        session type => 'user';

		redirect params->{'url'};
    } else {
        redirect params->{'url'} . '?failed=1';
    }

};

any ['get','post'] => '/logout' => sub {
    app->destroy_session;
    redirect params->{'url'};
};

get '/cart' => sub {

    if( session('email') ) { # Logged in
        my $r = $ua->get( $host . '/user/' . session('email') );
        my $user = from_json( $r->{'content'} );

        my @products;
        for my $p ( keys $user->{'cart'}->%* ) {
            my $r_prod = $ua->get( $host . '/product/' . $p ); # Optimization possible.
            my $phash = from_json( $r_prod->{'content'} );
            $phash->{'quantity'} = $user->{'cart'}->{$p}->{'quantity'};
            push @products, $phash;
        }

        #    p @products;

        template 'user/cart' => {
            products => \@products
        };
    } else {
        # I need to show client-side cart for anonymous users
        template 'user/cart';
    }
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
			email => session('email'),
			nicename => session('nicename'),
        };
    };
=cut

};


true;
