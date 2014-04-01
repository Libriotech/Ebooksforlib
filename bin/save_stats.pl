#!/usr/bin/perl 

# save_stats.pl
# Copyright 2013 Magnus Enger Libriotech

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

# Get the libraries
my @libraries = resultset('Library')->all;
foreach my $library ( @libraries ) {
    say "*** ", $library->name if $verbose;
    my $stats = _get_simplestats( $library->id );
    if ( $verbose ) {
        foreach my $key ( keys $stats ) {
            say "\t$key: ", $stats->{$key};
        }
    }
    # Actually save the data
    if ( $run ) {
        try {
            my $new_stat = resultset('Stat')->create({
                library_id => $library->id,
            	users      => $stats->{'users'},
	            oldloans   => $stats->{'oldloans'},
	            onloan     => $stats->{'onloan'},
	            items      => $stats->{'items'},
            });
            say "\tStats saved" if $debug;
        } catch {
            error "*** Error while saving stats: $_";
        };
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
    
save_stats.pl - Take a snapshot of stats and save it to the database.
        
=head1 SYNOPSIS
            
DANCER_ENVIRONMENT=production perl save_stats.pl -r
               
=head1 OPTIONS
              
=over 4
                                                   
=item B<-r, --run>

Save data to the database. If you run the script without -r but with -v, you will 
see the stats printed to the terminal.

=item B<-v --verbose>

More output. The default is no output at all. 

=item B<-d --debug>

Even more output.

=item B<-h, -?, --help>
                                               
Prints this help message and exits.

=back
                                                               
=cut
