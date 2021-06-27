use strict;
use warnings;

use LWP::Simple;
use List::Util qw[min max];
use MIME::Lite;

use Log::Log4perl::Appender::File;

use XML::Simple;
use Data::Dumper;
use DBI;
use File::Basename;
do "/home/zuofeng/projects/BioCreativeii5/workspace/functlist.pl";
print "Content-type: text/html\n\n";

my $path = dirname($0);#predefined name in Perl

#$path = "/home/zuofeng/project/mutation/workspace/rsca";

#print "dddd-$path --path";

print 'OMIM id examples:
MIMID: 189980';

my $parsize = 6;###

my $argc = @ARGV;# get the number of arguments
my $sbstep = -1;
if($argc ==0)
{
	$sbstep =1;
}
elsif($argc == $parsize)
{
	$sbstep = -1;
}
else
{
	die ("$0 db[1|0] 1 mimid  oldseq[y|n] n n ");
}

#print $sbstep;




=head
my $flog = Log::Log4perl::Appender::File->new(
      filename  => 'omim-ncbi-mapping.log',
      mode      => 'append',#
      autoflush => 1,
      umask     => 0222,
    );
=cut

my $message = &GetCurrentTimeDate();
#$flog->log(message => $message."\n");


my $dbname = $path."/AV_DB/mutationdb.sqlite";
print $dbname;
my ($sql,$sth);
###########################################################
use DBI;
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", "", "",
                     { RaiseError => 1, AutoCommit => 1 });
if(!defined $dbh) {die "Cannot connect to database!\n";}
#################################### 
my @mutdbs = ("omim", "cosmic");
print "which mutation data base to explor:\n";
for(my $i = 0; $i< scalar(@mutdbs); $i++)
{
    print $i.":". $mutdbs[$i]."\n";
}
my $mutDBchoice = <>;
chomp($mutDBchoice);

my $PointMutationTable = "point_mutation";
if($mutDBchoice > 0){
    $PointMutationTable .= "_". $mutdbs[$mutDBchoice];
}


my $seqdbname = "";

print 'Which data base you will use to check the mutation data:
1: NCBI
2: Uniprot
3: Both
';
my $dbsel = $ARGV[0];

if($sbstep > 0)
{
	$dbsel = <>;
	chomp($dbsel);
}


if($dbsel == 1)
{
	$seqdbname = "NCBI";
}
else
{
	$seqdbname = "UniProt";#uniprot
}




my @omim_list =();

print "1 single analysis \n";
print "5 batch analyais \n";

my $option = $ARGV[1];

if($sbstep > 0)
{
	$option =<>;
	chomp($option);
}

my $IsOldVersionIncluded = -1;
print 'Do you want to query the old version of database squences?[Y/N]';

my $choice = $ARGV[3];
if($sbstep >0)
{ 
	$choice = <>;
	chomp($choice);
}

if($choice=~/Y/i)
{
	$IsOldVersionIncluded = 1;
}

#use signal peptide offset to rescue the ummapped av list
my $offsetRescue = -1;
print 'Would you like to use offset analysis (signal peptide and N-terminal methionine) for unmapped OMIM AVs:[Y/N]';
$choice = $ARGV[4];
if($sbstep > 0)
{
	$choice = <>;
	chomp($choice);
}

if($choice=~/Y/i)
{
	$offsetRescue = 1;
}

#check if the mapped list could also be mapped by signal offset
my $MappedOffsetCheck = -1;
print 'Would you like to check the mapped lsit with signal offset:[Y/N]';
$choice = $ARGV[5];
if($sbstep > 0)
{
	$choice = <>;
	chomp($choice);
}
if($choice=~/Y/i)
{
	$MappedOffsetCheck = 1;
}

=head
my $taskdesp = 
"This run is in BATCH mode!\n 
The omim against $dbname database without old version of sequence.
The begining time is 06:28 PM May 15, 2009.

Server: 129.89.59.59:3
";
=cut
print "Please type in the task description:\n";

my $taskdesp = "default run";
if($sbstep > 0)
{
	$taskdesp = <>;
}
=head
'This run is a test. for pdf taskid is 0;

Server: 129.89.59.59:2
';
=cut
my $taskid =&GetTaskId($dbh, $taskdesp, $option,$seqdbname, $IsOldVersionIncluded); #for test#($dbh_,$desp, $mode, $dbtype,$isOldIncluded)


my $begin = -1;
my $curmmid = "";

if($option == 5)
{
	@omim_list = &GetOMIMList($dbh, $seqdbname, $taskid);
}
else
{
	#($option == 1)
	print "please type in the omim_id:";
	
	my $id = $ARGV[2];
	if($sbstep > 0)
	{
		$id = <>;
		chomp($id);
	}
	
	my $rlt = &CheckOMIMid($dbh, $id);

	if( $rlt < 1)
	{
		die("There is no mutation information for this omimid!\n\n");
	}
	#print "I am here";
	my @list = &GetOMIMList($dbh, $seqdbname);
	
	my %omimids=();
	foreach my $mimid (@list)
	{
		#print $mimid."\n";
		$omimids{$mimid} = 1;
	}
	
	if(!defined($omimids{$id}))
	{
		die("There is no sequence mapping in $seqdbname database for OMIMID:$id\n");
	}
	
	
	push(@omim_list, $id);
}
#@omim_list=();
#@omim_list=("612392", "611776");


