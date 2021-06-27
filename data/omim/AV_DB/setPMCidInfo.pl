use strict;
use warnings;
use Win32::Clipboard;

use LWP::Simple;

use XML::Simple;
use Data::Dumper;





print "input the pmid:";
my $pmid = <>;
chomp($pmid);
my $type = 1;
my %c = &ConvertPmid($pmid, $type);

my $reference = $c{"authors"}."\. ".$c{"title"}." ".$c{"journal"}." ".$c{"year"}.", ".$c{"volume"}."\(".$c{"issue"}."\):".$c{"medlinePgn"}."\.";

print $c{"abstract"};
#currently, could not add link to pmid
my $clipstr = $reference." ".$pmid;
print $clipstr."\n";
my $CLIP = Win32::Clipboard();
print "Send the reference to clipboard(Y/N):Y";
my $input = <>;
chomp($input);

if($input eq "" || $input =~/[Yy]/)
{
	$CLIP->Empty();
	$CLIP->Set($clipstr);
}

sub ConvertPmid()
{
	my ($id, $type) = @_;
	#http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml&id=17495998
	my $base_url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml&id=";
	my $content = get($base_url.$id);
	
	my $xml = new XML::Simple;
	my $data = $xml->XMLin($content, ForceArray => 1);
	my %citation = ();
	open(OUT, ">test.txt");
	print OUT Dumper($data);
	$citation{"pmid"} = $data->{PubmedArticle}->[0]->{MedlineCitation}->[0]->{PMID}->[0];
	$citation{"journal"} = $data->{PubmedArticle}->[0]->{MedlineCitation}->[0]->{Article}->[0]->{Journal}->[0]->{ISOAbbreviation}->[0];
	$citation{"title"} = $data->{PubmedArticle}->[0]->{MedlineCitation}->[0]->{Article}->[0]->{ArticleTitle}->[0];
	$citation{"year"} = $data->{PubmedArticle}->[0]->{MedlineCitation}->[0]->{Article}->[0]->{Journal}->[0]->{JournalIssue}->[0]->{PubDate}->[0]->{Year}->[0];
	$citation{"volume"} = $data->{PubmedArticle}->[0]->{MedlineCitation}->[0]->{Article}->[0]->{Journal}->[0]->{JournalIssue}->[0]->{Volume}->[0];
	$citation{"issue"} = $data->{PubmedArticle}->[0]->{MedlineCitation}->[0]->{Article}->[0]->{Journal}->[0]->{JournalIssue}->[0]->{Issue}->[0];
	$citation{"medlinePgn"} = $data->{PubmedArticle}->[0]->{MedlineCitation}->[0]->{Article}->[0]->{Pagination}->[0]->{MedlinePgn}->[0];
	$citation{"abstract"} = $data->{PubmedArticle}->[0]->{MedlineCitation}->[0]->{Article}->[0]->{Abstract}->[0]->{AbstractText}->[0];

	#get an array for authors
	my $authors =$data->{PubmedArticle}->[0]->{MedlineCitation}->[0]->{Article}->[0]->{AuthorList}->[0]->{Author};
	my $names = "";
	foreach my $author (@$authors)
	{
		if($names ne "")
		{
			$names.=", ";
		}
		$names .=$author->{LastName}->[0];
		$names .=" ";
		$names .=$author->{Initials}->[0];
	}
	$citation{"authors"} = $names;
	#$citation{"author"} = $data->{PubmedArticle}->[0]->{MedlineCitation}->[0]->{Article}->[0]->{AuthorList}->[0]->{Author}->[0]->{Initials}->[0];

	foreach my $name (keys(%citation))
	{
		if(!defined($citation{$name}))
		{
			$citation{$name} = "";
		}
	}

	return %citation;
	
}