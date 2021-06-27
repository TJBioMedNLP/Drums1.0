sub LoosPatternMatcher_ex()
{
	my ($avtext) = @_;
	
	$avtext =~ s/^\s+//;
	$avtext =~ s/\s+$//;
		
	if($avtext =~ s/,$//)
	{
		$avtext =~ s/^\s+//;
		$avtext =~ s/\s+$//;
	}
	my @EvlRlt__ = ();
	
	#push(@EvlRlt__, &IsDouble_ex($avtext));

	push(@EvlRlt__, &IsSinglePaaps_ex($avtext));
	
	push(@EvlRlt__, &IsNmerNTDeletion_ex($avtext));

	push(@EvlRlt__, &IsSingleTransition_ex($avtext));
	
	push(@EvlRlt__, &IsNmerInsertion_ex($avtext));

	push(@EvlRlt__, &IsTensNmerInsertion_ex($avtext));

	push(@EvlRlt__, &IsdbSNPAccNumber_ex($avtext));
	
	push(@EvlRlt__, &IsTensNmerDeletion_ex($avtext));

	push(@EvlRlt__, &IsNmerDuplication_ex($avtext));

	push(@EvlRlt__, &IsTensNmerDuplication_ex($avtext));

	push(@EvlRlt__, &IsIntronTransition_ex($avtext));
	
	push(@EvlRlt__, &IsSpliceDonorSite_ex($avtext));	
	
	push(@EvlRlt__, &IsSpliceReceptorSite_ex($avtext));
	
	push(@EvlRlt__, &IsAAPlusNTDetail_ex($avtext));
	
	push(@EvlRlt__, &SingleExonDeletion_ex($avtext));
	
	push(@EvlRlt__, &CondonDelInsertion_ex($avtext));
	
	push(@EvlRlt__, &InitialCodonMutation_ex($avtext));
	
	push(@EvlRlt__, &IsFrameshift_ex($avtext));
	
	push(@EvlRlt__, &IsTerminalInfo_ex($avtext));
	
	push(@EvlRlt__, &IsExonDeletion_ex($avtext));
	push(@EvlRlt__, &NmerTransition_ex($avtext));
	
	#########################
	push(@EvlRlt__, &IsAminoAcidPositionPattern($avtext));
	
	return @EvlRlt__;
}

sub IsSinglePaaps_ex()
{
	my($desp) = @_;
	my $reg = "";
	#print $desp;
	#codon del is added here.
	#PHE234DEL
	if($desp=~/(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter)\d+(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter|del)/i)
	{
		#print $desp."\n";
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsNmerNTDeletion_ex()
{
	my ($desp) = @_;
	#1-BP DEL, 1030C
	#2-BP DEL, 424TT
	#2-BP DEL, 793TG
	if($desp=~/\d+-BP\s+DEL,(\s+|\s+-)(\d+)([A|C|T|G]{1,10})/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsTensNmerDeletion_ex()
{
	my ($desp) = @_;
	#24-BP DEL, NT10814
	if($desp=~/\d+-BP DEL,\s+NT\d+/)
	{
		return 1;
	}
	elsif($desp=~/(\d+)([A|C|G|T]{1,10})\s+DEL/)
	{
		#2141CT DEL
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsSingleTransition_ex()
{
	my ($desp) = @_;
	if($desp=~/(\+|\-|)(\d+)(A|C|G|T)-(A|C|G|T)/)
	{
		#-1377G-A
		return 1;
	}
	elsif($desp=~/\d+(A|C|G|T)-(A|C|G|T),\s+[+-](\d+)/)
	{
		#810G-A, +1
		return 1;
	}
	else
	{
		return 0;
	}
}

sub NmerTransition_ex()
{
	my ($desp) = @_;
	if($desp=~/(\d+)([A|C|G|T]{1,10})-([A|C|G|T]{1,10})/)
	{
		#3245ATC-TGAT
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsNmerInsertion_ex()
{
	my ($desp) = @_;

	if($desp=~/\d+-BP\s+INS,(\s+|\s+-)(\d+)([A|C|T|G]{1,10})/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsTensNmerInsertion_ex()
{
	my ($desp) = @_;

	#11-BP INS, NT1060
	if($desp=~/\d+-BP\s+INS,\s+NT(\d+)/)
	{
		return 1;
	}
	elsif($desp=~/(\d+)([A|C|G|T]{1,10})\s+INS/)
	{
		#1033G INS
		return 1;
	}
	elsE
	{
		return 0;
	}
}


sub IsdbSNPAccNumber_ex()
{
	my ($desp) = @_;

	if($desp=~/rs\d+/)
	{
		return 1;
	}
	if($desp=~/\{dbSNP (rs\d+)\}/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsNmerDuplication_ex()
{
	my ($desp) = @_;

	if($desp=~/\d+-BP\s+DUP,(\s+|\s+-)(\d+)([A|C|T|G]{1,10})/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsTensNmerDuplication_ex()
{
	my ($desp) = @_;

	#17-BP DUP, NT117
	if($desp=~/\d+-BP\s+DUP,\s+NT(\d+)/i)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsIntronTransition_ex()
{
	my ($desp) = @_;
	
	#IVS9, G-A, +1
	if($desp=~/IVS\d+,\s+(A|C|T|G)-(A|C|T|G),\s+(\+|-)\d+/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

#IVS5DS, G-A, +1
sub IsSpliceDonorSite_ex()
{
	my($desp) = @_;
	
	if($desp=~/IVS\d+DS, ([A|C|G|T])-([A|C|G|T]), ([+|-])(\d+)/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

#IVS28AS, G-A, -1
#IVS28AS, G-A, -1
sub IsSpliceReceptorSite_ex()
{
	my ($desp) = @_;
	
	if($desp=~/IVS(\d+)AS,\s+([A|C|G|T])-([A|C|G|T]),\s+([-|+])(\d+)/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

#MET680ILE, 2040G-C
#316G-A, GLY106ARG
sub IsAAPlusNTDetail_ex()
{
	my ($desp) = @_;
	
	if($desp=~/(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro)(\d+)(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter),\s+(\d+)([A|C|G|T])-([A|C|G|T])/i)
	{
		return 1;
	}
	elsif($desp=~/\d+[A|C|G|T]-[A|C|G|T],\s+(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro)\d+(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter)/i)
	{
		return 1;
	}
	elsif($desp=~/(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro)-(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter),\s+(\d+)([A|C|G|T])-([A|C|G|T])/i)
	{
		#TYR-TER, 1500T-G
		return 1;
	}
	else
	{
		return 0;
	}	
}

sub SingleExonDeletion_ex()
{
	my ($desp) = @_;
	
	if($desp=~/EX(\d+)DEL/)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub CondonDelInsertion_ex()
{
	my ($desp) = @_;
	
	if($desp=~/(\d+)-BP (DEL|INS), CODON (\d+)/i)
	{
		#1-BP DEL, CODON 257
		return 1;
	}
	elsif($desp=~/(\d+)-BP (INS|DEL), CODONS (\d+)-(\d+)/)
	{
		#2-BP DEL, CODONS 209-210
		return 1;
	}
	else
	{
		return 0;
	}
}

sub InitialCodonMutation_ex()
{
	my ($desp) = @_;
	
	if($desp=~/METi(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter)/i)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsFrameshift_ex()
{
	my ($desp) = @_;

	if($desp=~/(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter)\d+(\s+FS|FS)/i)
	{
		
		#CYS1190FS
		return 1;
	}
	elsif($desp=~/(\d+)-BP\s+(DEL|INS),\s+FS(\d+)TER/)
	{
		#2-BP DEL, FS51TER
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsTerminalInfo_ex()
{
	my ($desp) = @_;
	
	if($desp=~/ter-(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro)/i)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsExonDeletion_ex()
{
	my($desp) = @_;
	
	if($desp=~/EX\d+\s+DEL/)
	{
		return 1;
	}
	elsif($desp=~/EX(\d+)-EX(\d+)\s+DEL/i)
	{
		#EX3-EX12 DEL
		return 1;
	}
	elsif($desp=~/EX(\d+)-(\d+)DEL/)
	{
		#EX4-6DEL
		return 1;
	}
	else
	{
		return 0;
	}
}

sub IsAminoAcidPositionPattern()
{
	my ($desp) = @_;
	
	if($desp=~/(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter)\d+/i)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}