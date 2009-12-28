use strict;
use utf8;

no warnings 'utf8';

use Test::More tests => 20;
use Test::NoWarnings;

use Unicode::Stringprep;

#     [
#       "Non-ASCII multibyte space character U+2000",
#       "\x{2000}", "\x20"
#     ],
#     [
#       "Larger test (shrinking)",
#       "X\x{00AD}\x{00DF}\x{0130}\x{2121}\x6a\x{030C}\x{00A0}".
#       "\x{00AA}\x{03B0}\x{2000}", "xssi\x{0307}tel\x{01F0} a\x{03B0} ",
#       "Nameprep"
#     ],


sub mk {
  my @d = map { $_ || undef; } @_;

  return Unicode::Stringprep->new(
    3.2,
    $d[0] && [ \@Unicode::Stringprep::Mapping::B1, \@Unicode::Stringprep::Mapping::B2 ],
    $d[1] && 'KC',
    $d[2] && [ \@Unicode::Stringprep::Prohibited::C12, \@Unicode::Stringprep::Prohibited::C22, \@Unicode::Stringprep::Prohibited::C3, \@Unicode::Stringprep::Prohibited::C4, \@Unicode::Stringprep::Prohibited::C5, \@Unicode::Stringprep::Prohibited::C6, \@Unicode::Stringprep::Prohibited::C7, \@Unicode::Stringprep::Prohibited::C8, \@Unicode::Stringprep::Prohibited::C9 ],
    $d[3] && 1,
  );
}

is( mk(0,0,0,0)->("\x{2000}"), "\x{2000}",	'U+2000 (pass-through)' );

is( mk(1,0,0,0)->("\x{2000}"), "\x{2000}",	'U+2000 (mapping)' );
is( mk(0,1,0,0)->("\x{2000}"), " ",		'U+2000 (normalization)' );
is( eval { mk(0,0,1,0)->("\x{2000}") }, undef,	'U+2000 (prohibited)' );
is( mk(0,0,0,1)->("\x{2000}"), "\x{2000}",	'U+2000 (bidi)' );

is( mk(1,1,0,0)->("\x{2000}"), " ",		'U+2000 (mapping+normalization)' );
is( eval { mk(1,0,1,0)->("\x{2000}") }, undef,	'U+2000 (mapping+prohibited)' );
is( mk(1,0,0,1)->("\x{2000}"), "\x{2000}",	'U+2000 (mapping+bidi)' );

is( mk(1,1,1,0)->("\x{2000}"), " ",		'U+2000 (mapping+normalization+prohibited)' );
is( mk(1,1,0,1)->("\x{2000}"), " ",		'U+2000 (mapping+normalization+bidi)' );
is( eval { mk(1,0,1,1)->("\x{2000}") }, undef,	'U+2000 (mapping+prohibited+bidi)' );

is( mk(0,1,1,0)->("\x{2000}"), ' ',		'U+2000 (normalization+prohibited)' );
is( mk(0,1,0,1)->("\x{2000}"), " ",		'U+2000 (normalization+bidi)' );
is( eval { mk(0,0,1,1)->("\x{2000}") }, undef,	'U+2000 (prohibited+bidi)' );

is( mk(0,1,1,1)->("\x{2000}"), ' ',		'U+2000 (normalization+prohibited+bidi)' );

is( mk(1,1,1,1)->("\x{2000}"), " ",		'U+2000 (complete)' );

is( Unicode::Normalize::NFKC("\x{2000}"), " ", 	'U+2000 (Unicode::Normalize::NFKC)' );

no bytes; # make bytes::length available
is( bytes::length("\x{2000}"), 3,	'bytes::length of U+2000 char literal');
is( bytes::length(chr(hex(2000))), 3,	'bytes::length of U+2000 chr() output');
