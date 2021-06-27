import sys
sys.path.append('/home/zuofeng/projects/platform/bminfo/bminfo/scripts')

from ppMapDB import ppMapMySQL, ppMapSQLite
pp = ppMapMySQL('bminfo')

sql = 'DROP TABLE  IF EXISTS OMIM_MUTATION_INFO'
pp.execute(sql)

sql = '''
CREATE TABLE OMIM_MUTATION_INFO
(
   "INDEX"              int not null,
   OMIM_ID              text,
   AV_ID                text,
   AV_TEXT              text,
   AV_DESCRIPTION       text,
   MUT_TYPE             text,
   RECORD_STATUS        text,
   MODIFY_DATE          date,
   primary key ("INDEX")
);
'''

pp.execute(sql)


pp_sqlite = ppMapSQLite('/data_pool/home/zuofeng/projects/platform/bminfo/data/mutations/omim/AV_DB/mutationdb.sqlite')
sql = 'select * from MUTATION_INFO limit 1'
lines = pp_sqlite.execute(sql)
fout = 
for line in lines:
    
    

    