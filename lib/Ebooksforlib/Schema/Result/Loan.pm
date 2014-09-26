use utf8;
package Ebooksforlib::Schema::Result::Loan;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::Loan

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

=head1 TABLE: C<loans>

=cut

__PACKAGE__->table("loans");

=head1 ACCESSORS

=head2 item_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 loaned

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 due

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 library_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 gender

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 1
  size: 1

=head2 age

  data_type: 'integer'
  is_nullable: 1

=head2 zipcode

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 1
  size: 9

=cut

__PACKAGE__->add_columns(
  "item_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "loaned",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "due",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "library_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "gender",
  { data_type => "char", default_value => "", is_nullable => 1, size => 1 },
  "age",
  { data_type => "integer", is_nullable => 1 },
  "zipcode",
  { data_type => "char", default_value => "", is_nullable => 1, size => 9 },
);

=head1 PRIMARY KEY

=over 4

=item * L</item_id>

=item * L</user_id>

=back

=cut

__PACKAGE__->set_primary_key("item_id", "user_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<item_id>

=over 4

=item * L</item_id>

=back

=cut

__PACKAGE__->add_unique_constraint("item_id", ["item_id"]);

=head1 RELATIONS

=head2 item

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::Item>

=cut

__PACKAGE__->belongs_to(
  "item",
  "Ebooksforlib::Schema::Result::Item",
  { id => "item_id" },
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
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "RESTRICT",
  },
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


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-09-26 13:32:38
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2DYNOSRWYgP/I6PBSxG4+w

use Dancer ':syntax';

# Repeat these here to add the timezone
__PACKAGE__->add_columns(
  "loaned",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
    timezone => setting('time_zone'),
  },
  "due",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
    timezone => setting('time_zone'),
  },
);

sub time_left {
    my $self = shift;
    my $now = DateTime->now( time_zone => setting('time_zone'), );
    my $diff = $self->due - $now;
    return $diff;
}

sub overdue {
    my $self = shift;
    my $now = DateTime->now( time_zone => setting('time_zone'), );
    if ( $self->due < $now ) {
        return 1;
    } else {
        return 0;
    }
}

1;
