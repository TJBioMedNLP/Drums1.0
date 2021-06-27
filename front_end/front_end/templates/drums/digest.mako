<%
    import sys, urllib2, urlparse, re
    sys.path.append('/home/zuofeng/projects/toc/ppMap')
    import ground as gd
    from ppMapDB import ppMapMySQL
    pp = ppMapMySQL('bminfo')
    
    
    pars = request.POST
    if len(pars.keys()) == 0:
        pars = request.params
    
    category = None
    qterm = ''
    if pars.has_key('c'):
        category = pars['c']
    if pars.has_key('t'):
        qterm = pars['t']
    
    mutids = []

    if category == 'mtid':
        mutids = qterm.split(',')
    else:
        return
    
    if not len(mutids) == 1:
        return
    mutid = mutids[0]
    
    #get information from database
    
    sql = 'SELECT title, seq FROM DRUMS_SEQS WHERE drums_mutid =' + mutid
    lines = pp.execute(sql)
    mutseq = ''
    seq_title = ''
    left_seq = ''
    right_seq = ''
    bases = []
    isRightBegin = False
    if lines:
        seq_title = lines[0][0]
        mutseq += '>' + seq_title + '\n'
        for base in lines[0][1]:
            if base in ['A','C','T','G']:
                mutseq += base
                if isRightBegin:
                    right_seq += base
                else:
                    left_seq += base
            else:
                mutseq += '\n' + base + '\n'
                bases = gd.getBasesFromIUPAC(base)
                isRightBegin = True
                  #0     1           2            3           4                  5         6             7
    sql = 'SELECT url, genome_hgvs, protein_hgvs, exon_index, hgnc_gene_Symbol, pmid_info, drum_lsdb_id, protein_ref from GENOTYPE_PHENOTYPE_PRODUCT WHERE data_status="init" AND drums_mut_uid =' + mutid
    lines = pp.execute(sql)
    
    upToDate = True

    if not lines:
        upToDate = False
        sql = 'SELECT url from GENOTYPE_PHENOTYPE_PRODUCT WHERE data_status="updated" AND drums_mut_uid =' + mutid
        lines = pp.execute(sql)
        urls = []
        for line in lines:
            urls.append(line[0])
        sql = 'SELECT drums_mut_uid from GENOTYPE_PHENOTYPE_PRODUCT WHERE data_status="init" AND url in ("' + '","'.join(urls) + '")' 
        lines = pp.execute(sql)
        upToDateMutids = []
        for line in lines:
            upToDateMutids.append(line[0])
    else:
        lsdbs = []
        
        if lines:
            for line in lines:
                orig_url = urllib2.unquote(line[0])
                url = urlparse.urlparse(orig_url)
                lsdb = {}
                lsdb['url'] = orig_url
                lsdb['root'] = url.scheme+'://'+ url.netloc
                lsdb['genome'] = line[1]
                lsdb['protein'] = line[2]
                lsdb['exon_index'] = line[3]
                lsdb['gene_symbol'] = line[4]
                lsdb['pmid'] = line[5]
                lsdb['drums_lsdb_id'] = line[6]
                lsdb['protein_ref'] = line[7]
                lsdbs.append(lsdb)
        #mapping the mutation to omim av entry
        omimids = []
        pmids = []
        for lsdb in lsdbs:
            lsdb_drums_id  = lsdb['drums_lsdb_id']
            sql = 'SELECT omim_id from lsdb_list WHERE unique_id = ' + str(lsdb_drums_id)
            lines = pp.execute(sql)
            if lines:
                omimids.append(lines[0][0])
            if not lsdb['pmid'] in pmids:
                pmids.append(lsdb['pmid'])
            
        #data cleaning
        if 'na' in pmids:
            pmids.remove('na')
        
        omim_avs = {}
        mid = ''
        if len(set(omimids)) == 1:
            #http://www.codersmart.com/3/drums/details.html?c=mtid&t=1972
            #pmid 9171832
            #omim: 276903

            mid = omimids[0]

            sql = 'SELECT av_text, pmids, hgvs_protein, av_id FROM OMIM_MUTATION_INFO WHERE omim_id="{mid}"'.format(mid=mid)
            lines = pp.execute(sql)

            for line in lines:
                avtext = line[0]
                omim_pmids = line[1].split('\t')
                hgvs_protein_omim = line[2]
                avid = line[3]
                
                if set(omim_pmids) & set(pmids):
                    for lsdb in lsdbs:
                        if lsdb['protein'] == hgvs_protein_omim:
                            omim_avs[avid] = avtext
                            #rint avid
                            break
                    
                    
        else:
            pass
            #do nothing
        
        #restriction analysis
        #http://www.roche-applied-science.com/pack-insert/1131419a.pdf
        #http://www.roche-applied-science.com/pack-insert/1047744a.pdf
        #http://rebase.neb.com/cgi-bin/azlist?re2+1+351+cy
        renzymeFile = '/home/zuofeng/projects/platform/bminfo/data/mutations/resources/renzyme_transformed.tsv'
        restrEnzymes = {} # = {'Nsp I':'[AG]CATG[TC]','Sty I':'CC[AT][AT]GG', 'Nsp V':'TTCGAA'}
        for line in open(renzymeFile, 'r').readlines():
            fds = line.split('\t')
            restrEnzymes[fds[0]] = fds[1]

        restInfo = {}
        old_spl = []
        for e in restrEnzymes.keys():
            restInfo[e] = 0
            p = restrEnzymes[e]
            splicing = []
            for base in bases:
                seq = left_seq + base + right_seq
                splicing = []
                if re.search(p, seq):
                    restInfo[e] += 1
                else:
                    restInfo[e] -= 1
            
            if old_spl:
                if not old_spl == splicing:
                    restInfo[e] = 1
                else:
                    restInfo[e] =0
                    
            old_spl = splicing
        for e in restInfo:
            #normalization
            restInfo[e] = float(restInfo[e])/float(len(bases))
    
    
    
    
