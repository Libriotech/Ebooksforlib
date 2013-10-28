use utf8;
package Ebooksforlib::Schema::Result::Log;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::Log

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

=head1 TABLE: C<log>

=cut

__PACKAGE__->table("log");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_nullable: 0

=head2 time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_nullable: 0

=head2 library_id

  data_type: 'integer'
  is_nullable: 0

=head2 logcode

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 logmsg

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_nullable => 0 },
  "time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "user_id",
  { data_type => "integer", is_nullable => 0 },
  "library_id",
  { data_type => "integer", is_nullable => 0 },
  "logcode",
  { data_type => "char", is_nullable => 0, size => 32 },
  "logmsg",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-10-28 11:13:39
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:iEI6jr52zxzaHpUcCTKbpQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