print "do you want to check the a0b0[y/n]?";
my $a0b0 = <>;
chomp($a0b0);
if($a0b0 =~/y/i)
{
	print "Type in the A Task id:";
	my $fid = <>;
	print "Type in the B Task id:";
	my $sid = <>;
	@omim_list = ();
	@omim_list = &GetABZEROS($fid, $sid);
}

my $total = scalar(@omim_list);
my $count_mim = 0;

foreach my $id (@omim_list)
{
	$count_mim ++;
	print "\nINFO:".(($count_mim/$total)*100)."%, remain ".($total-$count_mim)."\n";
	
	$curmmid = $id;
=head
#####################debug regin
	if($id !~/61232/ && $begin < 0)
	{
		print $id."\n";
		next;
	}
	$begin = 1;
######################end of debug region
=cut
	


	my %paaps =();
    #omim database
	%paaps = &GetAVlist($dbh, $id);
    
   #other mutation database, for example cosmic
    #my $dbname = "cosmic";
   # %paaps = &GetAVlist($dbh, $id, $dbname);
    
	foreach my $key (keys(%paaps))
	{
		print $key."  ".$paaps{$key}."\n";
	}
	
	my $paap_size = scalar(keys(%paaps));
	
	my @paap = ();
	my $count =0;
	foreach my $pos (keys(%paaps))
	{
		#72_X, X in upper;
		if($pos=~/(\d+)_X/)
		{
			$paap[$count][0]= $1;
			#next;
		}else{
			$paap[$count][0]= $pos;
		}
		$paap[$count][1]= $paaps{$pos};
		$count++;
	}

	#sort $paap
	@paap = sort {
		$a->[0] <=> $b->[0]||
		$a->[1] cmp $b->[1]
	} @paap;
	
	#print "----".$paap_size;
	my @seqs = ();
	
	my $refseq_number = scalar(@seqs);

	#my $seqfile = "tempseqfile.uniprot";
	my $rlt_seq = "";
	my $wait = 5;
	while($refseq_number < 1)
	{
		$rlt_seq = &GetSequenceByOMIM($dbh, $id, $IsOldVersionIncluded,$seqdbname);
		#print "rlt_seq----".$rlt_seq."\n";
=head
		unless(open(SEQFILE, ">$seqfile"))
		{
			die("create file erro");
		}
		print SEQFILE $rlt;
		close(SEQFILE);
=cut	
		#
		@seqs = &ReadFastaString($rlt_seq, $seqdbname);
		$refseq_number = scalar(@seqs);
		
		my $x = scalar(@seqs);
		print "I am out $x \n";
		$wait *=5;
		sleep($wait);
	}
	my @rsca_rlt = ();
	my @seqlist = ();
	
	my %LongestSeq = ();
	$LongestSeq{"index"} = 0;
	$LongestSeq{"length"} =0;
	my @consensusId = ();

	my @dsmMatrix = ();
	for(my $i=0; $i< $refseq_number; $i++)#bug 20090515
	{
		my $Candidate_seq = $seqs[$i][1];
		my $seq_id = $seqs[$i][0];
		my($score, $line) = &GetScoreVector($seq_id, $Candidate_seq, @paap);
		$dsmMatrix[$i][0] = $score;
		$dsmMatrix[$i][1] = $line;
		
		push(@seqlist, $seqs[$i][1]);
		my $length = length($seqs[$i][1]);
		
		#for contig view
		if($LongestSeq{"length"} < $length)
		{
			$LongestSeq{"length"} = $length;
			$LongestSeq{"index"} = $i;
		}
		#########contig view###
		#print "k---".$seqs[$i][1]."----ddd\n";
		
		my $type = &rscaAA($seqs[$i][1], @paap);
		
		#my $offsetRescue = -1;
		if($type < 4 && $offsetRescue > 0)
		{	
			print "do offset check\n";
			
			my $offsetype = 0;
			
			#if($type < 4)
			#{
				$offsetype = &rscaAASignalOffset($seqs[$i][1], @paap);
			
				if($offsetype > $type)
				{
					$type = $offsetype;
					&Log5Msg($taskid,"signal-offset",$id,"ok","effective"); 
				}
				else
				{
					&Log5Msg($taskid,"signal-offset",$id,"fail","not effective"); 
				}
				
				###n-terminal offset
				my $delNTerMet = "";
				my $NTerm = uc(substr($seqs[$i][1],0,1,));
				if($NTerm eq "M")
				{
					$delNTerMet = substr($seqs[$i][1],1,length($seqs[$i][1]));
					
					$offsetype = &rscaAASignalOffset($delNTerMet, @paap);
					if($offsetype > $type)
					{
						$type = $offsetype;
						&Log5Msg($taskid,"NTerminal-offset",$id,"ok","effective"); 
					}
					else
					{
						&Log5Msg($taskid,"NTerminal-offset",$id,"fail","not effective"); 
					}					
				}
			
			#}
		}
		
		#print "\n".$type."\n";
		push(@rsca_rlt, $type);
		
		#out put the mapped id
		#200906051125am
		if($type == 4)
		{
			print "\nThe mapped sequence id is: ". $seqs[$i][0];
			print "\n";
			push(@consensusId, $seqs[$i][0]);
		}
	}
	
	@dsmMatrix = reverse sort {$a->[0] <=> $b->[0]} @dsmMatrix;
	open(OUTMATRIX, ">123.txt");
	print OUTMATRIX "MIMID:$curmmid\n";
	print OUTMATRIX "Seq_id\t";
	for(my $i =0; $i < scalar(@paap); $i++){
		print OUTMATRIX $paap[$i][0]."-".$paap[$i][1]."\t";
	}
	print OUTMATRIX "Score\n";
	for(my $i=0; $i < scalar(@dsmMatrix); $i++){
		print OUTMATRIX $dsmMatrix[$i][1]."\n";
	}
	close(OUTMATRIX);
=head	
	print "\n";
	foreach my $rlt(@rsca_rlt)
	{
		print $rlt."\t";
	}
	print "\n";
	#<>;
=cut

	if(max(@rsca_rlt) == 4)
	{
		&Log5Msg($taskid, "consensus mapping", $id, join(",", @consensusId), scalar(@consensusId));
		#add reference sequence
		$message = $id."\t".$paap_size."\t"."1"."\t".$refseq_number;
		
		#write database
		$dbh->do("INSERT INTO RSCA_REPORT (task_id, omim_id , av_size, rsca) values (?,?,?,?);",
				undef,
				$taskid,$id,$paap_size,1);
		$dbh->commit();
		
		#check if the mapped list could also be mapped by signal offset
		#my $MappedOffsetCheck = 1;
		if($MappedOffsetCheck > 0)
		{
			my @rlt = ();
			foreach my $seq (@seqlist)
			{
				my $type = &rscaAASignalOffset($seq, @paap);
				push(@rlt, $type);
			}
			if(max(@rlt) == 4)
			{
				&Log5Msg($taskid,"Mapped-single-offset-check",$id,"offset-effective","gold");
			}
		}	
	}
	else
	{
		$message = $id."\t".$paap_size."\t"."0"."\t".$refseq_number;
		&Log5Msg($taskid,"omim refseq number",$id,$refseq_number,$paap_size); 
		#write database
		$dbh->do("INSERT INTO RSCA_REPORT (task_id, omim_id , av_size, rsca) values (?,?,?,?);",
				undef,
				$taskid,$id,$paap_size,0);
		$dbh->commit();
	}
	print "\nOMIM_ID\tPAAP_SIZE\tRSCA_RLT(0/1)\tNumberOfSequence\n";
    print "\n".$message."\n";
	#$flog->log(message => $message."\n");
	

	
	##########
	###
	if($option == 1)
	{
		my $seqfile = "$path/tmp/tempseqfile.uniprot";
		my $mutant = &ConstructMutantSeq(%paaps);
		unless(open(SEQFILE, ">$seqfile"))
		{
			die("appen file erro Error:20091216");
		}
		print SEQFILE $rlt_seq ;
		print SEQFILE "\n>$id|mutant\n";
		print SEQFILE $mutant;
		close(SEQFILE);
		
		#for contig view
		my $MergedSeqfile = "$path/tmp/merged";
		my $PrimarySeqfile = "$path/tmp/primary";
		unless(open(MERGED, ">$MergedSeqfile"))
		{
			die("create $MergedSeqfile erro! Erro:200905312320");
		}
		for(my $i=0; $i< $refseq_number; $i++)#bug 20090515
		{
			
			if($LongestSeq{"index"} == $i)
			{
				unless(open(PRIMARY, ">$PrimarySeqfile"))
				{
					die("create $PrimarySeqfile erro! ERRO: 200905312330");
				}
				print PRIMARY "$seqs[$i][2]\n";
				print PRIMARY $seqs[$i][1];
				close(PRIMARY);
			}
			else
			{
				print MERGED  "$seqs[$i][2]\n";
				print MERGED $seqs[$i][1]."\n";
			}
		}
		
		print MERGED "\n>$id|mutant\n";
		print MERGED $mutant;
		close(MERGED);
		my $align_length = $LongestSeq{'length'};
		my $align_outfile = "$path/tmp/align_rlt";
		my $cmdline = "/home/zuofeng/projects/mutation/workspace/EMBOSS-6.0.1/emboss/water   -asequence $PrimarySeqfile -bsequence $MergedSeqfile -gapopen 10 -gapextend 0.5  -outfile $align_outfile  -aglobal3 true -sprotein1 true -awidth3 $align_length ";
		print $cmdline."\n";
		system($cmdline);
		
	}
	###	

	sleep(1);
	#<>;
}




