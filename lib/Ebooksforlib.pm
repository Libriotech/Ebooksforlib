package Ebooksforlib;
use Dancer ':syntax';

our $VERSION = '0.1';

hook 'before' => sub {
    var appname => config->{appname};
};

get '/' => sub {
    template 'index';
};

get '/about' => sub {
    template 'about', { pagetitle => 'About' };
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
