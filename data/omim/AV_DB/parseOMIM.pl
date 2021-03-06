use strict;
use warnings;
use List::Util qw[min max sum];

unless(open(OMIM, "av_text.txt"))
{
	die("open file erro!");
}

my $line = "";
my $count = 0;
open (OUT, ">report.txt");
open (AVTEXTRST, ">avrst.txt");
print OUT "index\tCompound\tPAAP\tSingleNTdel\tSingleNTTransion\n";

while($line=<OMIM>)
{
	my @EvlRlt = ();

	chomp($line);
	my $avtext = "";


	if($line=~/(.*?)\t(.*?)\t(.*?),(.*)/)
	{

		
		$avtext = $4;
		if($avtext eq "")
		{
			next;
		}
		my $linehead = $1."-".$2."\t";
		



		if($avtext!~/[0-9]/)
		{
			print AVTEXTRST $avtext."\n";
			next;
		}
		
		print OUT $linehead;
		$avtext =~ s/^\s+//;
		$avtext =~ s/\s+$//;
		

		push(@EvlRlt, &IsDouble($avtext));

		push(@EvlRlt, &IsSinglePaaps($avtext));
		
		push(@EvlRlt, &IsNmerNTDeletion($avtext));

		push(@EvlRlt, &IsSingleTransition($avtext));
		
		push(@EvlRlt, &IsNmerInsertion($avtext));

		push(@EvlRlt, &IsTensNmerInsertion($avtext));

		push(@EvlRlt, &IsdbSNPAccNumber($avtext));
		
		push(@EvlRlt, &IsTensNmerDeletion($avtext));

		push(@EvlRlt, &IsNmerDuplication($avtext));

		push(@EvlRlt, &IsTensNmerDuplication($avtext));

		push(@EvlRlt, &IsIntronTransition($avtext));
		
	}
	else
	{
		next;
	}	
	if(sum(@EvlRlt) <1)
	{
		print AVTEXTRST $avtext."\n";
	}
	foreach my $value (@EvlRlt)
	{
		print OUT $value."\t";

		
		
	}
	print OUT "\n";
}



sub IsDouble()
{
	my ($desp) = @_;
	if($desp=~/ and /i)
	{
		print $desp."\n";
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsSinglePaaps()
{
	my($desp) = @_;
	my $reg = "";
	#print $desp;
	#codon del is added here.
	#PHE234DEL
	if($desp=~/^(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro)\d+(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter|del)$/i)
	{
		#print $desp."\n";
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsNmerNTDeletion()
{
	my ($desp) = @_;
	#1-BP DEL, 1030C
	#2-BP DEL, 424TT
	#2-BP DEL, 793TG
	if($desp=~/^\d+-BP\s+DEL,(\s+|\s+-)(\d+)([A|C|T|G]{1,10})$/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsTensNmerDeletion()
{
	my ($desp) = @_;
	#24-BP DEL, NT10814
	if($desp=~/\d+-BP DEL, NT\d+$/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsSingleTransition()
{
	my ($desp) = @_;
	#1-BP DEL, 381C
	if($desp=~/^(-\d+|\d+)(A|C|G|T)-(A|C|G|T)$/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsNmerInsertion()
{
	my ($desp) = @_;

	if($desp=~/^\d+-BP\s+INS,(\s+|\s+-)(\d+)([A|C|T|G]{1,10})$/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsTensNmerInsertion()
{
	my ($desp) = @_;

	#11-BP INS, NT1060
	if($desp=~/^\d+-BP\s+INS,\s+NT(\d+)$/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}


sub IsdbSNPAccNumber()
{
	my ($desp) = @_;

	if($desp=~/^rs\d+$/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsNmerDuplication()
{
	my ($desp) = @_;

	if($desp=~/^\d+-BP\s+DUP,(\s+|\s+-)(\d+)([A|C|T|G]{1,10})$/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsTensNmerDuplication()
{
	my ($desp) = @_;

	#17-BP DUP, NT117
	if($desp=~/^\d+-BP\s+DUP,\s+NT(\d+)$/i)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsIntronTransition()
{
	my ($desp) = @_;
	
	#IVS9, G-A, +1
	if($desp=~/^IVS\d+,\s+(A|C|T|G)-(A|C|T|G),\s+(\+|-)\d+$/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}