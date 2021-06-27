import sys,os, re
sys.path.append('/home/zuofeng/projects/platform/bminfo/bminfo/scripts')
import ground as gd
from BeautifulSoup import BeautifulSoup
import urllib2

from ppMapDB import ppMapMySQL
pp = ppMapMySQL('bminfo')
import random, time

TEST = 1

from datetime import date
from datetime import datetime

import pickle

whiteList = {'david.baux@inserm.fr':'david baux','ammar.husami@cchmc.org':'Ammar Husami','giardine@bx.psu.edu':'','graeme.grimes@hgu.mrc.ac.uk':'','ivy.Jennes@ua.ac.be':'','jasavige@unimelb.edu.au':'','nancy.braverman@mcgill.ca':'','p.a.van.der.zwaag@medgen.umcg.nl':'','raymond.dalgleish@le.ac.uk':''}
blackList = {'auerbac@rockefeller.edu':'','ddunnen@HumGen.nl':'', 'm.losekoot@lumc.nl':'', 'n.van_der_stoep@lumc.nl':'','paul.westwood@luht.scot.nhs.uk':''}
noresponseList = {'J.P.L.Bayley@lumc.nl':'', 'mauno.vihinen@uta.fi ':'', 'depalma@rascal.med.harvard.edu':'', 'r.ekong@ucl.ac.uk':'', 'H.B.Ginjaar@lumc.nl':'', 'Derek.Lim@bwhct.nhs.uk':'', 'bharathi.kattamuri@cmmc.nhs.uk':'', 'd.j.m.peters@lumc.nl':'', 'postmaster@genomed.org':'', 'M.P.G.Vreeswijk@LUMC.nl':'', 'diane.beysen@ugent.be':'', 'simon.ramsden@cmmc.nhs.uk':'', 'M.J.van_Belzen@LUMC.nl':'', 'P.Devilee@lumc.nl':'', 'vincentjanmaat@hotmail.com':'', 'patcon@virginia.edu':'', 'e.bakker@lumc.nl':'', 'bschuele@parkinsonsinstitute.org':'', 'G.Salomons@vumc.nl':'', 'P.Taschner@lumc.nl':'', 'jorge.oliveira@igm.min-saude.pt':'', 'E.M.J.Boon@LUMC.nl':'', 'peikuancong@163.com':''}


def checkLOVDStatus(url, genes):
    '''
        input a homepage of LOVD and return all lovds url belong to this website
    '''
    statusUrl = url + 'status.php'
    src = gd.getHtmlSrc(statusUrl)
    stats = []
    if not src:
        sys.exit('could not get' + url)
        
    if src.find('LOVD v.2.0') >=0:
        soup = BeautifulSoup(src)
        #http://stackoverflow.com/questions/2224602/parsing-table-with-beautifulsoup-and-write-in-text-file
        dataTable = soup.find("table", {"class" : "data"})
        if dataTable:
            for row in dataTable.findAll('tr'):
                cols = row.findAll('td')
                if cols: #skip table head
                    stat = {}
                    stat['url'] = url
                    geneSymbol = cols[0].getText().strip()
                    geneSymbol = gd.convertHtmlEntities2Unicode(geneSymbol).strip()
                    if geneSymbol:
                        stat['geneSymbol'] = geneSymbol
                        stat['geneName'] = cols[1].getText().strip()
                        stat['TotalVariants'] = cols[2].getText().strip()
                        stats.append(stat)                    
                    
                        if not geneSymbol in genes:
                            print 'gene symbol is not match',
                            print 'lovd 2.0' + geneSymbol + 'gene symbol exception' + url
        else:
            lines = src.split('\n')
            pInfoLine = re.compile('\\s+<B>(.*)<BR>\\s*$')
            matches = []
            
            for line in lines:
                rlt = pInfoLine.search(line)
                if rlt:
                    matches.append(rlt.group(1))
            for i in range(0, len(matches), 3):
                if matches[i].find('Total of') >=0:
                    continue
                stat = {}
                stat['url'] = url
                rlt = re.search('(.*?)\s+\\((.*)\\)', matches[i])
                if rlt:
                    stat['geneSymbol'] = rlt.group(1)
                    stat['geneName'] = rlt.group(2)
                else:
                    sys.exit('no gene name')
                    
                rlt = re.search('Total.*(\\d+)', matches[i+1])
                if rlt:
                    stat['TotalVariants'] = rlt.group(1)
                else:
                    sys.exit('no mutation count')
                stats.append(stat)
                
            if not stats:
                sys.exit('lovd 2.0 exception' + statusUrl)
    else:
        #sys.exit('not lovd 2.0' + statusUrl)
        stat = {}
        stat['url'] = url
        stat['originURL'] = url
        stat['finalURL'] = url
        stat['TotalVariants'] = 999 # could not check the data size
        
    return stats
