package Ebooksforlib;
use Dancer ':syntax';
use Dancer::Plugin::Auth::Extensible;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::FlashMessage;
use Dancer::Exception qw(:all);
use Data::Dumper; # DEBUG 

our $VERSION = '0.1';

hook 'before' => sub {

    var appname => config->{appname};

    if ( logged_in_user ) {
        # Get the data for the logged in user
        my $user = logged_in_user;
        # Remove the password, no reason to be passing it around
        delete $user->{password};
        # Store the data in the session, so it's available to templates etc
        session user  => $user;
        session roles => user_roles;
    }

};

get '/' => sub {
    template 'index';
};

get '/about' => sub {
    template 'about';
};

get '/my' => sub {
    template 'my';
};

get '/admin' => require_role admin => sub { 
    template 'admin';
};

get '/superadmin' => require_role superadmin => sub { 
    my @users     = schema->resultset('User')->all;
    my @libraries = schema->resultset('Library')->all;
    template 'superadmin', { 
        'users'     => \@users,
        'libraries' => \@libraries,
    };
};

get '/libraries/add' => require_role superadmin => sub { 
    template 'libraries_form';
};

post '/libraries/add' => require_role superadmin => sub {

    my $name = param 'name';
    if ( schema->resultset('Library')->count({ name  => $name }) ) {
        flash error => "A library with that name already exists";
        template 'libraries_form', { name => $name };
    } else {
        my $new_library = schema->resultset('Library')->create({
            name  => param 'name',
        });
        flash info => 'A new library was added!';
        redirect '/superadmin';
    }

#    try {
#        my $new_library = schema->resultset('Library')->create({
#            name  => param 'name',
#        });
#    } catch {
#        flash error => "got a db error: ";
#        redirect '/superadmin';
#    };
#
#    flash info => 'A new library was added!';
#    redirect '/superadmin';

};

get '/libraries/:action/:id?' => require_role superadmin => sub { 
    template 'libraries';
};

get '/users/:action/:id?' => require_role superadmin => sub { 
    template 'users';
};

# Reader-app API
# The server-side component of the reader-app will be talking to this API
# TODO These are dummy functions with hardcoded responses, for now

set serializer => 'JSON';

get '/rest/login' => sub {

    return { 
        hash => '0c86b9ecb91ee1e16f96363956dff7e5'
    };

};

get '/rest/logout' => sub {

    return { 
        logout => 1
    };

};

get '/rest/listbooks' => sub {

    return { 
        1 => { title => 'a', author => 'b' },
        2 => { title => 'c', author => 'd' },
    };

};

get '/rest/getbook' => sub {

    return { 
        login => 'ok'
    };

};

true;
