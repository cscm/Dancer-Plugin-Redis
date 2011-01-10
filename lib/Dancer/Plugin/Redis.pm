package Dancer::Plugin::Redis;

use strict;
use Dancer::Plugin;
use Redis;

=head1 NAME

Dancer::Plugin::Redis - easy database connections for Dancer applications

=cut

our $VERSION = '0.01';

my $settings = plugin_setting;
my %handles;
# Hashref used as key for default handle, so we don't have a magic value that
# the user could use for one of their connection names and cause problems
# (Kudos to Igor Bujna for the idea)
my $def_handle = {};

register redis => sub {
    my $name = shift;
    my $handle = defined($name) ? $handles{$name} : $def_handle;
    my $settings = _get_settings($name);

    if ($handle->{dbh}) {
        if (time - $handle->{last_connection_check}
            < $settings->{connection_check_threshold}) {
            return $handle->{dbh};
        } else {
            if (_check_connection($handle->{dbh})) {
                $handle->{last_connection_check} = time;
                return $handle->{dbh};
            } else {
                Dancer::Logger::debug(
                    "Redis connection went away, reconnecting"
                );
                return $handle->{dbh}= _get_connection($settings);
            }
        }
    } else {
        # Get a new connection
        if (!$settings) {
            Dancer::Logger::error(
                "No DB settings named $name, so cannot connect"
            );
            return;
        }
        if ($handle->{dbh} = _get_connection($settings)) {
            $handle->{last_connection_check} = time;
            return $handle->{dbh};
        } else {
            return;
        }
    }
};

register_plugin;

# Given the settings to use, try to get a database connection
sub _get_connection {
    my $settings = shift;

    my $r = Redis->new(
	server =>  $settings->{server}, debug =>  $settings->{debug} 
    );

    if (!$r) {
        Dancer::Logger::error(
            "Redis connection failed - " 
        );
    }

    return $r;
}



# Check the connection is alive
sub _check_connection {
    my $dbh = shift;
    return unless $dbh;
    my $result;
    # Redis.pm die when the connection is closed
    eval { $result = $dbh->ping; }; return 0 if $@;
    if ($result eq "PONG") {
            return 1;
    };
    return 0;
}

sub _get_settings {
    my $name = shift;
    my $return_settings;

    # If no name given, just return the default settings
    # (Take a copy and remove the connections key, so we have only the main
    # connection details)
    if (!defined $name) {
        $return_settings = { %$settings };
    } else {
        # If there are no named connections in the config, bail now:
        return unless exists $settings->{connections};


        # OK, find a matching config for this name:
        if (my $settings = $settings->{connections}{$name}) {
            $return_settings = { %$settings };
        } else {
            # OK, didn't match anything
            Dancer::Logger::error(
                "Asked for a database handle named '$name' but no matching  "
               ."connection details found in config"
            );
        }
    }
    
    # We should have soemthing to return now; remove any unrelated connections
    # (only needed if this is the default connection), and make sure we have a
    # connection_check_threshold, then return what we found
    delete $return_settings->{connections};
    $return_settings->{connection_check_threshold} ||= 5;
    return $return_settings;

}


=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::Redis;

    # Calling the redis keyword will get you a connected Redis Database handle:
    get '/widget/view/:id' => sub {
        template 'display_widget', { widget => redis->get('hash_key'); };
    };

    dance;

Redis connection details are read from your Dancer application config - see
below.


=head1 DESCRIPTION

Provides an easy way to obtain a connected Redis database handle by simply calling
the redis keyword within your L<Dancer> application.

Takes care of ensuring that the database handle is still connected and valid.
If the handle was last asked for more than C<connection_check_threshold> seconds
ago, it will check that the connection is still alive, using either the 
C<< $r->ping >> method if the Redis driver supports it, or performing a simple
no-op query against the database if not.  If the connection has gone away, a new
connection will be obtained and returned.  This avoids any problems for
a long-running script where the connection to the database might go away.

=head1 CONFIGURATION

Connection details will be taken from your Dancer application config file, and
should be specified as, for example: 

    plugins:
        Redis:
            server: '127.0.0.1:6379'
            debug: 0

The C<connectivity-check-threshold> setting is optional, if not provided, it
will default to 30 seconds.  If the database keyword was last called more than
this number of seconds ago, a quick check will be performed to ensure that we
still have a connection to the database, and will reconnect if not.  This
handles cases where the database handle hasn't been used for a while and the
underlying connection has gone away.


=head1 GETTING A DATABASE HANDLE

Calling C<redis> will return a connected database handle; the first time it is
called, the plugin will establish a connection to the database, and return a
reference to the DBI object.  On subsequent calls, the same DBI connection
object will be returned, unless it has been found to be no longer usable (the
connection has gone away), in which case a fresh connection will be obtained.

If you have declared named connections as described above in 'DEFINING MULTIPLE
CONNECTIONS', then calling the database() keyword with the name of the
connection as specified in the config file will get you a database handle
connected with those details.

=head1 AUTHOR

Christophe Nowicki, C<< <cscm@csquad.org> >>



=head1 CONTRIBUTING

This module is developed on Github at:

L<https://github.com/cscm/Dancer-Plugin-Redis>

Feel free to fork the repo and submit pull requests!


=head1 ACKNOWLEDGEMENTS

Igor Bujna, David Precious


=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-database at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-Redis>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Redis


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Redis>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-Redis>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Redis>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-Redis/>

=back

You can find the author on IRC in the channel C<#dancer> on <irc.perl.org>.


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Christophe Nowicki.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=head1 SEE ALSO

L<Dancer>

L<DBI>



=cut

1; # End of Dancer::Plugin::Redis
