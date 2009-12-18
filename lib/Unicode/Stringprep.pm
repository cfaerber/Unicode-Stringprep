package Unicode::Stringprep;

use strict;
use utf8;
use warnings;
require 5.006_000;

our $VERSION = '1.09_20091218';
$VERSION = eval $VERSION;

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(stringprep);

use Carp;

use Unicode::Normalize();

use Unicode::Stringprep::Unassigned;
use Unicode::Stringprep::Mapping;
use Unicode::Stringprep::Prohibited;
use Unicode::Stringprep::BiDi;

sub new {
  my $self  = shift;
  my $class = ref($self) || $self;
  return bless _compile(@_), $class;
}

## Here be eval dragons

sub _compile {
  my $unicode_version = shift;
  my $mapping_tables = shift;
  my $unicode_normalization = uc shift;
  my $prohibited_tables = shift;
  my $bidi_check = shift;

  croak 'Unsupported UNICODE version '.$unicode_version.'.' 
    unless $unicode_version == 3.2;

  my $code = 'no warnings "utf8";'.
    'my $string = shift;';
  my $u8_status = 2;

  my $cs = sub {
    my($u8,$new_code) = @_;
    return unless $new_code;
    $code .= '_u8_on ($string);' if $u8_status < $u8;
    $code .= '_u8_off($string);' if $u8_status > $u8;
    $code .= '{ use '.($u8 ? 'utf8' : 'bytes').';';
    $code .= $new_code."}\n";
    $u8_status = $u8;
  };

  $cs->(0, '_check_malformed($string, "at input")');
  $cs->(0, _compile_mapping($mapping_tables));
  $cs->(1, _compile_normalization($unicode_normalization));
  $cs->(0, _compile_prohibited($prohibited_tables));
  $cs->(0, $bidi_check ? '_check_bidi($string)' : undef);
  #$cs->(0, '_check_malformed($string, "at output")');
  $cs->(1, 'return $string');

# print STDERR "$code";
  return eval "sub{$code}" || die $@;
}

