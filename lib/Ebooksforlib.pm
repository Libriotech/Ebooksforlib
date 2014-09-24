
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
use Ebooksforlib::Route::Superadmin::Logs;
use Ebooksforlib::Route::Superadmin::Stats;
use Ebooksforlib::Route::Superadmin::DeleteBook;

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
        unless ( request->path =~ /\/choose/   || # Let users choose a library
                 request->path =~ /\/set\/.*/  || # Let users set a library
                 request->path =~ /\/page\/.*/ || # Let users look at pages without choosing a library
                 request->path =~ /\/in/       || # Let users log in
                 request->path =~ /\/blocked/  || # Display the blocked message to blocked users
                 request->path =~ /\/unblock/  || # Let users unblock themselves
                 request->path =~ /\/rest\/.*/   # Don't force choosing a library for the API
               ) {
            return redirect '/choose';
        }
    }
    
    # Guard against session hijacking
    # Get the session from the database
    my $session = resultset('Sessioncount')->find({ 'session_id' => cookie( 'dancer.session' ) });
    # Check that IP and UA have not changed since the session was created
    if ( $session && ( $session->ip ne request->remote_address || $session->ua ne request->user_agent ) ) {
        # Allow the reader to "hijack" sessions, since that is basically how it does it's job
        if ( request->path !~ /\/rest\/.*/ && !config->{ 'rest_allowed_ips' }{ request->remote_address } ) {
            # Log the incident
            _log2db({
                logcode => 'SESSIONHIJACK',
                logmsg  => "Username: " . session( 'logged_in_user' ) . " ID: " . session( 'logged_in_user_id' ),
            });
            my $username    = session( 'logged_in_user' );
            my $userid      = session( 'logged_in_user_id' );
            my $recorded_ip = $session->ip;
            my $current_ip  = request->remote_address;
            my $recorded_ua = $session->ua;
            my $current_ua  = request->user_agent;
            error "SESSIONHIJACK - Username: $username ID: $userid Recorded IP: $recorded_ip Current IP: $current_ip Recorded UA: $recorded_ua Current UA: $current_ua";
            # Log the user out
            session->destroy;
            debug "+++ Session was destroyed because of a suspected session hijacking";
            # This flash message has to be set after the session is destroyed, to be displayed to the user
            flash info => "Your IP or User Agent changed. You have been logged out. Please log in again.";
            return redirect '/choose';
        }
    }

    # This is a legit request, update sessions.last_active
    my $real_session = resultset('Session')->find( cookie( 'dancer.session' ) );
    $real_session->set_column( 'last_active', undef );
    $real_session->update;

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

    my @libraries = rset( 'Library' )->all;
    template 'chooselib', { 
        libraries          => \@libraries, 
        disable_search     => 1,
        pagetitle          => l( 'Choose library' ),
    };

};

get '/set/:library_id' => sub {
    my $library_id = param 'library_id';
    # cookie chosen_library => $library_id; # FIXME Expiry
    my $library = rset('Library')->find( $library_id );
    if ( $library ) {
        debug "*** Going to set chosen library in session";
        session chosen_library       => $library->id;
        session chosen_library_name  => $library->name;
        session chosen_library_piwik => $library->piwik;
    } else {
        flash error => localize("Not a valid library.");
    }
    redirect '/';
};

get '/lang' => sub {
    redirect request->referer;
};

true;
