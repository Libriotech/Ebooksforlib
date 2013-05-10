package Ebooksforlib::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 NAME

Ebooksforlib::Schema::Result::User

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 password

  data_type: 'varchar'
  is_nullable: 0
  size: 64

=head2 name

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 anonymize

  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=head2 hash

  data_type: 'char'
  default_value: (empty string)
  is_nullable: 1
  size: 64

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "password",
  { data_type => "varchar", is_nullable => 0, size => 64 },
  "name",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "anonymize",
  { data_type => "integer", default_value => 1, is_nullable => 1 },
  "hash",
  { data_type => "char", default_value => "", is_nullable => 1, size => 64 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("username", ["username"]);

=head1 RELATIONS

=head2 comments

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::Comment>

=cut

__PACKAGE__->has_many(
  "comments",
  "Ebooksforlib::Schema::Result::Comment",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 loans

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::Loan>

=cut

__PACKAGE__->has_many(
  "loans",
  "Ebooksforlib::Schema::Result::Loan",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 old_loans

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::OldLoan>

=cut

__PACKAGE__->has_many(
  "old_loans",
  "Ebooksforlib::Schema::Result::OldLoan",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_libraries

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::UserLibrary>

=cut

__PACKAGE__->has_many(
  "user_libraries",
  "Ebooksforlib::Schema::Result::UserLibrary",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_roles

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "Ebooksforlib::Schema::Result::UserRole",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2013-05-10 13:27:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+sDDaa2GcL5Mk7GavXjXYw

__PACKAGE__->many_to_many( libraries => 'user_libraries', 'library' );

__PACKAGE__->many_to_many( roles => 'user_roles', 'role' );

sub number_of_loans_from_library {
    my ( $self, $library_id ) = @_;
    my $number_of_loans = 0;
    foreach my $loan ( $self->loans ) {
        if ( $loan->item->library_id == $library_id ) {
            $number_of_loans++;
        }
    }
    return $number_of_loans;
}

sub belongs_to_library {
    my ( $self, $library_id ) = @_;
    foreach my $library ( $self->libraries ) {
        if ( $library->id == $library_id ) {
            return 1;
        }
    }
    return 0;    
}

1;