def checkDrums(geneSymbol, lsdb_url, variant_size):
       
    #whether is it lovd?
    try:
        src = gd.getHtmlSrc(lsdb_url)
    except:
        return -1
    
    lsdbCategory = '-'  
    omimId = '-'     
    refDNASeq = '-'
    curatorEmails = []
    copyrightRequest = 'NOTYET'
    
    try:
        if src.find('LOVD development team') >=0:
            lsdbCategory = 'lovd'
            soup = BeautifulSoup(src)
            for row in soup.findAll('tr'):
                th = row.find('th')
                if th is not None:
                    title = th.getText().lower()
                    #get omimid
                    if title.find('omim') >=0 and title.find('gene') >0:
                        omimId = row.find('td').getText()
                    #get reference sequence
                    if title.find('genbank') >=0 and title.find('reference')>0:
                        td = row.find('td')
                        
                        if str(td).find('www.ncbi.nlm.nih.gov') > 0:
                            rlt = re.search('list_uids=(.*?)"', str(td))
                            if rlt:
                                refDNASeq = rlt.group(1)
                        else:
                            rlt = re.search('href="(.*?)"', str(td))
                            if rlt:
                                seq_url = rlt.group(1)
                                if seq_url.find('http') < 0:
                                    lovdRoot = lsdb_url[:lsdb_url.find('home.php?select_db=')]
                                    seq_url = lovdRoot + seq_url
                                seqFileSrc = gd.getHtmlSrc(seq_url)
                                if seqFileSrc:
                                    try:
                                        rlt = re.search('VERSION     (.*?)  GI:\d+', seqFileSrc)
                                        if rlt:
                                            refDNASeq = rlt.group(1)
                                    except:
                                        pass
                                        #time.sleep(random.randint(1,3))
                            
            #get curator emails
            pEmail = re.compile('"mailto:(.*)"')
            
            for email in pEmail.finditer(src):
                curatorEmails.append(email.group(1).lower())
            
            
            if set(whiteList.keys()) & set(curatorEmails):
                copyrightRequest = 'CLEARED'
            if set(blackList.keys()) & set(curatorEmails):
                copyrightRequest = 'OBJECTED'
            if set(noresponseList.keys()) & set(curatorEmails):
                copyrightRequest = 'REQUESTED'
            
    except:
        pass
        
    #get drums_url
    drums_url = '-'    
    if re.search('http.*home.php\?select_db=\w+$', lsdb_url):
        drums_url = lsdb_url
    #claculate the progress
    #When these codes are changed, the code in lsdb_summary should also be changed.
    drumProgressScore = 0
    if len(drums_url) > 3:
        drumProgressScore +=10
        if not lsdbCategory.lower() == 'unclassified':
            drumProgressScore +=10
            if len(omimId) > 2:
                drumProgressScore +=10
                if len(refDNASeq) >2 :
                    drumProgressScore +=10
                    if copyrightRequest.upper() == 'CLEARED':
                        drumProgressScore +=10
    
    #convert http->https
    #convert https-> http
    transformUrl = ''
    if lsdb_urls.find('https') == 0:
        transformUrl = 'http' + lsdb_url[5:]
    else:
        transformUrl = 'https' + lsdb_url[4:]
        
    print lsdb_urls
    raw_input(transformUrl)
    #             0      1                2           3              4        5                6
    sql = 'select status, drums_categories,copr_reqst,genomic_refseq, omim_id, drums_progress, drums_url from lsdb_list where hgvs_url ="' + lsdb_url + '"';
    lines = pp.execute(sql)
    if lines:
        line = lines[0]
        if line[0]: # in case status = NULL
            progress = line[5]
            if progress < 50:
                items = ['drums_categories','copr_reqst','genomic_refseq', 'omim_id', 'drums_url']
                values = [lsdbCategory,copyrightRequest,refDNASeq,omimId, drums_url]
                
                sql = 'UPDATE lsdb_list SET '
                for i in range(1, len(items)):
                    sql += items[i] + '="'
                    sql += values[i] + '"'
                    sql += ', '
                    
                sql += ' drums_progress=' + str(drumProgressScore)
                sql += ' WHERE hgvs_url ="' + lsdb_url + '"';
                pp.update(sql)
            
        return 1
    else:
        if variant_size:
            values = [geneSymbol, lsdb_url, '1','1', lsdbCategory, copyrightRequest, refDNASeq, omimId, drums_url]
        else:
            values = [geneSymbol, lsdb_url, '1','0', lsdbCategory, copyrightRequest, refDNASeq, omimId, drums_url]
        

        
        sql = 'INSERT INTO lsdb_list (gene_symbol, hgvs_url, hgvs_duplicate_count, status, drums_categories,copr_reqst,genomic_refseq, omim_id, drums_url, drums_progress) values ("' + '","'.join(values) + '",' + str(drumProgressScore) +')'
        pp.insert(sql)
        pp.commit()
        return 0
    
