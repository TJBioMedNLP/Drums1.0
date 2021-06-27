use Encode;

open(INFILE, "omim_sprotf_2009_Feb_10.csv");
open(OUT, ">omim_sprot.txt");

while($line= <INFILE>)
{
	chomp($line);
	$line.=",\n";
	print OUT encode("utf8", $line);
}
close(OUT);