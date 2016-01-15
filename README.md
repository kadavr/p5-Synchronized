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
