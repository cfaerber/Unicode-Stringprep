use strict;
use Test::More;

eval "use Test::Pod 1.00";

plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
plan skip_all => "perl <= 5.7.3 does not support UTF-8 pods" if $] <= 5.007003;

all_pod_files_ok();
