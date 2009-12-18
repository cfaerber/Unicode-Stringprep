use bytes;
use strict;

use Test::More tests => 13;
use Test::NoWarnings;

use Unicode::Stringprep;

no warnings 'utf8';

foreach my $u (
  0x00000000, 0x0000007F, 0x00000080, 0x000007FF, 0x00000800, 0x0000FFFF,
  0x00010000, 0x001FFFFF, 0x00200000, 0x03FFFFFF, 0x04000000, 0x7FFFFFFF,
) {
  my $result = [ Unicode::Stringprep::_u8_a($u) ];
  my $expect = eval sprintf('"\x{%x}"',$u);

use utf8;
utf8::encode($expect);

  $expect = [ unpack('C*', $expect) ];

  is_deeply($result, $expect, sprintf('U+%08X test', $u));
}
