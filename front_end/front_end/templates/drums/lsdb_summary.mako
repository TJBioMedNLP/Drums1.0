<%include file="../bminfo_header.html"/>


<%
    import sys, urllib
    sys.path.append('/home/zuofeng/projects/toc/ppMap')
    from ppMapDB import ppMapMySQL
    pp = ppMapMySQL('bminfo')
    
    parString = request.environ.get('QUERY_STRING')
    if parString:
        parString = parString.replace('+', ' ')
        params = dict([part.split('=') for part in parString.split('&')])
    
    geneSymbol = ''
    if params.has_key('gene_symbol'):
        geneSymbol = params.get('gene_symbol')
    curatorURL = ''
    if params.has_key('curator_url'):
        curatorURL = params.get('curator_url')
        curatorURL = urllib.unquote(curatorURL)
    omimId = ''
    if params.has_key('omid'):
        omimId = params.get('omid')
        
    drums_lsdb_id = ''
    doUpdate = True
    if params.has_key('act'):
        #modification, alternative and new submission
        #only modification is implemented.
        actionType = params.get('act')
        if actionType == 'mod':
            uid = params.get('uid')
            drums_lsdb_id = uid
            
            #update lsdb information
            geneSymbol = params.get('gene_symbol')
            curatorURL = urllib.unquote(params.get('curator_url'))
            drumsURL = urllib.unquote(params.get('drums_url'))
            omimId = params.get('omid')
            
            lsdbCat = params.get('cat')
            genomeRef = params.get('gen_ref')
            transcriptRef = params.get('tra_ref')
            proteinRef = params.get('pro_ref')
            copyrightRequest = params.get('copr_reqst')
            emailList = params.get('emails')
            
            sql  = 'UPDATE lsdb_list SET gene_symbol="' + geneSymbol + '",'
            sql += 'omim_id="' + omimId + '",'
            sql += 'drums_url="' + drumsURL + '",'
            sql += 'hgvs_url ="' + curatorURL + '",'
            sql += 'drums_categories ="' + lsdbCat + '",'
            sql += 'genomic_refseq="' + genomeRef + '",'
            sql += 'transcript_refseq="' + transcriptRef + '",'
            sql += 'protein_refseq = "' + proteinRef + '",'
            sql += 'copr_reqst = "' + copyrightRequest + '",'
            sql += 'emails="' + emailList + '" '
            
            sql += 'where unique_id=' + uid
            print sql
            pp.update(sql)
            
            #update drums_progress
            #When these codes are changed, the code in parseLovdList.py should also be changed.
            drumProgressScore = 0
            if len(drumsURL) > 3:
                drumProgressScore +=10
                if not lsdbCat.lower() == 'unclassified':
                    drumProgressScore +=10
                    if len(omimId) > 2:
                        drumProgressScore +=10
                        if len(genomeRef) >2 or len(transcriptRef)>2 or len(proteinRef) > 2:
                            drumProgressScore +=10
                            if copyrightRequest.upper() == 'CLEARED':
                                drumProgressScore +=10
                            
            sql = 'select drums_progress from  lsdb_list WHERE unique_id = ' + str(uid)
            lines = pp.execute(sql)
            if lines:
                if lines[0][0] is None:
                    score = 0
                else:
                    score = int(lines[0][0])
                if score > drumProgressScore:
                    drumProgressScore = score
                    if score == 60 and len(genomeRef) >2 and len(transcriptRef)>2 and len(proteinRef) > 2:
                        drumProgressScore = 70
                    
                    
                sql = 'UPDATE lsdb_list SET drums_progress=' + str(drumProgressScore) + ' WHERE unique_id=' + uid 
                pp.update(sql)
            
    else:
        doUpdate = False
        #get uid and display
        drums_lsdb_id = params.get('uid')
    
    if not drums_lsdb_id:
        #add a new record to lsdb_list table        
        sql = 'INSERT INTO lsdb_list (gene_symbol, hgvs_url, omim_id, status) values ("' + geneSymbol + '","' + curatorURL + '","' + omimId + '", 1)'
        pp.insert(sql)
        pp.commit()
        
        #get drums_lsdb_id
        drums_lsdb_id = str(pp.lastrowid)
                  #0          1          2         3        4                  5               6                 7                8              9         10
    sql = 'select gene_symbol,drums_url, hgvs_url, omim_id, drums_categories, genomic_refseq, transcript_refseq, protein_refseq, drums_progress, copr_reqst, emails from lsdb_list WHERE status>=0 and unique_id = "' + drums_lsdb_id + '"'
    lines = pp.execute(sql)
    lsdb = lines[0]
    geneSymbol = lsdb[0]
    durms_lsdb_url = lsdb[1]
    omimId = lsdb[3]
    genome = lsdb[5]
    cDNA = lsdb[6]
    protein = lsdb[7]
    drums_progress = lsdb[8]
    copyrightPermission = lsdb[9]
    
    emailListStr = lsdb[10]
    if emailListStr is None:
        emailListStr = ''
    
    if '-' == omimId:
        omimId = ''
    lsdb_category = lsdb[4]
    
    #get lsdb information
    sql = 'select unique_id, drums_url from lsdb_list WHERE status=1 and gene_symbol = "' + lsdb[0] + '"  and unique_id<>' + drums_lsdb_id
    alt_lsdbs = pp.execute(sql)
    
    #phenotype information
    sql = 'select entityB_id, entityB_name, relationship, entityA_id from pharmagkb_rel where entityA_name like "' + geneSymbol + '"'
    parmagkbRels = pp.execute(sql)
    
    #check lsdb url duplication
    sql = 'select hgvs_url from lsdb_list WHERE status = 1 and hgvs_url = "' + lsdb[2] + '"'
    dups = pp.execute(sql)
    
    
    #check lsdb data status
    sql = 'select * from GENOTYPE_PHENOTYPE WHERE data_status="init" and drum_lsdb_id = "' + drums_lsdb_id + '"'
    vars = pp.execute(sql)
    
    
    
