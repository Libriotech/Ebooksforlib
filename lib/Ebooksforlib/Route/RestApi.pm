package Ebooksforlib::Route::RestApi;

=head1 Ebooksforlib::Route::RestApi

The API that the reader component talks to. 

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;
use Digest::MD5 qw( md5_hex );

# Default serialization should be JSON
set serializer => 'JSON';

get '/rest/libraries' => sub {
    my @libraries = rset('Library')->all;
    my @data;
    foreach my $lib ( @libraries ) {
        my %libdata = (
            name  => $lib->name,
            realm => $lib->realm,
        );
        push @data, \%libdata;
    }
    return \@data;
};

# FIXME Switch from GET to POST before launch, to avoid passwords in logs etc
get '/rest/login' => sub {

    my $username  = param 'username';
    my $password  = param 'password';
    my $userrealm = param 'realm';
    my $pkey      = param 'pkey';
    
    # Check that we have the necessary info
    unless ( $username ) {
        return { 
            status => 1,
            error  => 'Missing parameter: username',
        };
    }
    unless ( $password ) {
        return { 
            status => 1,
            error  => 'Missing parameter: password',
        };
    }
    unless ( $userrealm ) {
        return { 
            status => 1,
            error  => 'Missing parameter: realm',
        };
    }
    unless ( $pkey ) {
        return { 
            status => 1,
            error  => 'Missing parameter: pkey',
        };
    }
    
    # Try to log in
    my ( $success, $realm ) = authenticate_user( $username, $password, $userrealm );
    if ( $success ) {
        # Find the user
        my $user = rset('User')->find({ username => $username });
        # Check if a hash has been saved already
        if ( $user->hash eq '' ) {
            # Create the local_hash
            my $now = DateTime->now;
            my $local_hash = md5_hex( $username . $now->datetime() );
            # Save the new local_hash
            try {
                $user->set_column( 'hash', $local_hash );
                $user->update;
            }
        }
        # Hash the pkey with the user hash and return the result
        my $hash = hash_pkey( $user->hash, $pkey );
        return { 
            'status'   => 0,
            'userdata' => {
                'hash'     => $hash,
                'uid'      => $user->id,
                'username' => $user->username,
                'name'     => $user->name,
                'realm'    => $realm,
            }
        };
    } else {
        return { 
            status => 0,
            error  => 'Login failed',
        };
    }
};

# FIXME Not implemented
get '/rest/logout' => sub {

    return { 
        status => 0
    };

};

get '/rest/whoami' => sub {

    if ( logged_in_user ) {
    
        my $pkey           = param 'pkey';
        my $logged_in_user = logged_in_user; 

        # Find the user
        my $user = rset('User')->find( $logged_in_user->{'id'} );
        
        my $hash;
        if ( $pkey ) {
        
            # Check if a hash has been saved already
            if ( $user->hash eq '' ) {
                # Create the local_hash
                my $now = DateTime->now;
                my $local_hash = md5_hex( $user->username . $now->datetime() );
                # Save the new local_hash
                try {
                    $user->set_column( 'hash', $local_hash );
                    $user->update;
                }
            }
            # Hash the pkey with the user hash and return the result
            $hash = hash_pkey( $user->hash, $pkey );
        
        }

        return { 
            'status'   => 0,
            'userdata' => {
                'hash'            => $hash,
                'uid'             => $user->id,
                'username'        => $user->username,
                'name'            => $user->name,
                'realm'           => session('logged_in_user_real_realm'),
                'realmprettyname' => session('chosen_library_name'),
            }
        };
    
    } else {
    
        return { 
            'status' => 1,
            'error'  => 'User is not logged in',
        };
    
    }
    
};

