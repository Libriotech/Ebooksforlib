#!/usr/bin/perl 

# import_books.pl
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
use File::Slurp;
use Business::ISBN;
use Getopt::Long;
use Data::Dumper;
use Pod::Usage;
use Modern::Perl;

use Ebooksforlib::Util;

# Get options
my ( $run, $verbose, $debug ) = get_options();

# Get the directories we should be looking at
my $providers = config->{'providers'};
IMPORTDIR: foreach my $provider ( @{ $providers } ) {

    # Be verbose
    say Dumper $provider if $debug;
    say "Looking at $provider->{'dir'}" if $verbose;
    
    # Check that the directory exists before proceeding
    if ( !-e $provider->{'dir'} ) { die "$provider->{'dir'} does not exist"; }
    
    my @files = read_dir( $provider->{'dir'} );
    my $num_files = @files;
    say "Found $num_files files" if $verbose;
    
    FILE: foreach my $filename ( @files ) {
        
        say "----------------------------\n$filename" if $verbose;
        
        my $file_path = $provider->{'dir'} . '/' . $filename;
        say "Path: $file_path" if $verbose;
        
        # Split up the filename
        my ( $isbn_string, $fileext ) = split /\./, $filename;
        say "ISBN: $isbn_string" if $verbose;
        say "File extension: $fileext" if $verbose;
        
        # Check if the ISBN is valid
        my $isbn = Business::ISBN->new( $isbn_string );
        unless ( $isbn->is_valid ) {
            say "! $isbn_string is not a valid ISBN";
            next FILE;
        }
        
        # Check that we have an .epub
        unless ( $fileext eq 'epub' ) {
            say "! $filename is not an .epub";
            next FILE;
        }
        
        # Get data based on the ISBN
        # my $data = _get_data_from_isbn( $isbn );
        # say Dumper $data if $debug;
        
        # Insert the ISBN into the books table
        my $book_id;
        try {
            my $new_book = resultset('Book')->find_or_new({
                isbn => $isbn->common_data,
            });
            if( $new_book->in_storage ) {
                say "! A book with this ISBN already exists" if $verbose;
                next FILE;
            } else {
                $new_book->insert;
            }
            $book_id = $new_book->id;
            say "\n* Added book with ISBN = $isbn_string as id = $book_id";
        } catch {
            say "Error while saving book: $_";
            next FILE;
        };
        
        my $file_id;
        try {
            # Insert the file into the files table
            my $file_contents = read_file( $file_path );
            my $new_file = rset( 'File' )->create({
                book_id     => $book_id,
                provider_id => $provider->{ 'provider_id' },
                file        => $file_contents,
            });
            $file_id = $new_file->id;
            say "Added file with id = $file_id";
        } catch {
            say "Error while saving file: $_";
            next FILE;
        };
                
        # Add the items
        my $libraries = $provider->{ 'libraries' };
        LIBRARY: foreach my $library ( @{ $libraries } ) {
            say $library->{ 'slug' } if $verbose;
            for ( 1..$library->{ 'copies' } ) {
                try {
                    my $new_item = resultset('Item')->create({
                        library_id  => $library->{ 'library_id' },
                        file_id     => $file_id,
                        loan_period => $library->{ 'loan_period' },
                    });
                    say "Added item with id = " . $new_item->id;
                } catch {
                    say "Error while saving item: $_";
                }
            }
        }
        
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
    
import_books.pl - Import books found in a directory on the server. Filenames should be <ISBN>.epub
        
=head1 SYNOPSIS
            
DANCER_ENVIRONMENT=production perl import_books.pl -r
               
=head1 OPTIONS
              
=over 4
                                                   
=item B<-r, --run>

Actually run the import process. Running the script without this option will only report the number of books that would have been done with this option. 

=item B<-v --verbose>

More output. The default is no output at all. 

=item B<-d --debug>

Even more output.

=item B<-h, -?, --help>
                                               
Prints this help message and exits.

=back
                                                               
=cut
