package Ebooksforlib::Schema::Result::Library;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Ebooksforlib::Schema::Result::Library

=cut

__PACKAGE__->table("libraries");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 realm

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "realm",
  { data_type => "varchar", is_nullable => 1, size => 32 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("realm", ["realm"]);
__PACKAGE__->add_unique_constraint("name", ["name"]);

=head1 RELATIONS

=head2 items

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::Item>

=cut

__PACKAGE__->has_many(
  "items",
  "Ebooksforlib::Schema::Result::Item",
  { "foreign.library_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lists

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::List>

=cut

__PACKAGE__->has_many(
  "lists",
  "Ebooksforlib::Schema::Result::List",
  { "foreign.library_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_libraries

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::UserLibrary>

=cut

__PACKAGE__->has_many(
  "user_libraries",
  "Ebooksforlib::Schema::Result::UserLibrary",
  { "foreign.library_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-19 15:21:03
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ekkPTxTF+7JVnyYE96EcPQ

__PACKAGE__->many_to_many( users => 'user_libraries', 'user' );

1;
