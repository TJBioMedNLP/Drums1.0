#!/usr/bin/perl
#zuofeng li
#lizuofeng@gmail.com
#2008.07.01

#Last Modification
#2008.09.21
#2009.04.28
#change the database name

# use module
use LWP::Simple;
use Log::Log4perl qw(:easy);

use XML::Simple;
use Data::Dumper;

use Encode;
use utf8;
use strict;
use DBI;

=obsolete
unless(open(OMIMID, ">Allelic%20Variants[pr].xml"))
{
	die("create file erro!");
}
=cut

my %originid = ();
if(!open(LOGFILE, "your_logfilename.log"))
{
    print "Begin new thread!!!\n";
}
else
{
     my $line = "";
     my $mimid = "";
     while($line=<LOGFILE>)
     {

	if($line=~/INFO - ([0-9]{1,5}) ([0-9]{6})/)
	{
		$mimid = $2;
		$originid{$mimid} = 0;
		next;
	}

	if($line =~/^INFO - End/ && ($mimid ne ""))
	{
		$originid{$mimid} = 1;
		$mimid = "";
	}

	if($line=~/^INFO - Have been downloaded/ && ($mimid ne ""))
	{
		$originid{$mimid} = 1;
		$mimid = "";
	}
      }

      close(LOGFILE);
}

foreach my $tmp (keys(%originid))
{
	print $tmp."\t".$originid{$tmp};
	print "\n";
}

&InitLogger();
my $log = Log::Log4perl::get_logger();
$log->info("Starting $0");


#date             | Count|
#2008.09.23|2245|
#Arp-28-2009|2289|
#Apr-29-2009|2290|
#Sep-14-2009|2331
#June-04-2010|2435|

#To get the maximum number
#http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=omim&term=Allelic%20Variants[pr]&retmax=1
print "Do you need to change the maximum return id? (y/n)";
my $input = <>;
if($input=~/[y|Y]/){
	die("please modify the code and run me again!");
}
#my $queryrlt = 2289;
my $queryrlt = 2509;#20110117:2435;#09142009
my $esearch_url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=omim&term=Allelic%20Variants[pr]&retmax=$queryrlt";
my $omimListInXml = "";
$omimListInXml = get($esearch_url);
#print OMIMID $omimListInXml;
#close(OMIMID);


# create object
my $xml = new XML::Simple;
# read XML file
#my $data = $xml->XMLin("Allelic%20Variants[pr].xml");
my $data = $xml->XMLin($omimListInXml);
# print output
#print Dumper($data);

my $size = $data->{RetMax};
#print $data->{IdList}->{Id}->[1];

my $mimdb_base_url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=omim&retmode=xml&id=";
my $i=0;

for($i=0; $i<$size; $i++)
{
	#/IdList/Id
	my $id = $data->{IdList}->{Id}->[$i];
	$log->info($i." $id\t");
	if($originid{$id} >=1)
	{
		$log->info("Have been downloaded");
		next;
	}


	# create object
	#open(OMIMXML, ">omim.xml");
	my $c = get($mimdb_base_url.$id);
	while(!defined($c))
	{
		sleep(3);
		$log->info("try to get the url content again in 3 seconds");
		$c = get($mimdb_base_url.$id);
	}
	
	my $tmp = encode("utf8", $c);

	# the minus symbol in OMIM xml file such as Mim-entry  will make
	#perl XML::simple crash. Therefore, here we replace it with  underline. 
	#this may lead some modificaiton in the content.
	#later the modification of the regulatory epression may get good results.
		
	#TH, _70G_A 
	#This is side effect of this algorithm. 
	#-70 is converted to a underline.
	
	#This problem is solved by following code named OMIM_XML_PROBLEM
	#20080921
	my @field=split(/[\n\r]/, $tmp);
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
	
	
	#$xmlcont =~s/-/_/g;
	#print OMIMXML $xmlcont;
	#$c=~s/-/_/g;     print OMIMXML $c;//old
	#close(OMIMXML);
	
	#check if omimid.xml  file exists in the database
	#if true update
	#if false create new.
	#my $code = &GetOmimIdStatusCode($id, $xmlcont);
	my $code = 1;
	&UpdateAVData($xmlcont);
	#http://www.ncbi.nlm.nih.gov/entrez/query/static/eutils_help.html
	#Make no more than 3 requests every 1 second. 
	sleep(0.5);
}

