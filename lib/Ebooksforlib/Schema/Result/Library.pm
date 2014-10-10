use utf8;
package Ebooksforlib::Schema::Result::Library;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Ebooksforlib::Schema::Result::Library

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

=head1 TABLE: C<libraries>

=cut

__PACKAGE__->table("libraries");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 realm

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 concurrent_loans

  data_type: 'integer'
  default_value: 1
  is_nullable: 0

=head2 detail_head

  data_type: 'text'
  is_nullable: 1

=head2 soc_links

  data_type: 'text'
  is_nullable: 1

=head2 piwik

  data_type: 'integer'
  is_nullable: 1

=head2 is_consortium

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "realm",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "concurrent_loans",
  { data_type => "integer", default_value => 1, is_nullable => 0 },
  "detail_head",
  { data_type => "text", is_nullable => 1 },
  "soc_links",
  { data_type => "text", is_nullable => 1 },
  "piwik",
  { data_type => "integer", is_nullable => 1 },
  "is_consortium",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 UNIQUE CONSTRAINTS

=head2 C<name>

=over 4

=item * L</name>

=back

=cut

__PACKAGE__->add_unique_constraint("name", ["name"]);

=head2 C<realm>

=over 4

=item * L</realm>

=back

=cut

__PACKAGE__->add_unique_constraint("realm", ["realm"]);

=head1 RELATIONS

=head2 consortium_members_consortiums

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::ConsortiumMember>

=cut

__PACKAGE__->has_many(
  "consortium_members_consortiums",
  "Ebooksforlib::Schema::Result::ConsortiumMember",
  { "foreign.consortium_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 consortium_members_libraries

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::ConsortiumMember>

=cut

__PACKAGE__->has_many(
  "consortium_members_libraries",
  "Ebooksforlib::Schema::Result::ConsortiumMember",
  { "foreign.library_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 files

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::File>

=cut

__PACKAGE__->has_many(
  "files",
  "Ebooksforlib::Schema::Result::File",
  { "foreign.library_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 items

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::Item>

=cut

__PACKAGE__->has_many(
  "items",
  "Ebooksforlib::Schema::Result::Item",
  { "foreign.library_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 lists

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::List>

=cut

__PACKAGE__->has_many(
  "lists",
  "Ebooksforlib::Schema::Result::List",
  { "foreign.library_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 loans

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::Loan>

=cut

__PACKAGE__->has_many(
  "loans",
  "Ebooksforlib::Schema::Result::Loan",
  { "foreign.library_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 old_loans

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::OldLoan>

=cut

__PACKAGE__->has_many(
  "old_loans",
  "Ebooksforlib::Schema::Result::OldLoan",
  { "foreign.library_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 stats

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::Stat>

=cut

__PACKAGE__->has_many(
  "stats",
  "Ebooksforlib::Schema::Result::Stat",
  { "foreign.library_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 user_libraries

Type: has_many

Related object: L<Ebooksforlib::Schema::Result::UserLibrary>

=cut

__PACKAGE__->has_many(
  "user_libraries",
  "Ebooksforlib::Schema::Result::UserLibrary",
  { "foreign.library_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 consortiums

Type: many_to_many

Composing rels: L</consortium_members_consortiums> -> consortium

=cut

__PACKAGE__->many_to_many("consortiums", "consortium_members_consortiums", "consortium");

=head2 libraries

Type: many_to_many

Composing rels: L</consortium_members_consortiums> -> library

=cut

__PACKAGE__->many_to_many("libraries", "consortium_members_consortiums", "library");

=head2 users

Type: many_to_many

Composing rels: L</user_libraries> -> user

=cut

__PACKAGE__->many_to_many("users", "user_libraries", "user");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-10-10 11:19:33
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:L32/+4GHNLiOG5ThxPA9cg

__PACKAGE__->add_columns(
  "piwik",
  { data_type => "integer", is_nullable => 0, size => 16 },
);

use Dancer::Plugin::DBIC;

# For some reason, library.consortiums (in TT) does not work, so here is a 
# workaround...
sub get_consortia {

    my $self = shift;
    my @memberships = resultset('ConsortiumMember')->find({ library_id => $self->id });
    my @consortia;
    foreach my $mem ( @memberships ) {
        my $consortium = resultset('Library')->find({ id => $mem->consortium_id });
        push @consortia, $consortium;
    }
    return @consortia;

}

1;
