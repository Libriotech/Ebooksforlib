use utf8;
package Ebooksforlib::Schema::Result::Sessioncount;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::Sessioncount

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

=head1 TABLE: C<sessioncounts>

=cut

__PACKAGE__->table("sessioncounts");

=head1 ACCESSORS

=head2 session_id

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 last_modified

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 ip

  data_type: 'char'
  is_nullable: 0
  size: 16

=head2 ua

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "session_id",
  { data_type => "char", is_nullable => 0, size => 40 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "last_modified",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "ip",
  { data_type => "char", is_nullable => 0, size => 16 },
  "ua",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</session_id>

=back

=cut

__PACKAGE__->set_primary_key("session_id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-03-05 10:45:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:xVDv5TgEU5q7Q0DhZQyOfA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
