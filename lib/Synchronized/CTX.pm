package Synchronized::CTX;

use strict;

use constant {
    LOCK_CB       => 0,
    UNLOCK_CB     => 1,
    GEN_NAME_PART => 2,
    CHILD         => 3
};

sub new {
    my $class = shift;
    my %opts  = @_;
    my @CTX;

    $CTX[LOCK_CB] = $opts{lock} || ( !$opts{lazy} && die "need lock cb" );
    $CTX[UNLOCK_CB]
        = $opts{unlock} || ( !$opts{lazy} && die "need unlock cb" );
    $CTX[GEN_NAME_PART] = $opts{gen_name_part};
    bless \@CTX, $class;
}

sub lock_cb {
    my $ctx = shift;
    if ( $_[0] ) {
        $ctx->[LOCK_CB] = $_[0];
    }
    else {
        return $ctx->[LOCK_CB];
    }
    1;
}

sub unlock_cb {
    my $ctx = shift;
    if ( $_[0] ) {
        $ctx->[UNLOCK_CB] = $_[0];
    }
    else {
        return $ctx->[UNLOCK_CB];
    }

    1;
}

sub gen_name_part_cb {
    my $ctx = shift;
    if ( $_[0] ) {
        $ctx->[GEN_NAME_PART] = $_[0];
    }
    else {
        return $ctx->[GEN_NAME_PART];
    }
    1;
}

sub attach_child {
    my $ctx       = shift;
    my $child_ctx = shift;
    $ctx->[CHILD] = $child_ctx;
    1;
}

sub child {
    my $ctx = shift;
    $ctx->[CHILD];
}

1;
