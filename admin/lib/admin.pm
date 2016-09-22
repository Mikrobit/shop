package admin;
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
    forward '/product/list';
};

# Login
hook before => sub {
    if (!session('email') && request->dispatch_path !~ m{^/login}) {
        # Pass the original path requested along to the handler:
        forward '/login', { requested_path => request->dispatch_path };
    }
};

get '/login' => sub {
    template 'login', { path => vars->{'requested_path'}, failed => params->{'failed'} };
};

post '/login' => sub {

    redirect '/login?failed=1' unless ( params->{'email'} and params->{'pass'} );
    my $email = params->{'email'};
    my $pass = params->{'pass'};

    my $response = $ua->post_form(
        $host . '/login',
        { email => $email, pass => $pass }
    );

    if( $response->{'success'} ) {
        my $user = decode_json( $response->{'content'} );

        if( $user->{'type'} eq 'admin' ) {
            session email => $user->{'email'};
            session nicename => $user->{'name'} . ' ' . $user->{'surname'};
            session type => $user->{'type'};

            redirect params->{'path'} || '/';
        } else {
            redirect '/login?failed=1';
        }
    } else {
        redirect '/login?failed=1';
    }
};

get '/logout' => sub {
    context->destroy_session;
    redirect params->{'path'} || '/login';
};

