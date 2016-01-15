package Synchronized;

use strict;
use warnings FATAL => 'all';

use Data::Dumper;

use Synchronized::CTX;

use constant {
    OK          => 0,
    CANT_LOCK   => 1,
    LOCK_DIED   => 2,
    CANT_UNLOCK => 3,
    UNLOCK_DIED => 4,
    BODY_DIED   => 5,
    RECURSION   => 6,
};

use constant {
    LOCK_CB       => 0,
    UNLOCK_CB     => 1,
    GEN_NAME_PART => 2
};

our $VERSION = 0.01;

my %CTX;

sub ctx {
    return $CTX{ '' . caller };
}

sub synchronized(&) {
    die 'not implemented';
}

my $depth = 0;

sub internal_synchronized($$$$) {
    my ( $cv, $patent_ctx, $package, $line ) = @_;
    my $lock_name = "lock_${package}_${line}";
    if ( $patent_ctx->[GEN_NAME_PART] ) {
        $lock_name .= $patent_ctx->[GEN_NAME_PART]->($patent_ctx) // '';
    }

    if ( ++$depth > 1 ) {
        return RECURSION;
    }

    my $ret = OK;
    my $lock
        = eval { return $patent_ctx->[LOCK_CB]->( $lock_name, $patent_ctx ); };

    if ($@) {
        warn $@;
        $ret = LOCK_DIED;
    }
    elsif ( !$lock ) {
        $ret = CANT_LOCK;
    }
    else {
        eval { $cv->(); };
        if ($@) {
            $ret = BODY_DIED;
        }

        my $unlock = eval {
            return $patent_ctx->[UNLOCK_CB]->( $lock_name, $patent_ctx );
        };
        if ($@) {
            $ret = UNLOCK_DIED;
        }
        elsif ( !$unlock ) {
            $ret = CANT_UNLOCK;
        }
    }
    $depth--;
    $ret;
}

sub internal_ctx($) {
    return $CTX{ $_[0] };
}

sub internal_new_ctx($;@) {
    my $package = shift;
    my %args    = @_;
    $CTX{$package} = Synchronized::CTX->new(%args);
}

sub internal_export_symbol($$$) {
    my ( $package, $name, $symbol ) = @_;
    no strict;
    *{ $package . '::' . $name } = $symbol;
    use strict;
    1;
}

1;