sub _compile_mapping {
  use bytes;
  my %map = ();
  sub _mapping_tables {
    my $map = shift;
    while(@_) {
      my $data = shift;
      if(ref($data) eq 'HASH') { %{$map} = (%{$map},%{$data}) }
      elsif(ref($data) eq 'ARRAY') { _mapping_tables($map,@{$data}) }
      else{ $map->{$data} = shift };
    }
  }
  _mapping_tables(\%map,@_);

  return undef if !%map;

  sub _compile_mapping_r { 
     my $map = shift;
     if($#_ <= 20000) {
       return (join '', (map { '$char == '.$_.
        ' ? "'._u8_qmeta($$map{$_}).'"'.
        '   : ' } @_)).' die sprintf("Internal error: U+%04X not expected",$char)';
     } else {
      my @a = splice @_, 0, int($#_/2);
      return '$char < '.$_[0].' ? ('.
        _compile_mapping_r($map,@a).
	') : ('.
        _compile_mapping_r($map,@_).
	')';
     }
  };

  my @from = sort { $a <=> $b } keys %map;

  return sprintf '$string =~ s/(%s)/my $char = _u8_ord($1); %s /ge;',
    _compile_set(map { ($_,$_) } @from),
    _compile_mapping_r(\%map, @from);
}

sub _compile_normalization {
  my $unicode_normalization = shift;
  $unicode_normalization =~ s/^NF//;

  return '$string = Unicode::Normalize::NFKC($string);' if $unicode_normalization eq 'KC';
  return '' if $unicode_normalization eq '';

  croak 'Unsupported UNICODE normalization (NF)'.$unicode_normalization.'.';
}

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
	
    # make sure each set only contains characters with the same number of bytes
    # used for utf8

    foreach my $g (0x80, 0x800, 0x10000, 0x200000, 0x4000000) {
      if($set[$#set]->[0] < $g && $set[$#set]->[1] >= $g) {
        my $d_1 = $set[$#set]->[1];
	$set[$#set]->[1] = $g - 1;
        push @set, [ $g, $d_1 ];
      }
    }
  }

  return undef if !@set;

  sub _set_str {
    use bytes;
    my($a,$b) = @_;
    my $l = length($a);
    die if $l != length($b); 	# should not happen!

    return _u8_qmeta($a) if $a eq $b;

    if($l <= 1) {
      return '['._b_qmeta($a)._b_qmeta($b).']' if ord($a) >= ord($b)-1;
      return '['._b_qmeta($a).'-'._b_qmeta($b).']';
    }

    my $a1 = substr($a, 0, 1); my $a2 = substr($a, 1);
    my $b1 = substr($b, 0, 1); my $b2 = substr($b, 1);
    my $l2 = $l - 1;

    my $min = chr(0x80) x $l2;
    my $max = chr(0x80 + 0x3F) x $l2;

    if($a1 eq $b1) {
      return _b_qmeta($a1)._set_str($a2, $b2);
    }

    if($a2 ne $min) {
      return '(?:'._set_str($a, $a1.$max).
	'|'._set_str(chr(ord($a1)+1).$min, $b).')';
    }

    if($b2 ne $max) {
      return '(?:'._set_str($a, chr(ord($b1)-1).$max).
	'|'._set_str($b1.$min, $b).')';
    }

    return _set_str($a1,$b1).'[\x80-\xBF]{'.$l2.','.$l2.'}';
  };

  sub _set_str_u8 {
    return _set_str(map { _u8_chr(hex($_)) } @_);
  }

#  foreach (@set) {
#   printf STDERR "[%04X-%04X]: <%s>\n", @{$_} , _set_str_u8(map { sprintf '%X', $_} @{$_});
#  };

  return join '|', map { _set_str( map { _u8_chr($_) } @{$_}) } @set;

  return '['.join('', map {
    sprintf( $_->[0] >= $_->[1] 
      ? "\\x{%04X}"
      : "\\x{%04X}-\\x{%04X}",
      @{$_})
    } @set).']';
}

sub _compile_prohibited {
  my $prohibited_sub = _compile_set(@_);

  if($prohibited_sub) {
    return 
      'if($string =~ m/('.$prohibited_sub.')/) {'.
          'die sprintf("prohibited character U+%04X",_u8_ord($1))'.
      '}';
  }
}

our $is_RandAL = _compile_set(@Unicode::Stringprep::BiDi::D1);
our $is_L = _compile_set(@Unicode::Stringprep::BiDi::D2);

our $re_is_RandAL = eval 'qr/'.$is_RandAL.'/';
our $re_is_RandALstart = eval 'qr/^'.$is_RandAL.'/';
our $re_is_RandALend = eval 'qr/'.$is_RandAL.'$/';
our $re_is_L = eval 'qr/'.$is_L.'/';

sub _check_bidi {
  my $string = shift;

  if($string =~ m/$is_RandAL/) {
    if($string =~ m/$is_L/) {
        die "string contains both RandALCat and LCat characters";
      } elsif($string !~ m/^($is_RandAL)/) {
        die "string contains RandALCat character but does not start with one";
      } elsif($string !~ m/($is_RandAL)$/) {
        die "string contains RandALCat character but does not end with one";
      };
    };
}

sub _check_malformed {
  my $string = shift;

  $string =~ m/^(?:[\x00-\x7f]|[\xc0-\xdf][\x80-\xbf]|[\xe0-\xef][\x80-\xbf]{2}|[\xf0-\xf7][\x80-\xbf]{3})*([\x80-\xFF]+)?/;
  die "malformed UTF-8 sequence ".shift().": "._u8_qmeta($1)." (len ".length($1).")" if(defined $1);
}

## utf8 helpers

sub _u8_ord { no warnings 'utf8'; use bytes; unpack('U0U', shift); }
sub _u8_chr { no warnings 'utf8'; use bytes; pack('U', shift); }

sub _u8_a { unpack 'C*', _u8_chr shift }

*_u8_off = ($] < 5.007001) ? sub { $_[0].=pack('U*'); } : \&utf8::encode;
*_u8_on  = ($] < 5.007001) ? sub { $_[0]=pack('U*', unpack 'U0U*', $_[0]); } : \&utf8::decode;

