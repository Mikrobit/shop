package Product;

use strict;
use warnings;
#no warnings "experimental::autoderef";
use v5.24;

use JSON::Parse qw(valid_json parse_json);
use JSON;

use Data::Printer;

use lib '.';
use Db;

=over

=item new()

    Constructor.
    Can optionally be passed a product such as:
    
    C<my $product = Product->new($p);>

    where C<$p> is a hash ref containing the following fields:

    * (int) id
    * (json) name
    * (json) short_desc
    * (json) long_desc
    * (json) variations
    * (json) images
    * (float) price
    * (float) taxes
    * (int) stock
    * (int) weight
    * (float) discount
    * (bool) published
    * (bool) starred

=back

=cut

sub new {
    my ( $class, $p ) = @_;
    
    my $self = {
        id          => $p->{'id'}           || 0,
        name        => $p->{'name'}         || {},
        short_desc  => $p->{'short_desc'}   || {},
        long_desc   => $p->{'long_desc'}    || {},
        variations  => $p->{'variations'}   || {},
        images      => $p->{'images'}       || [],
        price       => $p->{'price'}        || 0.0,
        taxes       => $p->{'taxes'}        || 0.0,
        stock       => $p->{'stock'}        || 1,
        discount    => $p->{'discount'}     || 0,
        weight      => $p->{'weight'}       || 100,
        published   => $p->{'published'}    || 1,
        starred     => $p->{'published'}    || 0,
    };


    $self->{'slug'} = $class->_mkSlug( $self->{'name'} ) if( $self->{'name'} and $self->{'name'} ne '{}' );

    $self->{'price'} =~ s/,/\./g;

    return bless( $self, $class );
}

sub list {
    my ( $class, $category ) = @_;
    my $status = { ok => 0, status => 'You can get the products in a category by giving a category id', code => 400 };

    my $result;

    if( defined $category and $category =~ /^\d+$/ ) {
        my $handle = Db::prep('get_products_by_category');
        $handle->execute( $category );
        $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 } ;
    } else {
        my $handle = Db::prep('get_products');
        $handle->execute();
        $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 } ;
    }

    return [ $status, $result->{'products'} ];
}

=over

=item get()

    Populate a Product object with data from the database

=back

=cut

sub get {
    my $self = shift;
    my $status = { ok => 0, status => 'You can get a product by giving an id', code => 400 };
    my $result;

    if( $self->{'id'} =~ /^\d+$/ ) {

        my $handle = Db::prep('get_product_by_id');
        $handle->execute( $self->{'id'} );
        $result = $handle->fetchrow_hashref;

        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 404 };

        if( $result->{'ok'} ) {
            $status->{'code'} = 200;
        }
    }

    return [ $status, $result->{'product'} ];
}

sub get_categories {
    my $self = shift;
    my $status = {  ok => 0, status => 'You can get categories by giving a product id', code => 400 };
    my $result;

    if( $self->{'id'} =~ /^\d+$/ ) {

        my $handle = Db::prep('get_categories_for_product');
        $handle->execute( $self->{'id'} );
        $result = $handle->fetchrow_hashref;

        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 404 };

        if( $result->{'ok'} ) {
            $status->{'code'} = 200;
            $status->{'categories'} = $result->{'categories'};
        }
    }

    return $status;
}

=over

=item save()

    Write this Product's data to the database.

=back

=cut

sub save {
    my $self = shift;

    my $handle = Db::prep('add_product');
    $handle->execute(
        to_json($self->{'name'}),
        $self->{'slug'},
        to_json($self->{'short_desc'}),
        to_json($self->{'long_desc'}),
        to_json($self->{'variations'}),
        to_json($self->{'images'}),
        $self->{'price'},
        $self->{'taxes'},
        $self->{'stock'},
        $self->{'discount'},
        $self->{'weight'},
        $self->{'published'},
        $self->{'starred'},
    );
    my $result = $handle->fetchrow_hashref;
    my $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 201, pid => $result->{'product_id'} };

    # TODO: If a category is specified, deal with it.
    return $status;
}

sub update {
    my $self = shift;
    my $status = { ok => 0, status => 'You can modify a product by giving an id', code => 400 };

    if( $self->{'id'} =~ /^\d+$/ ) {
        my $handle = Db::prep('update_product');
        $handle->execute(
            $self->{'id'},
            to_json($self->{'name'}),
            $self->{'slug'},
            to_json($self->{'short_desc'}),
            to_json($self->{'long_desc'}),
            to_json($self->{'variations'}),
            to_json($self->{'images'}),
            $self->{'price'},
            $self->{'taxes'},
            $self->{'stock'},
            $self->{'discount'},
            $self->{'weight'},
            $self->{'published'},
            $self->{'starred'},
        );
        my $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 201 };
        $status->{'code'} = 404 if( !$result->{'ok'} );
    }

    return $status;

}

sub star {
    my $self = shift;
    my $status = { ok => 0, status => 'You can star a product by giving an id', code => 400 };

    if( $self->{'id'} =~ /^\d+$/ ) {
        my $handle = Db::prep('star_product');
        $handle->execute( $self->{'id'} );
        my $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 };
        $status->{'code'} = 404 if( !$result->{'ok'} );
    }

    return $status;
}

sub unstar {
}

sub toggle_star {
    my $self = shift;
    my $status = { ok => 0, status => 'You can star/unstar a product by giving an id', code => 400 };

    if( $self->{'id'} =~ /^\d+$/ ) {
        my $handle = Db::prep('toggle_product_star');
        $handle->execute( $self->{'id'} );
        my $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 };
        $status->{'code'} = 404 if( !$result->{'ok'} );
    }

    return $status;
}


sub delete {
    my $self = shift;
    my $status = { ok => 0, status => 'You can delete a product by giving an id', code => 400 };
    my $result;

    if( $self->{'id'} =~ /^\d+$/ ) {
        my $handle = Db::prep('delete_product');
        $handle->execute( $self->{'id'} ) or $result = 0;
        $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 };
    }

    return $status;
}

sub del_categories {
    my $self = shift;
    my $status = { ok => 0, status => 'Please pass in a valid product id', code => 400 };
    my $result;

    if( $self->{'id'} =~ /^\d+$/ ) {
        my $handle = Db::prep('del_product_from_categories');
        $handle->execute( $self->{'id'} );
        $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 };
    }

    return $status;
}

sub del_image {
    my ( $self, $key, $path ) = @_;
    my $status = { ok => 0, status => 'Please, pass in a valid image key', code => 400 };
    my $result;

    my $i = 0;
    foreach my $img ( values @{$self->{'images'}} ) {

        my $img_key = $img->{'url'}->{'it'};
        $img_key =~ s/\/i\/it\///g;

        if( $img_key eq $key ) {
            splice( @{$self->{'images'}}, $i, 1 );
            $status = { ok => 1, status => 'Image deleted', code => 200 };
            $self->update();
            unlink $path . 'it/' . $key or $status->{'status'} = $!;
            unlink $path . 'it/thumb/' . $key or $status->{'status'} = $!;
        }

        $i++;
    }

    return $status;
}

# XXX: This sucks.
sub _mkSlug {
    my ( $class, $name ) = @_;
    my $n = $name->{'EN'} // "no_name";
    my $slug = time . '.' . rand(1000) . '_' . $n;
    $slug =~ s/\s/_/g;
    $slug =~ s/\W//g;
    $slug =~ s/_/-/g;
    return lc $slug;
}

"Ambè";