my $uniqName = &GetUniqueFileName();
my $pdfile = &RunRcmd($uniqName, $taskid);

if($option == 1)
{
	die("\nNormally exit the analysis!");
}

#############SEND EMAIL TO ZUOFENG###########
my $msg = MIME::Lite->new(
    From    => 'lizuofeng@gmail.com',
    To      => 'lizuofeng@gmail.com',
    Subject => "RSCA Taskid:$taskid",
    Type    => 'multipart/mixed',
);

$msg->attach(
    Type     => 'application/pdf',
    Path     => $pdfile,
    Filename => $pdfile,
    Disposition => 'attachment',
);


$msg->send;

###########################
#return plot file path
sub RunRcmd()
{
	my($uid, $taskid)= @_;
	my $rfile = "$path/tmp/$uid.R";
	my $pdfile = "$path/tmp/$uid.pdf";
	
	open(RFILE, ">$rfile");
	
	print RFILE "taskid = $taskid;\n";
	print RFILE "pdf(\"$pdfile\")";
	
	print RFILE '
library(RSQLite);
library(gplots);
#Begin time
date();

#############################Database Initiation##########3
#initdb();
	#Open database named :mutationdb.sqlite
	dbid<-"/home/zuofeng/projects/mutation/workspace/rsca/AV_DB/mutationdb.sqlite";

	#Get database driver
	driver<-dbDriver("SQLite");
	#创建连接
	connect_mutdb<-dbConnect(driver,dbname=dbid);
	
	sql<-paste("SELECT  AV_SIZE, RSCA  FROM RSCA_REPORT WHERE TASK_ID=",taskid, sep="");
	dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
	rlt<-fetch(dbQuery, -1);
	sqliteCloseResult(dbQuery);

	#
	uni_size<-unique(rlt[,1]);
	
	#To get
	#av_size    rsca_p_sum    rsca_n_sum
	av_size <- c();
	rsca_p_sum <- c();#rsca = 1
	rsca_n_sum <- c(); #rsca = 0

	#interating through all the Allelic Variance size of OMIM
	for(i in 1:length(uni_size))
	{
		p_number<-0;#rsca = 1
		n_number<-0;#rsca = 0
		
		##interating through all the OMIM RSCA analysis results
		for(j in 1:length(rlt[,1]))
		{
			if(uni_size[i] == rlt[j,1])
			{
				if(rlt[j,2] > 0)
				{
                 	p_number<-p_number+1;
				}else
				{
					n_number<-n_number+1;
				}
			}else
			{
				next;
			}
      }
	  av_size[i] <- uni_size[i];
	  rsca_p_sum[i] <- p_number;
	  rsca_n_sum[i] <- n_number;
	}
	crlt<-cbind(av_size, rsca_p_sum, rsca_n_sum);
	
	par(mfrow=c(2,2))#for plot

	#write.table(crlt, file="rlt.txt", sep="\t");
	x_title <- "AV size";
	y_title <- "Number of consistent entry";
	figure_title<-"RSCA Taskid:";
	figure_title<-paste(figure_title, taskid);

	plot(crlt[,1], crlt[,2], xlab=x_title, ylab=y_title, main=figure_title);
	
	x_title <- "AV size";
	y_title <- "Rate of consistent entry";
	figure_title<-"RSCA Taskid:";
	figure_title<-paste(figure_title, taskid);
	
	plot(crlt[,1], crlt[,2]/(crlt[,2]+ crlt[,3]),xlab=x_title, ylab=y_title, main=figure_title);
	
	#trhee and fourth plot
	#-----------------------------------------
	sql<-paste("SELECT count(  distinct OMIM_ID) FROM RSCA_REPORT WHERE TASK_ID=",taskid, sep="");
	dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
	rlt<-fetch(dbQuery, -1);
	sqliteCloseResult(dbQuery);
	
	total_number <-rlt[1,];
	#
	
	sql<-paste("SELECT count(  distinct OMIM_ID) FROM RSCA_REPORT WHERE TASK_ID=",taskid, " AND rsca=1 ", sep="");
	dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
	rlt<-fetch(dbQuery, -1);
	sqliteCloseResult(dbQuery);
	mapped_number <-rlt[1,];
	
	rltmatrix<-c();
	row<-c(mapped_number, total_number-mapped_number, total_number);
	rltmatrix<-rbind(rltmatrix, row);
	row<-c(mapped_number/total_number, (total_number-mapped_number)/total_number, NA);
	row<-round(row, digit=2);
	rltmatrix<-rbind(rltmatrix, row);
	
	rnames<-c("mimEntry", "Rate");
	rownames(rltmatrix)<-rnames;
	
	cnames<-c("Mapped", "Unmapped", "Total");
	colnames(rltmatrix)<-cnames;
	
	textplot(rltmatrix,valign="top");
	
	
	#############
	
	sql<-paste("SELECT * FROM RSCA_PROCESS WHERE TASKID=",taskid, sep="");
	dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
	rlt<-fetch(dbQuery, -1);
	sqliteCloseResult(dbQuery);
	
	msg <-paste("DATABASE: ",rlt[1,5], "\n", sep="");
	if(rlt[1,6] ==1)
	{
		msg<-paste(msg,"old version squence is included", sep="");
	}else
	{
		msg<-paste(msg,"without old version squence", sep="");
	}
	textplot(msg, valign="top", halign="left");
	
	######
	
	
	
	
	
		# CLOSE THE CONNECTION  
	sqliteCloseConnection(connect_mutdb);
dev.off() 
	
	';
	my $cmdline = "sudo R --vanilla <$rfile";
	print $cmdline."\n";
	system($cmdline);
	
	return $pdfile;
}


