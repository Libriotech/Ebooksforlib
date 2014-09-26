use utf8;
package Ebooksforlib::Schema::Result::Creator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::Creator

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

=head1 TABLE: C<creators>

=cut

__PACKAGE__->table("creators");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 dataurl

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "dataurl",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 book_creators

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::BookCreator>

=cut

__PACKAGE__->has_many(
  "book_creators",
  "Ebooksforlib::Schema::Result::BookCreator",
  { "foreign.creator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 books

Type: many_to_many

Composing rels: L</book_creators> -> book

=cut

__PACKAGE__->many_to_many("books", "book_creators", "book");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-09-26 13:32:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Qxil5bv0ekvGAkhzbMDbMA

1;
