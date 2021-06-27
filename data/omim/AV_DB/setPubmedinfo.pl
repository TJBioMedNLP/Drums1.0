use strict;
use LWP::Simple;
use Mail::Sendmail;

use Log::Log4perl::Appender::File;

use XML::Simple;
use Data::Dumper;
use DBI;

do "/home/zuofeng/projects/platform/bminfo/bminfo/scripts/perls/functlist.pl";

my $flog = Log::Log4perl::Appender::File->new(
      filename  => 'setPMIDinfo.log',
      mode      => 'append',
      autoflush => 1,
      umask     => 0222,
    );
my $message = &GetCurrentTimeDate();
$flog->log(message => $message."\n");


my $dbname = "mutationdb.sqlite";
my ($sql,$sth);

###########################################################
my $dbargs = {AutoCommit => 0,
                  PrintError => 1};
my $dbpath = "mutationdb.sqlite";
    
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbpath","","",$dbargs);

if(!defined $dbh) {die "Cannot connect to database!\n";}

####################################
my $sql = qq{DROP TABLE  IF EXISTS AVID_PMID;};
#print $sql."\n";
$sth = $dbh ->prepare($sql) or die("123");
$sth->execute() or die("456");
$dbh->commit( );

$sql = qq{CREATE TABLE AVID_PMID (id int, mutinfo_id text, pmid text,pmcid text, abstract text);};
#print $sql."\n";
$sth = $dbh ->prepare($sql) or die("123");
$sth->execute() or die("456");
#print "create avid_pmid table";
$dbh->commit( );
#########################################

$sql = qq{select "INDEX", OMIM_ID, AV_DESCRIPTION from MUTATION_INFO};
#print $sql;

$sth = $dbh ->prepare($sql) or die("123");
$sth->execute() or die("456");

my $rlt = $sth->fetchall_arrayref;
my $index =0;
my $number =0;
foreach my $row_id_url (@{$rlt})
{
	$number++;

	my ($mutinfo_id,$omim_id,$descript) = @$row_id_url;
	#print $omim_id;AA
	my %rlt = &GetOMIMRefList($omim_id);
	my $idlist =  &GetPubmedId($descript); 
	my @field = split(/,/, $idlist);
	foreach my $id (@field)
	{
		$index++;
		#print $id."\t".$rlt{$id}."\n";
		my $message = $id."\tOMIM:$omim_id\t".$rlt{$id}."\n";
		$flog->log(message => $message);
		my $pmid = $rlt{$id};
		my $null = "NULL";
		my $abstr = "NA";
		if($pmid  > 0)
		{
			my %pm = &ConvertPmid($pmid);
			sleep(0.3);
			$abstr = $pm{"abstract"};
		}


		#$sql = qq{insert into avid_pmid (id, mutinfo_id, pmid, pmcid, abstract) values ($index,"$mutinfo_id","$pmid",NULL,$abstr);};
		#print $sql;
		$dbh->do("INSERT INTO avid_pmid (id, mutinfo_id, pmid, pmcid, abstract) values (?,?,?,?,?);", undef,$index,$mutinfo_id,$pmid,$null ,$abstr);
		$dbh->commit();
		#$sth = $dbh ->prepare($sql) or die("123");
		#$sth->execute() or die("456");
		
	}
	#print "-$number- analysis over. There are -$index- pmid\n\n";
	my $message = "-$number- analysis over. There are -$index- pmid\n\n";
	$flog->log(message => $message);	
	sleep(0.3);
	
}
#########################
sendmail(
    From    => 'lizuofeng@gmail.com',
    To      => 'lizuofeng@gmail.com',
    Subject => 'Task OMIM_PMID_INFO_EXTRACT over!',
    Message => "This eamil inform you that the task named OMIM_PMID_INFO_EXTRACT was done. Please check it at 129.89.59.59:3",
);
###################################

sub GetPubmedId()
{
	my($desp) = @_;
	#{17:Grundy et al. (1992)}
	#print $desp."\n";
	if($desp=~/{(\d{1,3}):(.*?)}/)
	{
		my $id = $1;
		my $match = $&;
		$desp=~s/\Q$match\E//;
		my $rlt = &GetPubmedId($desp);
		return $id.",".$rlt;
	}
	else
	{
		return "";
	}
}

sub GetOMIMRefList()
{
	my($omim_id) = @_;
	my %indexPmid =();

	my $mimdb_base_url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=omim&retmode=xml&id=";
	my $url = $mimdb_base_url.$omim_id;
	#print $url;

	my $content = get($url);
	
	my $count = 0;
	while($content eq "")
	{
		print "get OMIM xml erro!";
		$count++;
		sleep($count);
		if($count < 100)
		{
			$content = get($url);
		}
		else
		{
			die("get OMIM xml erro! The id is $omim_id");
		}
	}	
	
	
	$content = &ConvertOmimXml($content);#minus in tag
	#print $content;

	# create object
	my $xml = new XML::Simple;
	my $data = $xml->XMLin($content, ForceArray => 1);
	#print $data->{Mim_entry}->[0]->{Mim_entry_mimNumber}->[0];#no root
	
	my $references = $data->{Mim_entry}->[0]->{Mim_entry_references}->[0]->{Mim_reference};

	foreach my $ref (@$references)
	{
		my $index = $ref->{Mim_reference_number}->[0];
		my  $pmid = $ref->{Mim_reference_pubmedUID}->[0];#not all have a pmid, this situationis zero
		#print $index."\t".$pmid."\n";
		$indexPmid{$index} = $pmid;
	}
	return %indexPmid;
}

sub ConvertOmimXml()
{
	my ($content) = @_;

	my @field=split(/[\n\r]/, $content);
	my $xmlcont = "";
	my $count = 0; 
	foreach my $t (@field)
	{
		$count++;
		if($count<3)
		{
			next;
		}
		
		if($t=~/<(.*)>(.*)<\/(.*)>/)
		{
			my $first = $1;
			my $mid = $2;
			my $last = $3;
			$first=~s/-/_/g;
			$last =~s/-/_/g;
			
			$t = "<".$first.">".$mid."</".$last.">";
		}
		else
		{
			$t=~s/-/_/g;
		}
		$xmlcont.=$t;
	}
	return $xmlcont;
}