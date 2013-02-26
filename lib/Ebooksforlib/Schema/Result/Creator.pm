package Ebooksforlib::Schema::Result::Creator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Ebooksforlib::Schema::Result::Creator

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

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
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
  { "foreign.creator_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-26 11:46:34
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:O7SCwsxxS0mnItX4mVzIFQ

__PACKAGE__->many_to_many( books => 'book_creators', 'book' );

1;
