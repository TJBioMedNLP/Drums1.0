$desp = "browngrass\nbluegrass";

open(REG, "reg.txt");

@reg = <REG>;

foreach my $pattern (@reg)
{
	print $pattern."\n";
	
	if($desp=~/^$pattern/)
	{	
		print $1;
	}
}


