package Unicode::Normalize_3_2;

use 5.006_000;

use strict;
use utf8;
use warnings;

use Exporter;

use Unicode::Normalize 0.07 ();

use Unicode::Stringprep::Unassigned;
use Unicode::Stringprep::_Util('_compile_set');

my @__auto = ('NFD', 'NFC', 'NFKD', 'NFKC');

our @ISA = ('Exporter');
our @EXPORT = map { $_.'_3_2' } @__auto;
our @EXPORT_OK = map { $_.'_3_2' } 'normalize', @__auto;

our $VERSION = "1.09_20091227";
$VERSION = eval $VERSION;

sub normalize_3_2 {
  my($form_name, $string) = @_;

  _protect_unassigned($string);	# protect characters unassigned in Unicode 3.2
  _premap_erroneous($string);	# pre-apply old erroneous mappings
  $string = Unicode::Normalize($form_name, $string);
  _unprotect_unassigned($string); # reverse protection of unassigned characters
  return $string;
}

my $re_unassigned = _compile_set(@Unicode::Stringprep::Unassigned::A1);
sub _protect_unassigned {
  my $string = shift;

  return $string;

}

sub _premap_erroneous {
  my $string = shift;

  $string =~ s/\x{2F868}/\x{2136A}/;	# Corrigendum 4
  $string =~ s/\x{2F874}/\x{5F33}/g;	# Corrigendum 4
  $string =~ s/\x{2F91F}/\x{43AB}/g;	# Corrigendum 4
  $string =~ s/\x{2F95F}/\x{7AAE}/g;	# Corrigendum 4
  $string =~ s/\x{2F9BF}/\x{4D57}/g;	# Corrigendum 4

  return $string;
}

no strict 'refs';
*{$_.'_3_2'} = \sub { normalize_3_2($_, @_ } foreach @__auto;

1;

__END__

=head1 NAME

Unicode::Normalize_3_2 - Old Unicode 3.2 variant of Normalization Forms

=head1 SYNOPSIS

  use Unicode::Normalize_3_2;

  $NFD_string  = NFD_3_2($string);  # Normalization Form D
  $NFC_string  = NFC_3_2($string);  # Normalization Form C
  $NFKD_string = NFKD_3_2($string); # Normalization Form KD
  $NFKC_string = NFKC_3_2($string); # Normalization Form KC

=head1 DESCRIPTION

While L<Unicode::Normalize> provides Normalization Forms based on the Unicode
version supported by the installed perl version, this module always uses
version 3.2 of the Unicode standard.

For applications that do not need to keep bug-for-bug compatibility with
Unicode 3.2, use Unicode::Normalize instead.

This module provides a subset of the functionality provided by
Unicode::Normalize:

=over

=item $normalized_string = normalize_3_2($form_name, $string);

Returns C<$string> in the normalization form of C<$form_name>,
according to Unicode version 3.2.

As $form_name, one of the following names must be given.

=over 

=item *

'C'  or 'NFC'  for Normalization Form C  (UAX #15)

=item *

'D'  or 'NFD'  for Normalization Form D  (UAX #15)

=item *

'KC' or 'NFKC' for Normalization Form KC (UAX #15)

=item *

'KD' or 'NFKD' for Normalization Form KD (UAX #15)

=back

This function can be imported.

=item $NFD_string = NFD_3_2($string)

=item $NFC_string = NFC_3_2($string)

=item $NFKD_string = NFKD_3_2($string)

=item $NFKC_string = NFKC_3_2($string)

Same as C<normalize_3_2('NFD',$string)>, C<normalize_3_2('NFC',$string)>,
C<normalize_3_2('NFKD',$string)> or C<normalize_3_2('NFKC',$string)>,
respectively.

These functions are exported by default

=back

This module does not provide Unicode 3.2 equivalents for the following functions:
C<decompose>,
C<reorder>,
C<compose>,
C<splitOnLastStarter>,
C<normalize_partial>,
C<NFI<*>_partial>.

=head1 BUGS

This module actually needs perl 5.8.3 to work correctly but only declares perl
5.6.x as a requirement.

This will be fixed when L<Net::IDN::Encode> is updated for IDNA 2008, which no
longer relies on Stringprep and thus Unicode 3.2 Normalization.

=head1 AUTHOR

Claus FE<auml>rber E<lt>CFAERBER@cpan.orgE<gt>

=head1 LICENSE

Copyright 2010 Claus FE<auml>rber.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Unicode::Normalize>

=cut
