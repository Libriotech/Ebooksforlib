use utf8;
package Ebooksforlib::Schema::Result::Page;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::Page

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

=head1 TABLE: C<pages>

=cut

__PACKAGE__->table("pages");

=head1 ACCESSORS

=head2 slug

  data_type: 'char'
  is_nullable: 0
  size: 32

=head2 title

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 text

  data_type: 'text'
  is_nullable: 1

=head2 last_edit

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 last_editor

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "slug",
  { data_type => "char", is_nullable => 0, size => 32 },
  "title",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "text",
  { data_type => "text", is_nullable => 1 },
  "last_edit",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "last_editor",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);

=head1 PRIMARY KEY

=over 4

=item * L</slug>

=back

=cut

__PACKAGE__->set_primary_key("slug");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-11-26 09:05:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Agod0RY+V70Y5zbLXlWn3Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
