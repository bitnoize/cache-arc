#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Cache::ARC',
  VERSION_FROM => "lib/Cache/ARC.pm",
  ABSTRACT     => "Adaptive replacement cache",
  LICENSE      => "Artistic-2.0",
  AUTHOR       => "Dmitry Krutikov <mitya\@openmailbox.org>",
  PREREQ_PM    => { },
  test => { TESTS => "t/*.t" }
);
