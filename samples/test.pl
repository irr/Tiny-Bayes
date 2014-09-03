use 5.014;

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
    say "\nTesting $obj ( @{$words} )...";
    say Dump($b->query($words));
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