get '/rest/removebook' => sub {

    my $user_id = param 'uid';
    my $book_id = param 'bookid';
    my $pkey    = param 'pkey';
    
    # Check parameters
    unless ( $user_id ) {
        return { 
            status => 1,
            error  => 'Missing parameter: uid',
        };
    }
    unless ( $book_id ) {
        return { 
            status => 1,
            error  => 'Missing parameter: bookid',
        };
    }
    unless ( $pkey ) {
        return { 
            status => 1,
            error  => 'Missing parameter: pkey',
        };
    }

    # Check that the user is valid    
    my $user = rset('User')->find( $user_id );
    unless ( $user ) {
        return { 
            status => 1,
            error  => 'Unknown user',
        };
    }
    
    debug "*** /rest/removebook for user = $user_id";

    # TODO Check that the book_id is for a valid book
    # TODO Check that the book_id is on loan for the user
    debug "*** /rest/removebook for book_id = $book_id";
    
    my $download = rset('Download')->find({ user_id => $user_id, book_id => $book_id, pkeyhash => md5_hex( $pkey ) });
    if ( $download ) {
        try {
            # Remove the book from the table that tracks downloads 
            $download->delete;
            debug '*** Download deleted with id = ' . $download->id;
            # Add the download to the old_downloads table
            try {
                my $old_download = rset('OldDownload')->create({
                    id       => $download->id,
                    user_id  => $download->user_id,
                    book_id  => $download->book_id,
                    pkeyhash => $download->pkeyhash,
                    time     => $download->time,
                });
                debug "*** old_download was created";
            } catch {
                debug "*** Oops, we got an error when trying to create an old_download: $_";
            };
            return { 
                'status'   => 0, 
                'booklist' => "The book was removed"
            };
        } catch {
            debug "*** Oops, we got an error when trying to delete a download: $_";
            return { 
                status => 1,
                error  => 'An error occured while trying to remove the book',
            };
        };
    } else {
        return { 
                status => 1,
                error  => 'Book not found',
        };
    }    

};

=head2 /rest/:action

This route handles:

=over 4

=item * /rest/listbooks

=item * /rest/getbook

=item * /rest/ping

=item * /rest/return

=back

Required parameters for all of these are:

=over 4

=item * uid

=item * hash

=item * pkey

=back

/rest/getbook and /rest/return also requires bookid as a parameter.

=cut

