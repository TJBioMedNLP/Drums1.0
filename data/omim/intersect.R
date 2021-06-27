taskids = c(190,191);
blackBoxidNumber = c(8,7); #8 genbank, 7 Uniprot
pdf("./tmp/intersect.pdf")
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
	connect_mutdb<-dbConnect(driver,dbname=dbid);

	sql<-paste("select omim_id from rsca_report where task_id =",taskids[1]," AND rsca=1", sep="");
	dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
	rltA1 <-fetch(dbQuery, -1);
	sqliteCloseResult(dbQuery);

	sql<-paste("select omim_id from rsca_report where task_id =",taskids[2], " AND rsca=1", sep="");
	dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
	rltB1<-fetch(dbQuery, -1);
	sqliteCloseResult(dbQuery);
	
	sql<-paste("select omim_id from rsca_report where task_id =",taskids[1]," AND rsca=0", sep="");
	dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
	rltA0<-fetch(dbQuery, -1);
	sqliteCloseResult(dbQuery);
    
    #add no gene link omim ids
    sql<-paste("select RESULT from rsca_log where taskid =", taskids[1], " AND rsca_step = 'No OMIM-DB link'", sep="");
    dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
	rltAnolink<-fetch(dbQuery, -1);
	sqliteCloseResult(dbQuery);
    colnames(rltAnolink)<-"omim_id";
    names<-row.names(rltAnolink);
    mode(names)<-"integer"
    names<-names+ length(rltA0[,1]);
    row.names(rltAnolink)<-names;
    rltA0<-rbind(rltA0, rltAnolink);
    

	sql<-paste("select omim_id from rsca_report where task_id =",taskids[2], " AND rsca=0", sep="");
	dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
	rltB0<-fetch(dbQuery, -1);
	sqliteCloseResult(dbQuery);
    
    #add no gene link omim ids for task 2
    sql<-paste("select RESULT from rsca_log where taskid =", taskids[2], " AND rsca_step = 'No OMIM-DB link'", sep="");
    dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
	rltBnolink<-fetch(dbQuery, -1);
	sqliteCloseResult(dbQuery);
    colnames(rltBnolink)<-"omim_id";
    names<-row.names(rltBnolink);
    mode(names)<-"integer"
    names<-names+ length(rltB0[,1]);
    row.names(rltBnolink)<-names;
    rltB0<-rbind(rltB0, rltBnolink);
	
	a1b1 <-intersect(rltA1[,1], rltB1[,1]);
	length(a1b1);
	
	a0b1 <-intersect(rltA0[,1], rltB1[,1]);
	length(a0b1);
	
	a0b0 <-intersect(rltA0[,1], rltB0[,1]);
	length(a0b0);
	
	a1b0 <-intersect(rltA1[,1], rltB0[,1]);
	length(a1b0);
	
	length(rltA1[,1]);
	length(rltB1[,1]);
	
	rtable<-c();
	par(mfrow=c(2,2))#for plot
	row<-c(length(a1b1), length(a0b1));
	rtable<-rbind(rtable, row);
	
	row<-c(length(a1b0),length(a0b0));
	rtable<-rbind(rtable, row);
	

	
	B<-taskids[2];
	A<-taskids[1];
	rownames(rtable)<-c(paste(B,"+",sep=""), paste(B,"-", sep=""));
	colnames(rtable)<-c(paste(A,"+",sep=""), paste(A,"-", sep=""));
	
	textplot(rtable,valign="top");
	
	report<-chisq.test(rtable)
	textplot(report, valign="top");
	
	
	#pdf("./tmp/a0b0.pdf")
	par(mfrow=c(1,1))#for plot
	
	unmap<-c();
	count<-0;
	l<-c();
	for (i in 1:length(a0b0))
	{
		count<-count+1;
		
		if(count == 9)
		{
			l[count]<-a0b0[i];
			unmap<-rbind(unmap, l);
			
			count <-0;
			l<-c();
		}else
		{
			l[count]<-a0b0[i];
		}
	}
	if(count < 9 && count > 0)
	{
		for(i in (count+1):10)
		{
			l[i]<- "NA";
		}
		
		unmap<-rbind(unmap, l);
	}
	
	
	textplot(unmap, valign="top");
	
	dev.off();
    
#output the consensus ids
	sql<-paste("select object, result  from rsca_log where rsca_step = 'consensus mapping' and taskid =",taskids[1],sep="");
	dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
	consensusA <-fetch(dbQuery, -1);
	sqliteCloseResult(dbQuery);
    clnames<-c("omim_id", "consensuse_sequence_ids");
    colnames(consensusA)<-clnames;
    datafile = paste("./tmp/", taskids[1],".txt" , sep="");
    write.table(consensusA, file = datafile, sep = "\t",quote=FALSE, row.names = TRUE, col.names = TRUE);
    
    sql<-paste("select object, result  from rsca_log where rsca_step = 'consensus mapping' and taskid =",taskids[2],sep="");
	dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
	consensusB <-fetch(dbQuery, -1);
	sqliteCloseResult(dbQuery);
    colnames(consensusB)<-clnames;
    datafile = paste("./tmp/", taskids[2],".txt",  sep="");
    write.table(consensusB, file = datafile, sep = "\t",quote=FALSE, row.names = TRUE, col.names = TRUE);
    
#output the unmapped omim ids
    mutSize <-c();
    for(i in 1:length(a0b0))
    {
        sql<-paste("select count(*) from point_mutation where omim_id ='",a0b0[i],"'",sep="");
        dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
        rlt <-fetch(dbQuery, -1);
        sqliteCloseResult(dbQuery);
        mutSize[i]<- rlt[1,1];        
    }
    
    a0b0AndSize<-cbind(a0b0, mutSize);
    datafile = paste("./tmp/a0b0.", taskids[1],"-",taskids[2],".txt",  sep="");
    write.table(a0b0AndSize, file = datafile, sep = "\t",quote=FALSE, row.names = TRUE, col.names = TRUE);
	