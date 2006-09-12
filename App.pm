package Config::Simple::App;

# $Id: App.pm,v 1.4 2006/09/12 14:30:00 sherzodr Exp $

use strict;
#use warnings;
#use diagnostics;
use Carp qw( croak );
use Config::Simple;

$Config::Simple::App::VERSION = '0.01';


my $get_instance = sub {
    my ($class) = @_;

    no strict 'refs';
    if ( defined ${$class . "::_config_instance"} ) {
        return ${$class . "::_config_instance"};
    }
    return undef;
};


my $set_instance = sub {
    my ($class, $instance) = @_;

    no strict 'refs';
    ${ $class . "::_config_instance" } = $instance;
};


*instance = \&new;
sub new {
    my ($class, $filename) = @_;
    $class = ref($class) || $class;

    if ( defined (my $instance = $get_instance->($class)) ) {
        return $instance;
    }
    
    unless ( defined $filename ) {
        croak "Config::Simple::App->new(): usage error";
    }

    unless ( (-e $filename) && (-r $filename) ) {
        croak "Config::Simple::App->new(): '$filename' either doesn't exist, or is not readable";
    }

    my $config = Config::Simple->new($filename);
    unless ( $config ) {
        croak "Config::Simple::App->new(): error while reading '$filename': " . Config::Simple->errstr;
    }

    my $self = bless {
        _config_file    => $filename,
        _config_simple  => $config,     # <-- Config::Simple object
        _known_vars     => {},          # <-- Known and default vars
        _config_vars    => {},          # <-- Config. file values
    }, $class;

    my %vars = $config->vars();
    while (my ($key, $value) = each %vars ) {
        $self->{_config_vars}->{$key} = $value;
        {
            #
            # It's just temporary, with absolutely no validation
            # This adds convenience, that's all!
            no strict 'refs';
            * { $class . '::' . $key } = sub { $value };
        }
    }
    $self->_init();

    #
    # Now we're validating
    while (my ($key, $value) = each %vars ) {
        unless ( exists $self->{_known_vars}->{$key} ) {
            croak $class . "::new(): Invalid attribute '$key'";
        }
    }

    return $set_instance->($class, $self);
}

sub teardown {
    my $self = shift;
    my $class = ref($self) || $self;
    no strict 'refs'; 
    #
    # We first take care of all the variables
    #
    for my $key ( keys %{ $self->{_known_vars} } ) {
        undef( *{ $class . '::' . $key } );
    }

    #
    # In the end, we also take care of the instance.
    $self = ${$class . "::_config_instance"} = undef;
}


sub define {
    my ($self, $key, $default_value) = @_;

    if ( exists $self->{_known_vars}->{$key} ) {
        croak "Config::Simple::App->define(): '$key' was previously defined";
    }

    $self->{_known_vars}->{$key} = $default_value || "";

    unless ( $self->can($key) ) { 
        no strict 'refs';
        *{ ref($self) . '::' . $key } = sub {
            unless ( exists $_[0]->{_config_vars}->{$key} ) {
                return $_[0]->{_known_vars}->{$key}
            }
            return $_[0]->{_config_vars}->{$key};
        };
    }
}


sub undefine {
    my ($self, $key) = @_;
    unless ( defined $key ) {
        croak "undefine(): usage error";
    }
    delete $self->{_known_vars}->{$key};
    no strict 'refs';
    *{ ref($self) . '::' . $key } = undef;
}


sub as_hashref {
    my $self = shift;
    
    my %hashref = ();
    for my $key ( keys %{ $self->{_known_vars} } ) {
        $hashref{$key} = $self->$key;
    }
    return \%hashref;
}



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Config::Simple::App - Perl extension for managing application's configuration settings

=head1 SYNOPSIS

    # inside App/Config.pm
    package App::Config;
    use base qw( Config::Simple::App );

    sub _init {
        my $self = shift;

        $self->define("AppPath", "/home/sherzodr/public_html/author/");
        $self->define("AppURL", "http://author.handalak.com/");
        $self->define("CGIPath", $self->AppURL . "cgi-bin/" );
        $self->define("DBDriver");
        $self->define("DBName");
        $self->define("DBUser");
        $self->define("DBPassword");
        $self->define("DBPath", $self->AppPath . "db/");

    }

    1;

    __END__;


    # in your application:
    $config = new App::Config("config.ini");
    print $config->AppPath();
    # etc..

=head1 ABSTRACT

    Config::Simple::App is meant to be sub classed by applications' 
    configuration manager class. Relies on Config::Simple to parse
    configuration files into configuration manager instance.

=head1 DESCRIPTION

One can, of course, use L<Config::Simple|Config::Simple> to manage their applications'
configuration files. Although perfect for reading and writing configuration files of various
formats, L<Config::Simple|Config::Simple> does not provide obvious ways for validating 
configuration file's attributes and for assigning default attribute values.

Is that such a big deal? Consider the following:

=over 4

=item *

Most applications rely on predefined configuration attributes.

=item * 

More often than not configuration files consist of attributes that are rarely modified, but read frequently.

=item *

All configuration attributes should not be required to be set explicitly. Applications must be able to derive
default values for missing attributes, possibly by looking at other attributes.

=item *

Typos in configuration files must be detected as early as possible. Complex validation routines may be required to validate certain settings (such as a path that doesn't exist, but should).

=item *

Name based access is sometimes preferred 

=back

Config::Simple::App attempts to deliver all the above features to your application

=head2 EXPORT

None.


=head1 PROGRAMMING STYLE

Config::Simple::App is not meant to be used directly, but through sub classing.

First step in creating a configuration manager class is to subclass Config::Simple::App.

    package App::ConfigManager;
    use base qw( Config::Simple::App );

Config::Simple::App provides new() and define() methods to your configuration class. The 
next step is to define an C<_init()> routine that gets called by new() after configuration file
has been processed. You need to call define() for each attribute that a configuration file
can have that is considered valid. This does not mean all those attributes must be present, but can be present.

    sub _init {
        my $self = shift;

        $self->define("Path");
        $self->define("TemplatePath", $self->Path . 'tmpl');
    }


=head1 METHODS

=over 4

=item new($config_file)




=item define($attribute)

=item define($attribute, $default_value)

=back



=head1 SEE ALSO

L<Config::Simple>

=head1 AUTHOR

Sherzod B. Ruzmetov E<lt>sherzodr@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Sherzod B. Ruzmetov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
