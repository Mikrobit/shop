package Order;

use strict;
use warnings;
use v5.20;

use JSON::Parse qw(valid_json parse_json);
use JSON;
use Data::Printer;

use lib '.';
use Db;

=over

=item new()

    Constructor.
    Can optionally be passed a order such as:
    
    C<my $order = Order->new($o);>

    where C<$o> is a hash ref containing the db columns 

=back

=cut

sub new {
    my ( $class, $p ) = @_;
    
    my $order;
    if ( defined $p ) {
        $order = getData( $p->{'id'} );
    }

    my $self = {
        id          => $p->{'id'}           || undef,
        user        => $p->{'user'}         || '',
        products    => $p->{'products'}     || $order->{'products'},
        total       => $p->{'total'}        || $order->{'total'},
        pay_method  => $p->{'pay_method'}   || $order->{'pay_method'},
        payed       => $p->{'payed'}        || $order->{'payed'},
        sent        => $p->{'sent'}         || $order->{'sent'},
        name        => $p->{'name'}         || $order->{'name'},
        surname     => $p->{'surname'}      || $order->{'surname'},
        city        => $p->{'city'}         || $order->{'city'},
        province    => $p->{'province'}     || $order->{'province'},
        city_code   => $p->{'city_code'}    || $order->{'city_code'},
        address     => $p->{'address'}      || $order->{'address'},
        country     => $p->{'country'}      || $order->{'country'},
        telephone   => $p->{'telephone'}    || $order->{'telephone'},
    };

    if( ref($self->{'products'}) ne 'ARRAY' ) {
        $self->{'products'} = [ $self->{'products'} ];
    }

    return bless( $self, $class );
}

sub list {
    my $class = shift;

    my $handle = Db::prep('get_orders');
    $handle->execute();
    my $result = $handle->fetchrow_hashref;
    my $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 } ;

    return [ $status, $result->{'orders'} ];
}

sub getData {
    my $id = shift;

    my $handle = Db::prep('get_order');
    $handle->execute( $id );
    my $result = $handle->fetchrow_hashref or die $handle->errstr;
    my $order;
    $order = parse_json( $result->{'order'} ) if( valid_json( $result->{'order'} ) );

    return $order;
}

=over

=item get()

    Populate an Order object with data from the database

=back

=cut

sub get {
    my $self = shift;
    my $status = { ok => 0, status => 'You can get an order by giving an id', code => 400 };
    my $result;

    my $handle = Db::prep('get_order');
    $handle->execute( $self->{'id'} );
    $result = $handle->fetchrow_hashref;

    $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 404, order => $result->{'order'} };

    if( $result->{'ok'} ) {
        $status->{'code'} = 200;
    }

    return $status;
}

=over

=item save()

    Write this Order's data to the database.

=back

=cut

sub save {
    my $self = shift;

    my $handle = Db::prep('add_order');
    $handle->execute(
        $self->{'user'},
        $self->{'products'},
        $self->{'total'},
        $self->{'pay_method'},
        $self->{'payed'},
        $self->{'sent'},
        $self->{'name'},
        $self->{'surname'},
        $self->{'city'},
        $self->{'province'},
        $self->{'city_code'},
        $self->{'address'},
        $self->{'country'},
        $self->{'telephone'},
    );
    my $result = $handle->fetchrow_hashref;
    my $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 201, oid => $result->{'order_id'} };

    $status->{'code'} = 500 unless( $result->{'ok'} );

    return $status;
}

sub update {
    my $self = shift;
    my $status = { ok => 0, status => 'You can modify an order by giving an id', code => 400 };

    if( $self->{'id'} =~ m/\d+/ ) {
        my $handle = Db::prep('update_order');
        $handle->execute(
            $self->{'id'},
            $self->{'user'},
            $self->{'total'},
            $self->{'pay_method'},
            $self->{'payed'},
            $self->{'sent'},
            $self->{'name'},
            $self->{'surname'},
            $self->{'city'},
            $self->{'province'},
            $self->{'city_code'},
            $self->{'address'},
            $self->{'country'},
            $self->{'telephone'},
        );
        my $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 201 };
    }

    return $status;

}

sub delete {
    my $self = shift;
    my $status = { ok => 0, status => 'You can delete a order by giving an id', code => 400 };
    my $result;

    if( $self->{'id'} =~ m/\d+/ ) {
        my $handle = Db::prep('delete_order');
        $handle->execute( $self->{'id'} );
        $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 };
    }

    return $status;
}

"Ambè";
