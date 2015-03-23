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
    my $limit   = param 'limit';

    my $library_sql;
    if ( $library && $library =~ m/[0-9]{1,}/ && $library > 0 ) {
        $library_sql = "AND l.library_id = $library";
    }

    my $limit_sql = 'LIMIT ';
    if ( $limit ne '' ) {
        if ( $limit eq 'ten' )        { $limit_sql .= '10'; }
        if ( $limit eq 'twentyfive' ) { $limit_sql .= '25'; }
        if ( $limit eq 'fifty' )      { $limit_sql .= '50'; }
        if ( $limit eq 'hundred' )    { $limit_sql .= '100'; }
        if ( $limit eq 'all' )        { $limit_sql = ''; } # No limit
    } else {
        $limit_sql .= '10';
    }

my $sql = "SELECT
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
    $library_sql
GROUP BY
    isbn
ORDER BY
    loans DESC
$limit_sql;";

    my $sth = database->prepare( $sql );
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

get '/superadmin/stats/loantime' => require_role superadmin => sub { 

    # Average loan time
    my $average_sql = "SELECT AVG(TIMESTAMPDIFF(DAY, loaned, returned)) AS average FROM old_loans;";
    my $average = database->selectrow_array($average_sql);

    # Loan times in days
    my $days_sql = "
        SELECT ROUND(TIMESTAMPDIFF(DAY, loaned, returned)) AS loantime, COUNT(*) as count
        FROM old_loans 
        GROUP BY loantime
    ";
    my $days = database->selectall_arrayref( $days_sql, { Slice => {} });

    # Loan times in hours, for loans shorter than a day
    my $hours_sql = "
        SELECT ROUND(TIMESTAMPDIFF(HOUR, loaned, returned)) AS loantime, COUNT(*) as count 
        FROM old_loans
        GROUP BY loantime
        HAVING loantime < 25
    ";
    my $hours = database->selectall_arrayref( $hours_sql, { Slice => {} });    

    # Loan times in minutes, for loans shorter than an hour
    my $minutes_sql = "
        SELECT ROUND(TIMESTAMPDIFF(MINUTE, loaned, returned)) AS loantime, COUNT(*) as count
        FROM old_loans
        GROUP BY loantime
        HAVING loantime < 61
    ";
    my $minutes = database->selectall_arrayref( $minutes_sql, { Slice => {} }); 

    template 'superadmin_stats_loantime', { 
        'average' => $average,
        'days'    => $days,
        'hours'   => $hours,
        'minutes' => $minutes,
    };
};

true;