sub GetOMIMList()
{
	my ($dbh_, $dbName, $taskid) = @_;
	my $sql = "";
	my %dbmimlist =();
	#print $dbName."\n";
	if($dbName=~/Uniprot/i)
	{
		#$sql = qq{select UniProtKB_AC from IDMAP_UNIPROTKb WHERE mim="$mimid";};
		$sql = qq{select DISTINCT MIM from IDMAP_UNIPROTKb;};
	}
	elsif($dbName=~/NCBI/i)
	{
		#$sql = qq{select geneid  from mim_gene WHERE mim_number = "$mimid";};
		$sql = qq{select DISTINCT mim_number  from mim_gene;};
	}
	#print $sql."\n";
	my $sth_glst = $dbh_->prepare($sql) or die("0858");
	$sth_glst->execute() or die("0858am");
	
	my $rlt = $sth_glst->fetchall_arrayref;
	
	foreach my $row (@{$rlt})
	{
		my($id) = @$row;
		#print $id."\n";
		if($id=~/\;/)
		{
			#print $id."\n";
			my @field = ();
			@field = split(/;/, $id);
			foreach my $sid (@field)
			{
				$sid=~s/^\s+//;
				$sid=~s/\s+$//;
				
				$dbmimlist{$sid} = 1;
			}
			
		}
		else
		{
			$dbmimlist{$id} = 1;
		}
	}	

	
	
	#get omimid list from point mutation table
	#$sql = qq{select distinct omim_id from point_mutation;};
	$sql = qq{select distinct omim_id from $PointMutationTable;};
    
	my $sth = $dbh ->prepare($sql) or die("123");
	$sth->execute() or die("456");
	
	$rlt = $sth->fetchall_arrayref;
	my @idlist =();
	foreach my $row_id_url (@{$rlt})
	{
		my ($mimid) = @$row_id_url;
		#print $mimid."\n";
		#check if there is a gene link
		if(!defined($dbmimlist{$mimid}))
		{
			$message= "No OMIM-$dbName Link Report: $mimid";
			&Log5Msg($taskid,"No OMIM-DB link",$dbName,$mimid,""); 
			#$flog->log(message => $message."\n");
			next;
		}
		
		push(@idlist, $mimid);		
	}
	
	return @idlist;
}

