<%include file="../bminfo_header.html"/>
<%
    import os, re, sys, urllib2
    sys.path.append('/home/zuofeng/projects/toc/ppMap')
    from ppMapDB import ppMapMySQL
    pp = ppMapMySQL('bminfo')
    
    params = request.params
    ###print request.params
    
    qterm = params.get('t').replace('+', ' ')
    qterm = urllib2.unquote(qterm).strip()
    
    client_id = -1
    if params.has_key('clientid'):
        client_id = int(params['clientid'])
    
    start = 0
    if params.has_key('start'):
        start = int(params.get('start'))
    
    resource = params.get('r').replace('+', ' ')
    lines = []
    summary = {}
    
    #inits
    unique_drums_mut_ids = []
    unique_drums_vars = []
    
    ###negatives are the mutation without sequence information in drums
    negatives = []
    
    whoosh_results = []
    
    drum_mut_ids = [] #dbids in GENOTYPE_PHENOTYPE_PRODUCT table; redoundance mutation information
    drums_mut_db_id_list = ''
    diseases = {}
    pmids = []
    drums_muts = []
    
    print qterm
    
    if resource == 'mt' and len(qterm) >0:
        import whoosh.index as index
        from whoosh.qparser import QueryParser
        MUTATION_INDEX_FOLDER = '/home/zuofeng/projects/platform/bminfo/data/mutations/indexes/latest'
        ix = index.open_dir(MUTATION_INDEX_FOLDER)
        parser = QueryParser("content", schema= ix.schema)
        
        from whoosh.qparser import MultifieldParser
        parser = MultifieldParser(["content","problems"], schema= ix.schema)

        qterm = qterm.decode('utf-8')
        query = parser.parse(qterm)
        
        MAXIMUM_NUMBER_OF_RETURNED_QUERY_RESULTS = 1000
        
        searcher = ix.searcher()  
        whoosh_results = searcher.search(query, sortedby="genome", limit = MAXIMUM_NUMBER_OF_RETURNED_QUERY_RESULTS)
        obsoleteDrumsLSDBIds = ['13672','13675','13680','13700','13701','13716','13717','13719']
        for var in whoosh_results:
            if var['drum_lsdb_id'] in obsoleteDrumsLSDBIds:
                continue
            if var['protein'].find('p.=') >=0:
                continue
            print var
            uid = var['drums_mutseq_uid']    
            drum_mut_ids.append(var['dbid'])
            #get unique mutations: negatives: the ones without sequence information
            #uid: the unique sequence id
            print 'uid@@@@@@@@:',
            print uid
            if uid == '-1':
                negatives.append(var)
            else:
                if not uid in unique_drums_mut_ids:
                    unique_drums_mut_ids.append(uid)
                    unique_drums_vars.append(var)
                else:
                    ###print uid
                    pass
                    
            #get disease information
            problems = var['problems'].split('|')
            for problem in problems:
                
                if not problem in diseases.keys():
                    diseases[problem] = 0
                diseases[problem] +=1
            
            #get literature information
            ###print var['pmid']
            pmids += var['pmid'].split(',')

        drums_mut_db_id_list = '","'.join(drum_mut_ids)
                      #0             1             2                 3           4            5           6
        sql = 'select sequential_id, drum_lsdb_id, hgnc_gene_Symbol, pmid_info, genome_hgvs, protein_hgvs, url FROM GENOTYPE_PHENOTYPE_PRODUCT WHERE data_status="init" '
        sql += ' AND dbid in ("' + drums_mut_db_id_list + '")'
        #based on referee 2 suggestion
        #synonymous mutations are filtered
        #sql += ' AND  protein_hgvs not like "%p.=%"' 
        drums_muts = pp.execute(sql)
        
    
    lsdb_drums_ids = []
    gene_symbols = []
    
    if drums_muts:
        for mut in drums_muts:
            lsdb_id = mut[1]
            if not lsdb_id in lsdb_drums_ids:
                lsdb_drums_ids.append(lsdb_id)
            gene_symbol = mut[2]
            if not gene_symbol in gene_symbols:
                gene_symbols.append(gene_symbol)
            
            

    
    #get lsdb info
    lsdb_info_lines = []
         #             0            1          2          3         4               5              6                   7              8            9
    sql_lsdb = 'select gene_symbol,drums_url, hgvs_url, omim_id, drums_categories, genomic_refseq, transcript_refseq, protein_refseq, unique_id, drums_progress from lsdb_list '  
    sql_lsdbWithoutMuts = sql_lsdb
    lsdb_without_muts_lines =[]
    
    if not lsdb_drums_ids:
        sql_lsdb += ' where gene_symbol like "%' + qterm+ '%"'
        sql_lsdb += ' OR ' + ' drums_url like "%'  + qterm + '%"'
        sql_lsdb += ' OR ' + ' hgvs_url like "%'  + qterm + '%"'
    else:
        sql_lsdb += ' where unique_id in ("' + '","'.join(lsdb_drums_ids) + '")'
        #to handle the lsdbs without copyright request or not requested.
        sql_lsdbWithoutMuts += ' where (gene_symbol like "%' + qterm+ '%"'
        sql_lsdbWithoutMuts += ' OR ' + ' drums_url like "%'  + qterm + '%"'
        sql_lsdbWithoutMuts += ' OR ' + ' hgvs_url like "%'  + qterm + '%"'
        sql_lsdbWithoutMuts += ') AND unique_id not in ("' + '","'.join(lsdb_drums_ids) + '")'
        print sql_lsdbWithoutMuts 
        lsdb_without_muts_lines = pp.execute(sql_lsdbWithoutMuts)
        #####
        
    lsdb_info_lines = pp.execute(sql_lsdb)
    
    
    if not lsdb_drums_ids:
        for lsdb in lsdb_info_lines:
            lsdb_drums_ids.append(lsdb[8])
    
    sorted_disease_name_list = sorted(diseases, key=diseases.get, reverse=True)
    if sorted_disease_name_list:
        sorted_disease_name_list.remove('')
    
    
    #remove pmid duplicates
    pmids.append('na')
    pmid_sets = {}
    pmids = list(set(pmids))
    pmids.remove('na')
    for pmid in pmids:
        pubmedFile = '/home/zuofeng/projects/platform/bminfo/data/mutations/references/pmids/' + pmid
        if os.path.isfile(pubmedFile):
            fin = open( pubmedFile, 'r')
            title = fin.readlines()[0]
            fin.close()
            pmid_sets[pmid] = title
    
    omims = []
    if len(drums_muts) ==0:
    
        #get information from omim
        sql = 'SELECT omim_id, av_id, av_text FROM OMIM_MUTATION_INFO WHERE av_text LIKE "%{query_str}%" OR av_description LIKE "%{query_str}%"'.format(query_str = qterm)
        omims = pp.execute(sql)
