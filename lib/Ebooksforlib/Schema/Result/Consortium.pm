use utf8;
package Ebooksforlib::Schema::Result::Consortium;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::Consortium

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

=head1 TABLE: C<consortiums>

=cut

__PACKAGE__->table("consortiums");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 consortium_libraries

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::ConsortiumLibrary>

=cut

__PACKAGE__->has_many(
  "consortium_libraries",
  "Ebooksforlib::Schema::Result::ConsortiumLibrary",
  { "foreign.consortium_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 libraries

Type: many_to_many

Composing rels: L</consortium_libraries> -> library

=cut

__PACKAGE__->many_to_many("libraries", "consortium_libraries", "library");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-09-26 13:16:51
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wJrYRzP9iWBGg8r5c+9Tew


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
