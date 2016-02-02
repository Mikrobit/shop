package User;

use strict;
use warnings;
use v5.16;

use Data::Printer;
use JSON::Parse qw(valid_json parse_json);
use JSON;
use Mail::RFC822::Address qw(valid);
use Data::Entropy::Algorithms qw(rand_bits);
use Digest;
use Mail::Sendmail;

use lib '.';
use Db;

=over

=item new()

    Constructor.
    Can optionally be passed a user such as:
    
    C<my $user = User->new($p);>

    where C<$p> is a hash ref containing the db columns 

=back

=cut

sub new {
    my ( $class, $p ) = @_;
    
    my $user;
    if ( defined $p ) {
        $user = getData( $p->{'email'} );
    }

    my $self = {
        email       => $p->{'email'}        || '',
        token       => $p->{'token'}        || $user->{'token'},
        active      => $p->{'active'}       || $user->{'active'},
        type        => $p->{'type'}         || $user->{'type'}          || 'user',
        cart        => $p->{'cart'}         || $user->{'cart'}          || {},
        wishlist    => $p->{'wishlist'}     || $user->{'wishlist'}      || {},
        name        => $p->{'name'}         || $user->{'name'},
        surname     => $p->{'surname'}      || $user->{'surname'},
        city        => $p->{'city'}         || $user->{'city'},
        province    => $p->{'province'}     || $user->{'province'},
        city_code   => $p->{'city_code'}    || $user->{'city_code'},
        address     => $p->{'address'}      || $user->{'address'},
        country     => $p->{'country'}      || $user->{'country'},
        telephone   => $p->{'telephone'}    || $user->{'telephone'},
        cc_number   => $p->{'cc_number'}    || $user->{'cc_number'}     || '',
        cc_cvd      => $p->{'cc_cvd'}       || $user->{'cc_cvd'},
        cc_valid_m  => $p->{'cc_valid_m'}   || $user->{'cc_valid_m'},
        cc_valid_y  => $p->{'cc_valid_y'}   || $user->{'cc_valid_y'},
        paypal      => $p->{'paypal'}       || $user->{'paypal'},
    };

    # Remove any spaces from credit card number
    $self->{'cc_number'} =~ s/\s+//g;
    # TODO: Normalize telephone number
    # Plus sign is converted to space (normal for http), client should encode it. 
    #$self->{'telephone'} =~ s/\+/00/g;
    #$self->{'telephone'} =~ s/\.//g;

    return bless( $self, $class );
}

sub list {
    my $class = shift;

    my $handle = Db::prep('get_users');
    $handle->execute();
    my $result = $handle->fetchrow_hashref;
    my $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 } ;

    return [ $status, $result->{'users'} ];
}

sub getData {
    my $email = shift;

    my $handle = Db::prep('get_user');
    $handle->execute( $email );
    my $result = $handle->fetchrow_hashref or die $handle->errstr;
    my $user;
    $user = parse_json( $result->{'account'} ) if( valid_json( $result->{'account'} ) );
    return $user;
}

=over

=item get()

    Populate a User object with data from the database

=back

=cut

sub get {
    my $self = shift;
    my $status = { ok => 0, status => 'You can get a user by giving an email', code => 400 };
    my $result;

    if( valid( $self->{'email'} ) ) {

        my $handle = Db::prep('get_user');
        $handle->execute( $self->{'email'} );
        $result = $handle->fetchrow_hashref;

        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 404, user => $result->{'account'} };

        if( $result->{'ok'} ) {
            $status->{'code'} = 200;
        }
    }

    return $status;
}

=over

=item save()

    Write this User's data to the database.

=back

=cut

