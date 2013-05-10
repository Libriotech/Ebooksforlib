package Ebooksforlib::Schema::Result::Comment;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Ebooksforlib::Schema::Result::Comment

=cut

__PACKAGE__->table("comments");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 user_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 book_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 comment

  data_type: 'text'
  is_nullable: 0

=head2 time

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "book_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "comment",
  { data_type => "text", is_nullable => 0 },
  "time",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

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

=head2 book

Type: belongs_to

Related object: L<Ebooksforlib::Schema::Result::Book>

=cut

__PACKAGE__->belongs_to(
  "book",
  "Ebooksforlib::Schema::Result::Book",
  { id => "book_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-10 13:27:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YyPSUq9NnJyTCrC9hgu7eA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
