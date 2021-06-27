use strict;
use warnings;
use List::Util qw[min max];


#my $seqdb = "human.protein.faa";
my $seqdb = "uniprot_sprot.fasta";


my $line= "";

print "hello";

print "ddd";

print "Loading the position information....\n";

my $pcount =0;
my $lstfile = "paaps.lst";
#$lstfile = $ARGV[1];
print $lstfile;


my @paaps = &LoadPAAPs($lstfile);

my @synlist = &LoadSynoyms($lstfile);



 
$pcount = scalar(@paaps);
print "There are ".$pcount." position informaiton\n";

my %rlt = ();
print "Reference consistency analysis....\n";

my $count=0;
my $seq = "";

my @refseq = ();
print "Loading the fasta sequences....\n";
my $filename = $seqdb;

@refseq= &ReadFastaFile($filename);
$count = scalar(@refseq);
print "There are ".$count." sequences.\n";

for(my $i=0; $i<$count; $i++)
{
	my $seqid = $refseq[$i][0];
	my $seq = $refseq[$i][1];
	my $title = $refseq[$i][2];


	##############fileter sequence
	my $filtered = 1;
	foreach my $syn (@synlist)
	{
		#print $syn."\n";
		if($title =~/ $syn /)
		{
			$filtered = 0;
		}
	}
	#print $filtered."\n";
	if($filtered > 0)
	{
		next;
	}	
	###########################

	#$rlt{$seqid} = &rscaAA($seq, @paaps);
	
	my %offsetrlt = &rscaAAOffset($seq, @paaps);
	
	foreach my $pos (keys(%offsetrlt))
	{
		$rlt{$seqid."@".$pos} = $offsetrlt{$pos};
	}
	print $i."  $title\n\n";
	#my $line = <>;
}

open(OUT, ">rsca.rlt");
my $count =0; 
foreach my $seqid (keys(%rlt))
{
	if($rlt{$seqid} > 3)
	{
		print OUT $seqid."\t".$rlt{$seqid}."\n";
		$count++;
	}
	
}


print "end";

return $count;

#######################################################
#protein sequence
#three word system
#single word system
sub rscaAAOffset()
{
	my ($aaseq, @paaps) = @_;
	
	my $pcount = scalar(@paaps);
	my @poslist = ();
	for(my $i=0; $i<$pcount; $i++)
	{
		$poslist[$i] = $paaps[$i][0];#position
	}
	
	my $minp = min(@poslist);
	my $maxp = max(@poslist);
	#we will trunct the sequence from the 5' side one by one untill length-max;
	my $offend = length($aaseq) - $maxp;
	
	my %rlt = ();
	for(my $j=0; $j< $offend; $j++)
	{
		my $subseq = substr($aaseq, $j, length($aaseq)-$j);
		my $type = rscaAA($subseq, @paaps);
		if($type > 3)
		{
			$rlt{$j+1} = $type;
		}
	}
	return %rlt;
}

#######################################################
#protein sequence
#three word system
#single word system
sub rscaAA()
{
	my($sequence, @paapslist) = @_;
	
	my $map_Count = 0;
	my $p_count = scalar(@paapslist);
	
	for(my $j =0; $j< $p_count; $j++)
	{
	
		my $aa = $paapslist[$j][1];#amnio acid residue
		
		if(length($aa) == 3)
		{
			$aa = &tosingle($aa);
		}
		else
		{
			$aa = uc($aa);
		}
		
		my $pos = $paapslist[$j][0];#position
		
		my $sub = substr($sequence, $pos-1, 1);
        if ($sub eq $aa)
        {
            #print OUT $index."\t".$seqid."\n";
            #print $seq."\n".$sub." ".$pos." ".$aa."\n";#used to check th e find position and amino acid residue 
            $map_Count++;
            #print $seqid." ".$seqlist{$seqid};
        }
	}
	
	if($map_Count == $p_count)
	{
		return 4; #mapped
	}
	elsif($map_Count >= $p_count/2)
	{
		return 3; #most partial mapped
	}
	elsif ($map_Count < ($p_count/2) && $map_Count >0)
	{
		return 2; #LESS partial mapped
	}
	else
	{
		return 1;#unmapped
	}
}