sub UpdateAVData()
{
	#modified from updateavdata.pl
	my ($xmlin) = @_;
	my $xml = new XML::Simple;

	# read XML file

	#my $data = $xml->XMLin("omim.xml", forcearray => 1);
	my $data = $xml->XMLin($xmlin, forcearray => 1);

	my $dumper = Dumper($data);

	my $omimid =  $data->{Mim_entry}->[0]->{Mim_entry_mimNumber}->[0];

#if($dumper=~/\'Mim_allelic_variant\' \=\> \[/)
	{
	#exist multiple variance record
	my $index = 0;
	while()
	{
		my $varid = $data->{Mim_entry}->[0]->{Mim_entry_allelicVariants}->[0]->{Mim_allelic_variant}->[$index]->{Mim_allelic_variant_number}->[0];
		
		if(defined($varid))
		{
			#$log->info("AVid $varid");
			my $avtext =$data->{Mim_entry}->[0]->{Mim_entry_allelicVariants}->[0]->{Mim_allelic_variant}->[$index]->{Mim_allelic_variant_mutation}->[0]->{Mim_text}->[0]->{Mim_text_text}->[0];
			
			
			my $descriptext;#=$data->{Mim_entry}->{Mim_entry_allelicVariants}->{Mim_allelic_variant}->[$index]->{Mim_allelic_variant_description}->{Mim_text}->{Mim_text_text};
			my @field =$data->{Mim_entry}->[0]->{Mim_entry_allelicVariants}->[0]->{Mim_allelic_variant}->[$index]->{Mim_allelic_variant_description}->[0]->{Mim_text};
			
			my $descriptext = &GetDescription(@field);
			#print "\t $omimid";
			&WriteAVEntryInXml($omimid,$varid, $avtext, $descriptext);			
		}
		else
		{
			#print "exist ";
			$log->info( "End\n" );
			last;
		}
		$index++;
	}	
 }


}

# sub CreateNewOmimFileRecord()
# {
	# my ($omimid, $content, $date) = @_;
	
	# my $dbh = &GetOmimAvDbConnect();

	# $dbh->do("INSERT INTO omim_file(OMIM_ID, OMIM_ID_TEXT, DATE) values (?,?,?)", undef, $omimid, $content, $date);
	# $dbh->disconnect();
# }

sub GetOmimAvDbConnect()
{
	my $dbargs = {AutoCommit => 1,
                  PrintError => 1,
				  };
	#my $dbpath = "mutationdb.sqlite";
    #return DBI->connect("dbi:SQLite:dbname=$dbpath","","",$dbargs);
    my $db = "bminfo";
    my $host = "10.1.1.1";
    
    my $dbh = DBI->connect("DBI:mysql:database=$db:host=$host",'i2b2','uwmBIO09');
    return $dbh;    
}

