package Ebooksforlib::Schema::Result::Book;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Ebooksforlib::Schema::Result::Book

=cut

__PACKAGE__->table("books");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 date

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 isbn

  data_type: 'varchar'
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "date",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "isbn",
  { data_type => "varchar", is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 book_creators

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::BookCreator>

=cut

__PACKAGE__->has_many(
  "book_creators",
  "Ebooksforlib::Schema::Result::BookCreator",
  { "foreign.book_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 items

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::Item>

=cut

__PACKAGE__->has_many(
  "items",
  "Ebooksforlib::Schema::Result::Item",
  { "foreign.book_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 list_books

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::ListBook>

=cut

__PACKAGE__->has_many(
  "list_books",
  "Ebooksforlib::Schema::Result::ListBook",
  { "foreign.book_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-26 11:46:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7vuq9hilTYdx9mFnPA5UPw

__PACKAGE__->many_to_many( creators => 'book_creators', 'creator' );

__PACKAGE__->many_to_many( lists => 'list_books', 'list' );

__PACKAGE__->many_to_many( libraries => 'items', 'library' );

1;