sub _b_qmeta {
  use bytes;
  return ord($_[0]) < 128
    ? quotemeta($_[0]) 
    : sprintf('\x%02X', ord($_[0])); 
}

sub _u8_qmeta {
  use bytes;
  return undef if !defined $_[0];
  return join '', map { _b_qmeta($_) } split //, shift || '';
}

1;
__END__

=head1 NAME

Unicode::Stringprep - Preparation of Internationalized Strings (S<RFC 3454>)

=head1 SYNOPSIS

  use Unicode::Stringprep;
  use Unicode::Stringprep::Mapping;
  use Unicode::Stringprep::Prohibited;

  my $prepper = Unicode::Stringprep->new(
    3.2,
    [ { 32 => '<SPACE>'},  ],
    'KC',
    [ @Unicode::Stringprep::Prohibited::C12, @Unicode::Stringprep::Prohibited::C22,
      @Unicode::Stringprep::Prohibited::C3, @Unicode::Stringprep::Prohibited::C4,
      @Unicode::Stringprep::Prohibited::C5, @Unicode::Stringprep::Prohibited::C6,
      @Unicode::Stringprep::Prohibited::C7, @Unicode::Stringprep::Prohibited::C8,
      @Unicode::Stringprep::Prohibited::C9 ],
    1 );
  $output = $prepper->($input)

=head1 DESCRIPTION

This module implements the I<stringprep> framework for preparing
Unicode text strings in order to increase the likelihood that
string input and string comparison work in ways that make sense
for typical users throughout the world.  The I<stringprep>
protocol is useful for protocol identifier values, company and
personal names, internationalized domain names, and other text
strings.

The I<stringprep> framework does not specify how protocols should
prepare text strings. Protocols must create profiles of
stringprep in order to fully specify the processing options.

=head1 FUNCTIONS

This module provides a single function, C<new>, that creates a
perl function implementing a I<stringprep> profile.

This module exports nothing.

=over 4

=item B<new($unicode_version, $mapping_tables, $unicode_normalization, $prohibited_tables, $bidi_check)>

Creates a C<bless>ed function reference that implements a stringprep profile.

C<$unicode_version> is the Unicode version specified by the
stringprep profile. Currently, this must be C<3.2>.

C<$mapping_tables> provides the mapping tables used for
stringprep.  It may be a reference to a hash or an array. A hash
must map Unicode codepoints (as integers, S<e. g.> C<0x0020> for
U+0020) to replacement strings (as perl strings).  An array may
contain pairs of Unicode codepoints and replacement strings as
well as references to nested hashes and arrays.
L<Unicode::Stringprep::Mapping> provides the tables from S<RFC 3454>,
S<Appendix B.> For further information on the mapping step, see
S<RFC 3454>, S<section 3.>

C<$unicode_normalization> is the Unicode normalization to be used.
Currently, C<''> (no normalization) and C<'KC'> (compatibility
composed) are specified for I<stringprep>. For further information
on the normalization step, see S<RFC 3454>, S<section 4.>

C<$prohibited_tables> provides the list of prohibited output
characters for stringprep.  It may be a reference to an array. The
array contains pairs of codepoints, which define the start and end
of a Unicode character range (as integers). The end character may
be C<undef>, specifying a single-character range. The array may
also contain references to nested arrays.
L<Unicode::Stringprep::Prohibited> provides the tables from
S<RFC 3454>, Appendix C. For further information on the prohibition
checking step, see S<RFC 3454>, S<section 5.>

C<$bidi_check> must be set to true if additional checks for
bidirectional characters are required. For further information on
the bidi checking step, see S<RFC 3454>, S<section 6.>

