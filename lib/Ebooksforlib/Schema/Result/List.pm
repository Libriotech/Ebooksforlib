use utf8;
package Ebooksforlib::Schema::Result::List;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::List

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

=head1 TABLE: C<lists>

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

=head2 frontpage

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 mobile

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 frontpage_order

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

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
  "frontpage",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "mobile",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "frontpage_order",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
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


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-09-26 13:32:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:z5+bpBWJ+a8U+Bpiehl/sA

__PACKAGE__->many_to_many( books => 'list_books', 'book' );

1;
