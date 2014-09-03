package Tiny::Bayes;

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ('all' => [ qw() ]);
our @EXPORT_OK = ();
our @EXPORT = ();

our $VERSION = '0.01';

use JSON;

sub new {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    die "missing required classes" unless $args{classes};
    $self->{classes} = $args{classes};
    foreach (@{$self->{classes}}) {
        $self->{sets}->{$_} = { freqs => {}, total => 0 };
    }
    return $self;
}

sub new_from_file {
    my ($class, %args) = @_;
    my $self = bless {}, $class;
    die "missing required file" unless $args{file};
    $self->unfreeze($args{file});
    return $self;
}

sub learn {
    my ($self, $class, $words) = @_;
    my $data = $self->{sets}->{$class};

    foreach (@{$words}) {
        $data->{freqs}->{$_} += 1;
        $data->{total}++;
    } 

    return $self;  
}

sub query {
    my ($self, $words) = @_;
    my ($scores, $priors) = ({}, {});
    my $sum = 0;
    
    foreach (@{$self->{classes}}) {
        my $total = $self->{sets}->{$_}->{total};
        $priors->{$_} = $total;
        $sum += $total;
    }
    
    foreach (@{$self->{classes}}) {
        $priors->{$_} = $priors->{$_} / $sum;
    }
    
    $sum = 0;
    foreach (@{$self->{classes}}) {
        my $data = $self->{sets}->{$_};
        my $score = $priors->{$_};
        foreach (@{$words}) {
            my $freq = $data->{freqs}->{$_};
            $score = $score * (($freq) ? 
                ($freq / $data->{total}) : 0.00000000001);
        }
        $scores->{$_} = $score;
        $sum += $score;
    }

    foreach (@{$self->{classes}}) {
        $scores->{$_} = $scores->{$_} / $sum;
    }

    return $scores;
}

sub freeze {
    my ($self, $file) = @_;
    my $json = JSON->new->allow_nonref();
    my $data = $json->encode([$self->{classes}, $self->{sets}]); 
    open(my $out, '>:raw', $file) or die "Unable to open: $!";
    print $out $data;
    close($out);
    return $self;
}

sub unfreeze {
    my ($self, $file) = @_;
    my $size = -s $file;
    my $bin;
    open(my $in, '<:raw', $file) or die "Unable to open: $!";
    read($in, $bin, $size);
    close($in);
    my $json = JSON->new->allow_nonref();
    my $data = $json->decode($bin);
    $self->{classes} = @{$data}[0];
    $self->{sets} = @{$data}[1];
    return $self;
}

1;
__END__

=head1 NAME

Tiny::Bayes - Perl extension for naive bayesian classification

=head1 SYNOPSIS

    use 5.010001;

    use strict;
    use warnings;

    use Tiny::Bayes;
    use YAML;

    sub load {
        my $file = shift;
        my $contents =`cat $file` or die $!;
        return ($contents =~ /(\w+)/g);
    }

    sub test {
        my ($obj, $words) = @_;
        print "\nTesting $obj ( @{$words} )...\n";
        print Dump($b->query($words));
    }

    $b = Tiny::Bayes->new(classes => ["Doyle", "Dowson", "Beowulf"]);

    foreach ("Doyle", "Dowson", "Beowulf") {
        my @w = map { lc($_) } load("$_.txt");
        $b->learn($_, \@w);    
    }

    $b->freeze("f.bin");

    test($b, ["adventures", "sherlock", "holmes"]);
    test($b, ["comedy", "masks"]);
    test($b, ["hrothgar", "beowulf"]);

    $b = Tiny::Bayes->new_from_file(file => "f.bin");

    test($b, ["adventures", "sherlock", "holmes"]);
    test($b, ["comedy", "masks"]);
    test($b, ["hrothgar", "beowulf"]);

    unlink("f.bin");

=head1 DESCRIPTION

Perform naive Bayesian classification using an array of words per category.

=head1 SEE ALSO

Based upon:

=over

=item C<https://github.com/irr/bayesian>

=item C<https://github.com/irr/newlisp-labs/tree/master/bayes>

=back

=head1 AUTHOR

Ivan Ribeiro Rocha, E<lt>ivan.ribeiro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Ivan Ribeiro Rocha

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