%>


<script>
	$(function() {
		$( "#drums_query_rlt" ).tabs();
	});
</script>



<div class="demo">

<div id="drums_query_rlt">
	<ul>
        <li><a href="#mutation_tab"> All (${len(drums_muts)})</a></li>
        <li><a href="#unique_mut_tab">Sequences (${len(unique_drums_vars)})</a></li>
        <li><a href="#gene_tab">Gene (${len(gene_symbols)})</a></li>
		<li><a href="#lsdb_tab">LSDB (${len(lsdb_drums_ids)})</a></li>
        <li><a href="#literature_tab">Literature (${len(pmid_sets.keys())})</a></li>
        <li><a href="#disease_tab">Pheontype (${len(sorted_disease_name_list)})</a></li>
        %if len(omims) > 0:
            <li><a href="#omim_tab">OMIM (${len(omims)})</a></li>
        %endif
	</ul>
   
    
    <div id="unique_mut_tab">
    %for var in unique_drums_vars:
        <%
            url = var['url']
            genome = var['genome']
            protein = var['protein']
            drums_mutseq_uid = var['drums_mutseq_uid']
            gene_symbol = var['genesymbol']
            
            sql = 'select count(*)  from GENOTYPE_PHENOTYPE_PRODUCT WHERE drums_mut_uid={seqid} and data_status="init"'.format(seqid=drums_mutseq_uid)
            counts = pp.execute(sql)
            size = counts[0][0]
            
        %>
        <div  class="entry_div">
            <a href="../drums/details.html?c=mtid&t=${drums_mutseq_uid}" target="_blank"> ${gene_symbol} ${genome} ${protein} </a>[${size}]<BR>
            <cite>
            ../drums/details.html?c=mtid&t=${drums_mutseq_uid}
            </cite>
        </div>
    %endfor

    

    </div>
    
    <div id="omim_tab">
        
        %for omim in omims:
            <%
                mid = omim[0]
                av_id = omim[1]
                av_name = omim[2]
            %>
            <div class="entry_div">
                <a href="http://www.ncbi.nlm.nih.gov/omim/${mid}#${mid}Variants${av_id}" target="_blank">${av_name}</a>
                <div class="sub_entry_div">
                   
                </div>
                <cite>
                    http://www.ncbi.nlm.nih.gov/omim/${mid}#${mid}Variants${av_id}
                </cite>
            </div>
        %endfor    
    </div>

    <div id="disease_tab">
    % for name in sorted_disease_name_list:
        <div class="entry_div">
            <!--<a href="http://en.wikipedia.org/wiki/${name.lower().replace(' ', '_')}" target="_blank">${name}</a><BR>-->
            <a href="http://en.wikipedia.org/w/index.php?search=${name.lower()}" target="_blank">${name}</a><BR>
            <div class="sub_entry_div">
                <a href="../drums/details.html?fm=1&c=disease&t=${name}" target="_blank"> Mutations related</a>
            </div>
            <cite>
                http://en.wikipedia.org/w/index.php?search=${name.lower()}
            </cite>
        </div>
    % endfor
    </div>
    
	<div id="mutation_tab">
        % for drums_mut in drums_muts:
            <%
                var ={}
                var['genesymbol'] = drums_mut[2]
                var['genome'] = drums_mut[4]
                var['protein']  = drums_mut[5]
                var['url']  = drums_mut[6]
            %>
            <div class="entry_div">
                <a href="${urllib2.unquote(var['url'])}" target="_blank">${var['genesymbol']} ${var['genome']} ${var['protein']}</a> <BR>
                
                <%
                    url = urllib2.unquote(var['url'])
                    if len(url) > 53:
                        url = url.replace('variants.php?select_db=','...')
                        url = url.replace('&action=search_all&search_Variant', '...')
                   

                %>
                <cite>${url}</cite>
            </div>
        % endfor
        </p>
	</div>
    <div id="gene_tab">
        %for gene in gene_symbols:
            <div class="entry_div">
            <a href="http://www.genenames.org/cgi-bin/hcop.pl?species_pair=Human+and+Any+species&column=symbol&query=${gene}&Search=Search&.cgifields=textonly" target="_blank">${gene}</a><BR>
                <div class="sub_entry_div">
                    
                    <a href="../drums/details.html?c=gsymb&t=${gene}&fm=1" target="_blank"> Mutations from GENE:${gene}</a>
                </div>
                <cite>http://www.genenames.org/cgi-bin/hcop.pl?species_pair=Human+and+Any+species&query=${gene}</cite>
            </div>
        %endfor
    </div>
	<div id="lsdb_tab">
    % for lsdb in lsdb_info_lines:
        <div class="entry_div">
        <%
            durms_lsdb_url = lsdb[1]
            genome_ref = lsdb[5]
            cDNA_ref = lsdb[6]
            protein_ref = lsdb[7]
            lsdb_category = lsdb[4]
            summary = ''
            if durms_lsdb_url == '-':
                durms_lsdb_url = lsdb[2]
            
        %>
            <a href="${durms_lsdb_url}" target="_blank">drums${lsdb[8]}</a> <BR>
            %if len(drums_muts) >0:
                <div class="sub_entry_div">
                        <a href="../drums/details.html?fm=0&c=lsdb&t=${lsdb[8]}" target="_blank"> Mutations from the LSDB</a>
                </div>
            %endif
        
        <cite>
        % if lsdb[1] == '-' or (not lsdb[1]): #output hgvs url
            ${lsdb[2]}
        % else:#output drums_url
            ${lsdb[1]}  
        % endif
        </cite>
        </div>
    % endfor
    %if lsdb_without_muts_lines:
        <hr>
        %for lsdb in lsdb_without_muts_lines:
            <div class="entry_div">
                <a href="${lsdb[2]}" target="_blank">drums${lsdb[8]}</a> <BR>
                <cite>
                ${lsdb[2]}
                </cite>
                
            </div>
        %endfor
    %endif
    

        
	</div>
	<div id="literature_tab" >
		%for pmid in pmid_sets:
            <div class="entry_div">
                <a href="http://www.ncbi.nlm.nih.gov/pubmed/${pmid}" target="_blank">${pmid_sets[pmid]}</a>
                <div class="sub_entry_div">
                    <a href="../drums/details.html?fm=1&c=pmid&t=${pmid}" target="_blank"> Mutations from PMID:${pmid}</a>
                </div>
                <cite>
                    http://www.ncbi.nlm.nih.gov/pubmed/${pmid}
                </cite>
            </div>
        %endfor
	</div>
</div>

</div><!-- End demo -->