sub GetAVlist()
{
	my ($dbh_, $omim_id, $mutationDB) = @_;
    
    my $sql = qq{select position, aa  from $PointMutationTable where omim_id = "$omim_id";};

=head    
    if(defined($mutationDB)){
        my $table = "point_mutation_".$mutationDB;
        $sql = qq{select position, aa  from $table where omim_id = "$omim_id";};
    }
=cut

	my $sth = $dbh_->prepare($sql) or die("0610");
	$sth->execute() or die("0610pm");
	
	my $rlt = $sth->fetchall_arrayref;
	my %pairs =();
	foreach my $row_id_url (@{$rlt})
	{
		my ($pos, $aa) = @$row_id_url;
		if(defined($pairs{$pos}))
		{
			if($aa ne $pairs{$pos})
			{
				#how to cope with the conflict information
				#72_X, X in upper;
				my $message = "Conflict: $omim_id  $aa$pos <->  $pairs{$pos}$pos";
				#$flog->log(message => $message."\n");
				&Log5Msg($taskid,"Site Conflict",$omim_id,"$aa$pos","$pairs{$pos}$pos");
				
				my $conflict_pos= $pos."_X";
				if(defined($pairs{$conflict_pos}))
				{
					$pairs{$conflict_pos} .="\t".$aa;
				}
				else
				{
					$pairs{$conflict_pos} = $aa;
				}
			}
		}
		else
		{
			$pairs{$pos} = $aa;	
		}
	}
	
	return %pairs;	
}

