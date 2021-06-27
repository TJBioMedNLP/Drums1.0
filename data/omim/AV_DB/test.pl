use strict;
use warnings;
use LWP::Simple;
use DBI;
use MIME::Lite;

my $url = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term="Neoplasms"[Mesh] AND "Drug Resistance"[Mesh]&retmax=177150';
print $url."\n";

open (OUT, ">out.txt");

my $content = get($url);

my @field = split(/\n/, $content);

my %pmid = ();

foreach my $line (@field)
{
	$line=~s/^\s+//;
	$line=~s/\s+$//;
	
	if($line=~/<Id>(.*)<\/Id>/)
	{
		$pmid{$1} = 1;
	}
}

my $dbname = "./mutationdb.sqlite";
###########################################################
use DBI;
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
                     { RaiseError => 1, AutoCommit => 1 });
if(!defined $dbh) {die "Cannot connect to database!\n";}
#################################### 
my %risistlist = ();
my $sql = qq{select pubmed, UniProtKB_AC from IDMAP_UNIPROTKB;};
my $sth = $dbh->prepare($sql) or die("0623");
$sth->execute() or die("0623pm");
	
my $rlt = $sth->fetchall_arrayref;
	
foreach my $row_id_url (@{$rlt})
	{
		my ($pmidlist, $accid) =@$row_id_url;
		if($pmidlist=~/;/)
		{
			my @list = split(/;/, $pmidlist);
			foreach my $mid (@list)
			{
				if(defined($risistlist{$mid}))
				{
					$risistlist{$mid} .= $accid."\t";
				}
				else
				{
					$risistlist{$mid} = $accid;
				}
			}
		}
		else
		{
			if(defined($risistlist{$pmidlist}))
			{
				$risistlist{$pmidlist} .= $accid."\t";
			}
			else
			{
				$risistlist{$pmidlist} = $accid;
			}
		}
		
	}


my $outfile = "drugResitantGenelist.txt";
open(OUT, ">$outfile");

print OUT "GeneId\tPmidlist\n";

foreach my $id (keys(%risistlist))
{
	if(defined($pmid{$id}))
	{
		print $id."\t".$risistlist{$id}."\n";
		print OUT $id."\t".$risistlist{$id}."\n";
	}
}
close(OUT);

#############SEND EMAIL TO ZUOFENG###########
my $msg = MIME::Lite->new(
    From    => 'lizuofeng@gmail.com',
    To      => 'lizuofeng@gmail.com',
    Subject => "Drug Reristance gene id",
    Type    => 'text/html',
);

$msg->attach(
    Type     => 'application/pdf',
    Path     => $outfile,
    Filename => $outfile,
    Disposition => 'attachment',
);


$msg->send;

###########################

