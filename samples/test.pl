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

$b->freeze("data.json");

test($b, ["adventures", "sherlock", "holmes"]);
test($b, ["comedy", "masks"]);
test($b, ["hrothgar", "beowulf"]);

$b = Tiny::Bayes->new_from_file(file => "data.json");

test($b, ["adventures", "sherlock", "holmes"]);
test($b, ["comedy", "masks"]);
test($b, ["hrothgar", "beowulf"]);

unlink("data.json");
