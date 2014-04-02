#!/usr/bin/perl 

# purge_sessions.pl
# Copyright 2014 Magnus Enger Libriotech

# This is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This file is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this file; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

use Dancer ':script';
use Dancer::Plugin::DBIC;
use Try::Tiny;
use DateTime;
use Getopt::Long;
use Data::Dumper;
use Pod::Usage;
use Modern::Perl;

use Ebooksforlib::Util;

# Get options
my ( $run, $verbose, $debug ) = get_options();

# Find the sessions that have expired
# FIXME Make the number of minutes configurable
my @expired = resultset('Session')->search({ last_active => \'< DATE_SUB(NOW(), INTERVAL 30 MINUTE)' });
foreach my $ex ( @expired ) {
     
    say $ex->id . ' ' . $ex->last_active if $verbose;
    # Do the actual return
    if ( $run ) {
        $ex->delete;
        debug "*** Deleted session " . $ex->id . ' ' . $ex->last_active;
    }
    
}

sub get_options {

    # Options
    my $run        = '';
    my $verbose    = '';
    my $debug      = '';
    my $help       = '';
  
    GetOptions (
        'r|run'     => \$run,
        'v|verbose' => \$verbose,
        'd|debug'   => \$debug,  
        'h|?|help'  => \$help
    );

  pod2usage( -exitval => 0 ) if $help;

  return ( $run, $verbose, $debug );

}

__END__

=head1 NAME
    
purge_sessions.pl - Delete expired sessions from the database;
        
=head1 SYNOPSIS
            
DANCER_ENVIRONMENT=production perl purge_sessions.pl -r
               
=head1 OPTIONS
              
=over 4
                                                   
=item B<-r, --run>

Actually delete the expired sessions. Running the script without this option will only report the expired sessions, not delete them. 

=item B<-v --verbose>

More output. The default is no output at all. 

=item B<-d --debug>

Even more output.

=item B<-h, -?, --help>
                                               
Prints this help message and exits.

=back
                                                               
=cut
