# $Id$

use utf8;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Unicode::Stringprep',
    'VERSION_FROM'	=> 'lib/Unicode/Stringprep.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'Unicode::Normalize' => 0.01,
	},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT => 'Preparation of Internationalized Strings (RFC 3454)',
       AUTHOR   => 'Claus Färber <CFAERBER@cpan.org>') : ()),
);

sub MY::postamble {
return <<EOF
release: release-sf release-cpan

release-cpan:
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)

release-sf:
	sf-upload -groupid 112466 -packageid 246624 -r \$(VERSION) -cf Changes -nf README -f \$(DISTVNAME).tar\$(SUFFIX)
EOF
}
