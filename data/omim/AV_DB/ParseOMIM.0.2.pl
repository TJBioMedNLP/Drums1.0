use strict;
use warnings;
use DBI;

do "/home/zuofeng/projects/BioCreativeii5/workspace/functlist.pl";

my $dbname = "/home/zuofeng/projects/mutation/workspace/rsca/AV_DB/mutationdb.sqlite";
my $sql = "";
my $sth = "";
my $tablename = "Point_mutation";
###########################################################

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
                     { RaiseError => 1, AutoCommit => 1 });
if(!defined $dbh) {die "Cannot connect to database!\n";}
#################################### 

#$sql = qq{DROP TABLE IF EXISTS Point_mutation;};
$sql = qq{DROP TABLE IF EXISTS $tablename;};
$dbh->do($sql);
$dbh->commit();

$sql = qq{CREATE TABLE "$tablename" (
				"omim_id" TEXT,
				"av_id" TEXT,
				"aa" TEXT,
				"position" int,
				"mutant" TEXT
);};
$dbh->do($sql);
$dbh->commit();

$sql = qq{select OMIM_ID, AV_ID, AV_TEXT from MUTATION_INFO WHERE record_status = "active";};#active

my $sth_glst = $dbh->prepare($sql) or die("1138");
$sth_glst->execute() or die("1138am");
	
my $rlt = $sth_glst->fetchall_arrayref;
	
foreach my $row (@{$rlt})
{
	my($mimid, $avid, $avtext) = @$row;
	if(!defined($avtext))
	{
		next;
	}
	my %matchrlt = ();
	my $av = "";
	
	$avtext=~s/^\s+//;
	$avtext=~s/\s+$//;
	
	if($avtext=~/(.*?)[,|;](.*)/)
	{
		$av = $2;
		$av=~s/^\s+//;
		$av=~s/\s+$//;
		#print $avtext."\n";
		%matchrlt = &IsSinglePaaps($av);
	}
	else
	{
		print $avtext."\n";
		print "$mimid  $avid   something wrong\n";
		
		%matchrlt = &IsSinglePaaps($avtext);
	}
	
	if($matchrlt{"matched"} < 0)
	{
		next;
	}
	
	print $av."\n";
	$dbh->do("INSERT INTO $tablename (omim_id,av_id, aa,position, mutant) values (?,?,?,?,?);",
			undef,
			$mimid, $avid, $matchrlt{"wild"}, $matchrlt{"begin_position"}, $matchrlt{"mutant"});
	
	
}
$dbh->commit();

#write operation record
my $curtime = &GetCurrentTimeDate();

$dbh->do("INSERT INTO METAINFO (id, item_name, date) values (?, ? ,?);",
		undef,
		4, "update omim point mutation data in POINT_MUTATION table", $curtime);

$dbh->commit();


sub IsSinglePaaps()
{
	my($desp) = @_;
	my $reg = "";
	my %rlt = ();
	#print $desp;
	#codon del is added here.
	#PHE234DEL
	$rlt{"type"} = "protein";
	$rlt{"matched"} = 1;
	if($desp=~/^(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro)(\d+)(gly|ala|val|leu|ile|ser|thr|cys|met|asn|gln|asp|glu|lys|arg|phe|tyr|trp|his|pro|ter|del)$/i)
	{
		#print $desp."\n";
		$rlt{"wild"} = $1;
		$rlt{"begin_position"} = $2;
		$rlt{"mutant"} = $3;	
	}
	else
	{
		$rlt{"matched"} = -1;
	}
	
	return %rlt;
}