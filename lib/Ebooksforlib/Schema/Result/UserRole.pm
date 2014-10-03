use utf8;
package Ebooksforlib::Schema::Result::UserRole;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::UserRole

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

=head1 TABLE: C<user_roles>

=cut

__PACKAGE__->table("user_roles");

=head1 ACCESSORS

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 role_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "role_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</user_id>

=item * L</role_id>

=back

=cut

__PACKAGE__->set_primary_key("user_id", "role_id");

=head1 RELATIONS

=head2 role

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::Role>

=cut

__PACKAGE__->belongs_to(
  "role",
  "Ebooksforlib::Schema::Result::Role",
  { id => "role_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);

=head2 user

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Ebooksforlib::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-09-26 15:15:41
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:zEIOxN8cM1QJvDbE/0oiyg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
