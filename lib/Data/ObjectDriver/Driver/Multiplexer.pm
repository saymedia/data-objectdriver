# $Id$

package Data::ObjectDriver::Driver::Multiplexer;
use strict;
use warnings;

use base qw( Data::ObjectDriver Class::Accessor::Fast );

__PACKAGE__->mk_accessors(qw( on_search drivers ));

use Carp qw( croak );

sub init {
    my $driver = shift;
    $driver->SUPER::init(@_);
    my %param = @_;
    for my $key (qw( on_search drivers )) {
        $driver->$key( $param{$key} );
    }
    return $driver;
}

sub lookup {
    croak "lookup is not implemented in ", __PACKAGE__;
}

sub lookup_multi {
    croak "lookup_multi is not implemented in ", __PACKAGE__;
}

sub exists {
    croak "exists is not implemented in ", __PACKAGE__;
}

sub search {
    my $driver = shift;
    my($class, $terms, $args) = @_;
    my $sub_driver = $driver->_find_sub_driver($terms)
        or croak "No matching sub-driver found";
    return $sub_driver->search(@_);
}

sub replace { shift->_exec_multiplexed('replace', @_) }
sub insert  { shift->_exec_multiplexed('insert',  @_) }

sub update {
    croak "update is not implemented in ", __PACKAGE__;
}

sub remove {
    my $driver = shift;
    my(@stuff) = @_;
    if (ref $stuff[0]) {
        croak "Object-based remove is not implemented in ", __PACKAGE__;
    } else {
        my $removed = 0;
        for my $key (keys %{ $stuff[1] }) {
            my $sub_driver = $driver->on_search->{$key} or next;
            $removed += $sub_driver->remove(@stuff);
        }
        return $removed;
    }
}

sub _find_sub_driver {
    my $driver = shift;
    my($terms) = @_;
    for my $key (keys %$terms) {
        if (my $sub_driver = $driver->on_search->{$key}) {
            return $sub_driver;
        }
    }
}

sub _exec_multiplexed {
    my $driver = shift;
    my($meth, @args) = @_;
    for my $sub_driver (@{ $driver->drivers }) {
        $sub_driver->$meth(@args);
    }
}

1;
__END__

=head1 NAME

Data::ObjectDriver::Driver::Multiplexer - Multiplex multiple partitioned drivers

=head1 SYNOPSIS

    package MappingTable;

    use Foo;
    use Bar;

    my $foo_driver = Foo->driver;
    my $bar_driver = Bar->driver;

    __PACKAGE__->install_properties({
        columns => [ qw( foo_id bar_id value ) ],

        driver => Data::ObjectDriver::Driver::Multiplexer->new(
            on_search => {
                foo_id => $foo_driver,
                bar_id => $bar_driver,
            },

            drivers => [ $foo_driver, $bar_driver ],
        ),
    });

=head1 DESCRIPTION

I<Data::ObjectDriver::Driver::Multiplexer> associates a set of drivers to
a particular class. In practice, this means that all INSERTs and DELETEs
are propagated to all associated drivers (for example, all associated
databases or tables in a database), and that SELECTs are sent to the
appropriate multiplexed driver, based on partitioning criteria.

Note that this driver has the following limitations currently:

=over 4

=item 1. It only supports I<search>, I<replace>, I<insert>, and I<remove>.

=item 2. It doesn't support objects with primary keys.

=item 3. It's very experimental.

=back

=cut