use utf8;
package Ebooksforlib::Schema::Result::Session;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::Session

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

=head1 TABLE: C<sessions>

=cut

__PACKAGE__->table("sessions");

=head1 ACCESSORS

=head2 id

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 session_data

  data_type: 'text'
  is_nullable: 1

=head2 last_active

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "char", is_nullable => 0, size => 40 },
  "session_data",
  { data_type => "text", is_nullable => 1 },
  "last_active",
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

=head2 sessioncount

Type: might_have

Related object: L<Ebooksforlib::Schema::Result::Sessioncount>

=cut

__PACKAGE__->might_have(
  "sessioncount",
  "Ebooksforlib::Schema::Result::Sessioncount",
  { "foreign.session_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-04-02 20:33:08
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9RXqmhVztCoyY930szec3Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
