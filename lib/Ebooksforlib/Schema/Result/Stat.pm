use utf8;
package Ebooksforlib::Schema::Result::Stat;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::Stat

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<stats>

=cut

__PACKAGE__->table("stats");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 library_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 files

  data_type: 'integer'
  is_nullable: 0

=head2 users

  data_type: 'integer'
  is_nullable: 0

=head2 oldloans

  data_type: 'integer'
  is_nullable: 0

=head2 onloan

  data_type: 'integer'
  is_nullable: 0

=head2 items

  data_type: 'integer'
  is_nullable: 0

=head2 time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "library_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "files",
  { data_type => "integer", is_nullable => 0 },
  "users",
  { data_type => "integer", is_nullable => 0 },
  "oldloans",
  { data_type => "integer", is_nullable => 0 },
  "onloan",
  { data_type => "integer", is_nullable => 0 },
  "items",
  { data_type => "integer", is_nullable => 0 },
  "time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 library

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::Library>

=cut

__PACKAGE__->belongs_to(
  "library",
  "Ebooksforlib::Schema::Result::Library",
  { id => "library_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-14 21:09:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:MA/r9nGa5LaR1bX2J6Hu4g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
