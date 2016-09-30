#!/usr/bin/env perl

use strict;
use warnings;
use v5.20;

use Dancer;
use Dancer::Plugin::SecureHeaders;

use JSON::Parse qw(valid_json parse_json);
use Data::Printer;

use lib '../lib';
use Product;
use Category;
use User;
use Order;

#setting( port => 2000 );
setting( log => 'debug' );
setting( content_type => 'application/json' );
setting( charset => 'UTF-8' );
setting( logger => 'console' );
setting( traces => 1 );
setting( server_tokens => 0 );
setting( img_path => '../admin/public/i/' );

# Unbuffered output
#$| = 1;

post '/login' => sub {
    my $email = params->{'email'};
    my $pass = params->{'pass'};
    my $status = { ok => 0, status => "User not authenticated", code => 403 };

    my $user = User->new( { email => $email, token => $pass } );
    my $result = $user->authenticate();
    if( $result->{'ok'} ) {
        $status->{'ok'} = 1;
        $status->{'code'} = 200;
    }

    status( $status->{'code'} );
    return $status->{'status'} unless $status->{'ok'};
    return $result->{'user'};
};


prefix '/category' => sub {

    get '/list' => sub {
        my $result = Category->list();
        my $status = $result->[0];
        my $categories = $result->[1];

        status( $status->{'code'} );
        return $categories if $status->{'ok'};
        return $status->{'status'};
    };

    get '/:id' => sub {
        my $category = Category->new( { id => params->{'id'} } );
        my $result = $category->get();

        status( $result->[0]->{'code'} );
        return '{"category":'.$result->[1].'}' unless $result->[2];
        return '{"category":'.$result->[1].',"products":'.$result->[2].'}';
    };

    get '/:id/starred' => sub {
        my $category = Category->new( { id => params->{'id'} } );
        my $result = $category->get_starred();
        my $status = $result->[0];
        my $products = $result->[1];

        status( $status->{'code'} );
        return $products if $status->{'ok'};
        return $status->{'status'};
    };

    post '/' => sub {
        # Create a new category with params->{'category'}
        my $status = { ok => 0, status => 'Please, give me a json-formatted category to be added', code => 400 };
        my $input = params->{'category'};

        if( !valid_json( $input ) ) {
            status( $status->{'code'} );
            return $status->{'status'};
        }

        my $category = Category->new( parse_json( $input ) );
        $status = $category->save();

        status( $status->{'code'} );
        return $status->{'cid'} if $status->{'ok'};
        return $status->{'status'};
    };

    post '/:id' => sub {
        # update category :id using data in params->{'category'}
        my $id = param 'id';
        my $input = param 'category';
        my $status = { ok => 0, status => 'Please, give me a json-formatted category', code => 400 };

        if( !valid_json( $input ) ) {
            status( $status->{'code'} );
            return $status->{'status'};
        }

        $input = parse_json( $input );
        $input->{'id'} = $id;

        my $category = Category->new( $input );
        $status = $category->update();

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    del '/:id' => sub {
        my $input = params->{'id'};

        my $category = Category->new( { id => $input } );
        my $status = $category->delete();

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    options '/:id' => sub {
        return;
    };

    post '/:id/products' => sub {
        my $id = param 'id';
        my @products = parse_json( param 'products' );
        my $category = Category->new( { id => $id } );
        my $status;

        for my $product ( @{$products[0]} ) {
            # XXX: don't mask old errors!!!
            $status = $category->add_product( $product );
        }

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    get '/:id/add/:pid' => sub {
        # add product :pid to category :id
        my $category = Category->new( { id => params->{'id'} } );
        my $status = $category->add_product( params->{'pid'} );

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    get '/:id/del/:pid' => sub {
        # delete product :pid from category :id
        my $category = Category->new( { id => params->{'id'} } );
        my $status = $category->del_product( params->{'pid'} );

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    get '/:id/star' => sub {
        my $category = Category->new( { id => params->{'id'} } );
        my $status = $category->toggle_star();

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    del '/:id/products' => sub {
        my $id = param 'id';
        my $category = Category->new( { id => $id } );
        my $status = $category->del_products();

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    del '/:id/images/:image' => sub {
        my $id = params->{'id'};
        my $image_key = params->{'image'};

        # XXX: This sucks.
        my $category = Category->new( { id => $id } );
        my $status = $category->get();
        $category = Category->new( parse_json( $status->[1] ) );
        $status = $category->del_image( $image_key, config->{'img_path'} );

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    options '/:id/images/:image' => sub {
        # ajax first issues a options request, than what I asked.
        # It just needs to see the headers.
        return;
    };

};

prefix '/product' => sub {

    get '/list' => sub {
        my $result = Product->list();
        my $status = $result->[0];
        my $products = $result->[1];

        status( $status->{'code'} );
        return $products if $status->{'ok'};
        return $status->{'status'};
    };

    get '/list/:id' => sub {
        # :id is a category's id
        my $result = Product->list( params->{'id'} );
        my $status = $result->[0];
        my $products = $result->[1];

        status( $status->{'code'} );
        return $products if $status->{'ok'};
        return $status->{'status'};
    };

    get '/:id' => sub {
        my $product = Product->new( { id => params->{'id'} } );
        my $result = $product->get();

        status( $result->[0]->{'code'} );
        return $result->[1];
    };

    post '/' => sub {
        # create a new product with params->{'product'}
        my $status = { ok => 0, status => 'Please, give me a json-formatted product to be added', code => 400 };
        my $input = params->{'product'};

        if( !valid_json( $input ) ) {
            status( $status->{'code'} );
            return $status->{'status'};
        }

        my $product = Product->new( parse_json( $input ) );
        $status = $product->save();

        status( $status->{'code'} );
        return $status->{'pid'} if $status->{'ok'};
        return $status->{'status'};
    };

    post '/:id' => sub {
        # update product with id :id using data in params->{'product'}
        my $id = params->{'id'};
        my $input = params->{'product'};
        my $status = { ok => 0, status => 'Please, give me a json-formatted product', code => 400 };

        if( !valid_json( $input ) ) {
            status( $status->{'code'} );
            return $status->{'status'};
        }

        $input = parse_json( $input );
        $input->{'id'} = $id;

        my $product = Product->new( $input );
        $status = $product->update();

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    get '/:id/star' => sub {
        my $product = Product->new( { id => params->{'id'} } );
        my $status = $product->toggle_star();

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    del '/:id' => sub {
        my $input = params->{'id'};

        my $product = Product->new( { id => $input } );
        my $status = $product->delete();

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    options '/:id' => sub {
        return;
    };

    del '/:id/categories' => sub {
        # Remove all associations of this product with its categories.
        my $input = params->{'id'};

        my $product = Product->new( { id => $input } );
        my $status = $product->del_categories();

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    get '/:id/categories' => sub {
        # Get categories associated with this product.
        my $input = params->{'id'};

        my $product = Product->new( { id => $input } );
        my $status = $product->get_categories();

        status( $status->{'code'} );
        return $status->{'categories'} if $status->{'ok'};
        return $status->{'status'};
    };

    del '/:id/images/:image' => sub {
        my $id = params->{'id'};
        my $image_key = params->{'image'};

        # XXX: This sucks.
        my $product = Product->new( { id => $id } );
        my $status = $product->get();
        $product = Product->new( parse_json( $status->[1] ) );
        $status = $product->del_image( $image_key, config->{'img_path'} );

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    options '/:id/images/:image' => sub {
        # ajax first issues a options request, then what I asked.
        # It just needs to see the headers.
        return;
    };
};

prefix '/user' => sub {

    get '/list' => sub {
        my $result = User->list();
        my $status = $result->[0];
        my $users = $result->[1];

        status( $status->{'code'} );
        return $users if $status->{'ok'};
        return $status->{'status'};
    };

    get '/:email' => sub {
        my $user = User->new( { email => params->{'email'} } );
        my $status = $user->get();

        status( $status->{'code'} );
        return $status->{'user'} if $status->{'ok'};
        return $status->{'status'};
    };

    post '/' => sub {
        # create a new user with params->{'user'}
        my $status = { ok => 0, status => 'Please, give me a json-formatted user to be added', code => 400 };
        my $input = params->{'user'};

        if( !valid_json( $input ) ) {
            status( $status->{'code'} );
            return $status->{'status'};
        }

        my $user = User->new( parse_json( $input ) );
        $status = $user->save();

        status( $status->{'code'} );
        return $status->{'uid'} if $status->{'ok'};
        return $status->{'status'};
    };

    post '/:email' => sub {
        # update user with email :email using data in params->{'user'}
        my $email = params->{'email'};
        my $input = params->{'user'};
        my $status = { ok => 0, status => 'Please, give me a json-formatted user', code => 400 };

        if( !valid_json( $input ) ) {
            status( $status->{'code'} );
            return $status->{'status'};
        }

        $input = parse_json( $input );
        $input->{'email'} = $email;

        my $user = User->new( $input );
        $status = $user->update();

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    del '/:email' => sub {
        my $input = params->{'email'};

        my $user = User->new( { email => $input } );
        my $status = $user->delete();

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    options '/:email' => sub {
        # ajax first issues a options request, than what I asked.
        # It just needs to see the headers.
        return;
    };

    # TODO - cart:
    # Cart is client-side, then stored server-side for resiliency.
    get '/:email/cart' => sub {
        my $email = params->{'email'};
        my $user = User->new( { email => $email } );

        #TODO
        # get user's cart
        my $cart = $user->getCart();
        p $cart;
        # return it (as json)
        return $cart;
    };
    post '/:email/cart/update' => sub {
        my $email = params->{'email'};
        my $cart = params->{'cart'};

        my $status = { ok => 0, status => 'Please, give me an email and a json cart', code => 400 };

        if( !valid_json( $cart ) ) {
            status( $status->{'code'} );
            return $status->{'status'};
        }
        my $user = User->new( { email => $email, cart => $cart } );
        $status = $user->update();

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };
    options '/:email/cart/update' => sub {
        return;
    };


=cut
    ## User authentication, for frontend users and client administrators
    #
    # NOTE This is *not* api authentication. That's done by the webserver. NOTE
    #
    post '/activate' => sub {
        my $email = params->{'email'};

        my $user = User->new( { email => $email } );
        my $status = $user->newToken();

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};

    };

    post '/activate/:token' => sub {
        my $email = params->{'email'};
        my $token = params->{'token'};

        my $user = User->new( { email => $email } );
        my $status = $user->activate( $token );

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    post '/deactivate/:token' => sub {
        my $email = params->{'email'};
        my $token = params->{'token'};

        my $user = User->new( { email => $email } );
        my $status = $user->deactivate( $token );

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };
=cut
};

prefix '/order' => sub {

    get '/list' => sub {
        my $result = Order->list();
        my $status = $result->[0];
        my $users = $result->[1];

        status( $status->{'code'} );
        return $users if $status->{'ok'};
        return $status->{'status'};
    };

    get '/:id' => sub {
        my $order = Order->new( { id => params->{'id'} } );
        my $status = $order->get();

        status( $status->{'code'} );
        return $status->{'order'} if $status->{'ok'};
        return $status->{'status'};
    };

    post '/' => sub {
        # create a new order with params->{'order'}
        my $status = { ok => 0, status => 'Please, give me a json-formatted order to be added', code => 400 };
        my $input = params->{'order'};

        if( !valid_json( $input ) ) {
            status( $status->{'code'} );
            return $status->{'status'};
        }

        my $order = Order->new( parse_json( $input ) );
        $status = $order->save();

        status( $status->{'code'} );
        return $status->{'oid'} if $status->{'ok'};
        return $status->{'status'};
    };

    post '/:id' => sub {
        # update order with id :id using data in params->{'order'}
        my $id = params->{'id'};
        my $input = params->{'order'};
        my $status = { ok => 0, status => 'Please, give me a json-formatted order', code => 400 };

        if( !valid_json( $input ) ) {
            status( $status->{'code'} );
            return $status->{'status'};
        }

        $input = parse_json( $input );
        $input->{'id'} = $id;

        my $order = Order->new( $input );
        $status = $order->update();

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    del '/:id' => sub {
        my $input = params->{'id'};

        my $order = Order->new( { id => $input } );
        my $status = $order->delete();

        status( $status->{'code'} );
        return if $status->{'ok'};
        return $status->{'status'};
    };

    options '/:id' => sub {
        # ajax first issues a options request, than what I asked.
        # It just needs to see the headers.
        return;
    };

};

start;
