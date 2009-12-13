#!/usr/bin/perl

BEGIN { require 5.006; }

use utf8;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'		=> 'Unicode::Stringprep',
	'VERSION_FROM'	=> 'lib/Unicode/Stringprep.pm', # finds $VERSION
	'PREREQ_PM'	=> {
		'Unicode::Normalize' => 0.30,
		'Test::NoWarnings' => 0,
		'Test::More' => 0,
	    },
	'ABSTRACT'	=> 'Preparation of Internationalized Strings (RFC 3454)',
	'AUTHOR'	=> 'Claus Faerber <CFAERBER@cpan.org>',
	'LICENSE'	=> 'perl',

	$ExtUtils::MakeMaker::VERSION < 6.18 ? () : (
		'SIGN'		=> 1,
	    ),

	$ExtUtils::MakeMaker::VERSION < 6.45 ? () : (
  		'META_MERGE'	=> { 
			'requires'	=> { 'perl'	=> 5.006, },
			'recommends'	=> { 'perl'	=> 5.008003, },
			'resources' => {
				'homepage' => 'http://search.cpan.org/dist/Unicode-Stringprep',
				'repository' => 'http://github.com/cfaerber/Unicode-Stringprep',
		    	},
		    },
	    ),
);

sub MY::postamble {
return <<EOF
release: release-cpan

release-cpan:
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
EOF
}
