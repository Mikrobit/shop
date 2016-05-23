package Db;

use strict;
use warnings;
use v5.24;

use DBI;

my $config_file = 'conf.pl';
my $conf;
get_config( $config_file );

sub get_config {
    my $config_file = shift;
    open( my $confh, '<', "$config_file" )
        or die "Can't open the configuration file '$config_file'.\n";
    my $config = join "", <$confh>;
    close( $confh );
    eval $config;
}

sub conn {
    my $dbh = DBI->connect(
		$conf->{'db_host'},
	 	$conf->{'db_user'},
		$conf->{'db_pass'},
		{ pg_enable_utf8 => 1 }
	) or die ( ( defined DBI::errstr ) ? DBI::errstr : 'DBI::errstr undefined' );

    $dbh->do( "SET search_path TO shop" );
    $dbh->do( "SET NAMES 'UTF8'" );
    $dbh->do( "SET CLIENT_ENCODING TO 'UTF8'" );

    return $dbh;
}

sub prep {
    my $q = shift;

    my $dbh = conn();

    my $sa = 'SELECT * FROM ';
    my $queries = {

            ## Products
        get_products                => $sa . 'get_products()',
        get_product_by_id           => $sa . 'get_product_by_id(?)',                    # pid
        get_product_by_slug         => $sa . 'get_product_by_slug(?)',                  # slug
        get_products_by_category    => $sa . 'get_products_by_category(?)',             # cid
        get_starred_by_category     => $sa . 'get_starred_by_category(?)',              # cid
        delete_product              => $sa . 'delete_product(?)',                       # pid
        add_product                 => $sa . 'add_product(?,?,?,?,?,?,?,?,?,?,?,?,?)',  # name slug short_desc long_desc variations
                                                                                        # images price taxes stock weight discount published starred
        update_product              => $sa . 'update_product(?,?,?,?,?,?,?,?,?,?,?,?,?,?)', # pid name slug short_desc long_desc variations
                                                                                        # images price taxes stock weight discount published starred
        star_product                => $sa . 'star_product(?)',                         # pid
        toggle_product_star         => $sa . 'toggle_product_star(?)',                  # pid

            ## Categories
        get_categories              => $sa . 'get_categories()',
        get_category_by_id          => $sa . 'get_category_by_id(?)',                   # cid
        get_category_by_slug        => $sa . 'get_category_by_slug(?)',                 # slug
        get_categories_for_product  => $sa . 'get_categories_for_product(?)',           # pid
        delete_category             => $sa . 'delete_category(?)',                      # cid
        add_product_to_category     => $sa . 'add_product_to_category(?,?)',            # pid cid
        del_product_from_category   => $sa . 'del_product_from_category(?,?)',          # pid cid
        del_products_from_category  => $sa . 'del_products_from_category(?)',           # cid
        del_product_from_categories => $sa . 'del_product_from_categories(?)',          # pid
        add_category                => $sa . 'add_category(?,?,?,?,?,?,?,?)',           # name slug short_desc long_desc images
                                                                                        # discount published starred
        update_category             => $sa . 'update_category(?,?,?,?,?,?,?,?,?)',      # cid name slug short_desc long_desc
                                                                                        # images discount published starred
        star_category               => $sa . 'star_category(?)',                        # cid
        toggle_category_star        => $sa . 'toggle_category_star(?)',                 # cid

            ## Users
        get_users                   => $sa . 'get_users()',
        get_user                    => $sa . 'get_user(?)',                                     # email
        delete_user                 => $sa . 'delete_user(?)',                                  # email
        authenticate_user           => $sa . 'authenticate_user(?,?)',                          # email token
        add_user                    => $sa . 'add_user(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)', # email token type active cart wishlist name
                                                                                                # surname city province city_code address
                                                                                                # country telephone cc_number cc_cvd
                                                                                                # cc_valid_m cc_valid_y paypal

        update_user                 => $sa . 'update_user(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',# email token type active cart wishlist name
                                                                                                # surname city province city_code address
                                                                                                # country telephone cc_number cc_cvd
                                                                                                # cc_valid_m cc_valid_y paypal
        # carts, wishlists
        get_cart                    => $sa . 'get_cart(?)',                                     # email
        get_wishlist                => $sa . 'get_wishlist(?)',                                 # email
        update_cart                 => $sa . 'update_cart(?,?)',                                # email cart
        update_wishlist             => $sa . 'update_wishlist(?,?)',                            # email wishlist
        # authentication
        create_token                => $sa . 'create_token(?)',                                 # email
        verify_token                => $sa . 'verify_token(?,?)',                               # email token
        invalidate_token            => $sa . 'invalidate_token(?,?)',                           # email token

            ## Orders
        get_orders                  => $sa . 'get_orders()',
        get_order                   => $sa . 'get_order(?)',                                # oid
        delete_order                => $sa . 'delete_order(?)',                             # oid
        add_order                   => $sa . 'add_order(?,?,?,?,?,?,?,?,?,?,?,?,?,?)',      # email products total pay_method payed sent
                                                                                            # name surname city province city_code
                                                                                            # address country telephone
        update_order                => $sa . 'update_order(?,?,?,?,?,?,?,?,?,?,?,?,?,?)', # oid email products total pay_method payed
                                                                                            # sent name surname city province city_code address
                                                                                            # country telephone
        set_order_payed             => $sa . 'set_order_payed(?)',                          # oid
        set_order_sent              => $sa . 'set_order_sent(?)',                           # oid

    };
    return $dbh->prepare( $queries->{$q} ) || die ( ( defined DBI::errstr ) ? DBI::errstr : 'DBI::errstr undefined' );
}

"Ambè";