sub GetOmimIdStatusCode()
{
	my($mimid, $content) = @_;
	my $dbh = &GetOmimAvDbConnect();
	
	#my $sth = $dbh->prepare_cached("SELECT OMIM_ID_TEXT FROM omim_file WHERE OMIM_ID=?");
	#$sth->bind_param(1, $mimid);
	#$sth->execute();
	#my @field = $sth->fetchrow_array;
	#$sth->finish;
	#$dbh->do("SELECT OMIM_ID_TEXT FROM omim_file WHERE OMIM_ID=?",undef, $mimid);
	my @field = $dbh->selectrow_array("SELECT  OMIM_ID_TEXT FROM omim_file WHERE OMIM_ID=?",undef, $mimid);
	$dbh->disconnect();
	
	if(defined(@field))
	{
		if($#field>=1)
		{
			die("erro in database. Please check it 132");
		}
		else
		{
			if($content eq $field[0])
			{
				return 1;#no change since last update
			}
			else
			{
				return 0;#change has made since last update
			}
		}
	}
	else
	{
		#not  EXIST AND NEED CREATE NEW RECORD
		return -1;
	}
}



sub GetDescription()
{
	my (@field) = @_;
	my $out_text = "";
	
	my $id= 0;
	foreach my $tmp (@field)
	{
		while()
		{
			my $value = $tmp->[$id]->{Mim_text_text}->[0];
			if(defined($value))
			{
				$out_text.=$id."----\n".$value;
				$id++;
			}
			else
			{
				last;
			}
		}
	}
	return $out_text;
}
 
sub WriteAVEntryInXml()
{
	my ($mim_id, $var_id, $av_text, $av_description) =@_;
	#Apr-28-2009
	my $date = &GetCurrentDate();#"2008/09/24";

	my $dbh = &GetOmimAvDbConnect();

	#update
	#get original one
	my @field  = $dbh->selectrow_array("SELECT * FROM OMIM_MUTATION_INFO WHERE OMIM_ID=? AND AV_ID =? AND RECORD_STATUS=\"active\"", undef, $mim_id, $var_id);
	$dbh->disconnect();
	my $id = $field[0];
	
	if($id > 0)
	{
		if(($av_text eq $field[3]) && ($av_description eq $field[4]))
		{
			#av_text and av_description has no modification
			$log->info( "AVid $var_id\tExactly equal, no need update!");
			$dbh = &GetOmimAvDbConnect();
			$dbh->do("UPDATE OMIM_MUTATION_INFO SET MODIFY_DATE = ? where \"INDEX\" = ?", undef, $date, $field[0]);
			$dbh->disconnect();
			return;
		}
        else
        {
		        #modify original status
				$dbh = &GetOmimAvDbConnect();
				$dbh->do("UPDATE OMIM_MUTATION_INFO SET RECORD_STATUS = \"inactive\" where \"INDEX\" = ?", undef, $field[0]);
				$dbh->commit();
				$dbh->disconnect();
        }		
	}
	
	#insert new record
	@field = ();
	$dbh = &GetOmimAvDbConnect();
	@field = $dbh->selectrow_array("SELECT MAX(\"INDEX\")+1 FROM OMIM_MUTATION_INFO");
	$dbh->disconnect();
	my $index = 1;
	if(defined(@field))
	{
		$index = $field[0];
	}
	else
	{
		die("erro 150!");
	}
	if($index<1)
	{
		$index =1;
	}
	
	$log->info( "$index\t AVid:$var_id");
	
	my $status = "active";
	$dbh = &GetOmimAvDbConnect();
	
    $dbh->do("INSERT INTO OMIM_MUTATION_INFO(\"INDEX\", OMIM_ID, AV_ID, AV_TEXT, AV_DESCRIPTION, MODIFY_DATE, RECORD_STATUS) values (?,?,?,?,?,?,?)", 
	         undef, 
			 $index, $mim_id, $var_id, $av_text, $av_description, $date, $status);
	if ($dbh->err()) { die "$DBI::errstr\n"; }
	$dbh->commit();
	$dbh->disconnect();
}

# sub GetOmimAvDbConnect()
# {
	# my $dbargs = {AutoCommit => 0,
                  # PrintError => 1};
	# my $dbpath = "mutationdb.sqlite";
    # return DBI->connect("dbi:SQLite:dbname=$dbpath","","",$dbargs);
# }

sub InitLogger()
{
	my $log_conf = q/ 
    log4perl.category = INFO, Logfile, Screen 
     
    log4perl.appender.Logfile = Log::Log4perl::Appender::File 
    log4perl.appender.Logfile.filename = your_logfilename.log 
    log4perl.appender.Logfile.mode = write 
    log4perl.appender.Logfile.layout = Log::Log4perl::Layout::SimpleLayout
     
    log4perl.appender.Screen        = Log::Log4perl::Appender::Screen 
    log4perl.appender.Screen.layout = Log::Log4perl::Layout::SimpleLayout
/;

	Log::Log4perl::init( \$log_conf );
}

##Arp-20-2009
##http://www.vbforums.com/archive/index.php/t-278572.html
sub GetCurrentDate()
{
	my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
	$Year += 1900;
	$Month++;
	my $date = "$Month/$Day/$Year";
	return $date;
}