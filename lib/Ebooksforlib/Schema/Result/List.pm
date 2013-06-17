package Ebooksforlib::Schema::Result::List;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Ebooksforlib::Schema::Result::List

=cut

__PACKAGE__->table("lists");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 library_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 is_genre

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "library_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "is_genre",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 list_books

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::ListBook>

=cut

__PACKAGE__->has_many(
  "list_books",
  "Ebooksforlib::Schema::Result::ListBook",
  { "foreign.list_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 library

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::Library>

=cut

__PACKAGE__->belongs_to(
  "library",
  "Ebooksforlib::Schema::Result::Library",
  { id => "library_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-26 11:46:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wkYYHozteyq5bUndBn/BsA

__PACKAGE__->many_to_many( books => 'list_books', 'book' );

# FIXME Add this manually as long as we can't update automatically
__PACKAGE__->add_columns(
  "frontpage",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "frontpage_order",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
);


1;
