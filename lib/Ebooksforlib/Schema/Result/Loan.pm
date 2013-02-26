package Ebooksforlib::Schema::Result::Loan;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Ebooksforlib::Schema::Result::Loan

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
);
__PACKAGE__->set_primary_key("item_id", "user_id");
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
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 user

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::User>

=cut

__PACKAGE__->belongs_to(
  "user",
  "Ebooksforlib::Schema::Result::User",
  { id => "user_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-02-26 11:47:21
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:JonBs2sIITRW1KZs/qCmYw

use Dancer ':syntax';

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

1;
