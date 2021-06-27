<%include file="../bminfo_header.html"/>
<%
    import sys, urllib2
    sys.path.append('/home/zuofeng/projects/platform/bminfo/bminfo/scripts')
    from ppMapDB import ppMapMySQL
    pp = ppMapMySQL('bminfo')
    
    params = request.params
    if not params:
        params = request.POST
    
    clientid = 0
    if params.has_key('clientid'):
        clientid = int(params['clientid'])
    
    fields = ['sequential_id','hgnc_gene_Symbol','drum_lsdb_id','dbid','genome_hgvs',' protein_hgvs',' pmid_info','exon_index']
    fieldAliasNames = ['sequential_id','hgnc_gene_Symbol',' drum_lsdb_id',' dbid','nucleotide',' protein',' pmid_info', 'exon_index']


    sql = 'SELECT ' + ','.join(fields) + ' FROM GENOTYPE_PHENOTYPE_PRODUCT WHERE data_status ="init"';
        
        
    type = ''
    value = ''
    ###ATTENTION: The 'value' variable will be changed during processing. If you want to use the original value, please assign a new variable.
    lsdb_drums_id = ''
    if params.has_key('c'):
        type = params['c']
        value = params['t']
    if params.has_key('gensymb'):
        type = 'gensymb'
        value = params['gensymb']
    if type in ['gsymb', 'gensymb']:
        if value:
            sql += ' AND hgnc_gene_Symbol like "%' + value + '%"'
    if type in ['pmid']:
        if value:
            sql += ' AND pmid_info like "%' + value + '%"'
    
    if type in ['lsdb']:
        lsdb_drums_id = value
        if value:
            sql += ' AND drum_lsdb_id =' + value
    
    if type in ['disease']:
        if value:
            #search with disease name
            #try to get db id first
            dbid_list = []
            MUTATION_INDEX_FOLDER = '/home/zuofeng/projects/platform/bminfo/data/mutations/indexes/latest'
            import whoosh.index as index
            ix = index.open_dir(MUTATION_INDEX_FOLDER)
            searcher = ix.searcher()
            value += '|'
            for fds in searcher.all_stored_fields():
                if value in fds['problems']:
                    if not fds['dbid'] in dbid_list:
                        dbid_list.append(fds['dbid'])            
           
            sql += ' AND dbid IN ("' + '","'.join(dbid_list)+ '")'
            
    if params.has_key('exon'):
        value = params['exon']
        if value:
            sql += 'AND exon_index like "%' + value + '%"'
        
    if params.has_key('protein_hgvs'):
        pmut = params.get('protein_hgvs')
        if pmut:
            sql += ' AND protein_hgvs like "%' + pmut + '%"'
    if params.has_key('genome_hgvs'):
        dmut = params.get('genome_hgvs')
        ###print dmut
        if dmut:
            sql += ' AND genome_hgvs like "%' + dmut + '%"'
    if params.has_key('pd'):
        pmid = params.get('pd')
        if pmid:
            sql += ' AND pmid_info like "%' + pmid + '%"'
    
    fussy = 1
    if params.has_key('fm'):
        fussy = int(params['fm'])
    
    if not fussy:
        sql = sql.replace('like', '=')
        sql = sql.replace('%', '')
    ###print sql
    lines = pp.execute(sql)
    
    ###print params
    
    
%>


%if len(lines) > 0:
<head>
<script src="../jquery/extension/jquery.tablesorter-2.0.3.js" type="text/javascript"></script>
<script src="../jquery/extension/jquery.tablesorter.filer.js" type="text/javascript"></script>
<script src="../jquery/extension/jquery.tablesorter.pager.js" type="text/javascript"></script>

<script>
    function downloadDrums(size){                 
        if (size< 1){
                $( "#pagesize" ).val("${len(lines)}");
                $( "#pagesize" ).change();
            }
        
        //$("#pagesize option[value='334']").get(0).selected = true;
        
        isDirty = false;
        var csv_value = $('#drumsTable').table2CSV({
                        separator : '\t',
                        delivery:'value',
                        quote: '',
                        });
        $("#data").val(csv_value);
        //alert(data)
    }
</script>
</head>

<script type="text/javascript">

    
            //known issues: sorting function conficts with google chrome plugin: google dictionary.
            $("#drumsTable").tablesorter({ debug: false, sortList: [[0, 0]], widgets: ['zebra'] })
                        .tablesorterPager({ container: $("#pagerOne"), positionFixed: false })
                        .tablesorterFilter({ filterContainer: $("#filterBoxOne"),
                            filterClearContainer: $("#filterClearOne"),
                            filterColumns: [0, 1, 2, 4,5, 6, 7],
                            filterCaseSensitive: false

                        }); 
    </script>   
%if clientid > 0:
    <form action="http://autumn.ims.uwm.edu:5000/data/download" method="POST">
%else:
    <form action="../data/download" method="POST">
%endif
        <input type="hidden" name="data" id="data"/>
        
        <input type="submit" value="dowload showing entries" onclick="downloadDrums(1)"/>
        </td>
        
        <input type="submit" value="dowload all ${len(lines)} entries" onclick="downloadDrums(0)"/>

</form>
<table id="drumsTable" class="yui">
    <thead>
         <tr>
                    
                    
            
          

            <td colspan="12" class="filter">
                Filter hits: <input id="filterBoxOne" value="" maxlength="30" size="30" type="text">
                <img id="filterClearOne" src="../img/cross.png" title="Click to clear filter." alt="Clear Filter Image">
            </td>
         </tr> 	
        <tr>
            %for i in range(len(fields)):
                <th class="header"><a href="." title="Click Header to Sort">${fieldAliasNames[i]}</a></th>
            %endfor
        </tr>
    </thead>
    <tbody>
        %for line in lines:
            <tr>
                %for f in line:
                    <td>${f}</td>
                %endfor
            </tr>
        %endfor 
    </tbody>

    <tfoot>
        <tr id="pagerOne">
            <td colspan="7" >
                <img src="../img/first.png" class="first">
                <img src="../img/prev.png" class="prev">
                <input type="text" class="pagedisplay">
                <img src="../img/next.png" class="next">
                <img src="../img/last.png" class="last">
                <select id="pagesize" class="pagesize">
                    <option value="10">10</option>
                    <option selected="selected" value="20">20</option>
                    <option value="30">30</option>
                    <option  value="50">50</option>
                    <option  value="100">100</option>
                    <option  value="${len(lines)}">All</option>
                </select>
            </td>
            <td>
            </td>
        </tr>
    </tfoot>    
</table>
<script type="text/javascript" src="../jquery/extension/table2CSV.js" > </script>
%else:
    No results matching your query.
    %if type == 'lsdb':
    <a href="http://autumn.ims.uwm.edu:5000/mutation/lsdb?r=mt&uid=${lsdb_drums_id}" target="_blank">${lsdb_drums_id}<img src="../img/structure/lock_small.jpg"/></a></td>
    %endif
%endif