use strict;
use utf8;
use diagnostics;

no warnings 'utf8';

use Test::More;
use Test::NoWarnings;

use Unicode::Stringprep;

our @data = (
    [ 0x0000 => '^@' ],
    [ 0x0001 => '^A' ],
    [ 0x0041 => 'a' ],
    [ 0x00DF => 'ss' ],
    [ 0x123 => "ä" ],
    [ 0x20AC => 'EUR' ],
    [ 0x10FFFF => '#' ],
);

plan tests => ($#data+1) + 1;

my $prep = Unicode::Stringprep->new( 3.2, [ @data ], '', [ ], 0 );

foreach(@data) 
{
  my ($in,$out) = @{$_};
  is($prep->(chr($in)),
    (defined $out) ? $out : undef, 
    sprintf 'U+%04X', $in);
}
