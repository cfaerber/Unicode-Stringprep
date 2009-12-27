package Unicode::Stringprep::_Util;

use strict;
use utf8;
use warnings;
require 5.006_000;

use Exporter;
use Carp;

our $VERSION = "1.09_20091227";
$VERSION = eval $VERSION;

our @ISA = ('Exporter');
our @EXPORT = ('_mk_set', '_mk_map');
our @EXPORT_OK = ('_mk_set', '_mk_map', '_compile_set');

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

sub _compile_set {
  my @collect = ();
  sub _set_tables {
    my $set = shift;
    while(@_) {
      my $data = shift;
      if(ref($data) eq 'HASH') { _set_tables($set, %{$data}); }
      elsif(ref($data) eq 'ARRAY') { _set_tables($set, @{$data}); }
      else{ push @{$set}, [$data,shift || $data] };
    }
  }
  _set_tables(\@collect,@_);

  # NB: This destroys @collect as it modifies the anonymous ARRAYs
  # referenced in @collect.
  # This is harmless as it only modifies ARRAYs after they've been
  # inspected.

  my @set = ();
  foreach my $d (sort { $a->[0]<=>$b->[0] } @collect) {
    if(!@set || $set[$#set]->[1]+1 < $d->[0]) {
      push @set, $d;
    } elsif($set[$#set]->[1] < $d->[1]) {
      $set[$#set]->[1] = $d->[1];
    }
  }

  return undef if !@set;

  if ($Unicode::Stringprep::WARNINGS && ($] <= 5.008003)) {
    if(grep { $_->[0] <= 0xDFFF && $_->[1] >= 0xD800 } @set) {
      carp 'UNICODE surrogate pairs (U+D800..U+DFFF) cannot be handled'.
	' by your perl (version '.$].')';
    }
  }

  return '['.join('', map {
    sprintf( $_->[0] >= $_->[1] 
      ? "\\x{%X}"
      : "\\x{%X}-\\x{%X}",
      @{$_})
    } @set ).']';
}



1;

=head1 NAME

Unicode::Stringprep::_Util - Internal functions for Unicode::Stringprep

=head1 AUTHOR

Claus FE<auml>rber E<lt>CFAERBER@cpan.orgE<gt>
 
=head1 LICENSE
 
Copyright 2007-2009 Claus FE<auml>rber. All rights reserved.
 
This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