%>
%if upToDate:
<table>
    <tr>
        <td>Unique DRUMS sequence id</td>
        <td>${mutid}</td>
    </tr>
    <tr>
        <td>Species</td>
        <td>Homo sapiens</td>
    </tr>
    <tr>
        <td>Gene symbol</td>
        <td>${lsdb['gene_symbol']}</td>
    </tr>
    <tr>
        <td>HGVS Nucleotide</td>
        <td>${lsdb['genome']}</td>
    </tr>
    <tr>
        <td>Sequence<BR>(<a href="../drums/blast.html?mutseqid=${mutid}" target="_blank">blast it!</a>)</td>
        <td><pre>${mutseq}</pre></td>
    </tr>
    <tr>
        <td>Reference Protein</td>
        <td><a href="http://www.ncbi.nlm.nih.gov/protein/${lsdb['protein_ref']}" target="_blank">${lsdb['protein_ref']}</a></td>
    </tr>
    <tr>
        <td>HGVS Protein</td>
        <%
            rlt = re.search('p.([A-Z]+)(\\d+)([A-Z]+)', lsdb['protein'], re.I)
            hgvs_protein_waa = ''
            hgvs_protein_maa = ''
            hgvs_protein_pos = ''
            if rlt:
                hgvs_protein_waa = rlt.group(1)
                hgvs_protein_pos = rlt.group(2)
                hgvs_protein_maa = rlt.group(3)      
        %>
        %if hgvs_protein_waa:
            <td>${lsdb['protein']} <a href="http://safegene.hms.harvard.edu/zak/aa2nt.jsp?gene=${lsdb['gene_symbol']}&codon=${hgvs_protein_pos}&waa=${hgvs_protein_waa}&maa=${hgvs_protein_maa}" target="_blank"><img src="http://safegene.hms.harvard.edu/zak/images/Picture925.png" width="80" height="32"/></a></td>
        %else:
            <td>${lsdb['protein']} </td>
        %endif
    </tr>

    <tr>
        <td>Literature</td>
        <td>
            %for pmid in pmids:
            <a href="../drums/details.html?fm=1&c=pmid&t=${pmid}" target="_blank">PMID:${pmid}</a>
            %endfor
        </td>
    </tr>
    <tr>
        <td>Exon</td>
        <td><a href="../drums/details.html?c=gsymb&t=${lsdb['gene_symbol']}&fm=1&exon=${lsdb['exon_index']}" target="_blank">${lsdb['gene_symbol']} Exon: ${lsdb['exon_index']}</a></td>
    </tr>
    <tr>
        <td>LSDBs</td>
        <td>
            <table>
                %for lsdb in lsdbs:
                    <a href="${lsdb['url']}" target="_blank">${lsdb['root']}</a><BR>
                %endfor
            </table>
        </td>
    </tr>
    <tr>
        <td>OMIM</td>
        <td>
        %for av_id in omim_avs.keys():
            <a href="http://www.ncbi.nlm.nih.gov/omim/${mid}#${mid}Variants${av_id}">${omim_avs[av_id]}</a>
        %endfor
        </td>
    </tr>
   
    <tr>
        <td>Restriction Enzyme Analysis <BR>(&plusmn;1 no change)</td>
        <td>
            <table>
                %for e in restInfo:
                %if not restInfo[e] in [1.0, -1.0]:
                <tr>
                    <td><a href="http://rebase.neb.com/rebase/enz/${e}.html" target="_blank">${e}</a></td>
                    <td>${restInfo[e]}</td>
                </tr>
                %endif
                %endfor
            </table>
        </td>
    </tr>
</table>
<div class="note"></div>
%else:
    The data have been updated to <p>
    %for mutid in upToDateMutids:
        <a href="../drums/details.html?c=mtid&t=${mutid}">DRUMS:${mutid}</a>
    %endfor
%endif
