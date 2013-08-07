use utf8;
package Ebooksforlib::Schema::Result::ListBook;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::ListBook

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

=head1 TABLE: C<list_book>

=cut

__PACKAGE__->table("list_book");

=head1 ACCESSORS

=head2 book_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 list_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 promoted

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "book_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "list_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "promoted",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</book_id>

=item * L</list_id>

=back

=cut

__PACKAGE__->set_primary_key("book_id", "list_id");

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

=head2 list

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::List>

=cut

__PACKAGE__->belongs_to(
  "list",
  "Ebooksforlib::Schema::Result::List",
  { id => "list_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07036 @ 2013-08-07 14:19:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lZxK8ZTNb4uSK30MwJeuNQ

1;
