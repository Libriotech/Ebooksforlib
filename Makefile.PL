use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Ebooksforlib',
    AUTHOR              => q{YOUR NAME <youremail@example.com>},
    VERSION_FROM        => 'lib/Ebooksforlib.pm',
    ABSTRACT            => 'YOUR APPLICATION ABSTRACT',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'YAML'       => 0,
        'Dancer'     => 1.311,
        'Dancer::Plugin::Auth::Extensible' => 0,
        'Dancer::Plugin::Database' => 0,
        'Dancer::Plugin::DBIC' => 0,
        'Dancer::Plugin::FlashMessage' => 0,
        'Dancer::Plugin::Lexicon' => 0,
        'Dancer::Plugin::Email' => 0,
        'Dancer::Exception' => 0,
        'Business::ISBN' => 0,
        'HTML::Strip' => 0,
        'DateTime' => 0,
        'DateTime::Duration' => 0,
        'Data::Dumper' => 0,
        'Modern::Perl' => 0,
        'URI::Escape' => 0,
        'Dancer::Plugin::Auth::Basic' => 0,
        'Dancer::Plugin::EscapeHTML' => 0,
        'Locale::Maketext::Lexicon' => 0,
        'DateTime::Format::ISO8601' => 0,
        'DBIx::Class::Helper::ResultSet::AutoRemoveColumns' => 0,
        'Try::Tiny' => 0,
        'Data::Password::Check' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Ebooksforlib-*' },
);
