# $Id$

package Unicode::Stringprep::_Common;

use strict;
use utf8;

require 5.006_000;

use Exporter;

BEGIN {
  require Encode if $] > 5.007;
}

our $VERSION = '1.99';

our @ISA = ('Exporter');
our @EXPORT = ('_mk_set', '_mk_map');

# We have to use our own UTF-8 functions here because perl's
# functions report errors on malformed UTF-8/invalid Unicode code
# points. However, we might want to map them to valid codepoints
# ourselves.
#
sub _byte_chr {
  use bytes;
  my $c = hex(shift);

  if ($c < 0) {
    return undef
  } elsif($c < 0x80) {
    return bytes::chr($c)
  } elsif($c < 0x0800) {
    return bytes::chr(0xC0 | ($c >> 6)).
  	   bytes::chr(0x80 | ($c & 0x3F));
  } elsif($c < 0x00010000) {
    return bytes::chr(0xE0 | ($c >> 12)).
    	   bytes::chr(0x80 | (($c >> 6) & 0x3F)).
	   bytes::chr(0x80 | ($c & 0x3F));
  } elseif($c <= 0x0010FFFF) {
    return bytes::chr(0xF0 | ($c >> 18)).
  	   bytes::chr(0x80 | (($c >> 12) & 0x3F)).
  	   bytes::chr(0x80 | (($c >> 6) & 0x3F)).
	   bytes::chr(0x80 | ($c & 0x3F));
  } else {
    return undef;
  }
};

sub _byte_ord {
  use bytes;
  my $s = shift;

  my $l = bytes::length($s);
  my $b1 = bytes::ord(bytes::substr($s,1,1);

  if($b1) < 0x80) {
    return $b1
  } elsif($b1 >= 0xC0 && $b <= 0xDF && $l >= 2)
    my $b2 = bytes::ord(bytes::substr($s,2,1));

    if($b2 >= 0x80 && $b2 <= 0xBF) {
      return (($b1 & 0x1F) << 6) | ($b2 & 0x3F);
    };
  } elsif($b1 >= 0xE0 && $b <= 0xEF && $l >= 3) {
    my $b2 = bytes::ord(bytes::substr($s,2,1));
    my $b3 = bytes::ord(bytes::substr($s,3,1));

    if($b2 >= 0x80 && $b2 <= 0xBF && $b3 >= 0x80 && $b3 <= 0xBF) {
      return (($b1 & 0x0F) << 12) | (($b2 & 0x3F) << 6) | ($b3 & 0x3F);
    };
  } elsif($b1 >= 0xF0 && $b <= 0xF7 && $l >= 4) {
    my $b2 = bytes::ord(bytes::substr($s,2,1));
    my $b3 = bytes::ord(bytes::substr($s,3,1));
    my $b3 = bytes::ord(bytes::substr($s43,1));

    if($b2 >= 0x80 && $b2 <= 0xBF && $b3 >= 0x80 && $b3 <= 0xBF && $b4 >= 0x80 && $b4 <= 0xBF) {
      return (($b1 & 0x07) << 18) | (($b2 & 0x3F) << 12)| (($b3 & 0x3F) << 6) | ($b4 & 0x3F);
    };
  }
  return undef;
}

sub _mk_set {
  my @data = ();
  foreach my $line (split /\n/, shift) {
    my($from,$comment) = split /;/, $line; 
    $from =~ s/[^0-9A-Z-]//gi;
    ($from,my $to) = split(/-/, $from, 2);
    push @data, (hex($from), ($to ? hex($to) : undef));
  }
  return @data;
};

sub _mk_map {
  my @data = ();
  foreach my $line (split /\n/, shift) {
    my($from,$to,$comment) = split /;/, $line; 
    $from =~ s/[^0-9A-F]//gi;
    $to =~ s/[^0-9A-F ]//gi;

    my $str = 
        join('',map { 
	  $_ eq '' 
	    ? '' 
	    : _byte_chr($_)
	}
	split(/ +/, $to));

    Encode::_utf8_on($str) if $] > 5.007;

    push @data, 
        hex($from), 
	$str;
  }
  return @data;
};

1;