sub GetSequenceByOMIM()
{
	my ($dbh_, $omim_id, $IsOldIncluded, $dbName) = @_;
	
	my $sql = "";
	if($dbName=~/NCBI/i)
	{
		$sql = qq{select geneid  from mim_gene where mim_number = "$omim_id";};
	}
	elsif($dbName=~/UniProt/i)
	{
		$sql = qq{select UniProtKB_AC from IDMAP_UNIPROTKb WHERE mim like "%$omim_id%";};
	}
	print $sql;
	
	my $sth = $dbh_->prepare($sql) or die("0623");
	$sth->execute() or die("0623pm");
	
	my $rlt = $sth->fetchall_arrayref;
	my @geneids = ();
	foreach my $row_id_url (@{$rlt})
	{
		my ($geneid) =@$row_id_url;
		push(@geneids, $geneid);
	}
	#ene of get gene ids
	my $seqs = "";
	
	if($IsOldIncluded < 0)
	{
		if($dbName=~/ncbi/i)
		{
			$seqs = &GetSequenceByGeneidsFromNCBI($dbh_, \@geneids);
		}
		elsif($dbName=~/uniprot/i)
		{
			$seqs = &GetSequenceByGeneidsFromUniprot($dbh_, \@geneids, $IsOldIncluded);
		}
	}
	else
	{
		if($dbName=~/ncbi/i)
		{
			$seqs = &GetSequenceWithVersionByGeneidsFromNCBI($dbh_, \@geneids);
		}
		elsif($dbName=~/uniprot/i)
		{
			$seqs = &GetSequenceByGeneidsFromUniprot($dbh_, \@geneids, $IsOldIncluded);
		}
	}
	
	return $seqs;
}


sub GetSequenceByGeneidsFromNCBI()
{
	my($dbh_, $ids) = @_;
	my @pn_gi = ();
	
	foreach my $geneid (@{$ids})
	{
		my $sql = qq{select distinct(protein_gi) from EntrGene_ACCNUMBER where geneid="$geneid" and protein_gi !="-";};
		#print $sql;
		my $sth = $dbh->prepare($sql) or die("0632");
		$sth->execute() or die("0632pm");
	
		my $rlt = $sth->fetchall_arrayref;
		foreach my $row_id_url (@{$rlt})
		{
			my ($gi) =@$row_id_url;
			#print $gi."\n";
			push(@pn_gi, $gi);
		}
	}
	my $gilist = join(",", @pn_gi);
	
	my $url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&complexity=1&rettype=fasta&id=";#119619814
	$url = $url.$gilist;
	#print $url;
	
	return get($url);	
}

sub GetSequenceByGeneidsFromUniprot()
{
	my($dbh_, $ids, $OldIncluded) = @_;
	my @pn_gi = @{$ids};
	my $sql = "";
	my $sth = "";
	
	my $gilist = "";
	my $result = "";
	print "helelo I am here";
	my $url = "http://www.ebi.ac.uk/cgi-bin/dbfetch?db=UniProtKB&format=fasta&style=raw&id=";#119619814"";
	
	if($OldIncluded > 0)
	{
		#P36952
		$url = "http://www.ebi.ac.uk/cgi-bin/dbfetch?db=unisave&format=fasta&style=raw&id=";#119619814"";
		my %pids = ();
		foreach my $accid (@{$ids})
		{
			$sql = qq{select distinct primary_id from  unisave_map_9606 where merged_id="$accid" and primary_id ="primary";};
			$sth = $dbh->prepare($sql) or die("0632");
			$sth->execute() or die("0632pm");
			
			my $rlt = $sth->fetchall_arrayref;
			
			
			if(scalar(@{$rlt}) >0 )
			{
				$pids{$accid} = 1;
			}
			else
			{
				#get the pimary id
				$sql = qq{select distinct primary_id from  unisave_map_9606 where merged_id="$accid" and primary_id !="primary";};
				$sth = $dbh->prepare($sql) or die("0632");
				$sth->execute() or die("0632pm");
								
				my $rlt = $sth->fetchall_arrayref;
				foreach my $row_id_url (@{$rlt})
				{
					my ($pid) = @$row_id_url;
					$pids{$pid} = 1;
				}
			}
		}
		my @AccidDotVersion = ();
		foreach my $pid (keys(%pids))
		{
			#Bug:200905281102
			#To download sequence, the entry version should be used.
			#$sql = qq{select  merged_id, seq_version  from unisave_map_9606 where primary_id = "$pid" or merged_id = "$pid";};
			$sql = qq{select  merged_id, entry_version  from unisave_map_9606 where primary_id = "$pid" or merged_id = "$pid";};
			$sth = $dbh->prepare($sql) or die("0632");
			$sth->execute() or die("0632pm");
								
			my $rlt = $sth->fetchall_arrayref;
			foreach my $row_id_url (@{$rlt})
			{
				my ($id, $version) = @$row_id_url;
				push(@AccidDotVersion, $id.".".$version);
			}
			
		}
		
		$gilist= join(",", @AccidDotVersion);
	}
	else
	{
		$gilist = join(",", @pn_gi);
	}
		
	my $size = scalar(@pn_gi);
	
	
	
	
	if( $size < 200)
	{
		print $url.$gilist;
		$result = get($url.$gilist);
	}
	else
	{
		&Log5Msg($taskid,"uniprot:sequnce:200:omim id is",$curmmid,"$size","$gilist");
		my @partlst = ();
		for(my $i =0; $i< $size; $i++)
		{
			if(($i % 100 ==0) && ($i >0))
			{
				push(@partlst, $pn_gi[$i]);
				$gilist = join(",", @partlst);
				print $url.$gilist;
				$result.=get($url.$gilist);
				$result.="\n";
				
				@partlst = ();
			}
			else
			{
				push(@partlst, $pn_gi[$i]);
			}
		}
		
		if( scalar(@partlst) >0)
		{
			$gilist = join(",", @partlst);
			$result.=get($url.$gilist);
			$result.="\n";
		}
	}
	
	
	return $result;
}