# Admin
prefix '/product' => sub {

    get '/list' => sub {
        my $response = $ua->get( $host . '/product/list' );
        my $products = decode_json( $response->{'content'} );

        template 'products/list' => { products => $products };
    };

    get '/list/:id' => sub {
        my $response = $ua->get( $host . '/product/list/' . params->{'id'} );
        my $products = decode_json( $response->{'content'} );

        template 'products/list' => { products => $products };
    };

    get '/add' => sub {
        # Create a new *void* product, then redirect.
        # This may fill up the db with unused products. Maybe a
        # [TODO] database cleaning script in cronjob
        # could be a good idea.

        my $response = $ua->post(
            $host . '/product/',
            { product => encode_json( {} ) },
        );
        my $pid = $response->{'content'} ;

        redirect '/product/update/' . $pid, 302;

    };

    get '/update/:id' => sub {
        my $id = params->{'id'};

        my $r_product = $ua->get( $host . '/product/' . $id );
        my $product = decode_json( $r_product->{'content'} );

        my $r_categories = $ua->get( $host . '/category/list' );
        my $all_categories = decode_json( $r_categories->{'content'} );

        my $r_prod_categories = $ua->get( $host . '/product/' . $id . '/categories' );
        my $categories = decode_json( $r_prod_categories->{'content'} );

        template 'products/edit' => {
            all_categories => $all_categories,
            categories => $categories,
            product => $product
        };
    };

    post '/update/:id' => sub {
        my $id = params->{'id'};

        my $r_product = $ua->get( $host . '/product/' . $id );
        my $product = decode_json( $r_product->{'content'} );

        # Images' captions
        my $i = 0;
        foreach my $img ( values @{$product->{'images'}} ) {
            my $key = $img->{'url'}->{'it'};
            $key =~ s/\/i\/it\///g;
            if( defined params->{$key} ) {
                $product->{'images'}[$i]->{'caption'}->{'it'} = params->{$key};
            }
            $i++;
        }

        my $prod = {
            id          => $id,
            name        => {
                it => params->{'name.it'},
                en => params->{'name.en'},
            },
            short_desc  => {
                it => params->{'short_desc.it'},
                en => params->{'short_desc.en'},
            },
            long_desc   => {
                it => params->{'long_desc.it'},
                en => params->{'long_desc.en'},
            },

            price       => params->{'price'},
            taxes       => params->{'taxes'},
            stock       => params->{'stock'},
            weight      => params->{'weight'},

            images      => $product->{'images'},

            starred     => params->{'starred'},

            categories  => params->{'categories'},
        };

        # save all data
        my $response = $ua->post(
            $host . '/product/' . $id,
            { product => encode_json( $prod ) }
        );
        my $message = "Product updated";
        $message = "Product not updated: " . $response->{'content'} if $response->code >= 400;

        ## TODO: All this should go in the api
        # Remove current categories associations
        my $response2 = $ua->delete( $host . '/product/' . $id . '/categories' );

        # Set new categories associations
        my $r_categories;
        my @categories;
        # Not sure if this is the best way to accomplish what I want...
        if( ref($prod->{'categories'}) ne 'ARRAY' ) {
            push @categories, $prod->{'categories'};
        } else {
            push @categories, @{$prod->{'categories'}};
        }
        foreach my $category ( @categories ) {
            $r_categories = $ua->get( $host . '/category/' . $category . '/add/' . $id );
        }
        ##

        my $response5 = $ua->get( $host . '/category/list' );
        my $all_categories = decode_json( $response5->{'content'} );

        my $response6 = $ua->get( $host . '/product/' . $id . '/categories' );
        my $categories = decode_json( $response6->{'content'} );

        my $back_url = uri_for('/product/list');

        template 'products/edit' => {
            all_categories => $all_categories,
            categories => $categories,
            product => $prod,
            error => $response->{'reason'},
            message => $message,
            url => $back_url,
        };
    };

    post '/:id/images' => sub {
        my $id = params->{'id'};
        my @files = upload('files[]');
        use Imager;

        # Get current images for product :id
        my $response = $ua->get( $host . '/product/' . params->{'id'} );
        my $product = decode_json( $response->{'content'} );
        my $current_images = $product->{'images'};

        my @res_f;
        my @new_images;
        foreach my $file ( @files ) {
            my $filename = time . rand(100) . $file->filename;
            my $path = {
                image       => './public/i/it/'                     . $filename,
                thumb       => './public/i/it/thumb/'               . $filename,
                image_url   => '/i/it/'                             . $filename,
                thumb_url   => '/i/it/thumb/'                       . $filename,
                image_uri   => request->uri_base . '/i/it/'         . $filename,
                thumb_uri   => request->uri_base . '/i/it/thumb/'   . $filename,
            };

            $file->copy_to( $path->{'image'} );

            # Generate a structure for the database
            push @new_images, {
                caption => { it => "Immagine", en => "Image" },
                url     => { it => $path->{'image_url'},  en => $path->{'image_url'} },
                thumb   => { it => $path->{'thumb_url'},  en => $path->{'thumb_url'} },
            };

            # Generate a structure for jQuery.fileupload.js
            push @res_f, {
                name            => $filename,
                size            => $file->size,
                url             => $path->{'image_url'},
                thumbnailUrl    => $path->{'thumb_url'},
                deleteUrl       => $path->{'image_url'},
                deleteType      => "DELETE",
            };

            # Create a thumbnail for the image
            # XXX: This  is  s l o o o w...
            my $img = Imager->new( file => $path->{'image'} ) or die Imager->errstr();
            my $thumb = $img->scale( ypixels => '180' );
            my $width = $thumb->getwidth;
            my $thumb2 = $thumb->crop(
                left => $width / 2 - 90,
                width => 180,
            );
            $thumb2->write( file => $path->{'thumb'} );
        }

        push @{$current_images}, @new_images;

        # Save images to db
        $product->{'images'} = $current_images;
        my $new_response = $ua->post(
            $host . '/product/' . $id,
            { product => encode_json( $product ) }
        );

        return encode_json( { files => \@res_f } );

    };

};

