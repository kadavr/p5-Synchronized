#!perl

use lib './lib';
use Test::More no_plan;
use strict;
{
    use_ok('Synchronized');
}

{
    my $package = 'Test';
    my $ctx = Synchronized::internal_new_ctx( $package, lazy => 1 );
    isa_ok( $ctx, 'Synchronized::CTX' );
    no strict;
    foreach my $x (qw/LOCK_CB UNLOCK_CB GEN_NAME_PART CHILD/) {
        if ( ok( exists ${'Synchronized::CTX::'}{$x}, "Constant $x exists" ) )
        {
            ok( defined &{ 'Synchronized::CTX::' . $x }, "$x defined" )
                or next;
            my $sub = &{ 'Synchronized::CTX::' . $x };
            is( $ctx->[$sub], undef, 'lazy ctx, all fields undef' );
        }
    }
    use strict;
}

{

    my $lock_ref          = sub { };
    my $unlock_ref        = sub { };
    my $gen_name_part_ref = sub { };

    my $package = 'Test2';
    my $ctx     = Synchronized::internal_new_ctx(
        $package,
        unlock        => $unlock_ref,
        lock          => $lock_ref,
        gen_name_part => $gen_name_part_ref
    );
    isa_ok( $ctx, 'Synchronized::CTX' );
    no strict;
    foreach my $x (qw/LOCK_CB UNLOCK_CB GEN_NAME_PART/) {

        if ( ok( exists ${'Synchronized::CTX::'}{$x}, "Constant $x exists" ) )
        {
            my $sub = &{ 'Synchronized::CTX::' . $x };
            ok( defined &{ 'Synchronized::CTX::' . $x }, "$x defined" );
            ok( defined $ctx->[$sub], 'ctx field ' . $x . ' defined' );
        }
    }
    use strict;
}

{

    my $package = 'Test3';
    my $child_ctx = bless {}, 'Test3::CTX';

    my $ctx = Synchronized::internal_new_ctx(
        $package,
        unlock        => sub { },
        lock          => sub { },
        gen_name_part => sub { }
    );
    can_ok( 'Synchronized::CTX', 'child' );
    can_ok( 'Synchronized::CTX', 'attach_child' );

    is( $ctx->child,                    undef, 'child undef' );
    is( $ctx->attach_child($child_ctx), 1,     'attach_child ok' );
    isa_ok( $ctx->child, 'Test3::CTX', 'attach_child ok' );
}

{

    package Test4;
    use Synchronized;
    our $unlocked = 0;
    our $locked   = 0;
    my $ctx = Synchronized::internal_new_ctx(
        __PACKAGE__,
        lock   => sub { $locked   = 1; return 1; },
        unlock => sub { $unlocked = 1; return 1; },
        gen_name_part => undef
    );
    my $cv = sub {

    };
    my $res
        = Synchronized::internal_synchronized( $cv, $ctx, 'NULL', 'test' );

    package main;
    is( $locked,   1,                'get lock' );
    is( $res,      Synchronized::OK, 'body executed successfully' );
    is( $unlocked, 1,                'lock release' );
}

{

    package Test5;
    use Synchronized;
    our $unlock = 'not_executed';
    our $body   = 'not_executed';
    my $ctx = Synchronized::internal_new_ctx(
        __PACKAGE__,
        lock   => sub { die; },
        unlock => sub { $unlock = 'oops'; },
        gen_name_part => undef
    );
    my $cv = sub {
        $body = 'oops';
    };
    my $res
        = Synchronized::internal_synchronized( $cv, $ctx, 'NULL', 'test' );

    package main;
    is( $res, Synchronized::LOCK_DIED,
        'lock_cb died, Synchronized return LOCK_DIED' );
    is( $body,   'not_executed', 'body_cb not executed' );
    is( $unlock, 'not_executed', 'unlock_cb not executed' );
}

{

    package Test6;
    use Synchronized;
    our $lock   = 'not_executed';
    our $unlock = 'not_executed';

    my $ctx = Synchronized::internal_new_ctx(
        __PACKAGE__,
        lock   => sub { $lock   = 'executed'; return 1; },
        unlock => sub { $unlock = 'executed'; return 1; },
        gen_name_part => undef
    );
    my $cv = sub {
        die;
    };
    my $res
        = Synchronized::internal_synchronized( $cv, $ctx, 'NULL', 'test' );

    package main;
    is( $lock, 'executed', 'lock_cb executed' );
    is( $res, Synchronized::BODY_DIED,
        'body_cb died, Synchronized return BODY_DIED' );
    is( $unlock, 'executed', 'unlock_cb executed' );
}
