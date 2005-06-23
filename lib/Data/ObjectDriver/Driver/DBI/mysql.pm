# $Id$

package Data::ObjectDriver::Driver::DBI::mysql;
use strict;
use base qw( Data::ObjectDriver::Driver::DBI );

use Carp qw( croak );

sub fetch_id { $_[2]->{mysql_insertid} || $_[2]->{insertid} }

sub commit   { 1 }
sub rollback { 1 }

1;