# p5-Synchronized
Simple interface and implementation for distributed lock.

# Example
```perl
use Cache::Memcached::Fast;

use Synchronized::memd {
    memd => Cache::Memcached::Fast->new( { servers => ['127.0.0.1:11211'] } ),
};

synchronized {
    my $val = $memd->get($key);
    $val //= 0;
    $val += 1;
    $memd->set($key, $val);
    ();
};
```

# Complete example
```perl
#!perl

use AnyEvent;
use AnyEvent::Fork;
use AnyEvent::Fork::Pool;
use Cache::Memcached::Fast;
use Synchronized;

my $memd = Cache::Memcached::Fast->new( { servers => ['127.0.0.1:11211'] } );

my $key  = 'sync_test_88' . rand(1000000);
my $pool = AnyEvent::Fork->new->eval(
    do { local $/; <DATA> }
    )->AnyEvent::Fork::Pool::run(
    "AEWorker::run",

    max        => 4,
    idle       => 0,
    load       => 2,
    start      => 0.1,
    stop       => 10,
    on_destroy => ( my $finish = AE::cv ),
    );

for ( 1 .. 10000 ) {
    $pool->( $key, sub { } );
}

undef $pool;
$finish->recv;

print 'New key value: ' . $memd->get($key) . "\n";

__DATA__

package AEWorker;
use strict;
use Time::HiRes qw/usleep/;
use Cache::Memcached::Fast;

use Synchronized::memd {
    memd => Cache::Memcached::Fast->new( { servers => ['127.0.0.1:11211'] } ),
    livetime => 5,
};

sub run {
    my $key = shift;
    my $memd = Cache::Memcached::Fast->new( { servers => ['127.0.0.1:11211'] } );
    my $ret = synchronized {
        my $val = $memd->get($key);
        $val //= 0;
        $val += 1;
        $memd->set($key, $val);
    };
    return $ret
}


1;
```