prefix '/category' => sub {

    get '/list' => sub {
        my $response = $ua->get( $host . '/category/list' );
        my $categories = decode_json( $response->{'content'} );

        template 'categories/list' => { categories => $categories };
    };

    get '/add' => sub {
        # Create a new *void* category, then redirect.
        # This may fill up the db with unused categories. Maybe a
        # [TODO] database cleaning script in cronjob
        # could be a good idea.

        my $response = $ua->post(
            $host . '/category/',
            { category => encode_json( {} ) },
        );
        my $cid = $response->{'content'} ;

        redirect '/category/update/' . $cid, 302;

    };

    get '/update/:id' => sub {
        my $id = params->{'id'};

        my $r_category = $ua->get( $host . '/category/' . $id );
        my $result = decode_json( $r_category->{'content'} );

        my $r_products = $ua->get( $host . '/product/list' );
        my $all_products = decode_json( $r_products->{'content'} );

        if( $all_products ) {
            my @products = @{$all_products};
            my $p_all = @products;
            my @cat_products;
            if( defined $result->{'products'} ) {
                @cat_products = @{$result->{'products'}};
            }
            my $p_cat = @cat_products;
            if( $p_cat > 0 ) {
                for( my $i=0; $i<$p_all; $i++ ) {
                    for( my $j=0; $j<$p_cat; $j++ ) {
                        if( $all_products->[$i]->{'id'} == $cat_products[$j]->{'id'} ) {
                            $all_products->[$i]->{'present'} = 1;
                        }
                    }
                }
            }
        }
        template 'categories/edit' => { category => $result->{'category'}, products => $all_products };
    };

    post '/update/:id' => sub {
        my $id = params->{'id'};

        # Remove all product/category associations and replace with the new ones.
        my @new_products = params->{'product'};

        my $p;
        if( ref($new_products[0]) eq 'ARRAY' ) {
            $p = $new_products[0];
        } else {
            $p = \@new_products;
        }

        my $del_prods = $ua->delete( $host . '/category/' . $id . '/products' );
        my $add_prods = $ua->post(
            $host . '/category/' . $id . '/products',
            { products => encode_json( $p ) }
        );

        # Get category data
        my $r_category = $ua->get( $host . '/category/' . $id );
        my $result = decode_json( $r_category->{'content'} );
        my $category = $result->{'category'};
        my $products = $result->{'products'};

        # Get all products
        my $r_products = $ua->get( $host . '/product/list' );
        my $all_products = decode_json( $r_products->{'content'} );

        if( $all_products ) {
            # Mark products as present in category
            my @products = @{$all_products};
            my $p_all = @products;
            my @cat_products;
            if( defined $result->{'products'} ) {
                @cat_products = @{$result->{'products'}};
            }
            my $p_cat = @cat_products;
            for( my $i=0; $i<$p_all; $i++ ) {
                for( my $j=0; $j<$p_cat; $j++ ) {
                    if( $all_products->[$i]->{'id'} == $cat_products[$j]->{'id'} ) {
                        $all_products->[$i]->{'present'} = 1;
                    }
                }
            }
        }

        # Deal with images' captions
        my $i = 0;
        foreach my $img ( values @{$category->{'images'}} ) {
            my $key = $img->{'url'}->{'it'};
            $key =~ s/\/i\/it\///g;
            if( defined params->{$key} ) {
                $category->{'images'}[$i]->{'caption'}->{'it'} = params->{$key};
            }
            $i++;
        }

        my $cat = {
            id          => $id,
            name        => {
                it => params->{'name.it'},
                en => params->{'name.en'},
            },
            short_desc  => {
                it => params->{'short_desc.it'},
                en => params->{'short_desc.en'},
            },
            long_desc   => {
                it => params->{'long_desc.it'},
                en => params->{'long_desc.en'},
            },

            images      => $category->{'images'},

            starred     => params->{'starred'},
        };

        # save all data
        my $response = $ua->post(
            $host . '/category/' . $id,
            { category => encode_json( $cat ) }
        );
        my $message = "Category updated";
        $message = "Category not updated: " . $response->{'content'} if $response->code >= 400;

        my $back_url = uri_for('/category/list');

        template 'categories/edit' => {
            category => $cat,
            products => $all_products,
            error => $response->{'reason'},
            message => $message,
            url => $back_url,
        };
    };

    post '/:id/images' => sub {
        my @files = upload('files[]');
        use Imager;

        # Get current images for product :id
        my $response = $ua->get( $host . '/category/' . params->{'id'} );
        my $result = decode_json( $response->{'content'} );
        my $category = $result->{'category'};
        my $current_images = $category->{'images'};

        my @res_f;
        my @new_images;
        foreach my $file ( @files ) {
            my $filename = time . rand(100) . $file->filename;
            my $path = {
                image       => './public/i/it/'                     . $filename,
                thumb       => './public/i/it/thumb/'               . $filename,
                image_url   => '/i/it/'                             . $filename,
                thumb_url   => '/i/it/thumb/'                       . $filename,
                image_uri   => request->uri_base . '/i/it/'         . $filename,
                thumb_uri   => request->uri_base . '/i/it/thumb/'   . $filename,
            };

            $file->copy_to( $path->{'image'} ) or print "Buaaaa! $!";

            # Generate a structure for the database
            push @new_images, {
                caption => { it => "Immagine", en => "Image" },
                url     => { it => $path->{'image_url'},  en => $path->{'image_url'} },
                thumb   => { it => $path->{'thumb_url'},  en => $path->{'thumb_url'} },
            };

            # Generate a structure for jQuery.fileupload.js
            push @res_f, {
                name            => $filename,
                size            => $file->size,
                url             => $path->{'image_url'},
                thumbnailUrl    => $path->{'thumb_url'},
                deleteUrl       => $path->{'image_url'},
                deleteType      => "DELETE",
            };

            # Create a thumbnail for the image
            # XXX: This  is  s l o o o w...
            my $img = Imager->new( file => $path->{'image'} ) or print Imager->errstr();;
            my $thumb = $img->scale( ypixels => '180' );
            my $width = $thumb->getwidth;
            my $thumb2 = $thumb->crop(
                left => $width / 2 - 90,
                width => 180,
            );
            $thumb2->write( file => $path->{'thumb'} );
        }

        push @{$current_images}, @new_images;

        # Save images to db
        $category->{'images'} = $current_images;
        my $new_response = $ua->post(
            $host . '/category/' . params->{'id'},
            { category => encode_json( $category ) }
        );

        return encode_json( { files => \@res_f } );

    };

};

