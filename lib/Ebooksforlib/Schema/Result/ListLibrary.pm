use utf8;
package Ebooksforlib::Schema::Result::ListLibrary;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::ListLibrary

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

=head1 TABLE: C<list_libraries>

=cut

__PACKAGE__->table("list_libraries");

=head1 ACCESSORS

=head2 list_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 library_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 frontpage

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=head2 frontpage_order

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 mobile

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "list_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "library_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "frontpage",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
  "frontpage_order",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "mobile",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</list_id>

=item * L</library_id>

=back

=cut

__PACKAGE__->set_primary_key("list_id", "library_id");

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

=head2 list

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::List>

=cut

__PACKAGE__->belongs_to(
  "list",
  "Ebooksforlib::Schema::Result::List",
  { id => "list_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-10-22 20:32:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:peeFdUs3Cy9G8lsgZhA8cA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
