use utf8;
package Ebooksforlib::Schema::Result::Item;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::Item

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

=head1 TABLE: C<items>

=cut

__PACKAGE__->table("items");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 library_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 file_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 loan_period

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=head2 deleted

  data_type: 'integer'
  default_value: 0
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "library_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "file_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "loan_period",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
  "deleted",
  { data_type => "integer", default_value => 0, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 file

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::File>

=cut

__PACKAGE__->belongs_to(
  "file",
  "Ebooksforlib::Schema::Result::File",
  { id => "file_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "RESTRICT" },
);

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

=head2 loan

Type: might_have

Related object: L<Ebooksforlib::Schema::Result::Loan>

=cut

__PACKAGE__->might_have(
  "loan",
  "Ebooksforlib::Schema::Result::Loan",
  { "foreign.item_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 old_loans

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::OldLoan>

=cut

__PACKAGE__->has_many(
  "old_loans",
  "Ebooksforlib::Schema::Result::OldLoan",
  { "foreign.item_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-09-26 13:32:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0nTAWtMxshZuN3ChTiRrug

1;
