package Category;

use strict;
use warnings;
no warnings "experimental::autoderef";
use v5.16;

use JSON::Parse qw(valid_json parse_json);
use JSON;

use Data::Printer;

use lib '.';
use Db;

=over

=item new()

    Constructor.
    Can optionally be passed a category such as:

    C<my $category = Category->new($p);>

    where C<$p> is a hash ref containing the following fields:

    * (int) id
    * (json) name
    * (json) short_desc
    * (json) long_desc
    * (json) images
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
        images      => $p->{'images'}       || [],
        discount    => $p->{'discount'}     || 0,
        published   => $p->{'published'}    || 1,
        starred     => $p->{'starred'}      || 0,
    };

    $self->{'slug'} = $class->_mkSlug( $self->{'name'} ) if( $self->{'name'} and $self->{'name'} ne '{}' );

    return bless( $self, $class );
}

sub list {
    my $class = shift;
    my $status = { ok => 0, status => '', code => 400 };

    my $handle = Db::prep('get_categories');
    $handle->execute();
    my $result = $handle->fetchrow_hashref;
    $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 } ;

    return [ $status, $result->{'categories'} ];
}

=over

=item get()

    Populate a Category object with data from the database

=back

=cut

sub get {
    my $self = shift;
    my $status = { ok => 0, status => 'You can get a category by giving an id', code => 400 };
    my $result;

    if( $self->{'id'} =~ /^\d+$/ ) {

        my $handle = Db::prep('get_category_by_id');
        $handle->execute( $self->{'id'} );
        $result = $handle->fetchrow_hashref;

        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 404 };

        if( $result->{'ok'} ) {
            $status->{'code'} = 200;
        }
    }

    return [ $status, $result->{'category'}, $result->{'products'} ];
}

=over

=item get_starred()

    Get the first 6 products for this category

=back
=cut

sub get_starred() {
    my $self = shift;
    my $status = { ok => 0, status => 'You can get a category by giving an id', code => 400 };
    my $result;

    my $handle = Db::prep('get_starred_by_category');
    $handle->execute( $self->{'id'} );
    $result = $handle->fetchrow_hashref;

    $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 404 };

    if( $result->{'ok'} ) {
        $status->{'code'} = 200;
    }

    return [ $status, $result->{'products'} ];
}

=over

=item save()

    Write this Category's data to the database.

=back

=cut

sub save {
    my $self = shift;

    my $handle = Db::prep('add_category');
    $handle->execute(
        to_json($self->{'name'}),
        $self->{'slug'},
        to_json($self->{'short_desc'}),
        to_json($self->{'long_desc'}),
        to_json($self->{'images'}),
        $self->{'discount'},
        $self->{'published'},
        $self->{'starred'},
    );
    my $result = $handle->fetchrow_hashref;
    my $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 201, cid => $result->{'category_id'} };

    return $status;
}

sub update {
    my $self = shift;
    my $status = { ok => 0, status => 'You can modify a category by giving an id', code => 400 };

    if( $self->{'id'} =~ /^\d+$/ ) {
        my $handle = Db::prep('update_category');
        $handle->execute(
            $self->{'id'},
            to_json($self->{'name'}),
            $self->{'slug'},
            to_json($self->{'short_desc'}),
            to_json($self->{'long_desc'}),
            to_json($self->{'images'}),
            $self->{'discount'},
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
    my $status = { ok => 0, status => 'You can star a category by giving an id', code => 400 };

    if( $self->{'id'} =~ /^\d+$/ ) {
        my $handle = Db::prep('star_category');
        $handle->execute( $self->{'id'} );
        my $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 };
        $status->{'code'} = 404 if( !$result->{'ok'} );
    }

    return $status;
}

sub toggle_star {
    my $self = shift;
    my $status = { ok => 0, status => 'You can star/unstar a category by giving an id', code => 400 };

    if( $self->{'id'} =~ /^\d+$/ ) {
        my $handle = Db::prep('toggle_category_star');
        $handle->execute( $self->{'id'} );
        my $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 };
        $status->{'code'} = 404 if( !$result->{'ok'} );
    }

    return $status;
}

sub delete {
    my $self = shift;
    my $status = { ok => 0, status => 'You can delete a category by giving an id', code => 400 };
    my $result;

    if( $self->{'id'} =~ /^\d+$/ ) {
        my $handle = Db::prep('delete_category');
        $handle->execute( $self->{'id'} );
        $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 };
    }

    return $status;
}

sub add_product {
    my ( $self, $pid ) = @_;
    my $status = { ok => 0, status => 'Please pass in a valid product id', code => 400 };
    my $result;

    if( $self->{'id'} =~ /^\d+$/ and $pid =~ /^\d+$/ ) {
        my $handle = Db::prep('add_product_to_category');
        $handle->execute( $pid, $self->{'id'} );
        $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 };
    }

    return $status;
}

sub del_product {
    my ( $self, $pid ) = @_;
    my $status = { ok => 0, status => 'Please pass in a valid product id', code => 400 };
    my $result;

    if( $self->{'id'} =~ /^\d+$/ and $pid =~ /^\d+$/ ) {
        my $handle = Db::prep('del_product_from_category');
        $handle->execute( $pid, $self->{'id'} );
        $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 };
    }

    return $status;
}

sub del_products {
    my $self = shift;
    my $status = { ok => 0, status => 'Please pass in a valid category id', code => 400 };
    my $result;

    if( $self->{'id'} =~ /^\d+$/ ) {
        my $handle = Db::prep('del_products_from_category');
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
            splice( $self->{'images'}, $i, 1 );
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
    my $slug = time . '.' . rand(1000) . "_" . $n;
    $slug =~ s/\s/_/g;
    $slug =~ s/\W//g;
    $slug =~ s/_/-/g;
    return lc $slug;
}

"Ambè";