get '/rest/:action' => sub {

    my $action  = param 'action';
    my $user_id = param 'uid';
    my $hash    = param 'hash';
    my $pkey    = param 'pkey';
    
    ## Common security checks for all actions
    
    # Check parameters
    unless ( $user_id ) {
        return { 
            status => 1,
            error  => 'Missing parameter: uid',
        };
    }
    unless ( $hash ) {
        return { 
            status => 1,
            error  => 'Missing parameter: hash',
        };
    }
    unless ( $pkey ) {
        return { 
            status => 1,
            error  => 'Missing parameter: pkey',
        };
    }
    
    my $user = rset('User')->find( $user_id );
    unless ( $user ) {
        return { 
            status => 1,
            error  => 'Unknown user',
        };
    }
    
    # Check the user has a hash set
    if ( $user->hash eq '' ) {
        return { 
            status => 1,
            error  => 'User has never logged in',
        };
    }
    
    # Check the saved hash against the supplied hash
    unless ( check_hash( $user->hash, $hash, $pkey ) ) {
        return { 
            status => 1,
            error  => 'Credentials do not match',
        };
    }
    
    ## End of common security checks
    
    if ( $action eq 'listbooks' ) {

        debug "*** /rest/listbooks for user = $user_id";
    
        my @loans;
        foreach my $loan ( $user->loans ) {
            debug "Loan: " . $loan->loaned;
            my %loan;
            $loan{'bookid'}   = $loan->item->file->book->id;
            $loan{'loaned'}   = $loan->loaned->datetime;
            $loan{'due'}      = $loan->due->datetime;
            $loan{'expires'}  = $loan->due->epoch; # Same as 'due', but in seconds since epoch
            $loan{'title'}    = $loan->item->file->book->title;
            $loan{'name'}     = $loan->item->file->book->title;
            $loan{'language'} = 'no'; # FIXME Make this part of the schema
            $loan{'creator'}  = $loan->item->file->book->creators_as_string;
            $loan{'author'}   = $loan->item->file->book->creators_as_string;
            $loan{'coverurl'} = $loan->item->file->book->coverurl;
            $loan{'coverimg'} = $loan->item->file->book->coverimg;
            $loan{'pages'}    = $loan->item->file->book->pages;
            push @loans, \%loan;
        }
        return { 
            'status'   => 0, 
            'booklist' => \@loans
        };
        
    } elsif ( $action eq 'getbook' ) {
    
        debug "*** /rest/getbook for user = $user_id";
    
        my $book_id = param 'bookid';
        unless ( $book_id ) {
            return { 
                status => 1,
                error  => 'Missing parameter: bookid',
            };
        }
        debug "*** /rest/getbook for book_id = $book_id";
        
        foreach my $loan ( $user->loans ) {
            if ( $loan->item->file->book->id == $book_id ) {
                debug "*** /rest/getbook for loan with item_id = " . $loan->item_id . " user_id = " . $loan->user_id . " loaned = " . $loan->loaned;
                debug "*** /rest/getbook for item = " . $loan->item->id . " library_id = " . $loan->item->library_id . " file_id = " . $loan->item->file_id;
                debug "*** /rest/getbook for file = " . $loan->item->file->id;
                
                # Get the content from the DB - obsolete! 
                # EPUBxDB my $fulltext = rset('Fulltext')->find( $loan->item->file->id );
                # EPUBxDB my $content = $fulltext->file;

                # Get the content from the filesystem
                # Check that we have a path to an actual file
                if ( $loan->item->file->from_path && -f $loan->item->file->from_path ) {
                    # Keep track of this download in the downloads table
                    try {
                        rset('Download')->create({
                            user_id  => $user_id,
                            book_id  => $book_id,
                            pkeyhash => md5_hex( $pkey ),
                        });
                        debug "*** The download was recorded"
                    } catch {
                        debug "Oops, the download was NOT recorded: $_";
                    };
                    # Log the download
                    _log2db({
                        logcode => 'DOWNLOAD',
                        logmsg  => "user_id = $user_id, book_id = $book_id, item_id = " . $loan->item->id . ", file_id = " . $loan->item->file->id,
                    });
                    # Send the actual file
                    return send_file(
                        $loan->item->file->from_path,
                        system_path  => 1,
                        content_type => 'application/epub+zip',
                        filename     => 'book-' . $loan->item->file->id . '.epub'
                    );
                } else {
                    status 404;
                    return { 
                        'status' => 1, 
                        'error'  => 'Book not found',
                    };
                }
                # EPUBxDB undef $content;
            }
        }
        # If we got this far we did not find a file representing the given 
        # book that is on loan to the given user, so return an error
        status 500;
        return "This book is not on loan to the given user.";
        
    } elsif ( $action eq 'return' ) {
    
        debug "*** /rest/return for user = $user_id";
    
        my $book_id = param 'bookid';
        unless ( $book_id ) {
            return { 
                status => 1,
                error  => 'Missing parameter: bookid',
            };
        }
        debug "*** /rest/return for book_id = $book_id";
        
        foreach my $loan ( $user->loans ) {
            if ( $loan->item->file->book->id == $book_id ) {
                # Do the return
                my $return = _return_loan( $loan );
                # Check the outcome
                if ( $return->{'error'} == 1 ) {
                    # We got an error
                    debug "*** Error trying to process return from the reader API: " . $return->{'errormsg'};
                    return { 
                        'status' => 1, 
                        'error'  => $return->{'errormsg'},
                    }; 
                } else {
                    # Success
                    my $item_id = $loan->item->id;
                    # Log
                    _log2db({
                        logcode => 'APIRETURN',
                        logmsg  => "item_id: $item_id",
                    });
                    debug "*** Returned item for item_id = $item_id, user_id = $user_id";
                    return { 
                        'status' => 0, 
                    }; 
                }
            }
        }
        
        # If we got this far we did not find a file representing the given 
        # book that is on loan to the given user, so return an error
        status 404;
        return "This book is not on loan to the given user.";

    } elsif ( $action eq 'ping' ) {
    
        return { 
            'status' => 0, 
        };
        
    }
    
};

true;
