package Ebooksforlib::Route::Superadmin::Stats;

=head1 Ebooksforlib::Route::Superadmin::Stats

Routes for viewing stats.

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Database;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

get '/superadmin/stats/mostpop' => require_role superadmin => sub {

    my $library = param 'library';

    my $library_limit;
    if ( $library && $library =~ m/[0-9]{1,}/ && $library > 0 ) {
        $library_limit = "AND l.library_id = $library";
    }

    my $sth = database->prepare(
"SELECT
    b.id,
    b.title,
    b.isbn,
    COUNT(*) as loans
FROM
    books AS b,
    files AS f,
    items as i,
    old_loans as l
WHERE
    b.id = f.book_id AND
    f.id = i.file_id AND
    i.id = l.item_id
    $library_limit
GROUP BY
    isbn
ORDER BY
    loans DESC
LIMIT 10;"
    );
    $sth->execute();
    my @mostpop;
    while ( my $book = $sth->fetchrow_hashref ) {
        push @mostpop, $book;
    }

    my @libraries = rset('Library')->search(
        { is_consortium => 0 },
        { order_by => 'name' }
    );

    template 'superadmin_mostpop', { 
        mostpop   => \@mostpop,
        libraries => \@libraries,
    };
};

get '/superadmin/stats/failed' => require_role superadmin => sub { 

    my @failed = resultset('User')->search(
        \[ 'failed > 0' ]
    );
    template 'superadmin_stats_failed', { 
        failed => \@failed,
    };
};

true;
