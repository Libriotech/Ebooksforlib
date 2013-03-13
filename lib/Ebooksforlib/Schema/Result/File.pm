package Ebooksforlib::Schema::Result::File;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Ebooksforlib::Schema::Result::File

=cut

__PACKAGE__->table("files");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 book_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 provider_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 file

  data_type: 'longblob'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "book_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "provider_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "file",
  { data_type => "longblob", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

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

=head2 provider

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::Provider>

=cut

__PACKAGE__->belongs_to(
  "provider",
  "Ebooksforlib::Schema::Result::Provider",
  { id => "provider_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 items

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::Item>

=cut

__PACKAGE__->has_many(
  "items",
  "Ebooksforlib::Schema::Result::Item",
  { "foreign.file_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-03-13 14:51:31
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cgdwyABpi0vR7INeb5hTFA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
