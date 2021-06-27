<%include file="../bminfo_header.html"/>
<%
    import sys, urllib2
    import webhelpers.html.builder
    sys.path.append('/home/zuofeng/projects/toc/ppMap')
    from ppMapDB import ppMapMySQL
    pp = ppMapMySQL('bminfo')
    
    urlCmd = request.environ.get('QUERY_STRING')
    params = dict([part.split('=') for part in urlCmd.split('&')])
    
    userName = ''
    if request.environ.has_key("REMOTE_USER"):
        userName = request.environ.get("REMOTE_USER")
    
    drums_lsdb_id = ''
    
    geneSymbol = ''
    if params.has_key('gs'):
        geneSymbol = params.get('gs')
            
    omimId = ''
    if params.has_key('omid'):
        omimId = params.get('omid')
    
    if urlCmd:
        review = ''
        if params.has_key('uid'):
            drums_lsdb_id = params.get('uid')
        
        
    message = ''
    actionType = ''
    lsdb = None
    curator_url = ''
    drums_lsdb_url = ''
    lsdb_categories = ['unclassified', 'lovd', 'classical','table','404']
    copr_status =['NOTYET','CLEARED','REQUESTED','PROMISED','OBJECTED']
    genome = ''
    cDNA = ''
    protein = ''
    rscaReport = ''
    
    if drums_lsdb_id:
        #modification
        message = 'MODIFICATION'
        print drums_lsdb_id
        actionType = 'mod'
        sql = 'select gene_symbol,drums_url, hgvs_url, omim_id, drums_categories, genomic_refseq,transcript_refseq,protein_refseq, copr_reqst, rsca_report from lsdb_list WHERE unique_id = "' + drums_lsdb_id + '"'
        lines = pp.execute(sql)
        if lines:
            lsdb = lines[0]
            geneSymbol = lsdb[0]
            omimId = lsdb[3]
            curator_url = lsdb[2]
            drums_lsdb_url = lsdb[1]
            drums_category = lsdb[4]
            
            genome = lsdb[5]
            cDNA = lsdb[6]
            protein = lsdb[7]
            copyrightRequest = lsdb[8]
            if lsdb[9]:
                rscaReport = urllib2.unquote(lsdb[9])
        
    else:
        #submit a new
        if geneSymbol:
            #submit an alternative
            message = 'ALTERNATIVE SUBMISSION'
            
            actionType = 'alt'
        else:
            #submit a new one.
            message = 'LSDB SUBMISSION'
            copyrightRequest = 'NOTYET'
            actionType = 'sub'
%>
<head>
    <script>
        function validateForm(){
            return true;
        }
    </script>
</head>
<link rel="stylesheet" href="../stylesheets/bminfo.css"> 

<h1>${message}</h1>
<div id="form" class="form_div">
<form name="lsdb_form" method="get" action="../mutation/lsdb" onsubmit="return validateForm()">
    <ol>
        <li>
            <label for="name">Gene Symbol:</label>
            <input name="gene_symbol" value = "${geneSymbol}"/></p>
        </li>
        <li>
            <label for="name">UniProtKB:</label>
            <input name="uniprotkb_id" value = ""/></p>
        </li>
        
        
        % if  actionType == 'mod':
            <li>
                <label for="name">DRUMS URL:</label>
                <input name="drums_url" size=80% value = "${drums_lsdb_url}"/>
            </li>
        % endif
        <li>
            <label for="name">Curator URL:</label>
            <input name="curator_url" size=80% value = "${curator_url}"/>
        </li>
        <li>
            <label for="name">Curator emails</label>
            <input name="emails" size=80% value = ""/>
        </li>
        
        
        <li>
        <label for="name">Copyright request:</label>
                          <SELECT name="copr_reqst">
                            %for cs in copr_status:
                                % if cs == copyrightRequest:
                                <OPTION value="${cs}" SELECTED>${cs}</OPTION>
                                % else:
                                <OPTION value="${cs}">${cs}</OPTION>
                                % endif
                            %endfor
                          </SELECT>
        </li>
        <li>
            <label for="name">OMIM ID:</label>
            <input name="omid" value = "${omimId}"/></p>
        </li>
                
        % if actionType == 'mod':
            <li>
            <label for="name">LSDB Category</label>
            <select name='cat'>
              % for cat in lsdb_categories:
                % if drums_category == cat:
                    <option value="${cat}" selected>${cat}</option>
                % else:
                    <option value="${cat}">${cat}</option>
                % endif
              % endfor
            </select>
            </li>
        % endif
        
        <li>
            <label for="name">Genome:</label>
            <input name="gen_ref" value="${genome}"/>
        </li>
        <li>
        <label for="name">cDNA</label>
        <input name="tra_ref" value = "${cDNA}"/>
        %if cDNA:
            <a href="http://www.ncbi.nlm.nih.gov/nuccore/${cDNA}" target="_blank">${cDNA}</a>
        %endif
        </li>
        <li>
            <label>Protein</label>
            <input name="pro_ref" value = "${protein}"/></p>
        </li>
        <!--Curator Identity--> <input type="hidden" name = "curator_id" value = "${userName}" /></p>
        
        <input type = "submit" />
        <input type = "button" value= "Delete" onClick="location.href='../mutation/remove?db=lsdb&uid=${drums_lsdb_id}'"/>
        <input type = "hidden" name= 'uid' value = ${drums_lsdb_id} />
        <input type = "hidden" name= 'act' value = ${actionType} />
        <input type = "hidden" name= 'r' value = 'mt' />
    </ol>
</form>
</div>
<pre>
${webhelpers.html.builder.literal(rscaReport)}
</pre>