sub save {
    my $self = shift;

    my $handle = Db::prep('add_user');
    $handle->execute(
        $self->{'email'},
        $self->{'token'},
        $self->{'type'},
        $self->{'active'},
        to_json($self->{'cart'}),
        to_json($self->{'wishlist'}),
        $self->{'name'},
        $self->{'surname'},
        $self->{'city'},
        $self->{'province'},
        $self->{'city_code'},
        $self->{'address'},
        $self->{'country'},
        $self->{'telephone'},
        $self->{'cc_number'},
        $self->{'cc_cvd'},
        $self->{'cc_valid_m'},
        $self->{'cc_valid_y'},
        $self->{'paypal'},
    );
    my $result = $handle->fetchrow_hashref;
    my $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 201, uid => $result->{'user_id'} };

    return $status;
}

sub update {
    my $self = shift;
    my $status = { ok => 0, status => 'You can modify a user by giving an email', code => 400 };

    if( valid( $self->{'email'} ) ) {
        my $handle = Db::prep('update_user');
        $handle->execute(
            $self->{'email'},
            $self->{'token'},
            $self->{'type'},
            $self->{'active'},
            to_json($self->{'cart'}),
            to_json($self->{'wishlist'}),
            $self->{'name'},
            $self->{'surname'},
            $self->{'city'},
            $self->{'province'},
            $self->{'city_code'},
            $self->{'address'},
            $self->{'country'},
            $self->{'telephone'},
            $self->{'cc_number'},
            $self->{'cc_cvd'},
            $self->{'cc_valid_m'},
            $self->{'cc_valid_y'},
            $self->{'paypal'},
        );
        my $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 201 };
    }

    return $status;

}

sub delete {
    my $self = shift;
    my $status = { ok => 0, status => 'You can delete a user by giving an email', code => 400 };
    my $result;

    if( valid( $self->{'email'} ) ) {
        my $handle = Db::prep('delete_user');
        $handle->execute( $self->{'email'} );
        $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, code => 200 };
    }

    return $status;
}

sub authenticate {
    my $self = shift;
    my $status = { ok => 0, status => 'You can authenticate a user by giving an email and a token', code => 400 };
    my $result;

    if( valid( $self->{'email'} ) ) {

        # Cryptographically secure token
        my $bcrypt = Digest->new('Bcrypt');
        $bcrypt->cost(1);
        $bcrypt->salt(  pack( "C16", lc $self->{'email'} ) );
        $bcrypt->add( $self->{'token'} );
        $self->{'token'} = $bcrypt->hexdigest;

        my $handle = Db::prep('authenticate_user');
        $handle->execute( $self->{'email'}, $self->{'token'} );
        $result = $handle->fetchrow_hashref;
        $status = { ok => $result->{'ok'}, status => $result->{'status'}, user => $result->{'user'}, code => 200 };
    }

    return $status;
}

=cut
sub newToken {
    my $self = shift;
    my $status = { ok => 1, status => '', code => 200 };

    # Cryptographically secure token
    my $bcrypt = Digest->new('Bcrypt');
    $bcrypt->cost(1);
    $bcrypt->salt( rand_bits( 16*8 ) );
    $bcrypt->add( rand_bits( 256*8 ) );
    $self->{'token'} = substr $bcrypt->hexdigest, 20, 8;
    $bcrypt->reset;

    $status = $self->update;
    
    # TODO: Let the user choose how to be contacted. For now, just e-mail.

    sendmail(
        From    => 'shop@iannella.sh',
        To      => $self->{'email'},
        Subject => 'Your token',
        Message => $self->{'token'},
    ) || return { ok => 0, status => $Mail::Sendmail::error, code => 500 };
    
    return $status;
}

sub activate {
    my ( $self, $token ) = @_;
    my $status = { ok => 0, status => 'Invalid token', code => 401 };

    if( $token ne '' and $self->{'token'} eq $token ) {
        $self->{'active'} = 1;
        $status = $self->update;
    }
    
    return $status;
}

sub deactivate {
    my ( $self, $token ) = @_;
    my $status = { ok => 0, status => 'Invalid token', code => 401 };

    if( $self->{'token'} eq $token ) {
        $self->{'active'} = 0;
        $self->{'token'} = '';
        $status = $self->update;
    }
    
    return $status;
}
=cut

"Ambè";
