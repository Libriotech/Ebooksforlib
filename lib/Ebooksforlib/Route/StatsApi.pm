package Ebooksforlib::Route::StatsApi;

=head1 Ebooksforlib::Route::StatsApi

An API for getting live stats about the service. 

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;
use Digest::MD5 qw( md5_hex );

# Default serialization should be JSON
set serializer => 'JSON';

get '/stats' => sub {
    return { 
        libraries => resultset('Library')->count,
        books => resultset('Book')->count,
        files => resultset('File')->count,
        items => resultset('Item')->count,
        logged_in => resultset('Session')->count,
        loans => resultset('Loan')->count,
        old_loans => resultset('OldLoan')->count,
    };
};

true;