%>
<head>
    
        <style type="text/css">@import "../jquery/extension/jquery.svg.package-1.4.3/jquery.svg.css";</style> 
        <script type="text/javascript" src="../jquery/extension/jquery.svg.package-1.4.3/jquery.svg.js"></script>
        <script type="text/javascript" src="../jquery/extension/jquery.progressbar.js"></script>
        <script>
            $(document).ready(function() {
                $("#drums_curation_progress").progressBar();
            }
            );
        </script>

</head>
% if not doUpdate and params.has_key('act'):
<font color="red">You do not have the privilege to make changes.</font>
% endif

<h2>SUMMARY for DRUMS_LSDB_${drums_lsdb_id}</h2>
<a href= '../mutation/lsdb_curator?r=mt&uid=${drums_lsdb_id}'>Curation</a>
% if lines:
    <table>
        <tr>
            <td>Gene Name</td>
            <td>${lsdb[0]}</td>
        </tr>
        <tr>
            <td>DRUMS URL</td>
            <td><a href="${lsdb[1]}" target="_blank">${lsdb[1]}</a></td>
        </tr>
        <tr>
            <td>curator emails</td>
            <td>${urllib.unquote(emailListStr)}</td>
        </tr>
        <tr>
            <td>copyright permission</td>
            <td>${copyrightPermission}</td>
        </tr>
        <tr>
            <td>Origin URL</td>
            <td><a href="${lsdb[2]}" target="_blank">${lsdb[2]}</a></td>
        </tr>
        <tr>
            <td>OMIM ID</td>
            <td>${lsdb[3]}</td>
        </tr>
        <tr>
            <td>LSDB category</td>
            <td>${lsdb_category}</td>
        </tr>
        <tr>
            <td>Genome</td>
            <td>${genome}</td>
        </tr>
        <tr>
            <td>cDNA</td>
            <td>${cDNA}</td>
        </tr>
        <tr>
            <td>Protein</td>
            <td>${protein}</td>
        </tr>
        <tr>
            <td>Curation Progress</td>
            <td>
                % if lsdb[1] == '-':
                     <font color="red">Drums URL absent</font>
                % elif (not durms_lsdb_url) and len(dups) > 1:
                     <font color="red">Curator url not unique</font>
                % elif  not genome_ref and  not cDNA_ref and not protein_ref:
                     <font color="red">No reference sequence</font>
                % elif  '-' in genome and  '-' in cDNA and '-' in  protein:
                     <font color="red">No reference sequence</font>
                % elif lsdb_category == 'unclassified':
                    <font color="red">Database category</font>
                % else:
                    <font color="green">CLEAR</font>
                % endif
                <span class="progressBar" id="drums_curation_progress">${drums_progress}</span>
            </td>
        </tr>
    </table>
    
    <h2>VARIATION DATA</h2>
    <table>
        <tr>
            <td>Totally number</td><td><a href="../mutation/gen_phen_rel?lsdb=${drums_lsdb_id}">${len(vars)}</a><td>
        </tr>
        <tr>
            <td>Unique mutation</td><td>ntd</td>
        </tr>
        <tr>
            <td>point mutation</td><td>ntd</td>
        </tr>
        <tr>
            <td>insertion</td><td>ntd</td>
        </tr>
        <tr>
            <td>deletion</td><td>ntd</td>
        </tr>
        <tr>
            <td>unkown</td><td>ntd</td>
        </tr>
       
        <tr>
            <td>
            Mapping to reference sequence <a href="http://autumn.ims.uwm.edu:5000/lookseq/index" target="_blank">Here</a>
            </td>
        </tr>
    </table>
    <div id="geneDiagram">
    <svg version="1.1" width="150" height="150">
        <svg x="0" y="0" width="0" height="0" class="svg-graph"></svg>
        <svg x="0" y="0" width="0" height="0" class="svg-plot"></svg>
        <circle cx="75" cy="75" r="50" fill="none" stroke="red" stroke-width="3" onclick = "alert('hello');"></circle>
        <g stroke="black" stroke-width="2">
            <line x1="15" y1="75" x2="135" y2="75"></line>
            <line x1="75" y1="15" x2="75" y2="135"></line>
        </g>
    </svg>
    
    
    
    </div>
    
    <h2>ALTERNATIVES(${len(alt_lsdbs)})</h2><a href="../mutation/lsdb_curator?gs=${geneSymbol}&omid=${omimId}">Submit an alternative</a>
    <table>
        <tr>
            <th>Index</th><th>Drums ID</th><th>Drums URL</th>
        </tr>
        
            
        % for i in range(0,len(alt_lsdbs)):
            <%
                alt = alt_lsdbs[i]
            %>
            <tr>
            <td>${i}</td>
            <td><a href="../mutation/lsdb?uid=${alt[0]}">${alt[0]}</a></td>
            <td>${alt[1]}</td>
            </tr>
        % endfor
    </table>
    <h2>GENE'S RELATIONSHIP</h2>
    <table>
        <tr>
            <th>Entity</th>
            <th>PharmaGKB</th>
            <th>DRUMS</th>
        </tr>
        <tr>
            <td>Disease</td>
            <td>
                % for rel in parmagkbRels:
                    % if 'Disease:' in rel[0]:
                        ${rel[1]}</br>
                    % endif
                % endfor
            </td>
            <td>na</td>
        </tr>
        <tr>
            <td>Drug</td>
            <td>
                % for rel in parmagkbRels:
                    % if 'Drug:' in rel[0]:
                        ${rel[1]}</br>
                    % endif
                % endfor
            </td>
            <td>na</td>
        </tr>
    </table>
    
% else:
    Your search  did not match any our records. 
% endif
<div class="js-kit-comments" permalink="" uniq="/mutation/lsdb?uid=${drums_lsdb_id}" label="Comment this photo"></div>
<%include file="../bminfo_bottom.html"/>