sub tosingle()
{
    my ($thr) = @_;
	$thr = uc($thr);
	
    if($thr eq "PHE")
    {return "F"}
    elsif ($thr eq "LEU")
    {return "L"}
    elsif ($thr eq "ILE")
    {return "I"}
    elsif ($thr eq "MET")
    {return "M"}
    elsif ($thr eq "VAL")
    {return "V"}
    elsif ($thr eq "SER")
    {return "S"}
    elsif ($thr eq "PRO")
    {return "P"}
    elsif ($thr eq "THR")
    {return "T"}
    elsif ($thr eq "ALA")
    {return "A"}
    elsif ($thr eq "TRP")
    {return "W"}
    elsif ($thr eq "TYR")
    {return "Y"}
    elsif ($thr eq "HIS")
    {return "G"}
    elsif ($thr eq "ASN")
    {return "N"}
    elsif ($thr eq "LYS")
    {return "K"}
    elsif ($thr eq "ASP")
    {return "D"}
    elsif ($thr eq "GLU")
    {return "E"}
    elsif ($thr eq "CYS")
    {return "C"}
    elsif ($thr eq "TRP")
    {return "W"}
    elsif ($thr eq "ARG")
    {return "R"}
    elsif ($thr eq "GLY")
    {return "G"}
    else
    { return "X"}
 }
 
 sub ReadFastaFile()
 {
	my ( $infile) = @_;
	my @fastaseq = ();
	print $infile;
	unless(open(FASTA,$infile))
	{
		die ("open file $infile erro 200905061648");
	}
	
	my $size = 0;
	
	while($line=<FASTA>)
	{
		chomp($line);
		if($line=~/^>/)
		{
			my @field = split(/\|/, $line);
			if($infile=~/uniprot/i)
			{
				$fastaseq[$size][0] = $field[1];#seqid
				$fastaseq[$size][2] = $line;   #seq title
			}
			else
			{
				$fastaseq[$size][0] = $field[3];#seqid
				$fastaseq[$size][2] = $line;    #seq title
			}
 
			if ($size >0)
			{
				$fastaseq[$size-1][1] = $seq;#sequence
				$seq = "";
			}

			$size++;   
		}
		else
		{
			$line=~s/ //g;
			$seq .= $line;
		}
	}
	close(FASTA);
	$fastaseq[$size-1][1] = $seq;
	
	return @fastaseq;
 }

 sub LoadPAAPs()
 {
	my ($infile,) = @_;
	
	#my %rlt = ();
	my @paaplist = ();
	my @synonyms = ();
	
	unless(open(PAAPS, $infile))
	{
		print("Could not open the file!!!");
		return -1;
	}
	
	my $line = "";
	my $count = 0;
	while($line=<PAAPS>)
	{
		chomp($line);
		if($line=~/^#/)
		{
			next;
		}
		
		my @field =split(/\t/, $line);
		#$paaplist[$count][0] = $field[0];#index
		#$paaplist[$count][1] = $field[4];#amimo acid residue
		#$paaplist[$count][2] = $field[5];#position
		#$paaplist[$count][3] = $field[1];#omim_id

		$paaplist[$count][0] = $field[0];#position
		$paaplist[$count][1] = $field[1];#amimo acid residue
		$count ++;   
	}
	close(PAAPS);
	
	return @paaplist;
}

sub LoadSynoyms()
{
	my ($infile,) = @_;
	
	my @synonyms = ();
	
	unless(open(PAAPS, $infile))
	{
		print("Could not open the file!!!");
		return -1;
	}
	
	my $line = "";
	my $count = 0;
	while($line=<PAAPS>)
	{
		chomp($line);
		if($line=~/^#syn\t(.*)/)
		{
			@synonyms = split(/\|/, $1);
		}
		$count ++;   
	}
	close(PAAPS);
 
	return @synonyms;
}

=head1 AUTHORS
	Zuofeng LI <zfli@scbit.org>

=head1 Copyright and license
Copyright by Zuofeng LI

=cut