use strict;
use warnings;
use List::Util qw[min max sum];

do "LoosPatternMatch.pl";

unless(open(OMIM, "av_text.txt"))
{
	die("open file erro!");
}

my $line = "";
my $count = 0;
open (OUT, ">report.txt");
open (AVTEXTRST, ">avrst.txt");
print OUT "index\tCompound\tPAAP\tSingleNTdel\tSingleNTTransion\n";

open(EXCLUDED, ">excluded.txt");

while($line=<OMIM>)
{
	my @EvlRlt = ();

	chomp($line);
	my $avtext = "";


	if($line=~/(.*?)\t(.*?)\t(.*?),(.*)/)
	{
		my $linehead = $1."-".$2."\t";
		print OUT $linehead;
		
		##preprocessing
		$avtext = $4;
		
		#trim two side space
		$avtext =~ s/^\s+//;
		$avtext =~ s/\s+$//;
		###REPLACE FULL TO ABBREVIATION
		$avtext=~s/deletion/DEL/gi;
		$avtext=~s/insertion/INS/gi;
		
		####
		$avtext=~s/^(3|5)-PRIME UTR//;
		$avtext=~s/(3|5)-PRIME UTR$//;
		
		if($avtext eq "")
		{
			next;
		}

		
		#pattern recognition
		@EvlRlt = &StrictPatternMatcher($avtext);
	}
	else
	{
		next;
	}
	
	#filteration
	if(sum(@EvlRlt) <1)
	{
		if($avtext=~/[0-9]/)
		{
			my @numbers = ();
			my $line = $avtext;
			
			while($line=~/(\d+)(\.\d+|\,\d+|\d+|)/)
			{
				my $match = $&;
				push(@numbers, $match);#export match results
				$line =~s/\Q$match\E//;
			}
			
			my $size = scalar(@numbers);
			
			
			my $filtered = -1;
			if($avtext =~/\d+-(BP|KB|MB) /i || $avtext=~/(\d+|)(-|)(EX|IVS|DUP)(\d+|)/i)
			{
				#200-KB DEL
				#
				my $match = $&;
				
				if($size == 1)
				{
					$filtered = 1;
					print EXCLUDED $avtext." \t have $size numbers No Enough information\n";
				}
				elsif($size ==2)
				{
					my $line = $avtext;
					$line=~s/$match//;
					
					if($line=~/(\d+|)(-|)(EX|IVS|DUP)(\d+|)/i)
					{
						$filtered = 1;
						print EXCLUDED $avtext." \t have $size numbers No Enough information\n";
					}
				}
			}
			
			if($filtered < 0)
			{
				my @rlt = &LoosPatternMatcher_ex($avtext);
		
				if(sum(@rlt) == 0)
				{
				
					print EXCLUDED $avtext."\n";
				}
				else
				{
					print AVTEXTRST $avtext." \t have $size numbers \n";
				}
			}
		}
		else
		{
			print EXCLUDED $avtext."\t\t No Enough Information\n";
		}
	}
	foreach my $value (@EvlRlt)
	{
		print OUT $value."\t";
	}
	print OUT "\n";
}

