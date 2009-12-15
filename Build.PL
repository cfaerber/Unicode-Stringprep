#!/usr/bin/perl

use 5.006;
use strict;

use Module::Build;

my $b = Module::Build->new(
	'module_name'	=> 'Unicode::Stringprep',
	'license'	=> 'perl',

	'sign'		=> 1,
	'create_license' => 1,
	'create_makefile_pl' => 'traditional',

	'requires'	=> {
		'perl' => 5.006,
		'Unicode::Normalize' => 0.30,
	},
	'recommends'	=> {
		'perl' => 5.008003,
	},
	'build_requires' => {
		'Test::NoWarnings' => 0,
		'Test::More' => 0,
	},
	'no_index' => {
		'directory' => 'eg'
	},
	'resources' => {
		'homepage' => 'http://search.cpan.org/dist/Unicode-Stringprep',
		'repository' => 'http://github.com/cfaerber/Unicode-Stringprep',
	},
);

$b->create_build_script;
