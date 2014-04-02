use utf8;
package Ebooksforlib::Schema::Result::Sessioncount;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::Sessioncount

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

=head1 TABLE: C<sessioncounts>

=cut

__PACKAGE__->table("sessioncounts");

=head1 ACCESSORS

=head2 session_id

  data_type: 'char'
  is_foreign_key: 1
  is_nullable: 0
  size: 40

=head2 user_id

  data_type: 'integer'
  is_nullable: 1

=head2 ip

  data_type: 'char'
  is_nullable: 0
  size: 16

=head2 ua

  data_type: 'varchar'
  default_value: (empty string)
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "session_id",
  { data_type => "char", is_foreign_key => 1, is_nullable => 0, size => 40 },
  "user_id",
  { data_type => "integer", is_nullable => 1 },
  "ip",
  { data_type => "char", is_nullable => 0, size => 16 },
  "ua",
  { data_type => "varchar", default_value => "", is_nullable => 0, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</session_id>

=back

=cut

__PACKAGE__->set_primary_key("session_id");

=head1 RELATIONS

=head2 session

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::Session>

=cut

__PACKAGE__->belongs_to(
  "session",
  "Ebooksforlib::Schema::Result::Session",
  { id => "session_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-04-02 20:56:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7TbC1SngUoAlNYU55KaH8w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
