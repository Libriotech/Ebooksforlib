use utf8;
package Ebooksforlib::Schema::Result::OldLoan;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::OldLoan

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

=head1 TABLE: C<old_loans>

=cut

__PACKAGE__->table("old_loans");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 item_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 loaned

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 due

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 returned

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 0

=head2 gender

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 1
  size: 1

=head2 zipcode

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 1
  size: 9

=head2 age

  data_type: 'integer'
  is_nullable: 1

=head2 library_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "item_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "loaned",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "due",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "returned",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 0,
  },
  "gender",
  { data_type => "char", default_value => "", is_nullable => 1, size => 1 },
  "zipcode",
  { data_type => "char", default_value => "", is_nullable => 1, size => 9 },
  "age",
  { data_type => "integer", is_nullable => 1 },
  "library_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 item

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::Item>

=cut

__PACKAGE__->belongs_to(
  "item",
  "Ebooksforlib::Schema::Result::Item",
  { id => "item_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);

=head2 library

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::Library>

=cut

__PACKAGE__->belongs_to(
  "library",
  "Ebooksforlib::Schema::Result::Library",
  { id => "library_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "RESTRICT",
  },
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


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-11-15 17:19:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZwSiKi6HB1QvJjfbcQlY6A


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
