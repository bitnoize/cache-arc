# Adaptive Replacement Cache in pure Perl

package Cache::ARC::List;

use strict;
use warnings;

sub new {
  my ( $class ) = @_;

  my $self = bless {
    first => undef,
    last  => undef,
    count => 0
  }, $class;

  return $self;
}

package Cache::ARC::Item;

use strict;
use warnings;

use Scalar::Util qw/refaddr/;

sub new {
  my ( $class, $key, $value ) = @_;

  my $self = bless {
    next => undef,
    prev => undef,
    list => undef,

    key   => $key,
    value => $value,
  }, $class;

  return $self;
}

sub remove {
  my ( $self ) = @_;

  return unless $self->{list};

  $self->{list}{count}--;

  $self->{prev}{next} = $self->{next} if $self->{prev};
  $self->{next}{prev} = $self->{prev} if $self->{next};

  $self->{list}{first} = $self->{next}
    if refaddr $self->{list}{first} == refaddr $self;

  $self->{list}{last} = $self->{prev}
    if refaddr $self->{list}{last} == refaddr $self;

  $self->{prev} = undef;
  $self->{next} = undef;
  $self->{list} = undef;
}

sub append {
  my ( $self, $list ) = @_;

  $self->remove;

  if ( $list->{last} ) {
    $self->{prev} = $list->{last};
    $self->{prev}{next} = $self;
  }

  $self->{list} = $list;
  $self->{list}{count}++;

  $list->{last} = $self;
  $list->{first} ||= $self;
}

sub prepend {
  my ( $self, $list ) = @_;

  $self->remove;

  if ( $list->{first} ) {
    $self->{next} = $list->{first};
    $self->{next}{prev} = $self;
  }

  $self->{list} = $list;
  $self->{list}{count}++;

  $list->{first} = $self;
  $list->{last} ||= $self;
}

package Cache::ARC;

use strict;
use warnings;

use Scalar::Util qw/refaddr/;
use List::Util qw/reduce min max/;

use constant DEBUG => $ENV{CACHE_ARC_DEBUG} || 0;

our $VERSION = '0.01';

sub new {
  my ( $class, %args ) = @_;

  return bless {
    size  => $args{size} || 1024,
    cache => { },
    p     => 0,
    map { $_ => Cache::ARC::List->new } qw/t1 b1 t2 b2/
  };
}

sub request {
  my ( $self, $item ) = @_;

  my $switch = sub {
    $item->{list} and refaddr $item->{list} == refaddr $_[0] ? 1 : 0;
  };

  if ( $switch->( $self->{t1} ) ) {
    warn "-- Case I    => $item->{key}" if DEBUG;

    $item->prepend( $self->{t2} );
  }

  elsif ( $switch->( $self->{t2} ) ) {
    warn "-- Case I    => $item->{key}" if DEBUG;

    $item->prepend( $self->{t2} );
  }

  elsif ( $switch->( $self->{b1} ) ) {
    warn "-- Case II   => $item->{key}" if DEBUG;

    my $delta = $self->{b1}->{count} >= $self->{b2}->{count} ?
      1 : $self->{b2}->{count} / $self->{b1}->{count};

    $self->{p} = min( $self->{p} + int $delta, $self->{size} );

    $self->replace( $item );
    $item->prepend( $self->{t2} );
  }

  elsif ( $switch->( $self->{b2} ) ) {
    warn "-- Case III  => $item->{key}" if DEBUG;

    my $delta = $self->{b2}->{count} >= $self->{b1}->{count} ?
      1 : $self->{b1}->{count} / $self->{b2}->{count};

    $self->{p} = max( $self->{p} - int $delta, 0 );

    $self->replace( $item );
    $item->prepend( $self->{t2} );
  }

  else {
    if ( $self->{t1}{count} + $self->{b1}->{count} == $self->{size} ) {
      warn "-- Case IV A => $item->{key}" if DEBUG;

      if ( $self->{t1}{count} < $self->{size} ) {
        if ( $self->{b1}{last} ) {
          delete $self->{cache}{ $self->{b1}{last}->{key} };
          $self->{b1}{last}->remove;
        }

        $self->replace( $item );
      }

      else {
        if ( $self->{t1}{last} ) {
          delete $self->{cache}{ $self->{t1}{last}->{key} };
          $self->{t1}{last}->remove;
        }
      }
    }

    else {
      warn "-- Case IV B => $item->{key}" if DEBUG;

      my $size = reduce { $a + $b }
        map { $self->{ $_ }{count} } qw/t1 t2 b1 b2/;

      if ( $size >= $self->{size} ) {
        if ( $size == $self->{size} * 2 ) {
          if ( $self->{b2}{last} ) {
            delete $self->{cache}{ $self->{b2}{last}->{key} };
            $self->{b2}{last}->remove;
          }
        }

        $self->replace( $item );
      }
    }

    $item->prepend( $self->{t1} );
  }

  return $item->{value};
}

sub replace {
  my ( $self, $item ) = @_;

  if (
    $self->{t1}{count} > 0 and (
      ( $self->{t1}{count} > $self->{p} ) or

      ( $item->{list} and refaddr $item->{list} == refaddr $self->{b2}
        and $self->{t1}{count} == $self->{p} )
    )
  ) {
    $self->{t1}{last}->{value} = undef;
    $self->{t1}{last}->prepend( $self->{b1} );
  }

  else {
    $self->{t2}{last}->{value} = undef;
    $self->{t2}{last}->prepend( $self->{b2} );
  }
}

sub get {
  my ( $self, $key ) = @_;

  my $item = $self->{cache}{ $key };
  return $self->request( $item ) if $item;

  return undef;
}

sub set {
  my ( $self, $key, $value ) = @_;

  my $item = $self->{cache}{ $key };

  unless ( $item ) {
    $item = Cache::ARC::Item->new( $key, $value );
    $self->{cache}{ $key } = $item; 
  }

  else {
    $item->{value} = $value;
  }

  return $self->request( $item );
}

sub remove {
  my ( $self, $key ) = @_;

  my $item = delete $self->{cache}{ $key };

  return undef unless $item;

  return $item->{value};
}

sub clear {
  my ( $self ) = @_;

  $self->{cache} = { };
}


1;
