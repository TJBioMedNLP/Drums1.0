taskid = 59;

pdf("./tmp/rsca.pdf") 

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

	#write.table(crlt, file="rlt.txt", sep="\t");
	
	par(mfrow=c(2,2))
	plot(crlt[,1], crlt[,2]);
	plot(crlt[,1], crlt[,2]/(crlt[,2]+ crlt[,3]));
	
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
	
		# CLOSE THE CONNECTION
	sqliteCloseConnection(connect_mutdb);
	
	
dev.off() 
	

	