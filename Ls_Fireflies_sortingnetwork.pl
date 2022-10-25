# Prints comparator orders for the sorting network used in Ls_Fireflies.1.glsl
# The module needs to be installed from CPAN first with:
#    cpan Algorithm::Networksort

use Algorithm::Networksort;
use Algorithm::Networksort::Best qw(:all);
 
my $inputs = 9;

# First the standard algorithm-generated one:
my $algorithm = "bosenelson";
my $nw = nwsrt(inputs => $inputs, algorithm => $algorithm);
print $nw->title(), "\n";
print $nw, "\n";
print $nw->graph_text(), "\n";
$nw->formats([ "COMPARESWAP(%d, %d)\n" ]);
print $nw->formatted();

# Then possible better ones discovered separately:
my @nwkeys = nw_best_names($inputs);
for my $name (@nwkeys)
{
    my $nw = nwsrt_best(name => $name);
    print $nw->title(), "\n", $nw->formatted(), "\n\n";
    print $nw->graph_text(), "\n";
    $nw->formats([ "COMPARESWAP(%d, %d)\n" ]);
    print $nw->formatted();
}
