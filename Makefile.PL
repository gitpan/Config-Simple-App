use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Config::Simple::App',
    'VERSION_FROM'	=> 'App.pm', # finds $VERSION
    'PREREQ_PM'		=> {Config::Simple=>undef}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'App.pm', # retrieve abstract from module
       AUTHOR     => 'A. U. Thor <sherzodr@localdomain>') : ()),
);
