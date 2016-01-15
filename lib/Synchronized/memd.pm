package Synchronized::memd;

use Synchronized;
use strict;
use Data::Dumper;
use Time::HiRes qw/usleep/;

use constant { MEMD => 0, LIVETIME => 1 };

my $def_memd;

sub import {
    my $class = shift;
    my $opts  = shift;
    if ( ref $opts ne 'HASH' ) {
        die "Bad imports";
    }
    if (   !defined $def_memd
        && !exists $opts->{memd}
        && !exists $opts->{def_memd} )
    {
        die "def_memd && memd has undefined value";
    }
    else {
        if ( !defined $def_memd && $opts->{def_memd} ) {
            $def_memd = $opts->{def_memd};
        }
        $opts->{memd} = $opts->{memd} // $def_memd;
    }

    my $package   = $opts->{caller_package} // caller;
    my $export_as = $opts->{export_as}      // 'synchronized';
    my $my_ctx    = Synchronized::memd::CTX->new(%$opts);

    my $ctx = Synchronized::internal_new_ctx(
        $package,
        lock => sub {
            my $key = shift;
            my $ctx = shift;
            $ctx = $ctx->child;
            while ( !( $ctx->[MEMD] )->add( $key, 1, $ctx->[LIVETIME] ) ) {

                #usleep(5000);
            }
            1;
        },
        unlock => sub {
            my $key = shift;
            my $ctx = shift;
            $ctx = $ctx->child;
            return $ctx->[MEMD]->delete($key);
        }
    );
    $ctx->attach_child($my_ctx);

    Synchronized::internal_export_symbol( $package, $export_as,
        *synchronized );
}

sub synchronized(&) {
    my $sub = shift;
    my ( $package, undef, $line ) = caller;
    my $ctx = Synchronized::internal_ctx($package);
    return Synchronized::internal_synchronized( $sub, $ctx, $package, $line );
}


sub unimport {
    Synchronized->unimport;
}

package Synchronized::memd::CTX;

use constant { MEMD => 0, LIVETIME => 1 };

sub new {
    my $class = shift;
    my %opts  = @_;
    my @CTX;

    $CTX[MEMD]     = $opts{memd};
    $CTX[LIVETIME] = $opts{livetime};
    bless \@CTX, $class;
}
1;