The function returned can be called with a single parameter, the
string to be prepared, and returns the prepared string. It will
die if the input string is invalid (so use C<eval> if necessary).

For performance reasons, it is strongly recommended to call the
C<new> function as few times as possible, S<i. e.> once per
I<stringprep> profile. It might also be better not to use this
module directly but to use (or write) a module implementing a
profile, such as L<Net::IDN::Nameprep>.

=back

=head1 IMPLEMENTING PROFILES

You can easily implement a I<stringprep> profile without subclassing:

  package ACME::ExamplePrep;

  use Unicode::Stringprep;

  use Unicode::Stringprep::Mapping;
  use Unicode::Stringprep::Prohibited;

  *exampleprep = Unicode::Stringprep->new(
    3.2,
    [ \@Unicode::Stringprep::Mapping::B1, ],
    '',
    [ \@Unicode::Stringprep::Prohibited::C12,
      \@Unicode::Stringprep::Prohibited::C22, ],
    1,
  );

This binds C<ACME::ExamplePrep::exampleprep> to the function
created by C<Unicode::Stringprep-E<gt>new>.

Usually, it is not necessary to subclass this module. Sublassing
this module is not recommended.

=head1 DATA TABLES

The following modules contain the data tables from S<RFC 3454>.
These modules are automatically loaded when loading
C<Unicode::Stringprep>.

=over 4

=item * L<Unicode::Stringprep::Unassigned>

  @Unicode::Stringprep::Unassigned::A1	# Appendix A.1

=item * L<Unicode::Stringprep::Mapping>

  @Unicode::Stringprep::Mapping::B1	# Appendix B.1
  @Unicode::Stringprep::Mapping::B2	# Appendix B.2
  @Unicode::Stringprep::Mapping::B2	# Appendix B.3

=item * L<Unicode::Stringprep::Prohibited>

  @Unicode::Stringprep::Prohibited::C11	# Appendix C.1.1
  @Unicode::Stringprep::Prohibited::C12	# Appendix C.1.2
  @Unicode::Stringprep::Prohibited::C21	# Appendix C.2.1
  @Unicode::Stringprep::Prohibited::C22	# Appendix C.2.2
  @Unicode::Stringprep::Prohibited::C3	# Appendix C.3
  @Unicode::Stringprep::Prohibited::C4	# Appendix C.4
  @Unicode::Stringprep::Prohibited::C5	# Appendix C.5
  @Unicode::Stringprep::Prohibited::C6	# Appendix C.6
  @Unicode::Stringprep::Prohibited::C7	# Appendix C.7
  @Unicode::Stringprep::Prohibited::C8	# Appendix C.8
  @Unicode::Stringprep::Prohibited::C9	# Appendix C.9

=item * L<Unicode::Stringprep::BiDi>

  @Unicode::Stringprep::BiDi::D1	# Appendix D.1
  @Unicode::Stringprep::BiDi::D2	# Appendix D.2

=back

=head1 PERL VERSION

You should use perl 5.8.3 or higher.

While this module does work with earlier perl versions, there are
some limitations:

Perl 5.6 does not promote strings to UTF-8 automatically.
B<You> have to make sure that you only pass valid UTF-8 strings to
this module.

Perl 5.6 to 5.7 come with Unicode databases earlier than 
version 3.2. Strings that contain characters for which the
normalisation has been changed are not prepared correctly.

Perl 5.6 to 5.8.2 can't handle surrogate characters
(U+D800..U+DFFF) in strings.
If a profile tries to map these characters, they won't be mapped
(currently no stringprep profile does this).
If a profile prohibits these characters, this module may fail to
detect them (currently, all profiles do that, so B<you> have to
make sure that these characters are not present).

=head1 AUTHOR

Claus FE<auml>rber <CFAERBER@cpan.org>

=head1 LICENSE

Copyright 2007-2009 Claus FE<auml>rber.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Unicode::Normalize>, S<RFC 3454> (L<http://www.ietf.org/rfc/rfc3454.txt>)

=cut
