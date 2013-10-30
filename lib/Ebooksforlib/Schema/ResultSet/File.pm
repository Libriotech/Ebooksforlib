package Ebooksforlib::Schema::ResultSet::File;

use Modern::Perl;

use parent 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('Helper::ResultSet::AutoRemoveColumns');

1;
