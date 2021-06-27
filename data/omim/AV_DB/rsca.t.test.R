
taskids<-c(15,16);

library(RSQLite);

	#Open database named :mutationdb.sqlite
	dbid<-"/home/zuofeng/projects/mutation/workspace/rsca/AV_DB/mutationdb.sqlite";
	
	#Get database driver
	driver<-dbDriver("SQLite");
	#创建连接
	connect_mutdb<-dbConnect(driver,dbname=dbid);
	
	sql<-paste("SELECT  DISTINCT OMIM_ID FROM RSCA_REPORT WHERE TASK_ID=",taskids[1], sep="");
	dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
	rlt<-fetch(dbQuery, -1);
	
	omimlist <- rlt;
	rsca_rlts <-c();
	#omim  tid1 tid2 tid3 tid4
	for(i in 1:length(omimlist[,1]))
	{
		#rsca_rlts[i,1]<- omimlist[i,1];
		omim_row<-c();
		for(j in 1:length(taskids))
		{
			sql<-paste("SELECT  AV_SIZE, RSCA FROM RSCA_REPORT WHERE TASK_ID=",taskids[j]," AND OMIM_ID =",'"', omimlist[i,1], '"',sep="");
			dbQuery<-dbSendQuery(connect_mutdb, statement=sql);
			rlt<-fetch(dbQuery, -1);
			
			
			omim_row[1]<-omimlist[i,1];#this could change to av_size;
			
			if(length(rlt) > 0)
			{
				omim_row[j+1]<-rlt[1,2];#get rsca
			}
		}
		dataSize <-length(omim_row)-1;
		if( dataSize == length(taskids))
		{
			rsca_rlts<-rbind(rsca_rlts,omim_row);
		}
	}