use strict;
use warnings;
use List::Util qw[min max];
#use MIME::Lite;

do "/home/zuofeng/Desktop/link to projects/BioCreativeii5/workspace/functlist.pl";


#my $seqfile = "uniprot_sprot.fasta";
my $seqfile = "human.protein.faa";

my @seqs = &ReadFastaFile($seqfile);
my $range = scalar(@seqs);

#parameters
my $mutantNumber = 10;
my $repeatNumber = 5;
my $miniDist = 0;
unless(open(REPORT, ">simulation.txt"))
{
	die("could not create the file!");
}

print REPORT "mutant_dist\tmutant_size\tmax_number\n";

for(my $miniDist =0; $miniDist<= 5; $miniDist++)
{
for(my $size =1; $size <= $mutantNumber; $size++)
{
	my $curseqid = "";
	my @rlts = ();
	for(my $r =0; $r< $repeatNumber; $r++)
	{
		my $resample = 1;
		my $seq = "";
		my $length = "";
		while($resample > 0)
		{
			my $id = int(rand($range));#random get a sequence;
			$curseqid = $id;
			$seq = $seqs[$id][1];
			$resample = -1;

			#print $seq."\n";
			$length = length($seq);
			my $minilength = ($miniDist + 1)*$mutantNumber;
			if($length < $minilength)
			{
				$resample = 1;
				print "reapeat sample sequence";
			}
			
		}
				
		my %paaps = ();
		for(my $j=0; $j<$size; $j++)#random get a goup of position
		{
			my $pos = 0;
			my $aa = "";
			my $resample = 1;
			while($resample > 0)
			{
				$pos = int(rand($length));#random get the sequence
				$pos +=1;
				$aa = substr($seq,$pos-1,1);
				$resample = -1;
				foreach my $p (keys(%paaps))
				{
					if(abs($p-$pos) < $miniDist)
					{
						$resample = 1;
						print "reapeat sample POSTION";
					}
				}
				
			}
			$paaps{$pos} = $aa;
		}
		unless(open(OUT, ">paaps.lst"))
		{
			die("create file erro!");
		}
		foreach my $pos (keys(%paaps))
		{
			print OUT $pos."\t".$paaps{$pos}."\n";
		}
		close(OUT);
		
		
		my $result = &rscaMain(@seqs);
		push(@rlts, $result);
		
		if($result == 0)
		{
			print $seqs[$curseqid][1];
			<>;
		}
	}
	print REPORT $miniDist."\t".$size."\t".max(@rlts)."\n";
	print $miniDist."\t".$size."\t".max(@rlts)."\n";
}
}
close(REPORT);
#############SEND EMAIL TO ZUOFENG###########
my $msg = MIME::Lite->new(
    From    => 'lizuofeng@gmail.com',
    To      => 'lizuofeng@gmail.com',
    Cc      => 'wwwcomy@gmail.com',
    Subject => 'Automatic Eamil:Data simulation analysis results',
    Type    => 'data simulation',
);

my $message = "hi\n This message is the data simulation analysis results with $seqfile!\n";

$msg->attach(
    Type     => 'TEXT/html',
    Data     => $message,
);

$msg->attach(
    Type     => 'text/html',
    Path     => $message,
    Filename => $message,
    Disposition => 'attachment',
);


$msg->send;

###########################
