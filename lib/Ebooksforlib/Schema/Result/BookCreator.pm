package Ebooksforlib::Schema::Result::BookCreator;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Ebooksforlib::Schema::Result::BookCreator

=cut

__PACKAGE__->table("book_creators");

=head1 ACCESSORS

=head2 book_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 creator_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "book_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "creator_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("book_id", "creator_id");

=head1 RELATIONS

=head2 book

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::Book>

=cut

__PACKAGE__->belongs_to(
  "book",
  "Ebooksforlib::Schema::Result::Book",
  { id => "book_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 creator

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::Creator>

=cut

__PACKAGE__->belongs_to(
  "creator",
  "Ebooksforlib::Schema::Result::Creator",
  { id => "creator_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-14 15:33:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Vaj9ObBdkyd8uMWae5FIcg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
