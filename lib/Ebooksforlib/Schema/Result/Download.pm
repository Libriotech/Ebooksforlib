use utf8;
package Ebooksforlib::Schema::Result::Download;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::Download

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

=head1 TABLE: C<downloads>

=cut

__PACKAGE__->table("downloads");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 book_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 pkeyhash

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "book_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pkeyhash",
  { data_type => "char", is_nullable => 0, size => 32 },
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

=head1 UNIQUE CONSTRAINTS

=head2 C<user_id>

=over 4

=item * L</user_id>

=item * L</book_id>

=item * L</pkeyhash>

=back

=cut

__PACKAGE__->add_unique_constraint("user_id", ["user_id", "book_id", "pkeyhash"]);

=head1 RELATIONS

=head2 book

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::Book>

=cut

__PACKAGE__->belongs_to(
  "book",
  "Ebooksforlib::Schema::Result::Book",
  { id => "book_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);

=head2 user

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Ebooksforlib::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-09-26 15:15:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YFCXDmZFxdi5O12yfAwd/Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