sub GetSequenceWithVersionByGeneidsFromNCBI()
{
	my($dbh_, $ids) = @_;
	my @pn_acc = ();
	
	foreach my $geneid (@{$ids})
	{
		my $sql = qq{select distinct(protein_accession_version) from EntrGene_ACCNUMBER where geneid="$geneid" and protein_gi !="-";};
		#print $sql;
		my $sth = $dbh->prepare($sql) or die("0214");
		$sth->execute() or die("0214pm");
	
		my $rlt = $sth->fetchall_arrayref;
		foreach my $row_id_url (@{$rlt})
		{
			my ($acc) =@$row_id_url;
			if($acc=~/(.*?)\.(\d+)/)
			{
				my $accroot = $1;
				my $lastversion = $2;
				if($lastversion > 1)
				{
					for(my $i=1; $i< $lastversion; $i++)
					{
						my $oldacc = $accroot."\.".$i;
						#print $oldacc."\n";
						push(@pn_acc, $oldacc);
					}
				}
			}
			#push(@pn_acc, $acc);
		}
	}
	my $oldacclist = "";
	my $url = "";
	
	my $oldseqs = "";
	if(scalar(@pn_acc) >0)
	{
		$oldacclist = join(",", @pn_acc);
		$url = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=protein&complexity=1&rettype=fasta&id=";#119619814
		$url = $url.$oldacclist;
		$oldseqs = get($url);
		#print $url;
		sleep(0.3);
	}
	
	#get current sequence;
	my $curseqs =&GetSequenceByGeneidsFromNCBI($dbh_, $ids);
	my $allseqs = "";
	if(length($oldseqs) > 1)
	{
		$allseqs = $curseqs.$oldseqs;
	}
	else
	{
		$allseqs = $curseqs;
	}
	
	return $allseqs ;	
}



sub GetCurrentTimeDate()
{
	my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
	$Year += 1900;
	$Month++;
	my $td = "$Minute\.$Hour\.$Month\.$Day\.$Year";
	return $td;
}

sub CheckOMIMid()
{
	my ($dbh_, $omim_id) = @_;
	
	#my $sql = qq{select * from Point_mutation where omim_id = "$omim_id";};
    my $sql = qq{select * from $PointMutationTable where omim_id = "$omim_id";};
	
    my $sth = $dbh_->prepare($sql) or die("1149");
	$sth->execute() or die("1149am");
	my $rlt = $sth->fetchall_arrayref;
	
	return scalar(@{$rlt});
}

sub ConstructMutantSeq()
{
	my (%paap) = @_;
	my $maxpos = 0;
	foreach my $pos (keys(%paap))
	{
		if($pos=~/_X/)
		{
			next;
		}
	
		if($pos > $maxpos)
		{
			$maxpos = $pos;
		}
	}
	my $mutant = "";
	for(my $i=1; $i<=$maxpos; $i++)
	{
		if(defined($paap{$i}))
		{
			$mutant .=&tosingle($paap{$i});
			print $i."\t".$paap{$i}."\t".&tosingle($paap{$i})."\n";
		}
		else
		{
			$mutant .= "x";
		}
	}
	
	return $mutant;
}

sub GetTaskId()
{
	my ($dbh_,$desp, $mode, $dbtype,$isOldIncluded) = @_;
	my $sql = qq{select distinct taskid from RSCA_PROCESS;};
	
	my $sth = $dbh_->prepare($sql) or die("1149");
	$sth->execute() or die("1149am");
	my $rlt = $sth->fetchall_arrayref;
	my @ids = ();
	foreach my $row_id_url (@{$rlt})
	{
		my ($tid) =@$row_id_url;
		push(@ids, $tid);
	}
	
	my $max = max(@ids);
	my $NewTaskId = $max +1;

	my $date = &GetCurrentDate();

	$dbh_->do("INSERT INTO RSCA_PROCESS (taskid,author, task_desp,mode, database_type, oldversion_included, date) values (?,?,?,?,?,?,?);",
			undef,
			$NewTaskId,'lizuofeng@gmail.com',$desp,$mode, $dbtype, $isOldIncluded, $date);
	$dbh_->commit();
	
	return  $max+1;
}

