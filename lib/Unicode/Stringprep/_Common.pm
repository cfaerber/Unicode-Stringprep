# $Id$

package Unicode::Stringprep::_Common;

use strict;
use utf8;
require 5.006_000;

use Exporter;

our $VERSION = '1.00';

our @ISA = ('Exporter');
our @EXPORT = ('_mk_set', '_mk_map');

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

my $_mk_char = $] <= 5.008002
  ? sub { eval '"\\x{'.(shift).'}"' }
  : sub { chr(hex(shift)) };

sub _mk_map {
  my @data = ();
  foreach my $line (split /\n/, shift) {
    my($from,$to,$comment) = split /;/, $line; 
    $from =~ s/[^0-9A-F]//gi;
    $to =~ s/[^0-9A-F ]//gi;
    push @data, 
        hex($from), 
        join('',map { 
	  $_ eq '' 
	    ? '' 
	    : $_mk_char->($_)
	}
	split(/ +/, $to));
  }
  return @data;
};

1;

# =head1 AUTHOR
# 
# Claus Färber E<lt>CFAERBER@cpan.orgE<gt>
# 
# =head1 LICENSE
# 
# Copyright © 2007-2008 Claus Färber. All rights reserved.
# 
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
