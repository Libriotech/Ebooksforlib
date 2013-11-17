package Ebooksforlib::Route::Admin::Stats;

=head1 Ebooksforlib::Route::Admin::Stats

Routes for viewing statistics

=cut

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Ebooksforlib::Util;

get '/admin/stats' => require_role admin => sub { 
    
    my $library_id = _get_library_for_admin_user();
    
    my $livestats = _get_simplestats( $library_id );
    my @oldstats  = resultset('Stat')->search(
        { library_id => $library_id }, 
        {
            order_by => { -desc => 'time' },
            rows     => 30,
        }
    );
    template 'admin_stats', { 
        livestats => $livestats, 
        oldstats  => \@oldstats,
    };
};

get '/admin/stats/gender' => require_role admin => sub { 
    
    my $library_id = _get_library_for_admin_user();

    # Gender for all registered users
    my @user_gender  = resultset('User')->search(
        { 
            'user_libraries.library_id' => $library_id,
        },
        {
            'join'      => 'user_libraries',
            '+select'   => [ { count => '*' } ],
            '+as'       => [ 'gender_count' ],
            'group_by'  => [ 'gender' ],
            'order_by'  => [ 'gender' ],
        }
    );
 
    # Gender for current loans
    my @loan_gender  = resultset('Loan')->search(
        { 
            'library_id' => $library_id,
        },
        {
            '+select'   => [ { count => '*' } ],
            '+as'       => [ 'gender_count' ],
            'group_by'  => [ 'gender' ],
            'order_by'  => [ 'gender' ],
        }
    );   
    
    # Gender for old (returned) loans
    my @old_loan_gender  = resultset('OldLoan')->search(
        { 
            'library_id' => $library_id,
        },
        {
            '+select'   => [ { count => '*' } ],
            '+as'       => [ 'gender_count' ],
            'group_by'  => [ 'gender' ],
            'order_by'  => [ 'gender' ],
        }
    );

    template 'admin_stats_gender', {
        'simplestats'     => _get_simplestats( $library_id ),
        'user_gender'     => \@user_gender,
        'loan_gender'     => \@loan_gender,
        'old_loan_gender' => \@old_loan_gender,
    };
};

get '/admin/stats/age' => require_role admin => sub { 
    
    my $library_id = _get_library_for_admin_user();

    # FIXME Show distribution of ages among users

    # Ages for active loans
    my @loan_ages  = resultset('Loan')->search(
        { 
            library_id => $library_id, 
        },
        {
            '+select' => [ { count => '*' } ],
            '+as'     => [ 'age_count' ],
            group_by  => [ 'age' ],
            order_by  => [ 'age' ],
        }
    );
    
    # Ages for old loans
    my @old_loan_ages  = resultset('OldLoan')->search(
        { 
            library_id => $library_id, 
        },
        {
            '+select' => [ { count => '*' } ],
            '+as'     => [ 'age_count' ],
            group_by  => [ 'age' ],
            order_by  => [ 'age' ],
        }
    );

    template 'admin_stats_age', { 
        loan_ages     => \@loan_ages,
        old_loan_ages => \@old_loan_ages,
    };
};

true;
