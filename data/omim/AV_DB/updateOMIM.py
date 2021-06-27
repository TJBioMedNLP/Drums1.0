#version 1.3
#transfer from perl to python

import re, sys, urllib2
import libxml2
import hashlib
from datetime import date

from datetime import date
import random, time

sys.path.append('/home/zuofeng/projects/platform/bminfo/bminfo/scripts')
import ground as gd
from ppMapDB import ppMapMySQL
pp = ppMapMySQL('bminfo')

SILENT = 0

def getMaxOmimRecord():
    url = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=omim&term=Allelic%20Variants[pr]&retmax=1'
    sContent = gd.getHtmlSrc(url)
    doc = libxml2.parseDoc(sContent)
    max = doc.xpathEval('//eSearchResult/Count')[0].getContent()
    return int(max)
def getOmimIds(maxid):
    url = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=omim&term=Allelic%20Variants[pr]&retmax={maximum}'.format(maximum = maxid)
    sContent = gd.getHtmlSrc(url)
    doc = libxml2.parseDoc(sContent)
    idNodes = doc.xpathEval('//IdList/Id')
    ids = []
    for node in idNodes:
        ids.append(node.getContent())
    return ids
def checkOmimEntry(omim_id):
    #check whether the information have been updated
    #use md5 digest code to check.
    url = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=omim&retmode=xml&id={id}'.format(id=omim_id)
    sContent = gd.getHtmlSrc(url)
    doc = libxml2.parseDoc(sContent)
    
    h = hashlib.md5()
    h.update(sContent)# DO NOT CHANGE THIS CODE IF INDEXES HAVE BEEN BUILT.
    md5_uid = h.hexdigest()
    
    
    updated = False
    sql = 'SELECT * FROM OMIM_MUTATION_INFO WHERE record_status=1 AND md5_digest="{value}"'.format(value=md5_uid)

    lines = pp.execute(sql)
    if not lines:
        updated = True
    return updated, doc, md5_uid
def getPMIDsFromMimText(text, citDict):
    pmids = []
    rlts = re.finditer('\{(\d+)\:(.*?)\}', text)
    for rlt in rlts:
        cit_id = rlt.group(1)
        #print rlt.group(0)
        pmids.append(citDict[cit_id])
    return pmids
def parseAVNode(avNode, citDict):
    isSuccess = True   
    mimDespxTexts = []
    pmids = []
    snps = []
    
    avid = avNode.xpathEval('Mim-allelic-variant_number')[0].getContent();

    
    #USHER SYNDROME, TYPE ID
    name = avNode.xpathEval('Mim-allelic-variant_name')[0].getContent();
    
    try:
        #CDH23, GLN1496HIS
        text = avNode.xpathEval('Mim-allelic-variant_mutation/Mim-text/Mim-text_text')[0].getContent();
    except:
        text = ''

    for node in avNode.xpathEval('Mim-allelic-variant_description/Mim-text/Mim-text_text'):
        content = node.getContent()
        pmids += getPMIDsFromMimText(content, citDict)
        mimDespxTexts.append(content)
        
    for snp_id_node in avNode.xpathEval('Mim-allelic-variant_snpLinks/Mim-link/Mim-link_uids'):
        snpid = snp_id_node.getContent() #rs number
        snps.append(snpid)
        
    

    return isSuccess, avid, name, text, mimDespxTexts, snps, pmids
def getPmidCitDict(omim_xml):
    refs = omim_xml.xpathEval('//Mim-reference')
    citDict = {}
    for ref in refs:
        citId = ref.xpathEval('Mim-reference_origNumber')[0].getContent()
        pmid = ref.xpathEval('Mim-reference_pubmedUID')[0].getContent()
        if citDict.has_key(citId):
            assert(citDict[citId] == pmid)
        else:
            citDict[citId] = pmid
    return citDict    
def transforming(av_text):    
    #data cleaning
    
    #todo: transform nuclotide
    nucl = ''
    
    #CDH23, GLN1496HIS
    prot = ''
    fds = av_text.split(',')
    if len(fds) == 2:
        rlt = re.search('([A-Z][A-Z][A-Z])(\d+)([A-Z][A-Z][A-Z])', fds[1])
        if rlt:
            prot = 'p.'
            prot += rlt.group(1).title()
            prot += rlt.group(2)
            prot += rlt.group(3).title()

    return  nucl, prot
    
def updateOmimEntryInfo(omim_id, xml_omim, newmd5):
    citsDict = getPmidCitDict(xml_omim)

    avNodes = xml_omim.xpathEval('//Mim-allelic-variant')

    for node in avNodes:
        
        success, id, name, avtext, mimDespxTexts, snps, pmids = parseAVNode(node, citsDict)
        if success:
            hgvs_nucleotide, hgvs_protein = transforming(avtext)
        
        
            sql = 'UPDATE OMIM_MUTATION_INFO SET record_status=0 WHERE omim_id ="{omid}"'.format(omid= omim_id)
            lines = pp.update(sql)
            
            date_stamp = date.today().strftime("%Y-%m-%d")
            values = [omim_id, id, name,  avtext,hgvs_protein, newmd5, date_stamp, '\t'.join( mimDespxTexts), '\t'.join(snps), '\t'.join(pmids)]
            
            sql = 'INSERT INTO OMIM_MUTATION_INFO (omim_id, av_id, av_name,   av_text, hgvs_protein, md5_digest, modify_date, av_description, snps, pmids, record_status) VALUES ("' + '","'.join(values) + '"'
            sql += ',1)'
            
            pp.insert(sql)
            pp.commit()
        else:
            print '>>>error' + omim_id
    
##########################################
maxid = getMaxOmimRecord()
omim_ids = getOmimIds(maxid)
for id in omim_ids:
    # if not id == '276903':
        # continue   
    updated, xmlDoc, md5 = checkOmimEntry(id)

    if updated:
        updateOmimEntryInfo(id, xmlDoc, md5)
        #print 'done omim:' + id
    else:
        if not SILENT:
            print 'update is unecessary for omim:' + id
    time.sleep(random.randint(1,3))
    
    