prefix '/user' => sub {

    get '/list' => sub {
        my $response = $ua->get( $host . '/user/list' );
        my $users = decode_json( $response->{'content'} );

        template 'users/list' => { users => $users };
    };

    get '/add' => sub {
        template 'users/edit';
    };

    post '/add' => sub {
        my $user = {
            email       => params->{'email'},
            token       => params->{'token'},
            active      => params->{'active'},
            cart        => params->{'cart'} || {},
            wishlist    => params->{'wishlist'} || {},
            name        => params->{'name'},
            surname     => params->{'surname'},
            city        => params->{'city'},
            province    => params->{'province'},
            city_code   => params->{'city_code'},
            address     => params->{'address'},
            country     => params->{'country'},
            telephone   => params->{'telephone'},
            cc_number   => params->{'cc_number'},
            cc_cvd      => params->{'cc_cvd'},
            cc_valid_m  => params->{'cc_valid_m'},
            cc_valid_y  => params->{'cc_valid_y'},
            paypal      => params->{'paypal'},
        };
        my $response = $ua->post(
            $host . '/user/',
            { user => encode_json( $user ) },
        );
        my $uid = $response->{'content'} ;

        my $message = "User created";
        $message = "User not created: " . $response->{'content'} if $response->code >= 400;

        template 'users/edit' => {
            user => $user,
            error => $response->{'reason'},
            message => $message,
        };
    };

    get '/update/:email' => sub {
        my $email = params->{'email'};

        my $r_user = $ua->get( $host . '/user/' . $email );
        my $user = decode_json( $r_user->{'content'} );

        template 'users/edit' => { user => $user };
    };

    post '/update/:email' => sub {
        my $email = params->{'email'};

        my $r_user = $ua->get( $host . '/user/' . $email );
        my $user = decode_json( $r_user->{'content'} );

        my $u = {
            email       => params->{'email'},
            token       => params->{'token'},
            active      => params->{'active'},
            cart        => params->{'cart'},
            wishlist    => params->{'wishlist'},
            name        => params->{'name'},
            surname     => params->{'surname'},
            city        => params->{'city'},
            province    => params->{'province'},
            city_code   => params->{'city_code'},
            address     => params->{'address'},
            country     => params->{'country'},
            telephone   => params->{'telephone'},
            cc_number   => params->{'cc_number'},
            cc_cvd      => params->{'cc_cvd'},
            cc_valid_m  => params->{'cc_valid_m'},
            cc_valid_y  => params->{'cc_valid_y'},
            paypal      => params->{'paypal'},
        };

        # save all data
        my $response = $ua->post(
            $host . '/user/' . $email,
            { user => encode_json( $u ) }
        );
        my $message = "User updated";
        $message = "User not updated: " . $response->{'content'} if $response->code >= 400;

        template 'users/edit' => {
            user => $u,
            error => $response->{'reason'},
            message => $message,
        };
    };

};