sub Log5Msg()
{
	my ($tid, $step,$object, $rlt, $memo) = @_;
	
	$dbh->do("INSERT INTO RSCA_LOG (taskid, rsca_step, object, result, memo) values (?,?,?,?,?);",
			undef,
			$tid,$step,$object,$rlt,$memo);
	$dbh->commit();
}
#GET A0B0
sub GetABZEROS()
{
	my($tid_first, $tid_second) = @_;
	chomp($tid_first);
	chomp($tid_second);
	
	my $sql = qq{ select OMIM_ID, RSCA from rsca_report where (task_id = $tid_first OR task_id = $tid_second);};
	
	my $sth = $dbh->prepare($sql) or die("1149");
	$sth->execute() or die("1149am");
	my $rlt = $sth->fetchall_arrayref;
	my @ids = ();
	my %rsca = ();
	foreach my $row_id_url (@{$rlt})
	{
		my ($mimid, $rsca_rlt) =@$row_id_url;
		if(defined($rsca{$mimid}))
		{
			$rsca{$mimid} += $rsca_rlt;
		}
		else
		{
			$rsca{$mimid} = $rsca_rlt;
		}
	}
	my @a0b0 = ();
	
	foreach my $id (keys(%rsca))
	{
		if($rsca{$id} == 0)
		{
			push(@a0b0, $id);
		}
	}
	
	return @a0b0;
}

sub GetScoreVector()
{
	my ($seq_id, $seq, @paapslist) = @_;
	my $p_count = scalar(@paapslist);
	open(OUTMATRIX, ">>123.txt");
	#print OUTMATRIX "$seq_id\t";
	my $line = "$seq_id\t";
	my $line_score = 0;
	for(my $j =0; $j< $p_count; $j++){
		my $pos = $paapslist[$j][0];#position
		my $aa = $paapslist[$j][1];#amnio acid residue
		
		if(length($aa) == 3)
		{
			$aa = &tosingle($aa);
		}
		else
		{
			$aa = uc($aa);
		}
		my $dirValue = &GetDirectMapValue($pos, $aa, $seq);
		$line_score += $dirValue;
		my $sigalValue = &GetSignalPeptideOffsetValue($pos, $aa, $seq);
		$line_score += $sigalValue;
		my $NMetValue = &GetNMetValue($pos, $aa, $seq);
		$line_score += $NMetValue;
		
		#print OUTMATRIX $dirValue."-".$sigalValue."-".$NMetValue."\t";
		$line .= $dirValue."-".$sigalValue."-".$NMetValue."\t";
	}
	$line.="\t". $line_score;
	#print OUTMATRIX "\n";
	print OUTMATRIX $line."\n";
	close(OUTMATRIX);
	my @rlt = ();
	$rlt[0] = $line_score;
	$rlt[1] = $line;
	return @rlt;
}

sub GetDirectMapValue()
{
	my ($pos, $aa, $seq) = @_;
	$pos = $pos-1;
	
	if($pos > length($seq)){
		return 0;
	}
	
	my $sub = substr($seq, $pos, 1);
	if(!defined($sub)){
		return 0;
	}
	print "\n".$sub."---vs---".$aa;
	if($sub eq $aa){
		return 1;
	}else{
		return 0;
	}
}

sub GetNMetValue()
{
	my ($pos, $aa, $seq) = @_;
	my $result =0;
	
	my $delNTerMet = "";
	
	my $NTerm = uc(substr($seq,0,1,));
	
	if($NTerm eq "M")
	{
		$delNTerMet = substr($seq,1,length($seq));
		$pos = $pos-1;
		if($pos <= length($delNTerMet)){
			my $sub = substr($delNTerMet, $pos, 1);
			if($sub eq $aa){
				$result = 1;
			}
		}
	}
	
	return $result;
}

sub GetSignalPeptideOffsetValue()
{
	my ($pos, $aa, $seq)= @_;
		#annoted at 09/sep/15
	#my %signalp = &SignalP3($aaseq);
	my %signalp = &LocalSignalP3($seq);
	
	my $CleavageSite = 0;
	my $result = 0;
	#filteration
	if($signalp{"p value"} > 0.85)
	{
		$CleavageSite= $signalp{"cleavage site"};
	
	
		my $MninusSignalSeq = substr($seq, $CleavageSite, length($seq));

		if($pos <= length($MninusSignalSeq)){
			$pos = $pos -1;
			my $sub = substr($MninusSignalSeq, $pos, 1);
			if(defined($sub)){
				if($sub eq $aa){
					$result = 1;
				}
			}
		}
	}

	return $result;
}