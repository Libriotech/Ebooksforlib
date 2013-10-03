use utf8;
package Ebooksforlib::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::User

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

=head1 TABLE: C<users>

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

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<username>

=over 4

=item * L</username>

=back

=cut

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

=head2 downloads

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::Download>

=cut

__PACKAGE__->has_many(
  "downloads",
  "Ebooksforlib::Schema::Result::Download",
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

=head2 old_downloads

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::OldDownload>

=cut

__PACKAGE__->has_many(
  "old_downloads",
  "Ebooksforlib::Schema::Result::OldDownload",
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

=head2 ratings

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::Rating>

=cut

__PACKAGE__->has_many(
  "ratings",
  "Ebooksforlib::Schema::Result::Rating",
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

=head2 libraries

Type: many_to_many

Composing rels: L</user_libraries> -> library

=cut

__PACKAGE__->many_to_many("libraries", "user_libraries", "library");

=head2 roles

Type: many_to_many

Composing rels: L</user_roles> -> role

=cut

__PACKAGE__->many_to_many("roles", "user_roles", "role");


# Created by DBIx::Class::Schema::Loader v0.07025 @ 2013-08-07 14:07:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Rw5ywC3+inNqbEKivurhug

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
