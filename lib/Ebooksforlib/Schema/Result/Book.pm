package Ebooksforlib::Schema::Result::Book;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


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

=head2 creator

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 date

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "creator",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "date",
  { data_type => "varchar", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-14 13:49:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7rHnYX+Xr0G3E9mhYkf00Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
