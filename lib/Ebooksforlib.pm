
package Ebooksforlib;
use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::FlashMessage;
use Dancer::Plugin::Lexicon;
use Dancer::Exception qw(:all);
use Business::ISBN;
use HTML::Strip;
use DateTime;
use DateTime::Duration;
use Data::Dumper; # DEBUG 
use Modern::Perl;
use URI::Escape;

use Ebooksforlib::Util;
use Ebooksforlib::Route::Browse;
use Ebooksforlib::Route::Login;
use Ebooksforlib::Route::MyProfile;
use Ebooksforlib::Route::Circ;
use Ebooksforlib::Route::RestApi;
use Ebooksforlib::Route::Admin;
use Ebooksforlib::Route::Admin::Settings;
use Ebooksforlib::Route::Admin::Books;
use Ebooksforlib::Route::Admin::Covers;
use Ebooksforlib::Route::Admin::Creators;
use Ebooksforlib::Route::Admin::Items;
use Ebooksforlib::Route::Admin::Lists;
use Ebooksforlib::Route::Admin::Stats;
use Ebooksforlib::Route::Admin::Logs;
use Ebooksforlib::Route::Superadmin;
use Ebooksforlib::Route::Superadmin::Providers;
use Ebooksforlib::Route::Superadmin::Libraries;
use Ebooksforlib::Route::Superadmin::LocalUsers;

use Dancer::Plugin::Auth::Basic;
use Dancer::Plugin::EscapeHTML;

use Ebooksforlib::Err;

our $VERSION = '0.1';

hook 'before' => sub {

    errinit();

    var appname  => config->{appname};
    var min_pass => config->{min_pass}; # FIXME Is there a better way to do this? 
    var language_tag => language_tag;
    var installed_langs => installed_langs;

    set_language 'no';

    # Did the user try to access /admin or /superadmin without being logged in? 
    my $request_path = request->path();
    if ( ( $request_path eq '/admin' || $request_path eq '/superadmin' ) && !session('logged_in_user_id') ) {
        return redirect '/in?admin=1';
    }
    
    # Restrict access to the REST API
    if ( request->path =~ /\/rest\/.*/ && !config->{ 'rest_allowed_ips' }{ request->remote_address } ) {
        debug "Denied access to the REST API for " . request->remote_address;
        # Log
        _log2db({
            logcode => 'RESTDENY',
            logmsg  => "IP: " . request->remote_address,
        });
        status 403;
        halt("403 Forbidden");
    }
    
    # Force users to choose a library
    unless ( session('chosen_library') && session('chosen_library_name') ) {
        # Some pages must be reachable without choosing a library 
        # To exempt the front page, include this below: || request->path eq '/'
        unless ( request->path =~ /\/choose/  || # Let users choose a library
                 request->path =~ /\/set\/.*/ || # Let users set a library
                 request->path =~ /\/in/      || # Let users log in
                 request->path =~ /\/blocked/ || # Display the blocked message to blocked users
                 request->path =~ /\/unblock/ || # Let users unblock themselves
                 request->path =~ /\/rest\/.*/   # Don't force choosing a library for the API
               ) {
            return redirect '/choose?return_url=' . request->path();
            # To force users to one library, uncomment this:
            # return redirect '/set/2?return_url=' . request->path();
        }
    }
    
    # We need to show lists and genres on a lot of pages, so we might as well 
    # make the data available from here
    # TODO Perhaps have a list of pages that need the data here, to check
    # against? 
    # FIXME Not sure this is a good idea anymore...
    my @lists = rset('List')->search({
        'library_id' => session('chosen_library')
    });
    var lists => \@lists;

};

hook 'after' => sub {
    errexit();
};

get '/choose' => sub {

    my $return_url = param 'return_url';

    if ( $return_url ) {
        $return_url = '' if($return_url =~ /^[a-z]+\:/i);
        $return_url = uri_escape($return_url);
    }

    my @libraries = rset( 'Library' )->all;

    my $belongs_to_library = 0;
    if ( session('logged_in_user_id') ) {
        my $user = rset( 'User' )->find( session('logged_in_user_id') );
        $belongs_to_library = $user->belongs_to_library( session('chosen_library') )
    }

    template 'chooselib', { 
        libraries          => \@libraries, 
        return_url         => $return_url, 
        belongs_to_library => $belongs_to_library,
        disable_search     => 1,
        pagetitle          => l( 'Choose library' ),
    };

};

get '/set/:library_id' => sub {
    my $library_id = param 'library_id';
    # cookie chosen_library => $library_id; # FIXME Expiry
    my $library = rset('Library')->find( $library_id );
    if ( $library ) {
        session chosen_library => $library->id;
        session chosen_library_name => $library->name;
        # flash info => "A library was chosen.";
        if (params->{return_url}) {
           return redirect params->{return_url};
        }
    } else {
        flash error => localize("Not a valid library.");
    }
    redirect '/choose';
};

get '/lang' => sub {
    redirect request->referer;
};

true;
