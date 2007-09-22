# $Id: $

use strict;
use utf8;

use Test::More;

use Unicode::Stringprep;

our @strprep = (

  # test vectors from RFC 4013, section 3.
  #

  [ "I\x{00AD}X",       'IX',		'SOFT HYPHEN mapped to nothing' ],
  [ 'user',             'user',		'no transformation' ],
  [ 'USER',             'USER',		'case preserved, will not match #2' ],
  [ "\x{00AA}",         'a',		'output is NFKC, input in ISO 8859-1' ],
  [ "\x{2168}",         'IX',		'output is NFKC, will match #1' ],
  [ "\x{0007}",         undef,		'Error - prohibited character' ],
  [ "\x{0627}\x{0031}", undef,		'Error - bidirectional check' ],

  # some more tests
  #

  [ 'ÄÖÜß',		'ÄÖÜß',		'German umlaut case preserved' ],
  [ 'äöüß',		'äöüß',		'German umlaut case preserved' ],
  [ "\x{A0}",		' ',		'no-break space mapped to ASCII space' ],
  [ "\x{2009}",		' ',		'thin space mapped to ASCII space' ],
  [ "\x{3000}",		' ',		'ideographic space mapped to ASCII space' ],
  [ "\x{A0}\x{2009}\x{3000}", '   ',	'no space collapsing' ],

);

plan tests => ($#strprep+1);

my %C12_to_SPACE = ();
for(my $pos=0; $pos <= $#Unicode::Stringprep::Prohibited::C12; $pos+=2) 
{
  for(my $char = $Unicode::Stringprep::Prohibited::C12[$pos]; 
         defined $Unicode::Stringprep::Prohibited::C12[$pos]
	 && $char <= $Unicode::Stringprep::Prohibited::C12[$pos];
	 $char++) {
    $C12_to_SPACE{$char} = ' ';
  }
}

foreach my $m (@Unicode::Stringprep::Prohibited::C12) {
}

*saslprep = Unicode::Stringprep->new(
  3.2,
  [ \@Unicode::Stringprep::Mapping::B1,
    \%C12_to_SPACE ],
  'KC',
  [ \@Unicode::Stringprep::Prohibited::C12,
    \@Unicode::Stringprep::Prohibited::C21,
    \@Unicode::Stringprep::Prohibited::C22,
    \@Unicode::Stringprep::Prohibited::C3,
    \@Unicode::Stringprep::Prohibited::C4,
    \@Unicode::Stringprep::Prohibited::C5,
    \@Unicode::Stringprep::Prohibited::C6,
    \@Unicode::Stringprep::Prohibited::C7,
    \@Unicode::Stringprep::Prohibited::C8,
    \@Unicode::Stringprep::Prohibited::C9,
  ],
  1
);

foreach my $test (@strprep) 
{
  my ($in,$out,$comment) = @{$test};

  is(eval{saslprep($in)}, $out, $comment);
}