def checkLOVDSMaintainedByLOVD():
    txtContent = gd.getHtmlSrc('http://www.lovd.nl/2.0/index_list.php?export=txt')
    in_date = date.today()
    dateFile = in_date.strftime("%Y%m%d-lovdList.txt")

    if not os.path.isfile(dateFile):
        fout= open(dateFile, 'w')
        fout.write(txtContent)
        fout.close()

    fin = open(dateFile, 'r')
    lines =  fin.readlines()
    fin.close()

    lovd_lsdbs = []

    registried_lsdb_num = 0
    nonVoid_lsdb_num  = 0
    for i in range(1, len(lines)):
        fields = lines[i].split('\t')
        url =  fields[7].replace('"','').strip()
        geneList = fields[8].replace('"','').strip()
        if len(geneList) > 0:
            genes = geneList.split(',')
            for gene in genes:
                if not url.endswith('/'):
                    url += '/'

            #if not url in ['http://miracle.igib.res.in/ataxia/']:
            #    continue
            #ignore some urls that could not be accessed anymore
            if url in ['http://fishmap2.igib.res.in/','https://cnmd-sample.ich.ucl.ac.uk/LODv.2.0/','http://www.sysbio.org.cn/pcamdb/']:
                continue
             
            stats = checkLOVDStatus(url, genes)
            

                
            for stat in stats:
                #raw_input(stat)
                registried_lsdb_num += 1
                if int(stat['TotalVariants']) > 0:
                    nonVoid_lsdb_num += 1
                    
                print nonVoid_lsdb_num,
                print stat['geneSymbol'],
                finalUrl = stat['url'] + 'home.php?select_db=' + stat['geneSymbol']
                print finalUrl
                
                stat['finalURL'] = finalUrl
                redirected, finalURL = gd.redirectChecker(finalUrl)
                stat['originURL'] = stat['url']
                if redirected:
                    stat['finalURL'] = finalURL

                #raw_input(stat)
                lovd_lsdbs.append(stat)
                    
                    
    print 'Registried lsdb is: ',
    print registried_lsdb_num 
    print 'nonvoid lsdb is:',
    print nonVoid_lsdb_num
    return lovd_lsdbs
    
