package Ebooksforlib::Schema::Result::Provider;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Ebooksforlib::Schema::Result::Provider

=cut

__PACKAGE__->table("providers");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "description",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 items

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::Item>

=cut

__PACKAGE__->has_many(
  "items",
  "Ebooksforlib::Schema::Result::Item",
  { "foreign.provider_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-19 15:21:04
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1UxXvFkDBGfMU1OWHO+EVg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
