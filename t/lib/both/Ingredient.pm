# $Id$

package Ingredient;
use strict;
use base qw( Data::ObjectDriver::BaseObject );

use Carp ();
use Cache::Memory;
use Data::ObjectDriver::Driver::Cache::Cache;
use Data::ObjectDriver::Driver::Partition;
use Data::ObjectDriver::Driver::DBI;

our %IDs;

__PACKAGE__->install_properties({
    columns => [ 'id', 'recipe_id', 'name', 'quantity' ],
    datasource => 'ingredients',
    primary_key => [ 'recipe_id', 'id' ],
    driver      => Data::ObjectDriver::Driver::Cache::Cache->new(
        cache => Cache::Memory->new,
        fallback => Data::ObjectDriver::Driver::Partition->new(
            get_driver   => \&get_driver,
            pk_generator => \&generate_pk,
        ),
    ),
});

sub get_driver {
    my($terms) = @_;
    my $recipe;
    if (ref($terms) eq 'HASH') {
        my $recipe_id = $terms->{recipe_id}
            or Carp::croak("recipe_id is required");
        $recipe = Recipe->driver->lookup('Recipe', $recipe_id);
    } elsif (ref($terms) eq 'ARRAY') {
        ## With a multiple-column primary key, the $id is an array ref, where
        ## the first column is the recipe_id.
        $recipe = Recipe->driver->lookup('Recipe', $terms->[0]);
    }
    Data::ObjectDriver::Driver::DBI->new(
        dsn      => 'dbi:SQLite:dbname=cluster' . $recipe->cluster_id . '.db',
        pk_generator => \&generate_pk,
    );
}

sub generate_pk {
    my($obj) = @_;
    $obj->id(++$IDs{$obj->recipe_id});
    1;
}

1;