def checkLOVDListMaintainedInHGVS():
    
    in_date = date.today()
    dateFile = in_date.strftime("%Y%m%d-hgvsList.txt")
    lsdbs = []
    
    src = ''
    if not os.path.isfile(dateFile):
        src = gd.getHtmlSrc('http://www.hgvs.org/dblist/glsdb.html')
        if not src:
            sys.exit('could not get hgvs list')
        fout= open(dateFile, 'w')
        fout.write(src.encode('utf8'))
        fout.close()
    fin = open(dateFile, 'r')
    src = ''.join(fin.readlines())
    fin.close()
    
    soup = BeautifulSoup(src)
    table = soup.find('table' ,attrs={'cellpadding':'2','cellspacing':'2'})
    #print table
    #TODO: parse the table and get the gene symbol + url + ....Following data items.
    #stat['geneSymbol'] = geneSymbol
    #stat['geneName'] = cols[1].getText().strip()
    #stat['TotalVariants'] = cols[2].getText().strip()
    #stat['finalURL'] = finalUrl
    '''
    <TD ALIGN="left" BGCOLOR="#EEEEEE">	
		
				<B><A NAME="BIN1"></A><I><A HREF="http://www.genenames.org/data/hgnc_data.php?hgnc_id=1052" alt="GeneAlias:AMPHL, SH3P9, AMPH2" title="GeneAlias:AMPHL, SH3P9, AMPH2">BIN1</A></B></I>
				<BR>
				bridging integrator 1
			
			<BR>
				<A HREF="http://www.ncbi.nlm.nih.gov/omim/601248">601248</A>
					
			</TD>
    '''
    
    
    for row in table.findAll('tr'):
        cols = row.findAll('td')
        if not len(cols) == 3:
            continue

        
        url = cols[1].find('a')
        if not url:
            continue
            
        lovd = {}
        
        a1 = cols[0].find('a')
        lovd['geneSymbol'] =  a1['name']            
        
        
        
        lovd['curator'] = gd.convertHtmlEntities2Unicode(cols[2].getText()).strip().encode('utf8')
        
        redirected, finalURL = gd.redirectChecker(url.getText())
        lovd['originURL'] = url.getText()
        if redirected and finalURL.find('/home.php') >0:
            lovd['finalURL'] = finalURL + '?select_db=' + lovd['geneSymbol']
        else:
            lovd['finalURL'] = finalURL
        print lovd['geneSymbol']   
        print lovd['curator']
        print lovd['originURL']
        print lovd['finalURL']
        
        lovd['TotalVariants'] = 999 # could not be checked automatically.
        lsdbs.append(lovd)
        
    
    return lsdbs
def updateLRGs():
    url = 'http://www.lrg-sequence.org/page.php?page=view_all_lrgs'
    src = gd.getHtmlSrc(url)
    soup = BeautifulSoup(src)
    lrgTable = soup.find("table", {"class" : "lrg"})
    if lrgTable:
        for row in lrgTable.findAll('tr'):
            cols = row.findAll('td')
            if cols: #skip table head
                lrgId = cols[0].getText().strip()
                geneSymbol = cols[1].getText().strip()
                
    
if __name__ == '__main__':    

    updateLRGs()
    LOVDs = []
    in_date = date.today()
    pickleFile = in_date.strftime("%Y%m%d-lovdList.pkl")
    if not os.path.isfile(pickleFile):

        LOVDs += checkLOVDSMaintainedByLOVD()
        print 'LOVD maintained:',
        print len(LOVDs)

        hgvs_lovds = checkLOVDListMaintainedInHGVS()
        LOVDs += hgvs_lovds
        print 'hgvs maintained : ',
        print len(hgvs_lovds)

        output = open(pickleFile, 'wb')

        # Pickle dictionary using protocol 0.
        pickle.dump(LOVDs, output)
        output.close()
    else:
        pkl_file = open(pickleFile, 'rb')
        LOVDs = pickle.load(pkl_file)
        pkl_file.close()
        
        
    #load xingNan's list
    for line in open('LOVD_List_0423.txt','r').readlines():
        fds = line.split('\t')
        lsdb = {}
        lsdb['finalURL'] = fds[3]
        lsdb['geneSymbol'] = fds[0]
        lsdb['TotalVariants'] = 10
        LOVDs.append(lsdb)
    ####end of load xingNan's list
        

    new_lsdb_num = 0

    last = ''
    #last = 'http://bioinf.uta.fi/AIREbase/'
    resumed = True
    
    uniqueURLs = []
    for lsdb in LOVDs:
        
        finalUrl =lsdb['finalURL']
        
        #if not finalUrl in ['http://grenada.lumc.nl/LOVD2/TPI/home.php?select_db=PARK2']:
            #continue
        
        
        if finalUrl in uniqueURLs:
            continue
        uniqueURLs.append(finalUrl)
        
        
        if finalUrl == last:
            resumed = True
        if resumed:
            status = checkDrums(lsdb['geneSymbol'], finalUrl, int(lsdb['TotalVariants']))
            if  status ==0:
                new_lsdb_num += 1
                print 'New:', 
            elif status == -1:
                print 'Error:', 
            else:
                print 'Collected:', 
            print lsdb['finalURL']
        
    print 'new lsdb is',
    print new_lsdb_num
         
    
    