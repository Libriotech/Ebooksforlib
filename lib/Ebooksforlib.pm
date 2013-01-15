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

true;