prefix '/order' => sub {

    get '/list' => sub {
        my $response = $ua->get( $host . '/order/list' );
        my $orders = decode_json( $response->{'content'} );

        template 'orders/list' => { orders => $orders };
    };

    get '/add' => sub {
        my $response = $ua->get( $host . '/product/list' );
        my $products = decode_json( $response->{'content'} );

        template 'orders/add' => {
            products => $products,
        };
    };

    post '/add' => sub {
        my $order = {
            user        => params->{'user'},
            products    => params->{'products'},
            total       => params->{'total'},
            pay_method  => params->{'pay_method'},
            payed       => params->{'payed'},
            sent        => params->{'sent'},
            name        => params->{'name'},
            surname     => params->{'surname'},
            city        => params->{'city'},
            province    => params->{'province'},
            city_code   => params->{'city_code'},
            address     => params->{'address'},
            country     => params->{'country'},
            telephone   => params->{'telephone'},
        };
        my $response = $ua->post(
            $host . '/order/',
            { order => encode_json( $order ) },
        );
        my $oid = $response->{'content'} ;

        my $message = "Order created";
        $message = "Order not created: " . $response->{'content'} if $response->code >= 400;

        template 'orders/edit' => {
            order => $order,
            error => $response->{'reason'},
            message => $message,
        };
    };

    get '/update/:id' => sub {
        my $id = params->{'id'};

        my $r_order = $ua->get( $host . '/order/' . params->{'id'} );
        my $result = decode_json( $r_order->{'content'} );

        template 'orders/edit' => { order => $result };
    };

    post '/update/:id' => sub {
        my $id = params->{'id'};

        # TODO: set defaults with this
        my $r_order = $ua->get( $host . '/order/' . params->{'id'} );
        my $result = decode_json( $r_order->{'content'} );

        my $ord = {
            id          => params->{'id'},
            user        => params->{'user'},
            products    => params->{'products'},
            total       => params->{'total'},
            pay_method  => params->{'pay_method'},
            payed       => params->{'payed'},
            sent        => params->{'sent'},
            name        => params->{'name'},
            surname     => params->{'surname'},
            city        => params->{'city'},
            province    => params->{'province'},
            city_code   => params->{'city_code'},
            address     => params->{'address'},
            country     => params->{'country'},
            telephone   => params->{'telephone'},
        };

        # save all data
        my $response = $ua->post(
            $host . '/order/' . params->{'id'},
            { order => encode_json( $ord ) }
        );
        my $message = "Order updated";
        $message = "Order not updated: " . $response->{'content'} if $response->code >= 400;

        template 'orders/edit' => {
            order => $ord,
            error => $response->{'reason'},
            message => $message,
        };
    };

};



true;
