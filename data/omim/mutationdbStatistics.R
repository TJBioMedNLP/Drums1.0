library(RSQLite);
library(gplots);

pdf("./tmp/mutdbstats.pdf") 
	
	#Open database named :mutationdb.sqlite
	dbid<-"/home/zuofeng/projects/mutation/workspace/rsca/AV_DB/mutationdb.sqlite";
	
	#Get database driver
	driver<-dbDriver("SQLite");
	#Get database connection
	connect_mutdb<-dbConnect(driver,dbname=dbid);

	sql<-paste("SELECT  OMIM_ID, count (DISTINCT av_id) FROM POINT_MUTATION GROUP BY OMIM_ID", sep="");
	dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
	rlt<-fetch(dbQuery, -1);
	
	paaps<- rlt;
	total <-length(paaps[,2]);
	less<-c();
	count<-0;
	for(i in  1:length(paaps[,2]))
	{
		if(paaps[i, 2] < 20)
		{
			count<-count+1;
			less[count]<-paaps[i,2];
		}
	}
	rate<-count/total
	
	message<-paste("There are ", rate, " OMIM entry with PAAP number less than twenty. ", sep="");
	textplot(message,valign="top");
	
	#####################################################################
	s<-sort(paaps[,2],  decreasing = TRUE);
	size<-length(s);
	topns<-data.frame();
	count <-0;
	topsize<-50;#top 50;
	for(i in 1:topsize)
	{
		for(j in 1:total)
		{
			if(paaps[j,2] == s[i])
			{
				count <-count+1;
				topns[count,1]<-paaps[j,1];
				topns[count,2]<-paaps[j,2];
			}
		}
	}
	textplot(topns,valign="top");
	###############################################
	distribution<-table(paaps[,2]);
	plot(distribution,type='p', xlab="Number of PAAPs", ylab="Number", log="x");
	
	
	
	dev.off() 