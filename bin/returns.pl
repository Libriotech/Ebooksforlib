#!/usr/bin/perl 

# returns.pl
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

# Get options
my ( $run, $verbose, $debug ) = get_options();

# my $now = DateTime->now( time_zone => setting('time_zone') );
# say 'Now: ' . $now->datetime if $debug;

# Find the loans that have a due date in the past
my @overdues = rset('Loan')->search({ due => \'< NOW()' });
my $num_overdues = 0;
my $num_returned = 0;
my %overdues_per_library;
foreach my $odue ( @overdues ) {
     
     # Say what we found
     if ( $debug ) {
        say 'Item ' . $odue->item_id . ' - ' .  $odue->item->library->name;
        say "\t" . $odue->loaned . " -> " . $odue->due;
        say "\t" . $odue->user->name;
    }
    
    # Do the actual return
    if ( $run ) {
        
        # Add an old loan
        try {
            my $old_loan = rset('OldLoan')->create({
                item_id  => $odue->item_id,
                user_id  => $odue->user_id,
                loaned   => $odue->loaned,
                due      => $odue->due,
                returned => DateTime->now( time_zone => setting('time_zone') )
            });
            say "\tAdded to old loans" if $debug;
        } catch {
            say "Oops, we got an error:\n$_";
        };
        
        # Delete the loan
        try {
            $odue->delete;
            $num_returned++;
            say "\tRemoved from loans" if $debug;
        } catch {
            say "Oops, we got an error:\n$_";
        };
        
    }
    
    # Do some counting
    $num_overdues++;
    $overdues_per_library{ $odue->item->library->name }++;
}

# Summarize what we found and did
if ( $verbose ) {
    say "Found $num_overdues overdue loans:";
    foreach my $library ( keys %overdues_per_library ) {
        say "\t$library: " . $overdues_per_library{ $library };
    }
    say "Returned $num_returned loans.";
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
    
returns.pl - Script to be run as a cron job to "return" ebooks that are due. Part of Ebooksforlib.
        
=head1 SYNOPSIS
            
perl returns.pl -r
               
=head1 OPTIONS
              
=over 4
                                                   
=item B<-r, --run>

Actually run the return process. Running the script without this option will only report the number of returns that would have been done with this option. 

=item B<-v --verbose>

More output. The default is no output at all. 

=item B<-d --debug>

Even more output.

=item B<-h, -?, --help>
                                               
Prints this help message and exits.

=back
                                                               
=cut