sub StrictPatternMatcher()
{
	my ($avtext) = @_;
	
	$avtext =~ s/^\s+//;
	$avtext =~ s/\s+$//;
		
	if($avtext =~ s/,$// || $avtext =~ s/^,//)
	{
		$avtext =~ s/^\s+//;
		$avtext =~ s/\s+$//;
	}
	my @EvlRlt__ = ();
	my $MatchStrategy = 1;
	
	push(@EvlRlt__, &IsDouble($avtext));

	push(@EvlRlt__, &IsSinglePaaps($avtext));
	
	push(@EvlRlt__, &IsNmerNTDeletion($avtext));

	push(@EvlRlt__, &IsSingleTransition($avtext));
	
	push(@EvlRlt__, &IsNmerInsertion($avtext));

	push(@EvlRlt__, &IsTensNmerInsertion($avtext));

	push(@EvlRlt__, &IsdbSNPAccNumber($avtext));
	
	push(@EvlRlt__, &IsTensNmerDeletion($avtext));

	push(@EvlRlt__, &IsNmerDuplication($avtext));

	push(@EvlRlt__, &IsTensNmerDuplication($avtext));

	push(@EvlRlt__, &IsIntronTransition($avtext));
	
	push(@EvlRlt__, &IsSpliceDonorSite($avtext));	
	
	push(@EvlRlt__, &IsSpliceReceptorSite($avtext));
	
	push(@EvlRlt__, &IsAAPlusNTDetail($avtext));
	
	push(@EvlRlt__, &SingleExonDeletion($avtext));
	
	push(@EvlRlt__, &IsCondonDeletion($avtext));
	
	push(@EvlRlt__, &IsCondonInsertion($avtext));
	
	push(@EvlRlt__, &InitialCodonMutation($avtext));
	
	push(@EvlRlt__, &IsFrameshift($avtext));
	
	push(@EvlRlt__, &IsIndelToTerminate($avtext));
	
	push(@EvlRlt__, &IsTerminalInfo($avtext));
	
	push(@EvlRlt__, &IsExonDeletion($avtext));
	
	push(@EvlRlt__, &IsNmerTransition($avtext ,$MatchStrategy));
	
	push(@EvlRlt__, &IsNmerNTIndelInCodon($avtext));
	
	return @EvlRlt__;
}

sub IsDouble()
{
	my ($desp) = @_;
	if($desp=~/ and /i)
	{
		#print AVTEXTRST $desp."\n";
		my @rlt = &LoosPatternMatcher_ex($desp);
		
		if(sum(@rlt) == 0)
		{
			#print $desp."\t";
			#print "there ar ".sum(@rlt)." pattern!\n";
			print EXCLUDED $desp."\n";
		}
		
		return 1;
	}
	else
	{
		return 0;
	}
}
#1
sub IsSinglePaaps()
{
	my($desp) = @_;
	my $reg = "";
	#print $desp;
	#codon del is added here.
	#PHE234DEL
	if($desp=~/^(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter)\d+(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter|del)$/i)
	{
		#VAL285ILE
		#print $desp."\n";
		return 1;
	}
	else
	{
		return 0;
	}
}

#2
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
	elsif($desp=~/^(\d+)([A|C|G|T]{1,10})\s+DEL$/)
	{
		#2141CT DEL
		return 1;
	}
	else
	{
		return 0;
	}
}
#3
sub IsTensNmerDeletion()
{
	my ($desp) = @_;
	#24-BP DEL, NT10814
	if($desp=~/^\d+-BP DEL,\s+NT\d+$/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

#4
sub IsSingleTransition()
{
	my ($desp) = @_;
	if($desp=~/^(\+|\-|)(\d+)(A|C|G|T)-(A|C|G|T)$/)
	{
		#-1377G-A
		return 1;
	}
	elsif($desp=~/^\d+(A|C|G|T)-(A|C|G|T),\s+[+-](\d+)$/)
	{
		#810G-A, +1
		#print $desp."\n";
		return 1;
	}
	else
	{
		return 0;
	}
}
#5
sub IsNmerTransition()
{
	my ($desp, $strictMatch) = @_;
	#90CCG-GGT
	#22510C-G
	my $pattern = '(\d+)([A|C|G|T]{1,10})-([A|C|G|T]{1,10})';
	
	if($strictMatch > 0)
	{
		$pattern ="\^$pattern\$";
	}
	if($desp=~/$pattern/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

#6
sub IsNmerInsertion()
{
	my ($desp) = @_;

	if($desp=~/^\d+-BP\s+INS,(\s+|\s+-)(\d+)([A|C|T|G]{1,10})$/)
	{
		#1-BP INS, 84G
		return 1;
	}
	else
	{
		return 0;
	}
}

#7
sub IsTensNmerInsertion()
{
	my ($desp) = @_;

	#11-BP INS, NT1060
	if($desp=~/^\d+-BP\s+INS,\s+NT(\d+)$/)
	{
		return 1;
	}
	elsif($desp=~/^(\d+)([A|C|G|T]{1,10})\s+INS$/)
	{
		#1033G INS
		return 1;
	}
	elsE
	{
		return 0;
	}
}

#8
sub IsdbSNPAccNumber()
{
	my ($desp) = @_;

	if($desp=~/^rs\d+$/)
	{
		return 1;
	}
	if($desp=~/^\{dbSNP (rs\d+)\}$/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

#9
sub IsNmerDuplication()
{
	my ($desp) = @_;

	if($desp=~/^\d+-BP\s+DUP,(\s+|\s+-)(\d+)([A|C|T|G]{1,10})$/)
	{
		#1-BP DUP, 935T
		#4-BP DUP, 1124TGCC
		#print $desp."\n";
		return 1;
	}
	else
	{
		return 0;
	}
}

#10
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

#11
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

#12
sub IsSpliceDonorSite()
{
	my($desp) = @_;
	
	if($desp=~/^IVS\d+DS, ([A|C|G|T])-([A|C|G|T]), ([+|-])(\d+)$/)
	{#IVS5DS, G-A, +1
		return 1;
	}
	else
	{
		return 0;
	}
}

#13
#IVS28AS, G-A, -1
#IVS28AS, G-A, -1
sub IsSpliceReceptorSite()
{
	my ($desp) = @_;
	
	if($desp=~/^IVS(\d+)AS,\s+([A|C|G|T])-([A|C|G|T]),\s+([-|+])(\d+)$/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

#14
#MET680ILE, 2040G-C
#316G-A, GLY106ARG
sub IsAAPlusNTDetail()
{
	my ($desp) = @_;
	
	if($desp=~/^(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro)(\d+)(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter),\s+(\d+)([A|C|G|T])-([A|C|G|T])$/i)
	{
		return 1;
	}
	elsif($desp=~/^\d+[A|C|G|T]-[A|C|G|T],\s+(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro)\d+(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter)$/i)
	{
		return 1;
	}
	elsif($desp=~/^(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro)-(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter),\s+(\d+)([A|C|G|T])-([A|C|G|T])$/i)
	{
		#TYR-TER, 1500T-G
		return 1;
	}
	else
	{
		return 0;
	}	
}

#15
sub SingleExonDeletion()
{
	my ($desp) = @_;
	
	if($desp=~/^EX(\d+)DEL$/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

#16
sub IsCondonDeletion()
{
	my ($desp) = @_;
	#A
	if($desp=~/^(\d+)-BP DEL, CODON (\d+)$/i)
	{
		#1-BP DEL, CODON 257
		return 1;
	}#B
	elsif($desp=~/^(\d+)-BP DEL, CODONS (\d+)-(\d+)$/)
	{
		#2-BP DEL, CODONS 209-210
		return 1;
	}#C
	elsif($desp=~/^3-BP DEL, (gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter)(\d+)(DEL|)$/i)
	{
		#3-BP DEL, THR1302DEL
		print "-----".$desp."\n";
		return 1;
		
	}#D
	elsif($desp=~/^(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter)\d+\s+DEL$/i)
	{
		#ASN394 DEL
		return 1;
	}
	else
	{
		return 0;
	}
}

#17
sub IsCondonInsertion()
{
	my ($desp) = @_;
	
	if($desp=~/^(\d+)-BP INS, CODON (\d+)$/i)
	{
		
		#4-BP INS, CODON 95
		return 1;
	}
	elsif($desp=~/^(\d+)-BP INS, CODONS (\d+)-(\d+)$/)
	{
		#1-BP INS, CODONS 71-72
		return 1;
	}
	else
	{
		return 0;
	}
}

#18
sub InitialCodonMutation()
{
	my ($desp) = @_;
	
	if($desp=~/^METi(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter)$/i)
	{
		#METiGLY
		return 1;
	}
	else
	{
		return 0;
	}
}

#19
sub IsFrameshift()
{
	my ($desp) = @_;

	if($desp=~/^(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter)\d+(\s+FS|FS)$/i)
	{
		
		#CYS1190FS
		#print $desp."\n";
		return 1;
	}
	else
	{
		return 0;
	}
}

#20
sub IsIndelToTerminate()
{
	my ($desp) = @_;

	if($desp=~/^(\d+)-BP\s+(DEL|INS),\s+FS(\d+)TER$/)
	{
		#2-BP DEL, FS51TER
		#print $desp."\n";
		return 1;
	}
	else
	{
		return 0;
	}
}


#21
sub IsTerminalInfo()
{
	my ($desp) = @_;
	
	if($desp=~/^ter-(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro)$/i)
	{
		#print $desp."\n";
		return 1;
	}
	else
	{
		return 0;
	}
}

#22
sub IsExonDeletion()
{
	my($desp) = @_;
	#A 
	if($desp=~/^EX\d+\s+DEL$/)#15 OVERLAP
	{
		print  $desp."\n";
		return 1;
	}
	elsif($desp=~/^EX(\d+)-EX(\d+)\s+DEL$/i)
	{
		#EX3-EX12 DEL
		print  $desp."\n";
		return 1;
	}
	elsif($desp=~/^EX(\d+)-(\d+)DEL$/)
	{
		#EX4-6DEL
		print  $desp."\n";
		return 1;
	}
	else
	{
		return 0;
	}
}
#2
sub IsNmerNTIndelInCodon()
{
	my ($desp) = @_;
	
	if($desp=~/^\d+-BP (INS|DEL), CODON \d+, [A|C|G|T]{1,10}$/)
	{
		return 1;
	}
	else
	{
		return 0;
	}

	#4-BP DEL, CODON 675, AGTT
}

